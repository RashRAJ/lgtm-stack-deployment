#!/bin/bash

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

# Check if we're in the right directory
if [ ! -f "infrastructure/environments/production/main.tf" ]; then
    print_error "Please run this script from the repository root directory"
    exit 1
fi

print_info "Starting Terraform infrastructure setup..."

# Navigate to production environment
cd infrastructure/environments/production

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found!"
    print_info "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warn "Please edit terraform.tfvars with your values before continuing"
    exit 1
fi

# Create outputs directory if it doesn't exist
mkdir -p outputs

# Create cluster values template if it doesn't exist
if [ ! -f "templates/cluster-values.yaml.tpl" ]; then
    print_info "Creating cluster values template..."
    mkdir -p templates
    cat > templates/cluster-values.yaml.tpl << 'EOF'
# Auto-generated cluster values for ArgoCD
cluster:
  name: ${cluster_name}
  ingressIP: ${ingress_ip}

storage:
  loki:
    bucket: ${loki_bucket}
    serviceAccount: ${loki_service_account}
  mimir:
    bucket: ${mimir_bucket}
    serviceAccount: ${mimir_service_account}

serviceAccounts:
  certManager: ${cert_manager_service_account}

domains:
  grafana: ${grafana_domain}
  argocd: ${argocd_domain}
EOF
fi

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_info "Validating Terraform configuration..."
terraform validate

# Plan Terraform deployment
print_info "Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    print_warn "Terraform apply cancelled"
    exit 0
fi

# Apply Terraform
print_info "Applying Terraform configuration..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Get outputs
print_info "Retrieving outputs..."
terraform output -json > outputs/terraform-outputs.json

# Display summary
print_info "Infrastructure deployment complete!"
echo ""
terraform output deployment_summary

# Create kubeconfig
print_info "Configuring kubectl..."
eval $(terraform output -raw kubectl_command)

# Verify cluster access
if kubectl cluster-info &> /dev/null; then
    print_info "Successfully connected to cluster"
else
    print_error "Failed to connect to cluster"
    exit 1
fi

print_info "Next steps:"
echo "1. Review the cluster values in outputs/cluster-values.yaml"
echo "2. Run ./scripts/setup/04-bootstrap-argocd.sh to install ArgoCD"
echo "3. Commit the outputs/cluster-values.yaml to your git repository"