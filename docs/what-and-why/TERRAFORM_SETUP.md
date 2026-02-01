# Terraform Infrastructure Setup - Documentation

## 📋 Overview

This document explains the Terraform infrastructure setup for Automation Alchemy, including what was created, why certain decisions were made, and how everything works together.

---

## 🎯 What We Built

### Infrastructure Components

1. **VPC Network** (`automation-alchemy-vpc`)
   - Custom VPC for isolating our resources
   - No auto-created subnets (manual control)

2. **Subnet** (`automation-alchemy-subnet`)
   - IP range: `10.0.0.0/24` (256 IPs)
   - Region: `us-central1`
   - Private IP space for VM communication

3. **Firewall Rules** (5 rules)
   - **SSH (port 22)**: Access VMs remotely
   - **HTTP (ports 80, 8080, 8081, 8082, 3000)**: Application access
   - **HAProxy Stats (port 8404)**: Load balancer monitoring
   - **Netdata (port 19999)**: System monitoring
   - **Internal**: Full communication between VMs on subnet

4. **Compute Instance** (`automation-alchemy`)
   - Type: `e2-micro` (1 vCPU, 1GB RAM)
   - Disk: 30GB standard persistent disk
   - OS: Ubuntu 22.04 LTS
   - **FREE TIER ELIGIBLE** ✅

5. **Service Account** (`automation-alchemy-vm-sa`)
   - Minimal permissions (monitoring, logging only)
   - Follows principle of least privilege

6. **GCP APIs** (Auto-enabled)
   - Compute Engine API
   - IAM API
   - Cloud Resource Manager API

---

## 🤔 Why These Decisions?

### Why GCP Instead of Local VMs?

**Decision**: Use Google Cloud Platform instead of local VirtualBox/Hyper-V VMs.

**Reasons**:
1. **Future Project Alignment**: The next project (Voyager) requires cloud infrastructure
2. **Real-World Experience**: Learn actual cloud provider tools and concepts
3. **Cost-Effective**: Free tier available (1 VM free forever)
4. **Scalability**: Easy to scale from 1 to 4-5 VMs when needed
5. **Same Tools**: Uses Terraform (same tool as future project)

**Trade-offs**:
- Requires internet connection
- Small monthly cost if scaling beyond free tier
- More complex than local VMs

---

### Why Single VM Initially?

**Decision**: Start with `vm_count = 1` (single VM with all services).

**Reasons**:
1. **Cost**: $0/month (free tier)
2. **Learning**: Focus on automation tools, not multi-VM complexity
3. **Sufficient**: All services can run on one VM via Docker Compose
4. **Scalable**: Easy to change `vm_count` to 4-5 later

**When to Scale**:
- Change `vm_count = 4` in `terraform.tfvars`
- Run `terraform apply` to create separate VMs
- Cost: ~$21/month (1 free + 3 paid)

---

### Why e2-micro Machine Type?

**Decision**: Use `e2-micro` (smallest VM size).

**Reasons**:
1. **Free Tier**: 1 e2-micro is free forever
2. **Sufficient**: Enough for learning and development
3. **Cost-Effective**: Additional VMs are only ~$7/month each
4. **Upgradeable**: Can change machine type later if needed

**Specifications**:
- 1 vCPU (shared)
- 1GB RAM
- 30GB disk (free tier limit)

---

### Why Custom VPC Instead of Default?

**Decision**: Create custom VPC instead of using GCP default network.

**Reasons**:
1. **Isolation**: Separate network for our project
2. **Control**: Full control over IP ranges and subnets
3. **Best Practice**: Production environments use custom VPCs
4. **Learning**: Understand VPC concepts for future projects
5. **Security**: Can implement stricter firewall rules

**Configuration**:
- Network: `automation-alchemy-vpc`
- Subnet: `10.0.0.0/24` (private IP range)
- Region: `us-central1`

---

### Why These Firewall Rules?

**Decision**: Open specific ports for application access.

**Rules Created**:
1. **SSH (22)**: Required for remote access and Ansible
2. **HTTP (80, 8080, 8081, 8082, 3000)**: Application ports
3. **HAProxy Stats (8404)**: Monitoring dashboard
4. **Netdata (19999)**: System monitoring
5. **Internal (all ports)**: VM-to-VM communication

**Security Note**:
- Currently open to `0.0.0.0/0` (all IPs)
- **Production**: Should restrict to specific IPs
- Internal rule only allows subnet communication

---

### Why Service Account with Minimal Permissions?

**Decision**: Create dedicated service account with only necessary permissions.

**Reasons**:
1. **Security**: Principle of least privilege
2. **Best Practice**: Don't use default compute service account
3. **Audit Trail**: Easier to track what service account does what
4. **Future-Proof**: Can add more permissions later if needed

**Permissions Granted**:
- `roles/monitoring.metricWriter`: Write metrics to Cloud Monitoring
- `roles/logging.logWriter`: Write logs to Cloud Logging

**What It Can't Do**:
- Create/delete resources
- Access other projects
- Modify IAM permissions

---

### Why SSH Key Authentication?

**Decision**: Use SSH public key instead of password authentication.

**Reasons**:
1. **Security**: More secure than passwords
2. **Automation**: Required for Ansible
3. **Best Practice**: Standard for cloud infrastructure
4. **No Password Management**: Keys are easier to manage

**Implementation**:
- Key location: `C:\Users\M0usetrap\.ssh\id_rsa.pub`
- User: `devops` (created on VM)
- Added to VM metadata during creation

---

## 📁 File Structure

```
terraform/
├── main.tf              # Main infrastructure resources
├── variables.tf         # Input variables
├── outputs.tf          # Output values (for Ansible)
├── versions.tf         # Provider versions
├── terraform.tfvars    # Your configuration (not in git)
├── terraform.tfvars.example  # Example configuration
├── .gitignore          # Git ignore rules
└── README.md           # Quick reference
```

---

## 🔧 Configuration Explained

### terraform.tfvars

```hcl
project_id = "automation-alchemy"    # Your GCP project
region = "us-central1"               # GCP region
zone = "us-central1-a"              # Specific zone
vm_count = 1                         # Number of VMs (1 = free tier)
vm_machine_type = "e2-micro"         # VM size (free tier)
vm_disk_size = 30                    # Disk size in GB (free tier)
ssh_user = "devops"                  # SSH username
ssh_public_key_path = "C:/Users/..." # Full path to SSH key
```

**Why Full Windows Path?**
- Terraform on Windows doesn't expand `~` (home directory)
- Must use full path: `C:/Users/Username/.ssh/id_rsa.pub`
- Forward slashes work on Windows in Terraform

---

## 🚀 How It Works

### Terraform Workflow

1. **Initialize** (`terraform init`)
   - Downloads GCP provider
   - Sets up backend (local state for now)
   - Creates `.terraform` directory

2. **Plan** (`terraform plan`)
   - Shows what will be created
   - Validates configuration
   - No changes made yet

3. **Apply** (`terraform apply`)
   - Creates actual infrastructure
   - Enables APIs
   - Creates VPC, subnet, VMs, firewall rules
   - Takes 2-3 minutes

4. **Output** (`terraform output`)
   - Shows VM IPs
   - Shows Ansible inventory
   - Shows VPC information

5. **Destroy** (`terraform destroy`)
   - Removes all infrastructure
   - **Cost goes to $0/month**

---

## 💰 Cost Breakdown

### Current Setup (vm_count = 1)
- **1x e2-micro VM**: FREE (free tier)
- **30GB disk**: FREE (free tier)
- **VPC/Networking**: FREE
- **Firewall rules**: FREE
- **Total**: **$0/month** ✅

### If Scaling (vm_count = 4)
- **1x e2-micro**: FREE
- **3x e2-micro**: ~$7/month each = $21/month
- **Total**: ~$21/month

### With $300 GCP Credit
- **Months 1-3**: $0 (covered by credit)
- **Month 4+**: $0-21/month (depending on setup)

---

## 🔒 Security Considerations

### Current Setup (Development)
- ✅ SSH key authentication
- ✅ Service account with minimal permissions
- ✅ Custom VPC for isolation
- ⚠️ Firewall rules open to all IPs (0.0.0.0/0)

### Production Recommendations
- Restrict SSH to your IP address
- Restrict HTTP to specific IPs or use load balancer
- Enable Cloud Armor for DDoS protection
- Use Cloud IAP for secure access
- Enable audit logging
- Regular security updates

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────┐
│     GCP Project: automation-alchemy │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  VPC: automation-alchemy-vpc  │ │
│  │                                │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ Subnet: 10.0.0.0/24      │  │ │
│  │  │                          │  │ │
│  │  │  ┌────────────────────┐ │  │ │
│  │  │  │ VM: automation-     │ │  │ │
│  │  │  │      alchemy        │ │  │ │
│  │  │  │  (e2-micro)         │ │  │ │
│  │  │  │  - Ubuntu 22.04     │ │  │ │
│  │  │  │  - 30GB disk        │ │  │ │
│  │  │  │  - SSH key: devops  │ │  │ │
│  │  │  └────────────────────┘ │  │ │
│  │  └──────────────────────────┘  │ │
│  │                                │ │
│  │  Firewall Rules:               │ │
│  │  - SSH (22)                    │ │
│  │  - HTTP (80, 8080, etc.)      │ │
│  │  - HAProxy Stats (8404)        │ │
│  │  - Netdata (19999)             │ │
│  │  - Internal (all)              │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: "API not enabled"
**Solution**: Terraform auto-enables APIs, but if it fails:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
```

### Issue: "Quota exceeded"
**Solution**: Check GCP quotas in console
- Go to: IAM & Admin → Quotas
- Request increase if needed

### Issue: "Permission denied"
**Solution**: Verify authentication
```bash
gcloud auth application-default login
gcloud config set project automation-alchemy
```

### Issue: "SSH key not found"
**Solution**: Check path in `terraform.tfvars`
- Use full Windows path: `C:/Users/Username/.ssh/id_rsa.pub`
- Verify file exists: `Test-Path C:\Users\...\.ssh\id_rsa.pub`

---

## Next Steps

After Terraform creates infrastructure, configure VMs with Ansible and set up CI/CD with GitLab (see project README and ansible/).

---

## 🔄 Maintenance

### Updating Infrastructure
```bash
# Edit terraform.tfvars or .tf files
terraform plan    # Preview changes
terraform apply   # Apply changes
```

### Scaling Up
```bash
# Change vm_count in terraform.tfvars
vm_count = 4
terraform apply   # Creates additional VMs
```

### Cleaning Up
```bash
terraform destroy  # Removes all infrastructure
# Cost goes to $0/month
```

---

## 📝 Key Takeaways

1. **Infrastructure as Code**: Everything defined in Terraform files
2. **Version Controlled**: All configs in Git (except terraform.tfvars)
3. **Reproducible**: Can recreate infrastructure anywhere
4. **Cost-Optimized**: Using free tier resources
5. **Scalable**: Easy to add more VMs
6. **Secure**: Service accounts, SSH keys, custom VPC

---

**Terraform Version**: 1.13.5  
**GCP Provider**: ~> 5.0

