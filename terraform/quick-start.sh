#!/bin/bash
# Quick Start Script for Terraform Setup

set -e

echo "🚀 Automation Alchemy - Terraform Quick Start"
echo "=============================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed!"
    echo "   Install from: https://www.terraform.io/downloads"
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "⚠️  gcloud CLI is not installed (optional but recommended)"
    echo "   Install from: https://cloud.google.com/sdk/docs/install"
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✅ Created terraform.tfvars"
    echo ""
    echo "⚠️  IMPORTANT: Edit terraform.tfvars and set your project_id!"
    echo "   File: terraform/terraform.tfvars"
    echo ""
    read -r -p "Press Enter after you've edited terraform.tfvars..."
fi

# Check if SSH key exists
SSH_KEY_PATH=$(grep "ssh_public_key_path" terraform.tfvars | cut -d'"' -f2 | sed 's|~|'"$HOME"'|')
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "🔑 SSH key not found at: $SSH_KEY_PATH"
    echo "   Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "${SSH_KEY_PATH%.pub}" -N ""
    echo "✅ SSH key generated"
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review terraform.tfvars (make sure project_id is set)"
echo "2. Run: terraform plan    (preview changes)"
echo "3. Run: terraform apply   (create infrastructure)"
echo ""

