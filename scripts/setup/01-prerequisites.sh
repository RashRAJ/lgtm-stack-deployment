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
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_fail() { echo -e "${RED}[✗]${NC} $1"; }

# Check if a command exists
check_command() {
    local cmd=$1
    local install_msg=$2
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        print_success "$cmd found: $version"
        return 0
    else
        print_fail "$cmd not found"
        print_info "Installation: $install_msg"
        return 1
    fi
}

# Check Terraform version
check_terraform() {
    if command -v terraform &> /dev/null; then
        local version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || terraform --version | head -n 1)
        local major_minor=$(echo $version | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
        
        if (( $(echo "$major_minor >= 1.5" | bc -l) )); then
            print_success "terraform found: $version (meets minimum requirement 1.5.0)"
            return 0
        else
            print_fail "terraform version $version is below minimum requirement 1.5.0"
            return 1
        fi
    else
        print_fail "terraform not found"
        print_info "Installation: https://developer.hashicorp.com/terraform/install"
        return 1
    fi
}

# Main checks
main() {
    print_info "Checking prerequisites for LGTM Stack deployment..."
    echo ""
    
    local all_good=true
    
    # Required tools
    print_info "Checking required tools..."
    
    check_terraform || all_good=false
    
    check_command "gcloud" "https://cloud.google.com/sdk/docs/install" || all_good=false
    
    check_command "kubectl" "https://kubernetes.io/docs/tasks/tools/" || all_good=false
    
    check_command "git" "https://git-scm.com/downloads" || all_good=false
    
    echo ""
    
    # Optional but recommended tools
    print_info "Checking optional tools..."
    
    check_command "jq" "https://jqlang.github.io/jq/download/" || true
    
    check_command "yq" "https://github.com/mikefarah/yq#install" || true
    
    check_command "helm" "https://helm.sh/docs/intro/install/" || true
    
    check_command "argocd" "https://argo-cd.readthedocs.io/en/stable/cli_installation/" || true
    
    echo ""
    
    # Check gcloud configuration
    print_info "Checking gcloud configuration..."
    
    if gcloud config get-value project &> /dev/null; then
        local project=$(gcloud config get-value project)
        print_success "gcloud configured with project: $project"
    else
        print_fail "gcloud project not configured"
        print_info "Run: gcloud config set project YOUR_PROJECT_ID"
        all_good=false
    fi
    
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        local account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        print_success "gcloud authenticated as: $account"
    else
        print_fail "gcloud not authenticated"
        print_info "Run: gcloud auth login"
        all_good=false
    fi
    
    echo ""
    
    # Check APIs
    print_info "Checking required GCP APIs..."
    
    local required_apis=(
        "compute.googleapis.com"
        "container.googleapis.com"
        "storage.googleapis.com"
        "dns.googleapis.com"
        "iam.googleapis.com"
    )
    
    for api in "${required_apis[@]}"; do
        if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
            print_success "$api enabled"
        else
            print_warn "$api not enabled"
            print_info "Enable with: gcloud services enable $api"
            all_good=false
        fi
    done
    
    echo ""
    
    # Summary
    if [ "$all_good" = true ]; then
        print_success "All prerequisites met! You can proceed with the deployment."
        print_info "Next step: Run ./scripts/setup/02-gcp-setup.sh"
    else
        print_error "Some prerequisites are missing. Please install them before proceeding."
        exit 1
    fi
}

# Run main function
main "$@"