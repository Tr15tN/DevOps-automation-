# Automation Alchemy 🔮

## 🚀 Project Overview

**Automation Alchemy** is a comprehensive DevOps automation project demonstrating Infrastructure as Code (IaC), configuration management, and CI/CD pipeline implementation. This project automates the deployment of a multi-server infrastructure on Google Cloud Platform, transforming manual processes into fully automated workflows.

### Key Features

- 🏗️ **Infrastructure as Code**: Terraform for automated VM provisioning
- ⚙️ **Configuration Management**: Ansible for server configuration and hardening
- 🔁 **CI/CD Pipeline**: GitLab CI for automated deployments
- ☁️ **Cloud Infrastructure**: Google Cloud Platform (GCP) with free tier optimization
- 🐳 **Containerized Applications**: Docker-based application deployment
- 🔒 **Security**: Automated hardening, firewall rules, and best practices
- 📊 **Monitoring**: System monitoring and health checks
- 🎯 **One-Click Deployment**: Single command to deploy entire infrastructure

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│         ONE-CLICK AUTOMATION SCRIPT             │
│  (Terraform → Ansible → GitLab CI → Deploy)     │
└─────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  Terraform   │        │   Ansible    │
│  (Provision) │──────▶ │ (Configure)  │
└──────────────┘        └──────────────┘
        │                       │
        ▼                       ▼
┌─────────────────────────────────────────┐
│         GCP Cloud Infrastructure        │
│  ┌──────────┐  ┌──────────┐            │
│  │ Load Bal │  │ Web #1   │            │
│  │  (VM)    │  │  (VM)    │            │
│  └────┬─────┘  └────┬─────┘            │
│       │             │                   │
│  ┌────┴─────┐  ┌────┴─────┐            │
│  │ Web #2   │  │ App      │            │
│  │  (VM)    │  │  (VM)    │            │
│  └──────────┘  └──────────┘            │
│                                        │
│  ┌──────────┐                         │
│  │ Jenkins │                         │
│  │  (VM)   │                         │
│  └──────────┘                         │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│      Containers (on each VM)           │
│  (HAProxy, NGINX, Node.js, Netdata)    │
└─────────────────────────────────────────┘
```

### Current Setup (Phase 1 & 2 Complete)

- **Region**: `europe-north1` (Finland) - Optimized for Estonia
- **VM Count**: 1 (configurable: 1, 4, or 5)
- **Machine Type**: `e2-micro` (Free tier eligible)
- **Cost**: $0/month (using free tier)
- **Application**: ✅ Running at `http://34.88.104.254:8080`
- **Containers**: ✅ All 5 containers healthy (app-server, web-server-1, web-server-2, load-balancer, netdata)

---

## 📋 Prerequisites

- **Terraform** v1.5.0+ ([Installation Guide](docs/INSTALLATION_GUIDE.md))
- **gcloud CLI** (for GCP authentication)
- **Git** for version control
- **GCP Account** with project created ([Setup Guide](docs/GCP_BEGINNER_SETUP.md))
- **SSH Key** (will be generated if missing)

For Phase 2+:
- **Ansible** (for configuration management) ✅ Installed
- **GitLab Account** (for CI/CD) - Next phase

---

## 🚀 Quick Start

### Phase 1: Infrastructure Provisioning (✅ Complete)

1. **Set up GCP Account**
   ```bash
   # Follow: docs/GCP_BEGINNER_SETUP.md
   ```

2. **Configure Terraform**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project_id
   ```

3. **Authenticate with GCP**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Get VM Information**
   ```bash
   terraform output
   ```

### Phase 2: Configuration Management (✅ Complete)

1. **Update Ansible Inventory**
   ```bash
   cd ansible
   # Run the update script (or manually update inventory/hosts.yml)
   # The inventory should point to your VM IP from Terraform
   ```

2. **Run Ansible Playbooks**
   ```bash
   # From WSL (Ansible works best on Linux)
   cd ansible
   ansible-playbook playbooks/site.yml -i inventory/hosts.yml
   ```

3. **Verify Deployment**
   ```bash
   # Check containers are running
   ssh devops@<EXTERNAL_IP>
   docker ps
   
   # Test application
   curl http://<EXTERNAL_IP>:8080
   ```

### Phase 4: Testing Integration (🔄 In Progress)

1. **Run Tests Locally**
   ```bash
   # Code quality tests
   ./tests/code-quality.sh
   
   # Security scanning
   ./tests/security-scan.sh
   
   # Integration tests
   BASE_URL=http://34.88.104.254:8080 VM_IP=34.88.104.254 ./tests/integration-test.sh
   
   # Performance tests
   TARGET_URL=http://34.88.104.254:8080 ./tests/performance-test.sh
   ```

2. **Tests in CI Pipeline**
   - Code quality runs automatically on every commit
   - Security scanning runs after Docker build
   - Integration & performance tests run manually after deployment
   - See `.gitlab-ci.yml` for full pipeline configuration

3. **Test Documentation**
   - See `tests/README.md` for detailed test documentation

### Access Your VM

```bash
# SSH into the VM
ssh devops@<EXTERNAL_IP>

# Get IP from Terraform output
terraform output vm_instances

# Current VM: 34.88.104.254
```

---

## 📊 Project Status

### ✅ Phase 1: Infrastructure as Code (Terraform) - COMPLETE

- [x] Terraform configuration created
- [x] GCP infrastructure provisioned
- [x] VPC, subnet, firewall rules configured
- [x] VM instance running in Europe (europe-north1)
- [x] SSH access configured
- [x] Cost optimized (free tier)

**Current VM**: `automation-alchemy` at `34.88.104.254` (europe-north1-a)  
**Application**: ✅ Running at `http://34.88.104.254:8080`  
**Containers**: ✅ All 5 containers healthy (app-server, web-server-1, web-server-2, load-balancer, netdata)

### ✅ Phase 2: Configuration Management (Ansible) - COMPLETE

- [x] Ansible playbooks created
- [x] Inventory configured (from Terraform outputs)
- [x] SSH connection working
- [x] Docker installation automated ✅
- [x] Firewall configuration automated ✅
- [x] Security hardening automated ✅
- [x] Application deployment automated ✅
- [x] All containers healthy and running ✅

### ✅ Phase 3: CI/CD Pipeline (GitLab CI) - COMPLETE

- [x] GitLab project setup ✅
- [x] CI/CD pipeline configuration ✅
- [x] Docker image build and push to Artifact Registry ✅
- [x] Automated deployment via Ansible ✅
- [x] Health check stage ✅
- [x] End-to-end pipeline tested and working ✅

### 🔄 Phase 4: Testing Integration - IN PROGRESS

- [x] Code quality tests (ESLint + ShellCheck) ✅
- [x] Security scanning (Trivy) ✅
- [x] Performance tests (load testing) ✅
- [x] Integration tests (API endpoints) ✅
- [x] All tests integrated into CI pipeline ✅
- [ ] Pipeline testing (pending CI run)

### 📋 Phase 4-7: Testing, Alerts, Rollback, One-Click - PLANNED

See [Project Progress](docs/what-and-why/PROJECT_PROGRESS.md) for detailed status.

---

## 📁 Project Structure

```
automation-alchemy/
├── README.md                    # This file
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # Main infrastructure resources
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values (for Ansible)
│   ├── versions.tf            # Provider versions
│   └── terraform.tfvars        # Your configuration
│
├── ansible/                    # Configuration Management (Phase 2) ✅
│   ├── playbooks/              # Ansible playbooks
│   │   ├── site.yml           # Main playbook
│   │   ├── common.yml          # Common setup
│   │   ├── docker.yml          # Docker installation
│   │   ├── firewall.yml        # Firewall config
│   │   ├── security.yml        # Security hardening
│   │   └── app-deploy.yml      # Application deployment
│   ├── inventory/              # VM inventory
│   └── ansible.cfg             # Ansible configuration
│
├── tests/                      # Testing Framework (Phase 4) 🔄
│   ├── code-quality.sh         # ESLint + ShellCheck
│   ├── security-scan.sh        # Trivy security scanning
│   ├── performance-test.sh     # Load testing
│   ├── integration-test.sh     # API & E2E tests
│   └── README.md               # Test documentation
│
├── .gitlab-ci.yml              # GitLab CI pipeline (Phase 3)
│
├── docker/                     # Application code
│   └── app-server/            # Node.js backend
│
├── configs/                    # Service configurations
│   ├── haproxy/               # Load balancer config
│   └── nginx/                 # Web server configs
│
├── web-content/                # Frontend application
│   └── index.html
│
├── scripts/                    # Automation scripts
│   ├── install_docker.sh      # Docker installation
│   ├── configure_firewall.sh  # Firewall setup
│   └── backup/                # Backup scripts
│
└── docs/                       # Documentation
    ├── what-and-why/          # What we did and why
    ├── INSTALLATION_GUIDE.md   # Tool installation
    └── GCP_BEGINNER_SETUP.md   # GCP setup guide
```

---

## 🛠️ Technology Stack

| Component | Technology | Status |
|-----------|-----------|--------|
| **Infrastructure** | Terraform + GCP | ✅ Complete |
| **Configuration** | Ansible | ✅ Complete |
| **CI/CD** | GitLab CI | 📋 Planned |
| **Cloud Provider** | Google Cloud Platform | ✅ Complete |
| **Containerization** | Docker | ✅ Complete |
| **Load Balancer** | HAProxy | ✅ Complete |
| **Web Server** | NGINX | ✅ Complete |
| **Backend** | Node.js + Express | ✅ Complete |
| **Monitoring** | Netdata | ✅ Complete |

---

## 💰 Cost Management

### Current Setup (Free Tier)

- **1x e2-micro VM**: FREE (free tier)
- **30GB disk**: FREE (free tier)
- **VPC/Networking**: FREE
- **Total**: **$0/month** ✅

### Scaling Options

- **4 VMs**: ~$21/month (1 free + 3 paid)
- **5 VMs**: ~$28/month (1 free + 4 paid)

**Note**: With $300 GCP credit, you get ~14 months free!

See [Cost Optimization Strategy](docs/COST_OPTIMIZATION_STRATEGY.md) for details.

---

## 📚 Documentation

### Quick Links

- **New to cloud?** → [GCP Beginner Setup](docs/GCP_BEGINNER_SETUP.md)
- **Want to understand decisions?** → [What and Why](docs/what-and-why/)
- **Need installation help?** → [Installation Guide](docs/INSTALLATION_GUIDE.md)
- **Check progress?** → [Project Progress](docs/what-and-why/PROJECT_PROGRESS.md)

### Key Documents

- [Terraform Setup](docs/what-and-why/TERRAFORM_SETUP.md) - Complete infrastructure explanation
- [Architecture Decisions](docs/what-and-why/ARCHITECTURE_DECISIONS.md) - Why we chose what we did
- [Project Progress](docs/what-and-why/PROJECT_PROGRESS.md) - Detailed progress tracking

---

## 🔧 Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
region     = "europe-north1"      # Optimized for Estonia
zone       = "europe-north1-a"
vm_count   = 1                     # 1 = free tier, 4-5 = full setup
```

### VM Configuration

- **Machine Type**: `e2-micro` (free tier)
- **Disk Size**: 30GB (free tier)
- **OS**: Ubuntu 22.04 LTS
- **SSH User**: `devops`

---

## 🧪 Testing

### Verify Infrastructure

```bash
# Check Terraform state
cd terraform
terraform show

# Get VM IPs
terraform output vm_instances

# Test SSH access
ssh devops@34.88.104.254
```

### Verify Application

```bash
# Test load balancer
curl http://34.88.104.254:8080

# Test individual web servers
curl http://34.88.104.254:8081/health
curl http://34.88.104.254:8082/health

# Test app server directly
curl http://34.88.104.254:3000/health

# Check containers on VM
ssh devops@34.88.104.254
docker ps
```

### Verify VM Status

```bash
# In GCP Console
https://console.cloud.google.com/compute/instances

# Or via gcloud
gcloud compute instances list
```

---

## 🐛 Troubleshooting

### Terraform Issues

**Error: "API not enabled"**
```bash
gcloud services enable compute.googleapis.com
```

**Error: "Permission denied"**
```bash
gcloud auth application-default login
```

**Error: "Quota exceeded"**
- Check GCP quotas in console
- Request quota increase if needed

### SSH Issues

**Can't connect to VM**
- Check firewall rules: `gcloud compute firewall-rules list`
- Verify SSH key: `terraform output` shows key in metadata
- Check VM status: `gcloud compute instances describe automation-alchemy`

See [Terraform Setup](docs/what-and-why/TERRAFORM_SETUP.md) for more troubleshooting.

---

## 🧹 Cleanup

To destroy all infrastructure:

```bash
cd terraform
terraform destroy
```

**Warning**: This will delete all VMs and infrastructure. Cost goes to $0/month.

---

## 🎯 Goals & Learning Outcomes

By completing this project, you'll learn:

1. **Infrastructure as Code**: Terraform for cloud provisioning
2. **Configuration Management**: Ansible for server automation
3. **CI/CD**: GitLab CI pipeline creation
4. **Cloud Fundamentals**: GCP services, networking, security
5. **DevOps Best Practices**: Automation, version control, documentation
6. **Cost Optimization**: Free tier usage, resource management

---

## 🚀 Next Steps

1. ✅ **Phase 1 Complete**: Infrastructure provisioned
2. ✅ **Phase 2 Complete**: Ansible configuration and application deployment
3. 📋 **Phase 3**: Configure GitLab CI pipeline
4. 📋 **Phase 4-7**: Testing, alerts, rollback, one-click deployment

See [Project Progress](docs/what-and-why/PROJECT_PROGRESS.md) for detailed next steps.

---

## 📝 Contributing

This is an educational project. Feel free to:
- Experiment with configurations
- Add new features
- Improve documentation
- Share your learnings

---

## 📄 License

MIT License - Free to use for learning and development purposes.

---

## 🏆 Success Criteria

- ✅ Infrastructure provisioned with Terraform
- ✅ VMs accessible and configured
- ✅ Ansible automation complete (Docker, firewall, security, app deployment)
- ✅ Application deployed and healthy (all containers running)
- 📋 CI/CD pipeline functional (Phase 3)
- 📋 Automated testing integrated (Phase 4)
- 📋 One-click deployment working (Phase 7)
- ✅ Cost optimized (free tier)

---

## 🔗 Useful Links

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [GCP Documentation](https://cloud.google.com/docs)
- [GCP Free Tier](https://cloud.google.com/free)

---

**Ready to automate? Start with `terraform apply` and watch your infrastructure come to life! 🚀**

**Current Status**: Phase 1, 2 & 3 Complete ✅✅✅ | Phase 4 (Testing) In Progress 🔄

**Application Live**: `http://34.88.104.254:8080` 🎉

**Last Updated**: 2025-11-20

<!-- Pipeline test -->
