# Terraform Infrastructure Configuration

This directory contains Terraform configuration for provisioning GCP infrastructure for the Automation Alchemy project.

## 📋 Overview

This Terraform configuration creates:
- VPC network and subnet
- Firewall rules (SSH, HTTP, internal communication)
- Compute instances (VMs) - configurable count
- Service accounts with minimal permissions
- Required GCP APIs enabled

## 🚀 Quick Start

### Prerequisites

1. **GCP Account**: Project created and billing enabled
2. **Terraform**: Install from https://www.terraform.io/downloads
3. **gcloud CLI**: Install from https://cloud.google.com/sdk/docs/install
4. **SSH Key**: Generate if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

### Setup Steps

1. **Authenticate with GCP**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Set your project**:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Create terraform.tfvars**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project ID
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan the infrastructure**:
   ```bash
   terraform plan
   ```

6. **Apply the infrastructure**:
   ```bash
   terraform apply
   ```

7. **Get VM information**:
   ```bash
   terraform output
   ```

## 💰 Cost Optimization

### Free Tier Setup (vm_count = 1)
- **Cost**: $0/month (1 free e2-micro VM)
- **Setup**: All services on single VM
- **Perfect for**: Learning and development

### Multi-VM Setup (vm_count = 4-5)
- **Cost**: ~$21-28/month (1 free + 3-4 paid VMs)
- **Setup**: Separate VMs for each service
- **Perfect for**: Production-like environment

## 📁 File Structure

- `main.tf` - Main infrastructure resources
- `variables.tf` - Input variables
- `outputs.tf` - Output values (for Ansible)
- `versions.tf` - Provider versions
- `terraform.tfvars` - Your configuration (create from example)
- `README.md` - This file

## 🔧 Configuration Options

### VM Count
- `vm_count = 1`: Single VM (free tier)
- `vm_count = 4`: Load balancer + 2 web servers + app server
- `vm_count = 5`: Full setup (adds Jenkins)

### Machine Types
- `e2-micro`: Free tier eligible (1 vCPU, 1GB RAM)
- `e2-small`: ~$7/month (2 vCPU, 2GB RAM)
- `e2-medium`: ~$14/month (2 vCPU, 4GB RAM)

### Regions
- `us-central1`: Default (good performance, low cost)
- `us-east1`: Alternative
- `europe-west1`: For EU users

## 🔒 Security Notes

- **SSH Access**: Currently open to 0.0.0.0/0 (all IPs)
  - **Production**: Restrict to your IP address
- **Firewall Rules**: Basic rules for development
  - **Production**: Implement stricter rules
- **Service Account**: Minimal permissions (monitoring, logging)

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Important**: This will delete all VMs and infrastructure. Make sure you have backups!

## 📊 Outputs

After `terraform apply`, you'll get:
- VM IP addresses (internal and external)
- Ansible inventory format
- VPC network information

Use these outputs to configure Ansible (inventory).

## 🐛 Troubleshooting

### Error: "API not enabled"
- Run: `gcloud services enable compute.googleapis.com`

### Error: "Permission denied"
- Check: `gcloud auth list`
- Re-authenticate: `gcloud auth login`

### Error: "Quota exceeded"
- Check GCP quotas in console
- Request quota increase if needed

## 📚 Next Steps

After Terraform succeeds:
1. ✅ VMs are provisioned
2. ✅ Networking is configured
3. ✅ Firewall rules are set
4. ➡️ **Next**: Configure VMs with Ansible

See `../ansible/README.md` for next steps.

