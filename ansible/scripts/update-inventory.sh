#!/bin/bash
# Script to update Ansible inventory from Terraform outputs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../terraform"
INVENTORY_FILE="$SCRIPT_DIR/../inventory/hosts.yml"

echo "🔄 Updating Ansible inventory from Terraform outputs..."

cd "$TERRAFORM_DIR"

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

# Parse JSON and generate inventory (requires jq)
if command -v jq &> /dev/null; then
    echo "$VM_INFO" | jq -r 'to_entries[] | 
        "    \(.value.role):
      hosts:
        \(.value.name):
          ansible_host: \(.value.external_ip)
          ansible_user: devops
          role: \(.value.role)
          internal_ip: \(.value.internal_ip)"' >> "$INVENTORY_FILE"
else
    echo "⚠️  jq not found. Please install jq or manually update inventory/hosts.yml"
    echo "VM information from Terraform:"
    terraform output vm_instances
fi

echo "✅ Inventory updated: $INVENTORY_FILE"
echo ""
echo "To verify, run: ansible-inventory --list"

