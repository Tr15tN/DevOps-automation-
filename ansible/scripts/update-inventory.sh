#!/bin/bash
# Script to update Ansible inventory from Terraform outputs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../terraform"
INVENTORY_FILE="$SCRIPT_DIR/../inventory/hosts.yml"

echo "🔄 Updating Ansible inventory from Terraform outputs..."

cd "$TERRAFORM_DIR"

# Get SSH private key path from terraform.tfvars
SSH_PUBLIC_KEY_PATH=$(grep "ssh_public_key_path" terraform.tfvars 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p' || echo "")
if [ -n "$SSH_PUBLIC_KEY_PATH" ]; then
    # Convert public key path to private key path
    SSH_PRIVATE_KEY_PATH="${SSH_PUBLIC_KEY_PATH%.pub}"
    # Expand ~ to home directory
    SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH/#\~/$HOME}"
    # Convert Windows path to WSL path if needed
    if [[ "$SSH_PRIVATE_KEY_PATH" =~ ^[A-Za-z]: ]]; then
        # Windows path - convert to WSL path
        DRIVE_LETTER=$(echo "$SSH_PRIVATE_KEY_PATH" | cut -d: -f1 | tr '[:upper:]' '[:lower:]')
        PATH_PART=$(echo "$SSH_PRIVATE_KEY_PATH" | cut -d: -f2 | tr '\\' '/' | sed 's|^/||')
        SSH_PRIVATE_KEY_PATH="/mnt/$DRIVE_LETTER/$PATH_PART"
    fi
    
    # If key is on Windows filesystem (/mnt/c), check if WSL copy exists and matches
    if [[ "$SSH_PRIVATE_KEY_PATH" =~ ^/mnt/c ]] && [ -f "$SSH_PRIVATE_KEY_PATH" ]; then
        WSL_KEY_PATH="$HOME/.ssh/id_rsa"
        WSL_KEY_PUB_PATH="$HOME/.ssh/id_rsa.pub"
        
        # Check if WSL key already exists
        if [ -f "$WSL_KEY_PATH" ]; then
            # Compare keys - if they're the same, use WSL version
            if cmp -s "$SSH_PRIVATE_KEY_PATH" "$WSL_KEY_PATH" 2>/dev/null; then
                echo "ℹ️  Using existing WSL SSH key (matches Windows key)"
                SSH_PRIVATE_KEY_PATH="$WSL_KEY_PATH"
            else
                echo "ℹ️  WSL key exists but differs from Windows key - using WSL key"
                SSH_PRIVATE_KEY_PATH="$WSL_KEY_PATH"
            fi
        else
            # Copy to WSL home directory with correct permissions
            echo "ℹ️  SSH key is on Windows filesystem - copying to WSL with correct permissions..."
            
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
            
            # Use WSL path instead
            SSH_PRIVATE_KEY_PATH="$WSL_KEY_PATH"
            echo "✅ SSH key copied to WSL: $SSH_PRIVATE_KEY_PATH (permissions: 600)"
        fi
    fi
    
    # Verify the key exists, if not try WSL location
    if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        # Try WSL home directory
        if [ -f "$HOME/.ssh/id_rsa" ]; then
            SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
        # Try extracting username from Windows path
        elif [[ "$SSH_PUBLIC_KEY_PATH" =~ /Users/([^/]+) ]]; then
            WINDOWS_USER="${BASH_REMATCH[1]}"
            WSL_KEY="/mnt/c/Users/$WINDOWS_USER/.ssh/id_rsa"
            if [ -f "$WSL_KEY" ]; then
                SSH_PRIVATE_KEY_PATH="$WSL_KEY"
            fi
        fi
    fi
else
    # Try default locations
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
    elif [ -f "/mnt/c/Users/$USER/.ssh/id_rsa" ]; then
        SSH_PRIVATE_KEY_PATH="/mnt/c/Users/$USER/.ssh/id_rsa"
        # Copy to WSL if on Windows filesystem
        if [[ "$SSH_PRIVATE_KEY_PATH" =~ ^/mnt/c ]]; then
            mkdir -p "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
            cp "$SSH_PRIVATE_KEY_PATH" "$HOME/.ssh/id_rsa"
            chmod 600 "$HOME/.ssh/id_rsa"
            SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
        fi
    else
        SSH_PRIVATE_KEY_PATH=""
    fi
fi

# Debug output
if [ -n "$SSH_PRIVATE_KEY_PATH" ]; then
    if [ -f "$SSH_PRIVATE_KEY_PATH" ]; then
        echo "✅ Using SSH key: $SSH_PRIVATE_KEY_PATH"
    else
        echo "⚠️  SSH key not found: $SSH_PRIVATE_KEY_PATH"
        SSH_PRIVATE_KEY_PATH=""
    fi
fi

# Check if Terraform has been applied
if [ ! -f terraform.tfstate ]; then
    echo "❌ Error: Terraform state not found. Run 'terraform apply' first."
    exit 1
fi

# Get VM information from Terraform
VM_INFO=$(terraform output -json vm_instances 2>/dev/null)

if [ -z "$VM_INFO" ]; then
    echo "❌ Error: Could not get VM information from Terraform."
    exit 1
fi

# Generate inventory file
cat > "$INVENTORY_FILE" << 'EOF'
---
# Ansible Inventory
# Auto-generated from Terraform outputs
# Run: ansible/scripts/update-inventory.sh to regenerate

all:
  children:
EOF

# Parse JSON and generate inventory
if command -v jq &> /dev/null; then
    # Generate inventory entries with SSH key if available
    if [ -n "$SSH_PRIVATE_KEY_PATH" ]; then
        echo "$VM_INFO" | jq -r --arg ssh_key "$SSH_PRIVATE_KEY_PATH" 'to_entries[] | 
            "    \(.value.role):
      hosts:
        \(.value.name):
          ansible_host: \(.value.external_ip)
          ansible_user: devops
          ansible_ssh_private_key_file: \($ssh_key)
          role: \(.value.role)
          internal_ip: \(.value.internal_ip)"' >> "$INVENTORY_FILE"
    else
        echo "$VM_INFO" | jq -r 'to_entries[] | 
            "    \(.value.role):
      hosts:
        \(.value.name):
          ansible_host: \(.value.external_ip)
          ansible_user: devops
          role: \(.value.role)
          internal_ip: \(.value.internal_ip)"' >> "$INVENTORY_FILE"
    fi
else
    echo "⚠️  jq not found. Using fallback method..."
    
    # Fallback: Try to get IP from gcloud if Terraform output is empty
    VM_NAME=$(echo "$VM_INFO" | grep -o '"name"[[:space:]]*=[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    ZONE=$(echo "$VM_INFO" | grep -o '"zone"[[:space:]]*=[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    PROJECT_ID=$(terraform output -json project_info 2>/dev/null | jq -r '.project_id' 2>/dev/null || \
                 terraform output project_info 2>/dev/null | grep project_id | sed -n 's/.*"\([^"]*\)".*/\1/p' || \
                 echo "")
    
    # Try to get external IP from gcloud if available
    if [ -n "$VM_NAME" ] && [ -n "$ZONE" ] && [ -n "$PROJECT_ID" ]; then
        EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" \
                      --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")
        
        if [ -n "$EXTERNAL_IP" ]; then
            echo "✅ Found external IP from gcloud: $EXTERNAL_IP"
            INTERNAL_IP=$(echo "$VM_INFO" | grep -o '"internal_ip"[[:space:]]*=[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            ROLE=$(echo "$VM_INFO" | grep -o '"role"[[:space:]]*=[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            
            # Generate inventory entry
            cat >> "$INVENTORY_FILE" << EOF
    ${ROLE:-all-in-one}:
      hosts:
        ${VM_NAME}:
          ansible_host: ${EXTERNAL_IP}
          ansible_user: devops
EOF
            if [ -n "$SSH_PRIVATE_KEY_PATH" ]; then
                echo "          ansible_ssh_private_key_file: ${SSH_PRIVATE_KEY_PATH}" >> "$INVENTORY_FILE"
            fi
            cat >> "$INVENTORY_FILE" << EOF
          role: ${ROLE:-all-in-one}
          internal_ip: ${INTERNAL_IP}
EOF
        else
            echo "⚠️  Could not get external IP. Please update inventory/hosts.yml manually"
            echo "VM information from Terraform:"
            terraform output vm_instances
        fi
    else
        echo "⚠️  Could not parse VM information. Please update inventory/hosts.yml manually"
        echo "VM information from Terraform:"
        terraform output vm_instances
    fi
fi

echo "✅ Inventory updated: $INVENTORY_FILE"
echo ""
echo "To verify, run: ansible-inventory --list"

