# Ansible Configuration Management

This directory contains Ansible playbooks for configuring VMs provisioned by Terraform.

## 📋 Overview

Ansible playbooks automate:
- System updates and package installation
- Docker installation
- Firewall configuration (UFW)
- Security hardening
- Application deployment

## 🚀 Quick Start

### Prerequisites

1. **Ansible installed** (in WSL or on Arch laptop):
   ```bash
   # In WSL
   sudo apt install ansible
   # Verify
   ansible --version
   ```

2. **SSH access to VMs**:
   - SSH key configured (already done in Terraform)
   - SSH key copied to WSL: `cp /mnt/c/Users/M0usetrap/.ssh/id_rsa ~/.ssh/id_rsa`
   - Permissions set: `chmod 600 ~/.ssh/id_rsa`
   - Can SSH into VM: `ssh devops@<VM_IP>`

3. **Inventory configured**:
   - Inventory auto-generated from Terraform outputs
   - Or manually update `inventory/hosts.yml` with VM IP

### Running Playbooks

#### Run All Playbooks (Complete Setup)
```bash
# In WSL
cd /mnt/c/automation-alchemy/ansible
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
```

#### Run Individual Playbooks
```bash
# In WSL, from ansible/ directory
# Common setup (users, packages)
ansible-playbook playbooks/common.yml -i inventory/hosts.yml

# Docker installation
ansible-playbook playbooks/docker.yml -i inventory/hosts.yml

# Firewall configuration
ansible-playbook playbooks/firewall.yml -i inventory/hosts.yml

# Security hardening
ansible-playbook playbooks/security.yml -i inventory/hosts.yml

# Application deployment
ansible-playbook playbooks/app-deploy.yml -i inventory/hosts.yml
```

### Update Inventory from Terraform

```bash
# Get VM information
cd terraform
terraform output -json vm_instances > ../ansible/inventory/vms.json

# Or manually update inventory/hosts.yml with IPs from:
terraform output vm_instances
```

## 📁 Structure

```
ansible/
├── ansible.cfg          # Ansible configuration
├── inventory/
│   └── hosts.yml       # VM inventory
├── playbooks/
│   ├── site.yml        # Main playbook (runs all)
│   ├── common.yml      # Common setup
│   ├── docker.yml      # Docker installation
│   ├── firewall.yml    # Firewall configuration
│   ├── security.yml    # Security hardening
│   └── app-deploy.yml  # Application deployment
└── roles/              # Reusable roles (optional)
```

## 🔧 Configuration

### Inventory File

Edit `inventory/hosts.yml` with your VM IPs:

```yaml
all:
  children:
    app_servers:
      hosts:
        automation-alchemy:
          ansible_host: 34.88.104.254  # Update with your VM IP
          ansible_user: devops
```

### Get VM IP from Terraform

```bash
cd terraform
terraform output vm_instances
# Shows: external_ip, internal_ip, etc.
```

## 🧪 Testing

### Test Connection
```bash
# In WSL
cd /mnt/c/automation-alchemy/ansible
ansible all -m ping -i inventory/hosts.yml
```

Expected output:
```
automation-alchemy | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Dry Run (Check Mode)
```bash
ansible-playbook playbooks/site.yml --check
```

### Verbose Output
```bash
ansible-playbook playbooks/site.yml -v
# -vv for more verbose
# -vvv for even more
```

## 🔍 Troubleshooting

### Connection Issues

**"No inventory was parsed"**
```bash
# Always specify inventory explicitly in WSL
ansible all -m ping -i inventory/hosts.yml
```

**"Permission denied (publickey)"**
```bash
# Copy SSH key to WSL and set permissions
cp /mnt/c/Users/M0usetrap/.ssh/id_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
# Update inventory to use ~/.ssh/id_rsa
```

**"UNPROTECTED PRIVATE KEY FILE"**
```bash
# Set correct permissions (600 = owner read/write only)
chmod 600 ~/.ssh/id_rsa
```

**Test SSH connection**
```bash
ssh devops@<VM_IP>
```

**Check inventory**
```bash
ansible-inventory --list -i inventory/hosts.yml
```

### Permission Issues
```bash
# Run with become (sudo)
ansible-playbook playbooks/site.yml --become

# Or specify user
ansible-playbook playbooks/site.yml -u devops --become
```

### Docker Issues
```bash
# Check if Docker is installed
ansible all -m command -a "docker --version"

# Check Docker service
ansible all -m systemd -a "name=docker state=started"
```

## 📚 Next Steps

After Ansible completes:
1. ✅ VMs are configured
2. ✅ Docker is installed
3. ✅ Firewall is configured
4. ✅ Security is hardened
5. ✅ Application is deployed
6. **Next**: Set up GitLab CI (see docs/GITLAB_CI_SETUP.md)

---

**See**: `../docs/what-and-why/` for detailed explanations

