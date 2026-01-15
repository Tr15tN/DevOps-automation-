#!/bin/bash
# Master Deployment Script for Automation Alchemy
# Works in WSL, Linux, Mac, and Git Bash
# Handles Terraform + Ansible deployment with automatic resource import

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

# Flags
SKIP_TERRAFORM=false
SKIP_ANSIBLE=false
DESTROY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
            ;;
        --skip-ansible)
            SKIP_ANSIBLE=true
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--skip-terraform] [--skip-ansible] [--destroy]"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    if ! check_command terraform; then
        log_error "Terraform not found. Install from https://www.terraform.io/downloads"
        missing=1
    fi
    
    if ! check_command gcloud; then
        log_error "gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install"
        missing=1
    fi
    
    if [ "$SKIP_ANSIBLE" = false ]; then
        if ! check_command ansible; then
            log_error "Ansible not found. Install with: sudo apt install ansible (in WSL)"
            missing=1
        fi
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Please install missing prerequisites and try again"
        exit 1
    fi
    
    log_success "All prerequisites found"
}

# Check GCP authentication
check_gcp_auth() {
    log_info "Checking GCP authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "Not authenticated with GCP. Run: gcloud auth login"
        exit 1
    fi
    
    log_success "GCP authentication verified"
}

# Import existing resources if they exist
import_existing_resources() {
    log_info "Checking for existing resources that need to be imported..."
    
    cd "$TERRAFORM_DIR"
    
    # Get project ID from terraform.tfvars
    if [ ! -f terraform.tfvars ]; then
        log_warning "terraform.tfvars not found, skipping import check"
        return 0
    fi
    
    PROJECT_ID=$(grep -E "^project_id\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
    REGION=$(grep -E "^region\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
    
    if [ -z "$PROJECT_ID" ]; then
        log_warning "Could not determine project_id, skipping import check"
        return 0
    fi
    if [ -z "$REGION" ]; then
        log_warning "Could not determine region, skipping subnet import check"
    fi
    
    # Check and import VPC network if it exists
    if gcloud compute networks describe automation-alchemy-vpc --project="$PROJECT_ID" &>/dev/null; then
        log_info "Found existing VPC network, importing into Terraform state..."
        if terraform import google_compute_network.main "projects/$PROJECT_ID/global/networks/automation-alchemy-vpc" 2>/dev/null; then
            log_success "VPC network imported"
        else
            log_warning "VPC network already in state or import failed (this is OK)"
        fi
    fi

    # Check and import subnet if it exists
    if [ -n "$REGION" ] && gcloud compute networks subnets describe automation-alchemy-subnet \
        --region="$REGION" \
        --project="$PROJECT_ID" &>/dev/null; then
        log_info "Found existing subnet, importing into Terraform state..."
        if terraform import google_compute_subnetwork.main \
            "projects/$PROJECT_ID/regions/$REGION/subnetworks/automation-alchemy-subnet" 2>/dev/null; then
            log_success "Subnet imported"
        else
            log_warning "Subnet already in state or import failed (this is OK)"
        fi
    fi
    
    # Check and import service account if it exists
    if gcloud iam service-accounts describe automation-alchemy-vm-sa@"$PROJECT_ID".iam.gserviceaccount.com --project="$PROJECT_ID" &>/dev/null; then
        log_info "Found existing service account, importing into Terraform state..."
        if terraform import google_service_account.vm_service_account "projects/$PROJECT_ID/serviceAccounts/automation-alchemy-vm-sa@$PROJECT_ID.iam.gserviceaccount.com" 2>/dev/null; then
            log_success "Service account imported"
        else
            log_warning "Service account already in state or import failed (this is OK)"
        fi
    fi

    # Check and import firewall rules if they exist
    declare -A firewall_rules=(
        ["allow-ssh"]="ssh"
        ["allow-http"]="http"
        ["allow-haproxy-stats"]="haproxy_stats"
        ["allow-netdata"]="netdata"
        ["allow-internal"]="internal"
    )
    for rule in "${!firewall_rules[@]}"; do
        if gcloud compute firewall-rules describe "$rule" --project="$PROJECT_ID" &>/dev/null; then
            log_info "Found existing firewall rule ($rule), importing into Terraform state..."
            if terraform import "google_compute_firewall.${firewall_rules[$rule]}" \
                "projects/$PROJECT_ID/global/firewalls/$rule" 2>/dev/null; then
                log_success "Firewall rule ($rule) imported"
            else
                log_warning "Firewall rule ($rule) already in state or import failed (this is OK)"
            fi
        fi
    done
}

# Check SSH key
check_ssh_key() {
    log_info "Checking SSH key..."
    
    # Try to find SSH key in common locations
    SSH_KEY_PATHS=(
        "$HOME/.ssh/id_rsa.pub"
    )
    
    # Add Windows paths if we can determine the username
    if [ -n "${USER:-}" ]; then
        SSH_KEY_PATHS+=("/mnt/c/Users/$USER/.ssh/id_rsa.pub")
    fi
    if [ -n "${USERNAME:-}" ]; then
        SSH_KEY_PATHS+=("/mnt/c/Users/$USERNAME/.ssh/id_rsa.pub")
    fi
    # Also try common Windows usernames
    SSH_KEY_PATHS+=("/mnt/c/Users/M0usetrap/.ssh/id_rsa.pub")
    
    SSH_KEY=""
    for path in "${SSH_KEY_PATHS[@]}"; do
        if [ -f "$path" ]; then
            SSH_KEY="$path"
            break
        fi
    done
    
    if [ -z "$SSH_KEY" ]; then
        log_warning "SSH public key not found. Generating one..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" || {
            log_error "Failed to generate SSH key"
            exit 1
        }
        SSH_KEY="$HOME/.ssh/id_rsa.pub"
        log_success "SSH key generated at $SSH_KEY"
    else
        log_success "SSH key found at $SSH_KEY"
    fi
}

# Run Terraform
run_terraform() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        log_info "Skipping Terraform (--skip-terraform flag set)"
        return 0
    fi
    
    log_info "Running Terraform..."
    cd "$TERRAFORM_DIR"
    
    # Check terraform.tfvars
    if [ ! -f terraform.tfvars ]; then
        log_error "terraform.tfvars not found. Create it from terraform.tfvars.example"
        exit 1
    fi
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Import existing resources
    import_existing_resources
    
    if [ "$DESTROY" = true ]; then
        log_warning "Destroying infrastructure..."
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
        return 0
    fi
    
    # Plan
    log_info "Planning Terraform changes..."
    terraform plan -out=tfplan
    
    # Apply
    log_info "Applying Terraform changes..."
    terraform apply tfplan
    
    log_success "Terraform apply completed"
}

# Update Ansible inventory
update_ansible_inventory() {
    if [ "$SKIP_ANSIBLE" = true ]; then
        return 0
    fi
    
    log_info "Updating Ansible inventory from Terraform outputs..."
    
    cd "$TERRAFORM_DIR"
    
    # Check if terraform state exists
    if [ ! -f terraform.tfstate ]; then
        log_error "Terraform state not found. Run Terraform first."
        exit 1
    fi
    
    # Run the inventory update script
    if [ -f "$ANSIBLE_DIR/scripts/update-inventory.sh" ]; then
        bash "$ANSIBLE_DIR/scripts/update-inventory.sh"
    else
        log_warning "Inventory update script not found, skipping automatic update"
    fi
}

# Run Ansible
run_ansible() {
    if [ "$SKIP_ANSIBLE" = true ]; then
        log_info "Skipping Ansible (--skip-ansible flag set)"
        return 0
    fi
    
    if [ "$DESTROY" = true ]; then
        log_info "Skipping Ansible (destroy mode)"
        return 0
    fi
    
    log_info "Running Ansible playbooks..."
    cd "$ANSIBLE_DIR"

    if [ ! -f ansible.cfg ]; then
        log_error "ansible.cfg not found in $ANSIBLE_DIR"
        exit 1
    fi

    # Work around world-writable WSL path by copying config to a safe location
    SAFE_ANSIBLE_CONFIG="/tmp/automation-alchemy-ansible.cfg"
    cp ansible.cfg "$SAFE_ANSIBLE_CONFIG"
    chmod 600 "$SAFE_ANSIBLE_CONFIG"
    export ANSIBLE_CONFIG="$SAFE_ANSIBLE_CONFIG"
    
    # Check inventory
    if [ ! -f inventory/hosts.yml ]; then
        log_error "Ansible inventory not found. Run inventory update first."
        exit 1
    fi
    
    # Install Ansible requirements if needed
    if [ -f requirements.yml ]; then
        log_info "Installing Ansible requirements..."
        ansible-galaxy install -r requirements.yml
    fi
    
    # Run playbooks
    log_info "Running Ansible site playbook..."
    ansible-playbook playbooks/site.yml -i inventory/hosts.yml
    
    log_success "Ansible deployment completed"
}

# Main execution
main() {
    echo -e "${CYAN}🚀 Automation Alchemy Deployment Script${NC}"
    echo ""
    
    check_prerequisites
    check_gcp_auth
    check_ssh_key
    
    run_terraform
    update_ansible_inventory
    run_ansible
    
    if [ "$DESTROY" = false ]; then
        log_success "Deployment completed successfully!"
        echo ""
        log_info "To view VM information, run:"
        echo "  cd terraform && terraform output"
    fi
}

# Run main function
main
