#!/bin/bash
# One-Click Deployment Script for Automation Alchemy
# Interactive deployment and testing script

# Don't exit on error in interactive mode - we want to continue showing menu
# Individual functions will handle their own error checking
set +e

# Fix encoding - use Python encoding (works without locale)
# Don't set locale variables at script start - let individual functions handle it
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
step() { echo -e "\n${CYAN}🔷 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
TESTS_DIR="$PROJECT_ROOT/tests"

# Get VM IP from Terraform
get_vm_ip() {
    cd "$TERRAFORM_DIR"
    if terraform output -json vm_instances &> /dev/null; then
        VM_IP=$(terraform output -json vm_instances | jq -r 'to_entries[0].value.external_ip' 2>/dev/null || \
                terraform output vm_instances | grep external_ip | head -n 1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
        
        # If external IP is empty, VM might be stopped - try to get it from gcloud
        if [ -z "$VM_IP" ] || [ "$VM_IP" = "null" ] || [ "$VM_IP" = '""' ]; then
            VM_NAME=$(terraform output -json vm_instances | jq -r 'to_entries[0].value.name' 2>/dev/null || \
                     terraform output vm_instances | grep name | head -n 1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
            ZONE=$(terraform output -json vm_instances | jq -r 'to_entries[0].value.zone' 2>/dev/null || \
                   terraform output vm_instances | grep zone | head -n 1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
            PROJECT_ID=$(terraform output -json project_info | jq -r '.project_id' 2>/dev/null || \
                        terraform output project_info | grep project_id | sed -n 's/.*"\([^"]*\)".*/\1/p')
            
            if [ -n "$VM_NAME" ] && [ -n "$ZONE" ] && [ -n "$PROJECT_ID" ]; then
                # Try to get IP from gcloud
                VM_IP=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" \
                        --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")
            fi
        fi
        
        echo "$VM_IP"
    else
        echo ""
    fi
}

# Check and start VM if stopped
ensure_vm_running() {
    cd "$TERRAFORM_DIR"
    
    VM_NAME=$(terraform output -json vm_instances | jq -r 'to_entries[0].value.name' 2>/dev/null || \
             terraform output vm_instances | grep name | head -n 1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
    ZONE=$(terraform output -json vm_instances | jq -r 'to_entries[0].value.zone' 2>/dev/null || \
           terraform output vm_instances | grep zone | head -n 1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
    PROJECT_ID=$(terraform output -json project_info | jq -r '.project_id' 2>/dev/null || \
                terraform output project_info | grep project_id | sed -n 's/.*"\([^"]*\)".*/\1/p')
    
    if [ -z "$VM_NAME" ] || [ -z "$ZONE" ] || [ -z "$PROJECT_ID" ]; then
        warning "Could not get VM information from Terraform"
        return 1
    fi
    
    # Check VM status
    VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" \
                --format="get(status)" 2>/dev/null || echo "UNKNOWN")
    
    if [ "$VM_STATUS" = "TERMINATED" ] || [ "$VM_STATUS" = "STOPPED" ]; then
        warning "VM is stopped. Starting VM..."
        info "This may take a minute..."
        gcloud compute instances start "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID"
        
        if [ $? -eq 0 ]; then
            success "VM started successfully"
            info "Waiting for VM to be ready (30 seconds)..."
            sleep 30
            return 0
        else
            error "Failed to start VM"
            return 1
        fi
    elif [ "$VM_STATUS" = "RUNNING" ]; then
        info "VM is already running"
        return 0
    else
        warning "VM status: $VM_STATUS"
        return 1
    fi
}

# Detect environment
detect_environment() {
    if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
        echo "WSL"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$MSYSTEM" == "MINGW"* ]] || [[ -n "$WINDIR" ]]; then
        echo "GitBash"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pacman &> /dev/null; then
            echo "ArchLinux"
        elif command -v apt-get &> /dev/null; then
            echo "DebianUbuntu"
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            echo "RedHat"
        else
            echo "Linux"
        fi
    else
        echo "Unknown"
    fi
}

# Install Terraform
install_terraform() {
    local env=$1
    info "Installing Terraform..."
    
    case "$env" in
        WSL|DebianUbuntu)
            info "Detected WSL/Ubuntu. Installing Terraform..."
            if command -v curl &> /dev/null && command -v unzip &> /dev/null; then
                TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
                info "Downloading Terraform v${TERRAFORM_VERSION}..."
                curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
                unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                sudo mv terraform /usr/local/bin/
                rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                success "Terraform installed successfully"
                return 0
            else
                error "curl and unzip are required. Install with: sudo apt install curl unzip"
                return 1
            fi
            ;;
        ArchLinux)
            info "Detected Arch Linux. Installing Terraform..."
            if command -v yay &> /dev/null; then
                yay -S terraform --noconfirm
            elif command -v paru &> /dev/null; then
                paru -S terraform --noconfirm
            else
                error "Please install yay or paru first, or install Terraform manually"
                return 1
            fi
            ;;
        GitBash)
            warning "Terraform installation in Git Bash is not automated."
            info "Please install Terraform manually:"
            info "1. Download from: https://www.terraform.io/downloads"
            info "2. Extract and add to PATH"
            info "Or use WSL: wsl --install"
            return 1
            ;;
        *)
            error "Automatic Terraform installation not supported for this environment"
            info "Please install manually from: https://www.terraform.io/downloads"
            return 1
            ;;
    esac
}

# Install Ansible
install_ansible() {
    local env=$1
    info "Installing Ansible..."
    
    case "$env" in
        WSL|DebianUbuntu)
            info "Detected WSL/Ubuntu. Installing Ansible..."
            sudo apt update
            sudo apt install -y ansible
            success "Ansible installed successfully"
            return 0
            ;;
        ArchLinux)
            info "Detected Arch Linux. Installing Ansible..."
            sudo pacman -S --noconfirm ansible
            success "Ansible installed successfully"
            return 0
            ;;
        RedHat)
            info "Detected RedHat/CentOS. Installing Ansible..."
            sudo yum install -y ansible || sudo dnf install -y ansible
            success "Ansible installed successfully"
            return 0
            ;;
        GitBash)
            warning "Ansible cannot run in Git Bash due to encoding issues."
            info "Please use WSL instead:"
            info "1. Install WSL: wsl --install"
            info "2. In WSL: sudo apt update && sudo apt install -y ansible"
            return 1
            ;;
        *)
            error "Automatic Ansible installation not supported for this environment"
            info "Please install manually from: https://docs.ansible.com/ansible/latest/installation_guide/index.html"
            return 1
            ;;
    esac
}

# Install jq
install_jq() {
    local env=$1
    info "Installing jq..."
    
    case "$env" in
        WSL|DebianUbuntu)
            sudo apt install -y jq
            success "jq installed successfully"
            return 0
            ;;
        ArchLinux)
            sudo pacman -S --noconfirm jq
            success "jq installed successfully"
            return 0
            ;;
        RedHat)
            sudo yum install -y jq || sudo dnf install -y jq
            success "jq installed successfully"
            return 0
            ;;
        GitBash)
            warning "jq installation in Git Bash is not automated."
            info "Please install jq manually or use WSL"
            return 1
            ;;
        *)
            error "Automatic jq installation not supported for this environment"
            return 1
            ;;
    esac
}

# Install gcloud CLI
install_gcloud() {
    local env=$1
    info "Installing gcloud CLI..."
    
    case "$env" in
        WSL|DebianUbuntu|ArchLinux|RedHat|Linux)
            info "Installing gcloud CLI..."
            if [ ! -f ~/google-cloud-sdk/install.sh ]; then
                curl https://sdk.cloud.google.com | bash
                exec -l $SHELL
            fi
            info "gcloud CLI installed. Please run: gcloud init"
            return 0
            ;;
        GitBash)
            warning "gcloud CLI installation in Git Bash is not automated."
            info "Please install manually from: https://cloud.google.com/sdk/docs/install"
            info "Or use WSL"
            return 1
            ;;
        *)
            error "Automatic gcloud installation not supported for this environment"
            return 1
            ;;
    esac
}

# Validate Prerequisites with installation help
test_prerequisites() {
    local skip_terraform=$1
    local skip_ansible=$2
    
    step "Validating Prerequisites"
    
    local ENV=$(detect_environment)
    info "Detected environment: $ENV"
    
    local prerequisites_met=true
    local missing_tools=()
    
    # Check Terraform
    if [ "$skip_terraform" = false ]; then
        if command -v terraform &> /dev/null; then
            TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n 1)
            success "Terraform found: $TERRAFORM_VERSION"
        else
            error "Terraform not found"
            missing_tools+=("terraform")
            prerequisites_met=false
        fi
    fi
    
    # Check gcloud CLI
    if command -v gcloud &> /dev/null; then
        GCLOUD_VERSION=$(gcloud version --format="value(Google Cloud SDK)" 2>/dev/null || echo "installed")
        success "gcloud CLI found: $GCLOUD_VERSION"
        
        # Check for user authentication
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
            success "GCP user authentication verified"
        else
            warning "GCP user not authenticated"
            info "Run: gcloud auth login"
        fi
        
        # Check for application default credentials (required for Terraform)
        if gcloud auth application-default print-access-token &> /dev/null 2>&1; then
            success "GCP application default credentials verified"
        else
            error "GCP application default credentials not set (required for Terraform)"
            warning "Terraform needs application-default credentials to authenticate with GCP"
            echo ""
            # Always read from /dev/tty to ensure we get user input
            echo "Would you like to set up GCP authentication now? (y/n): " >/dev/tty
            read -r AUTH_CHOICE </dev/tty
            
            if [ "$AUTH_CHOICE" = "y" ] || [ "$AUTH_CHOICE" = "Y" ]; then
                info "Setting up GCP application-default credentials..."
                
                # Check if we're in WSL (no GUI browser available)
                if grep -qi microsoft /proc/version 2>/dev/null || [ -n "$WSL_DISTRO_NAME" ]; then
                    info "Detected WSL environment - using manual authentication"
                    info "This will provide a URL to copy and paste in your browser"
                    echo ""
                    warning "In WSL, you need to:"
                    warning "1. Copy the URL that will be shown"
                    warning "2. Open it in your Windows browser (not WSL)"
                    warning "3. Complete authentication in the browser"
                    warning "4. Copy the authorization code back to this terminal"
                    echo ""
                    read -r -p "Press Enter to continue..." </dev/tty
                    echo ""
                    gcloud auth application-default login --no-launch-browser
                else
                    info "This will open a browser for authentication..."
                    gcloud auth application-default login
                fi
                
                if [ $? -eq 0 ]; then
                    success "GCP authentication configured"
                else
                    error "Failed to set up authentication"
                    echo ""
                    error "Manual setup instructions:"
                    error "1. Run: gcloud auth application-default login --no-launch-browser"
                    error "2. Copy the URL shown and open it in your browser"
                    error "3. Complete authentication and paste the code back"
                    prerequisites_met=false
                fi
            else
                error "GCP authentication required. Run: gcloud auth application-default login"
                prerequisites_met=false
            fi
        fi
    else
        error "gcloud CLI not found (required for Terraform)"
        missing_tools+=("gcloud")
        prerequisites_met=false
    fi
    
    # Check Ansible
    if [ "$skip_ansible" = false ]; then
        if command -v ansible &> /dev/null; then
            ANSIBLE_VERSION=$(ansible --version | head -n 1)
            success "Ansible found: $ANSIBLE_VERSION"
        else
            error "Ansible not found"
            missing_tools+=("ansible")
            prerequisites_met=false
        fi
    fi
    
    # Check jq (optional but helpful)
    if command -v jq &> /dev/null; then
        success "jq found (optional tool)"
    else
        warning "jq not found (optional - helps with inventory updates)"
        missing_tools+=("jq")
    fi
    
    # Offer to install missing tools
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo ""
        warning "Missing tools: ${missing_tools[*]}"
        # Read from /dev/tty to ensure we get user input
        if [ -t 0 ]; then
            read -r -p "Would you like to install missing tools automatically? (y/n): " INSTALL_CHOICE </dev/tty
        else
            echo "Would you like to install missing tools automatically? (y/n): " >/dev/tty
            read -r INSTALL_CHOICE </dev/tty
        fi
        
        if [ "$INSTALL_CHOICE" = "y" ] || [ "$INSTALL_CHOICE" = "Y" ]; then
            for tool in "${missing_tools[@]}"; do
                case "$tool" in
                    terraform)
                        if [ "$skip_terraform" = false ]; then
                            install_terraform "$ENV"
                        fi
                        ;;
                    ansible)
                        if [ "$skip_ansible" = false ]; then
                            install_ansible "$ENV"
                        fi
                        ;;
                    jq)
                        install_jq "$ENV"
                        ;;
                    gcloud)
                        install_gcloud "$ENV"
                        ;;
                esac
            done
            
            # Re-check prerequisites
            echo ""
            info "Re-checking prerequisites..."
            prerequisites_met=true
            
            if [ "$skip_terraform" = false ] && ! command -v terraform &> /dev/null; then
                prerequisites_met=false
            fi
            
            if [ "$skip_ansible" = false ] && ! command -v ansible &> /dev/null; then
                prerequisites_met=false
            fi
        else
            echo ""
            info "Installation skipped. Please install missing tools manually:"
            for tool in "${missing_tools[@]}"; do
                case "$tool" in
                    terraform)
                        info "  Terraform: https://www.terraform.io/downloads"
                        if [ "$ENV" = "WSL" ] || [ "$ENV" = "DebianUbuntu" ]; then
                            info "    Or run: curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
                            info "    sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\""
                            info "    sudo apt update && sudo apt install terraform"
                        fi
                        ;;
                    ansible)
                        info "  Ansible: https://docs.ansible.com/ansible/latest/installation_guide/index.html"
                        if [ "$ENV" = "WSL" ] || [ "$ENV" = "DebianUbuntu" ]; then
                            info "    Or run: sudo apt update && sudo apt install -y ansible"
                        fi
                        ;;
                    jq)
                        info "  jq: https://stedolan.github.io/jq/download/"
                        if [ "$ENV" = "WSL" ] || [ "$ENV" = "DebianUbuntu" ]; then
                            info "    Or run: sudo apt install -y jq"
                        fi
                        ;;
                    gcloud)
                        info "  gcloud: https://cloud.google.com/sdk/docs/install"
                        ;;
                esac
            done
        fi
    fi
    
    if [ "$prerequisites_met" = false ]; then
        error "Prerequisites not met. Please install missing tools and try again."
        return 1
    fi
    
    success "All prerequisites met!"
    return 0
}

# Check Terraform Configuration
test_terraform_config() {
    step "Checking Terraform Configuration"
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            warning "terraform.tfvars not found. Creating from example..."
            cp terraform.tfvars.example terraform.tfvars
            success "Created terraform.tfvars"
            warning "⚠️  IMPORTANT: Edit terraform/terraform.tfvars and set your project_id!"
            if [ -t 0 ]; then
                read -r -p "Press Enter after you've edited terraform.tfvars (or Ctrl+C to cancel)..." </dev/tty
            else
                echo "Press Enter after you've edited terraform.tfvars (or Ctrl+C to cancel)..." >/dev/tty
                read -r </dev/tty
            fi
        else
            error "terraform.tfvars not found and no example file available"
            return 1
        fi
    fi
    
    # Check SSH key
    SSH_KEY_PATH=$(grep "ssh_public_key_path" terraform.tfvars | sed -n 's/.*"\([^"]*\)".*/\1/p' | sed "s|~|$HOME|")
    
    # Convert Windows path to WSL path if needed
    if [[ "$SSH_KEY_PATH" =~ ^[A-Za-z]: ]]; then
        DRIVE_LETTER=$(echo "$SSH_KEY_PATH" | cut -d: -f1 | tr '[:upper:]' '[:lower:]')
        PATH_PART=$(echo "$SSH_KEY_PATH" | cut -d: -f2 | tr '\\' '/' | sed 's|^/||')
        SSH_KEY_PATH="/mnt/$DRIVE_LETTER/$PATH_PART"
    fi
    
    if [ -n "$SSH_KEY_PATH" ]; then
        if [ ! -f "$SSH_KEY_PATH" ]; then
            warning "SSH key not found at: $SSH_KEY_PATH"
            if [ -t 0 ]; then
                read -r -p "Generate SSH key? (y/n): " GENERATE_KEY </dev/tty
            else
                echo "Generate SSH key? (y/n): " >/dev/tty
                read -r GENERATE_KEY </dev/tty
            fi
            if [ "$GENERATE_KEY" = "y" ] || [ "$GENERATE_KEY" = "Y" ]; then
                PRIVATE_KEY_PATH="${SSH_KEY_PATH%.pub}"
                ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N ""
                success "SSH key generated"
            else
                error "SSH key required. Exiting."
                return 1
            fi
        else
            success "SSH key found: $SSH_KEY_PATH"
        fi
    fi
    
    return 0
}

# Run Terraform Operations
invoke_terraform_deploy() {
    local destroy=$1
    
    step "Terraform Operations"
    
    cd "$TERRAFORM_DIR"
    
    info "Initializing Terraform..."
    terraform init
    success "Terraform initialized"
    
    if [ "$destroy" = true ]; then
        warning "DESTROYING infrastructure..."
        if [ -t 0 ]; then
            read -r -p "Are you sure you want to destroy all resources? (type 'yes' to confirm): " CONFIRM </dev/tty
        else
            echo "Are you sure you want to destroy all resources? (type 'yes' to confirm): " >/dev/tty
            read -r CONFIRM </dev/tty
        fi
        if [ "$CONFIRM" = "yes" ]; then
            terraform destroy -auto-approve
            success "Infrastructure destroyed"
            return 0
        else
            info "Destroy cancelled"
            return 1
        fi
    else
        info "Planning Terraform changes..."
        terraform plan -out=tfplan
        
        if [ $? -ne 0 ]; then
            error "Terraform plan failed"
            error ""
            error "Common issues:"
            error "1. GCP authentication: Run 'gcloud auth application-default login'"
            error "2. Project not set: Run 'gcloud config set project YOUR_PROJECT_ID'"
            error "3. Check terraform/terraform.tfvars has correct project_id"
            return 1
        fi
        
        info "Applying Terraform changes..."
        terraform apply tfplan
        
        if [ $? -ne 0 ]; then
            error "Terraform apply failed"
            return 1
        fi
        
        success "Infrastructure provisioned successfully"
        
        info "Retrieving VM information..."
        if terraform output -json vm_instances &> /dev/null; then
            success "VM information retrieved"
            terraform output vm_instances | grep -E "(name|external_ip)" || true
        fi
        
        # Ensure VM is running (it might have been stopped)
        info "Checking VM status..."
        ensure_vm_running
        
        # Refresh IP after starting VM
        info "Retrieving VM IP..."
        VM_IP=$(get_vm_ip)
        if [ -n "$VM_IP" ] && [ "$VM_IP" != "null" ] && [ "$VM_IP" != '""' ]; then
            success "VM IP: $VM_IP"
        else
            warning "VM IP not available yet. It may take a minute for the external IP to be assigned."
            info "You can check the IP later with: terraform output vm_instances"
        fi
        
        # Ensure WSL SSH key is on the VM (Terraform might have used Windows key)
        if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            info "Checking if WSL SSH key is on VM..."
            WSL_PUBLIC_KEY=$(cat "$HOME/.ssh/id_rsa.pub" | tr -d '\n\r')
            VM_KEYS=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" \
                      --format="get(metadata.items[ssh-keys].value)" 2>/dev/null || echo "")
            
            if echo "$VM_KEYS" | grep -q "$WSL_PUBLIC_KEY"; then
                info "WSL SSH key already on VM"
            else
                warning "WSL SSH key not found on VM, adding it..."
                SSH_USER=$(grep "ssh_user" terraform.tfvars | sed -n 's/.*"\([^"]*\)".*/\1/p' || echo "devops")
                SSH_KEY_ENTRY="${SSH_USER}:${WSL_PUBLIC_KEY}"
                
                # Add key to VM (append to existing keys)
                if [ -n "$VM_KEYS" ]; then
                    ALL_KEYS="${VM_KEYS}\n${SSH_KEY_ENTRY}"
                else
                    ALL_KEYS="$SSH_KEY_ENTRY"
                fi
                
                TEMP_KEYS_FILE=$(mktemp)
                echo -e "$ALL_KEYS" > "$TEMP_KEYS_FILE"
                
                gcloud compute instances add-metadata "$VM_NAME" \
                    --zone="$ZONE" \
                    --project="$PROJECT_ID" \
                    --metadata-from-file ssh-keys="$TEMP_KEYS_FILE" 2>/dev/null
                
                rm -f "$TEMP_KEYS_FILE"
                
                if [ $? -eq 0 ]; then
                    success "WSL SSH key added to VM"
                    info "Waiting 10 seconds for metadata to propagate..."
                    sleep 10
                else
                    warning "Failed to add WSL SSH key to VM"
                fi
            fi
        fi
    fi
    
    return 0
}

# Update Ansible Inventory
ensure_ssh_key_permissions() {
    # Get SSH private key path from inventory or terraform.tfvars
    SSH_PUBLIC_KEY_PATH=$(grep "ssh_public_key_path" terraform/terraform.tfvars | sed -n 's/.*"\([^"]*\)".*/\1/p' || echo "")
    
    # Convert Windows path to WSL path if needed
    if [[ "$SSH_PUBLIC_KEY_PATH" =~ ^[A-Za-z]: ]]; then
        DRIVE_LETTER=$(echo "$SSH_PUBLIC_KEY_PATH" | cut -d: -f1 | tr '[:upper:]' '[:lower:]')
        PATH_PART=$(echo "$SSH_PUBLIC_KEY_PATH" | cut -d: -f2 | tr '\\' '/' | sed 's|^/||')
        SSH_PUBLIC_KEY_PATH="/mnt/$DRIVE_LETTER/$PATH_PART"
    fi
    
    SSH_PRIVATE_KEY_PATH="${SSH_PUBLIC_KEY_PATH%.pub}"
    
    # Try default locations if not found
    if [ -z "$SSH_PRIVATE_KEY_PATH" ] || [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        if [ -f "$HOME/.ssh/id_rsa" ]; then
            SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
        elif [ -f "/mnt/c/Users/$USER/.ssh/id_rsa" ]; then
            SSH_PRIVATE_KEY_PATH="/mnt/c/Users/$USER/.ssh/id_rsa"
        else
            return 1
        fi
    fi
    
    # Check if key is in /mnt/c (Windows filesystem) - permissions can't be fixed there
    if [[ "$SSH_PRIVATE_KEY_PATH" =~ ^/mnt/c ]]; then
        # Copy to WSL home directory with correct permissions
        WSL_KEY_PATH="$HOME/.ssh/id_rsa"
        WSL_KEY_PUB_PATH="$HOME/.ssh/id_rsa.pub"
        
        info "SSH key is on Windows filesystem - copying to WSL with correct permissions..."
        
        # Create .ssh directory if it doesn't exist
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        # Copy private key
        cp "$SSH_PRIVATE_KEY_PATH" "$WSL_KEY_PATH"
        chmod 600 "$WSL_KEY_PATH"
        
        # Copy public key if it exists
        if [ -f "${SSH_PRIVATE_KEY_PATH%.pub}.pub" ]; then
            cp "${SSH_PRIVATE_KEY_PATH%.pub}.pub" "$WSL_KEY_PUB_PATH"
            chmod 644 "$WSL_KEY_PUB_PATH"
        fi
        
        success "SSH key copied to WSL: $WSL_KEY_PATH (permissions: 600)"
        
        # Update inventory to use WSL path
        if [ -f "$ANSIBLE_DIR/inventory/hosts.yml" ]; then
            # Update inventory file to use WSL path
            sed -i "s|ansible_ssh_private_key_file:.*|ansible_ssh_private_key_file: $WSL_KEY_PATH|g" "$ANSIBLE_DIR/inventory/hosts.yml"
            info "Updated inventory to use WSL SSH key path"
        fi
        
        return 0
    else
        # Key is already in WSL filesystem - just fix permissions
        chmod 600 "$SSH_PRIVATE_KEY_PATH" 2>/dev/null || true
        if [ -f "${SSH_PRIVATE_KEY_PATH}.pub" ]; then
            chmod 644 "${SSH_PRIVATE_KEY_PATH}.pub" 2>/dev/null || true
        fi
        return 0
    fi
}

update_ansible_inventory() {
    step "Updating Ansible Inventory"
    
    INVENTORY_SCRIPT="$ANSIBLE_DIR/scripts/update-inventory.sh"
    if [ -f "$INVENTORY_SCRIPT" ]; then
        info "Running inventory update script..."
        bash "$INVENTORY_SCRIPT"
        if [ $? -eq 0 ]; then
            success "Ansible inventory updated"
            return 0
        else
            warning "Inventory update script failed. You may need to update inventory manually."
            return 1
        fi
    else
        warning "Inventory update script not found. Please update ansible/inventory/hosts.yml manually"
        return 1
    fi
}

# Run Ansible Deployment
invoke_ansible_deploy() {
    step "Deploying with Ansible"
    
    cd "$ANSIBLE_DIR"
    
    INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
    if [ ! -f "$INVENTORY_FILE" ]; then
        error "Ansible inventory not found: $INVENTORY_FILE"
        info "Please run: ansible/scripts/update-inventory.sh"
        return 1
    fi
    
    info "Running Ansible playbooks..."
    
    # Fix encoding - completely avoid locale issues
    # Don't set any locale variables - Python will handle UTF-8 via environment variables
    info "Configuring Ansible encoding (avoiding locale issues)..."
    
    # Run Ansible in a clean environment - explicitly unset ALL locale vars
    # Python encoding will handle UTF-8 via PYTHONIOENCODING and PYTHONUTF8
    info "Starting Ansible deployment..."
    
    # Get SSH key path from inventory for debugging
    SSH_KEY_FROM_INVENTORY=$(grep "ansible_ssh_private_key_file" "$ANSIBLE_DIR/inventory/hosts.yml" | sed -n 's/.*ansible_ssh_private_key_file:[[:space:]]*\([^[:space:]]*\).*/\1/p' || echo "")
    if [ -n "$SSH_KEY_FROM_INVENTORY" ]; then
        # Expand ~ to home directory
        SSH_KEY_FROM_INVENTORY="${SSH_KEY_FROM_INVENTORY/#\~/$HOME}"
        info "Using SSH key from inventory: $SSH_KEY_FROM_INVENTORY"
        
        # Verify key exists and has correct permissions
        if [ ! -f "$SSH_KEY_FROM_INVENTORY" ]; then
            error "SSH key not found: $SSH_KEY_FROM_INVENTORY"
            return 1
        fi
        
        KEY_PERMS=$(stat -c "%a" "$SSH_KEY_FROM_INVENTORY" 2>/dev/null || stat -f "%OLp" "$SSH_KEY_FROM_INVENTORY" 2>/dev/null || echo "unknown")
        if [ "$KEY_PERMS" != "600" ] && [ "$KEY_PERMS" != "0600" ]; then
            warning "SSH key permissions are $KEY_PERMS (should be 600), fixing..."
            chmod 600 "$SSH_KEY_FROM_INVENTORY"
        fi
    fi
    
    # Change to ansible directory to ensure relative paths work
    cd "$ANSIBLE_DIR"
    
    # Test SSH connection first with the key from inventory
    info "Testing SSH connection with inventory key..."
    if [ -n "$SSH_KEY_FROM_INVENTORY" ]; then
        VM_IP=$(grep "ansible_host" inventory/hosts.yml | head -1 | sed -n 's/.*ansible_host:[[:space:]]*\([^[:space:]]*\).*/\1/p')
        if [ -n "$VM_IP" ]; then
            # Test with inventory key
            if ssh -i "$SSH_KEY_FROM_INVENTORY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                devops@"$VM_IP" "echo 'SSH test successful'" 2>&1; then
                success "SSH connection test passed with inventory key"
            else
                error "SSH connection test failed with key: $SSH_KEY_FROM_INVENTORY"
                
                # Try all possible key locations
                info "Trying alternative SSH key locations..."
                for TEST_KEY in "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519" "/mnt/c/Users/$USER/.ssh/id_rsa"; do
                    if [ -f "$TEST_KEY" ]; then
                        info "Testing with: $TEST_KEY"
                        if ssh -i "$TEST_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                            devops@"$VM_IP" "echo 'SSH test successful'" 2>&1; then
                            success "SSH works with: $TEST_KEY"
                            warning "Updating inventory to use working key..."
                            # Update inventory with working key
                            sed -i "s|ansible_ssh_private_key_file:.*|ansible_ssh_private_key_file: $TEST_KEY|g" inventory/hosts.yml
                            SSH_KEY_FROM_INVENTORY="$TEST_KEY"
                            break
                        fi
                    fi
                done
                
                # If still no working key, check what's on the VM
                if ! ssh -i "$SSH_KEY_FROM_INVENTORY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                    devops@"$VM_IP" "echo 'test'" 2>&1 >/dev/null; then
                    error "SSH connection test failed with all keys"
                    error ""
                    error "The SSH key on the VM might not match your local keys."
                    error "Check what keys are on the VM:"
                    error "  gcloud compute instances describe automation-alchemy --zone=europe-north1-a --format='get(metadata.items[ssh-keys].value)'"
                    error ""
                    error "Or add your public key to the VM:"
                    error "  gcloud compute instances add-metadata automation-alchemy --zone=europe-north1-a --metadata ssh-keys=\"devops:$(cat ~/.ssh/id_rsa.pub)\""
                    return 1
                fi
            fi
        fi
    fi
    
    # Use absolute path for inventory to avoid any path issues
    INVENTORY_ABS_PATH="$ANSIBLE_DIR/inventory/hosts.yml"
    
    env -u LC_ALL -u LANG -u LC_CTYPE -u LC_NUMERIC -u LC_TIME -u LC_COLLATE -u LC_MONETARY -u LC_MESSAGES \
        PYTHONIOENCODING=utf-8 \
        PYTHONUTF8=1 \
        ansible-playbook playbooks/site.yml -i "$INVENTORY_ABS_PATH" \
        -e "ansible_python_interpreter=python3" \
        2>&1 | tee /tmp/ansible_output.log
    
    ANSIBLE_EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $ANSIBLE_EXIT_CODE -eq 0 ]; then
        success "Ansible deployment completed"
        return 0
    else
        error "Ansible deployment failed (exit code: $ANSIBLE_EXIT_CODE)"
        
        # Check for encoding error specifically
        if grep -q "locale encoding.*UTF-8" /tmp/ansible_output.log 2>/dev/null; then
            error ""
            error "ENCODING ERROR DETECTED"
            error "================================"
            error "Ansible requires UTF-8 encoding, but detected Windows-1252"
            error ""
            error "SOLUTIONS:"
            error "1. Use WSL instead of Git Bash:"
            error "   wsl"
            error "   cd /mnt/c/automation-alchemy"
            error "   ./scripts/deploy.sh"
            error ""
            error "2. Or use GitLab CI/CD (recommended):"
            error "   - Push code to GitLab"
            error "   - Deploy via CI/CD pipeline"
            error "   - See: docs/GITLAB_DEPLOYMENT.md"
            error ""
            error "3. Install UTF-8 locale in Git Bash:"
            error "   (This may not work - WSL is recommended)"
            error ""
        fi
        
        return 1
    fi
}

# Verify Deployment
test_deployment() {
    step "Verifying Deployment"
    
    VM_IP=$(get_vm_ip)
    if [ -z "$VM_IP" ] || [ "$VM_IP" = "null" ]; then
        warning "Could not retrieve VM IP from Terraform output"
        return 1
    fi
    
    info "Testing application health..."
    HEALTH_URL="http://${VM_IP}:8080/health"
    
    if curl -sf --max-time 10 "$HEALTH_URL" > /dev/null 2>&1; then
        success "Application is healthy!"
        echo ""
        echo -e "${CYAN}🌐 Application URLs:${NC}"
        echo -e "   Load Balancer: ${BLUE}http://${VM_IP}:8080${NC}"
        echo -e "   App Server:    ${BLUE}http://${VM_IP}:3000${NC}"
        echo -e "   Web Server 1:  ${BLUE}http://${VM_IP}:8081${NC}"
        echo -e "   Web Server 2:  ${BLUE}http://${VM_IP}:8082${NC}"
        echo -e "   Netdata:       ${BLUE}http://${VM_IP}:19999${NC}"
        return 0
    else
        warning "Could not reach application at $HEALTH_URL"
        info "The application may still be starting. Wait a few minutes and check manually."
        return 1
    fi
}

# Run Tests
invoke_tests() {
    local test_type=$1
    
    VM_IP=$(get_vm_ip)
    if [ -z "$VM_IP" ] || [ "$VM_IP" = "null" ]; then
        warning "Could not retrieve VM IP. Please deploy infrastructure first."
        return 1
    fi
    
    step "Running Tests: $test_type"
    
    BASE_URL="http://${VM_IP}:8080"
    
    case "$test_type" in
        integration)
            info "Running integration tests..."
            export BASE_URL="$BASE_URL"
            export VM_IP="$VM_IP"
            bash "$TESTS_DIR/integration-test.sh"
            ;;
        performance)
            info "Running performance tests..."
            export TARGET_URL="$BASE_URL"
            bash "$TESTS_DIR/performance-test.sh"
            ;;
        security)
            info "Running security tests..."
            bash "$TESTS_DIR/security-scan.sh"
            ;;
        code-quality)
            info "Running code quality tests..."
            bash "$TESTS_DIR/code-quality.sh"
            ;;
        all)
            info "Running all tests..."
            export BASE_URL="$BASE_URL"
            export VM_IP="$VM_IP"
            export TARGET_URL="$BASE_URL"
            
            for script in code-quality.sh security-scan.sh integration-test.sh performance-test.sh; do
                if [ -f "$TESTS_DIR/$script" ]; then
                    info "Running $script..."
                    bash "$TESTS_DIR/$script" || true
                fi
            done
            ;;
        *)
            error "Unknown test type: $test_type"
            return 1
            ;;
    esac
    
    return 0
}

# Full Deployment
start_full_deployment() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Automation Alchemy - Full Deployment                ║${NC}"
    echo -e "${CYAN}║     Terraform → Ansible → Deploy                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! test_prerequisites false false; then
        return 1
    fi
    
    if ! test_terraform_config; then
        return 1
    fi
    
    if ! invoke_terraform_deploy false; then
        return 1
    fi
    
    if ! update_ansible_inventory; then
        warning "Inventory update failed, but continuing..."
    fi
    
    if ! invoke_ansible_deploy; then
        return 1
    fi
    
    test_deployment
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Deployment Completed Successfully!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    return 0
}

# Main Menu
show_main_menu() {
    local clear_screen=$1
    
    if [ "$clear_screen" = "true" ]; then
        clear
    else
        echo ""
        echo -e "${CYAN}===============================================================${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}===============================================================${NC}"
    echo -e "${CYAN}     Automation Alchemy - Deployment & Testing Menu${NC}"
    echo -e "${CYAN}===============================================================${NC}"
    echo ""
    echo -e "  ${NC}[1] Full Deployment (Terraform + Ansible)"
    echo -e "  ${NC}[2] Terraform Only (Infrastructure)"
    echo -e "  ${NC}[3] Ansible Only (Configuration)"
    echo -e "  ${YELLOW}[4] Destroy Infrastructure${NC}"
    echo ""
    echo -e "  ${GREEN}[5] Run All Tests${NC}"
    echo -e "  ${GREEN}[6] Integration Tests${NC}"
    echo -e "  ${GREEN}[7] Performance Tests${NC}"
    echo -e "  ${GREEN}[8] Security Tests${NC}"
    echo -e "  ${GREEN}[9] Code Quality Tests${NC}"
    echo ""
    echo -e "  ${RED}[0] Exit${NC}"
    echo ""
}

# Interactive Menu Loop
start_interactive_menu() {
    local first_run=true
    
    while true; do
        if [ "$first_run" = "true" ]; then
            show_main_menu "true"
            first_run=false
        else
            show_main_menu "false"
        fi
        
        read -r -p "Select an option: " choice
        
        case "$choice" in
            1)
                if ! start_full_deployment; then
                    echo ""
                    error "Deployment failed. Check errors above."
                fi
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            2)
                if test_prerequisites false true; then
                    if test_terraform_config; then
                        invoke_terraform_deploy false || true
                    fi
                fi
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            3)
                if test_prerequisites true false; then
                    if update_ansible_inventory; then
                        invoke_ansible_deploy || true
                    fi
                fi
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            4)
                warning "This will destroy all infrastructure!"
                if [ -t 0 ]; then
                    read -r -p "Type 'yes' to confirm: " confirm </dev/tty
                else
                    echo "Type 'yes' to confirm: " >/dev/tty
                    read -r confirm </dev/tty
                fi
                if [ "$confirm" = "yes" ]; then
                    if test_prerequisites false true; then
                        invoke_terraform_deploy true || true
                    fi
                fi
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            5)
                invoke_tests "all" || true
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            6)
                invoke_tests "integration" || true
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            7)
                invoke_tests "performance" || true
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            8)
                invoke_tests "security" || true
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            9)
                invoke_tests "code-quality" || true
                echo ""
                if [ -t 0 ]; then
                    read -r -p "Press Enter to return to menu..." </dev/tty
                else
                    echo "Press Enter to return to menu..." >/dev/tty
                    read -r </dev/tty
                fi
                ;;
            0)
                echo ""
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                warning "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Start interactive menu
start_interactive_menu
