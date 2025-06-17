#!/bin/bash
# scripts/setup/04-bootstrap-argocd.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please configure kubectl first."
        exit 1
    fi
    
    # Check if ArgoCD namespace already exists
    if kubectl get namespace argocd &> /dev/null; then
        print_warn "ArgoCD namespace already exists. Do you want to continue? (yes/no)"
        read -p "> " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Exiting..."
            exit 0
        fi
    fi
}

# Create ArgoCD namespace
create_namespace() {
    print_info "Creating ArgoCD namespace..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
}

# Install ArgoCD
install_argocd() {
    print_info "Installing ArgoCD..."
    
    # Get the latest stable version
    ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    print_info "Installing ArgoCD version: $ARGOCD_VERSION"
    
    # Apply ArgoCD manifests
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    print_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n argocd
}

# Configure ArgoCD for ingress
configure_ingress() {
    print_info "Configuring ArgoCD for ingress access..."
    
    # Get ingress IP from Terraform outputs
    if [ -f "infrastructure/environments/production/outputs/terraform-outputs.json" ]; then
        INGRESS_IP=$(jq -r '.ingress_ip.value' infrastructure/environments/production/outputs/terraform-outputs.json)
        ARGOCD_DOMAIN=$(jq -r '.argocd_url.value' infrastructure/environments/production/outputs/terraform-outputs.json | sed 's|https://||')
        
        print_info "Using ingress IP: $INGRESS_IP"
        print_info "ArgoCD domain: $ARGOCD_DOMAIN"
    else
        print_warn "Terraform outputs not found. Please enter values manually."
        read -p "Enter ingress IP: " INGRESS_IP
        read -p "Enter ArgoCD domain (e.g., argocd.yourdomain.com): " ARGOCD_DOMAIN
    fi
    
    # Create ArgoCD ingress
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - ${ARGOCD_DOMAIN}
    secretName: argocd-server-tls
  rules:
  - host: ${ARGOCD_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
}

# Get ArgoCD admin password
get_admin_password() {
    print_info "Getting ArgoCD admin password..."
    
    # Get the initial admin secret
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    print_info "ArgoCD admin credentials:"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
    echo ""
    print_warn "Please save these credentials and change the password after first login!"
}

# Configure ArgoCD CLI (optional)
configure_cli() {
    print_info "Do you want to install ArgoCD CLI? (yes/no)"
    read -p "> " install_cli
    
    if [ "$install_cli" == "yes" ]; then
        print_info "Installing ArgoCD CLI..."
        
        # Detect OS
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)
        
        if [ "$ARCH" == "x86_64" ]; then
            ARCH="amd64"
        fi
        
        # Download and install
        curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${OS}-${ARCH}
        chmod +x /tmp/argocd
        
        print_info "Moving ArgoCD CLI to /usr/local/bin (requires sudo)..."
        sudo mv /tmp/argocd /usr/local/bin/argocd
        
        print_info "ArgoCD CLI installed successfully"
    fi
}

# Create App of Apps
create_app_of_apps() {
    print_info "Creating App of Apps configuration..."
    
    # Check if the app-of-apps.yaml exists
    if [ ! -f "kubernetes/applications/app-of-apps.yaml" ]; then
        print_warn "app-of-apps.yaml not found. Creating template..."
        
        mkdir -p kubernetes/applications
        
        cat <<'EOF' > kubernetes/applications/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME
    targetRevision: HEAD
    path: kubernetes/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
        
        print_warn "Please update kubernetes/applications/app-of-apps.yaml with your GitHub repository details"
        print_info "Then run: kubectl apply -f kubernetes/applications/app-of-apps.yaml"
    else
        print_info "Applying App of Apps..."
        kubectl apply -f kubernetes/applications/app-of-apps.yaml
    fi
}

# Main execution
main() {
    print_info "Starting ArgoCD bootstrap process..."
    
    check_prerequisites
    create_namespace
    install_argocd
    configure_ingress
    get_admin_password
    configure_cli
    create_app_of_apps
    
    print_info "ArgoCD bootstrap complete!"
    print_info "Access ArgoCD at: https://${ARGOCD_DOMAIN}"
    print_info "Next steps:"
    echo "1. Update kubernetes/applications/app-of-apps.yaml with your repository URL"
    echo "2. Apply the App of Apps: kubectl apply -f kubernetes/applications/app-of-apps.yaml"
    echo "3. Create and push your application manifests to the repository"
    echo "4. Install NGINX Ingress Controller and cert-manager through ArgoCD"
}

# Run main function
main "$@"