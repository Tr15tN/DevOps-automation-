# Deployment Workflow Guide

This document explains the proper deployment workflow for Automation Alchemy, addressing common issues and best practices.

## 🎯 Overview

There are **two ways** to deploy:

1. **Local Deployment** (Development/Testing) - Use WSL (recommended) or Git Bash
2. **GitLab CI/CD** (Recommended for Production) - Automated deployments

---

## 🚀 Option 1: Local Deployment (WSL Recommended)

### Why WSL?

- ✅ Ansible works properly (no encoding issues)
- ✅ All bash scripts work natively
- ✅ Better compatibility with Linux-based tools
- ✅ **Auto-installation of missing tools**
- ✅ No Windows-specific workarounds needed

### Prerequisites

The deployment script will **automatically check and install** missing tools:

- **Terraform** - Auto-installed if missing
- **Ansible** - Auto-installed if missing
- **jq** - Auto-installed if missing (optional but helpful)
- **gcloud CLI** - Installation instructions provided

### Deployment Steps

```bash
# 1. Open WSL
wsl

# 2. Navigate to project
cd /mnt/c/automation-alchemy

# 3. Run deployment script (it will install missing tools automatically)
./scripts/deploy.sh
```

### What the Script Does

1. ✅ **Detects environment** (WSL, Git Bash, Linux, etc.)
2. ✅ **Checks prerequisites** (Terraform, Ansible, gcloud, jq)
3. ✅ **Offers to install missing tools** automatically
4. ✅ **Checks GCP authentication** and prompts to set up if needed
5. ✅ **Checks Terraform configuration**
6. ✅ **Provisions infrastructure** (if needed)
7. ✅ **Automatically starts VM if stopped**
8. ✅ **Updates Ansible inventory** with VM IP
9. ✅ **Deploys with Ansible** (handles encoding automatically)
10. ✅ **Verifies deployment**

### Auto-Installation Features

When you run the script, if tools are missing:

```
❌ Terraform not found
❌ Ansible not found
⚠️  jq not found

Would you like to install missing tools automatically? (y/n): y

✅ Installing Terraform...
✅ Installing Ansible...
✅ Installing jq...
✅ All prerequisites met!
```

**Supported environments:**
- ✅ WSL/Ubuntu/Debian - Full auto-installation
- ✅ Arch Linux - Full auto-installation
- ⚠️ Git Bash - Manual installation instructions

### GCP Authentication

The script automatically checks for GCP authentication:

```
✅ gcloud CLI found
✅ GCP user authentication verified
❌ GCP application default credentials not set (required for Terraform)

Would you like to set up GCP authentication now? (y/n): y

✅ Setting up GCP application-default credentials...
✅ GCP authentication configured
```

**Required authentication:**
- `gcloud auth login` - User authentication
- `gcloud auth application-default login` - Required for Terraform

---

## 🔄 Option 2: GitLab CI/CD (Recommended for Production)

### Why GitLab CI/CD?

- ✅ **No Windows compatibility issues** - Runs on Linux runners
- ✅ **Automated** - Deploys on every push (or manual trigger)
- ✅ **Consistent** - Same environment every time
- ✅ **Secure** - SSH keys stored in GitLab variables
- ✅ **Trackable** - Full deployment history

### Setup (One-Time)

1. **Set GitLab CI Variables** (Settings → CI/CD → Variables):

   | Variable | Value | Protected | Masked |
   |----------|-------|-----------|--------|
   | `VM_EXTERNAL_IP` | Your VM IP | ✅ | ❌ |
   | `SSH_PRIVATE_KEY` | Base64 encoded SSH key | ✅ | ✅ |
   | `GCP_SERVICE_ACCOUNT_KEY` | Base64 encoded GCP key | ✅ | ✅ |
   | `CONTAINER_REGISTRY` | `gcr.io` | ✅ | ❌ |
   | `GCP_PROJECT_ID` | Your project ID | ✅ | ❌ |

2. **Get SSH Private Key (Base64)**:
   ```bash
   # Linux/Mac/WSL
   cat ~/.ssh/id_rsa | base64 -w 0
   
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.ssh\id_rsa"))
   ```

3. **Get GCP Service Account Key** (see [GitLab CI Setup Guide](GITLAB_CI_SETUP.md))

### Deploy via GitLab CI

1. **Push code to GitLab**:
   ```bash
   git push origin main
   ```

2. **Pipeline runs automatically**:
   - Build stage: Builds Docker image
   - Test stage: Runs tests
   - Security stage: Scans for vulnerabilities

3. **Manual deployment** (for safety):
   - Go to **CI/CD → Pipelines**
   - Find the `deploy:ansible` job
   - Click **Play** ▶️ button
   - Deployment runs automatically

4. **Health check** runs automatically after deployment

---

## 🔧 Fixed Issues

### 1. Missing Tools

**Problem**: Tools not installed (Terraform, Ansible, etc.)

**Solution**: 
- ✅ Script detects missing tools
- ✅ Offers automatic installation
- ✅ Works in WSL/Ubuntu/Arch Linux
- ✅ Provides manual instructions for other environments

### 2. GCP Authentication

**Problem**: `Error: Attempted to load application default credentials`

**Solution**:
- ✅ Script checks for application-default credentials
- ✅ Prompts to set up if missing
- ✅ Runs `gcloud auth application-default login` automatically
- ✅ Clear error messages if authentication fails

### 3. Ansible Encoding Error

**Problem**: `ERROR: Ansible requires the locale encoding to be UTF-8; Detected 1252.`

**Solution**: 
- ✅ Script detects environment and sets encoding appropriately
- ✅ Uses `PYTHONUTF8=1` and `PYTHONIOENCODING=utf-8`
- ✅ Tries available UTF-8 locales (C.UTF-8, en_US.UTF-8)
- ✅ Falls back to POSIX with Python encoding (works without UTF-8 locale)
- ✅ Works in WSL (not PowerShell)

### 4. Empty External IP

**Problem**: `external_ip = ""` when VM is stopped.

**Solution**:
- ✅ Added `ensure_vm_running()` function
- ✅ Automatically detects stopped VM
- ✅ Starts VM and waits for IP assignment
- ✅ Retrieves IP from gcloud if Terraform output is empty
- ✅ Updates inventory with correct IP

### 5. Terraform Plan Failures

**Problem**: Terraform plan fails but script continues

**Solution**:
- ✅ Script checks if `terraform plan` succeeds
- ✅ Shows clear error messages for common issues
- ✅ Prevents applying failed plans
- ✅ Provides troubleshooting guidance

---

## 📋 Deployment Checklist

### Before Deployment

- [ ] Run `./scripts/deploy.sh` (it will check everything)
- [ ] Script will install missing tools if you approve
- [ ] Script will set up GCP authentication if needed
- [ ] Terraform configuration is correct (`terraform.tfvars`)

### After Deployment

- [ ] Verify VM is running: `gcloud compute instances list`
- [ ] Check external IP: `terraform output vm_instances`
- [ ] Test application: `curl http://<VM_IP>:8080`
- [ ] Check containers: `ssh devops@<VM_IP> "docker ps"`
- [ ] Review GitLab CI pipeline (if using CI/CD)

---

## 🎯 Recommended Workflow

### For Development/Testing

1. **Use local deployment** with WSL:
   ```bash
   wsl
   cd /mnt/c/automation-alchemy
   ./scripts/deploy.sh
   ```

2. **Script handles everything**:
   - Installs missing tools
   - Sets up authentication
   - Deploys infrastructure
   - Configures VMs

3. **Make changes** to code/configs

4. **Test locally** before pushing

### For Production

1. **Use GitLab CI/CD**:
   - Push code to GitLab
   - Pipeline builds and tests automatically
   - Manually trigger deployment (for safety)
   - Health checks verify deployment

2. **Benefits**:
   - No local environment setup needed
   - Consistent deployments
   - Full audit trail
   - Automated testing

---

## 🐛 Troubleshooting

### Tools Not Installing

**If auto-installation fails:**
```bash
# WSL/Ubuntu - Manual installation
sudo apt update
sudo apt install -y terraform ansible jq

# Arch Linux
sudo pacman -S terraform ansible jq
```

### GCP Authentication Issues

```bash
# Check current authentication
gcloud auth list

# Set up user authentication
gcloud auth login

# Set up application-default credentials (required for Terraform)
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Ansible Encoding Error

**Solution**: Use WSL, not PowerShell:
```bash
# In WSL
wsl
cd /mnt/c/automation-alchemy
./scripts/deploy.sh
```

The script handles encoding automatically in WSL.

### VM Won't Start

```bash
# Check VM status
gcloud compute instances describe automation-alchemy --zone=europe-north1-a

# Start manually
gcloud compute instances start automation-alchemy --zone=europe-north1-a

# Wait for IP assignment (30-60 seconds)
sleep 60
```

### External IP Still Empty

1. **Check VM is running**:
   ```bash
   gcloud compute instances list
   ```

2. **Start VM if stopped**:
   ```bash
   gcloud compute instances start automation-alchemy --zone=europe-north1-a
   ```

3. **Wait for IP assignment** (ephemeral IPs take 30-60 seconds)

4. **Get IP from gcloud**:
   ```bash
   gcloud compute instances describe automation-alchemy \
       --zone=europe-north1-a \
       --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
   ```

---

## 📚 Additional Resources

- [Installation Guide](INSTALLATION_GUIDE.md) - Tool installation details
- [GitLab CI Setup Guide](GITLAB_CI_SETUP.md) - Detailed CI/CD setup
- [GCP Beginner Setup](GCP_BEGINNER_SETUP.md) - GCP account setup
- [Terraform Setup](what-and-why/TERRAFORM_SETUP.md) - Infrastructure details
- [Ansible README](../ansible/README.md) - Ansible configuration

---

## ✅ Summary

**For Local Development**:
- ✅ Use WSL (recommended)
- ✅ Run `./scripts/deploy.sh`
- ✅ Script installs missing tools automatically
- ✅ Script sets up GCP authentication if needed
- ✅ Script handles VM startup automatically
- ✅ Script handles encoding automatically

**For Production**:
- ✅ Use GitLab CI/CD
- ✅ Set up CI variables once
- ✅ Push code and deploy via pipeline

**Key Features**:
- ✅ Auto-installation of missing tools
- ✅ Automatic GCP authentication setup
- ✅ Ansible encoding handled automatically
- ✅ VM startup automation
- ✅ External IP retrieval improved
- ✅ Better error handling and messages

---

**Last Updated**: 2025-01-XX  
**Status**: All issues resolved ✅
