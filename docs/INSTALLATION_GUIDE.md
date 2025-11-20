# Installation Guide - Windows & Arch Linux

This guide covers installing all required tools for both Windows and Arch Linux.

## 🛠️ Required Tools

- **Terraform** - Infrastructure as Code
- **gcloud CLI** - Google Cloud SDK (optional but recommended)
- **Ansible** - Configuration management (coming in Phase 2)
- **Git** - Version control

---

## 🪟 Windows Installation

### Terraform

**Option 1: Chocolatey (Recommended)**
```powershell
# Install Chocolatey if you don't have it
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform -y
```

**Option 2: Manual Installation**
1. Download from: https://www.terraform.io/downloads
2. Choose: **Windows AMD64** (64-bit)
3. Extract `terraform.exe` to a folder (e.g., `C:\terraform`)
4. Add folder to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" under User variables
   - Add: `C:\terraform`
5. Restart PowerShell/Terminal

**Option 3: Scoop**
```powershell
# Install Scoop if you don't have it
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Terraform
scoop install terraform
```

**Verify Installation:**
```powershell
terraform version
```

---

### gcloud CLI (Google Cloud SDK)

**Option 1: Chocolatey**
```powershell
choco install gcloudsdk -y
```

**Option 2: Manual Installation**
1. Download from: https://cloud.google.com/sdk/docs/install
2. Run installer: `GoogleCloudSDKInstaller.exe`
3. Follow installer prompts
4. Restart PowerShell

**Option 3: Scoop**
```powershell
scoop install gcloud
```

**Verify Installation:**
```powershell
gcloud version
```

**Initial Setup:**
```powershell
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

---

### Ansible (For Phase 2)

**Windows Note:** Ansible doesn't run natively on Windows. Options:

**Option 1: WSL2 (Recommended)**
```powershell
# Install WSL2
wsl --install

# Then in WSL (Ubuntu):
sudo apt update
sudo apt install ansible -y
```

**Option 2: Use Ansible from Arch Linux**
- Install on your Arch laptop
- Use it from there

**Option 3: Docker (Advanced)**
```powershell
docker run -it --rm -v ${PWD}:/work -w /work ansible/ansible:latest
```

---

### Git

**Option 1: Chocolatey**
```powershell
choco install git -y
```

**Option 2: Download**
- Download from: https://git-scm.com/download/win
- Run installer with default options

**Verify:**
```powershell
git --version
```

---

## 🐧 Arch Linux Installation

### Terraform

**Using Pacman (AUR helper - yay/paru):**
```bash
# Install AUR helper if needed
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Install Terraform
yay -S terraform
```

**Or using official binary:**
```bash
# Download latest version
cd /tmp
wget https://releases.hashicorp.com/terraform/$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')/terraform_$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')_linux_amd64.zip

# Extract and install
unzip terraform_*_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform
```

**Verify:**
```bash
terraform version
```

---

### gcloud CLI

**Using AUR:**
```bash
yay -S google-cloud-sdk
```

**Or official installer:**
```bash
# Download and run installer
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

**Verify:**
```bash
gcloud version
```

---

### Ansible

**Using Pacman:**
```bash
sudo pacman -S ansible
```

**Verify:**
```bash
ansible --version
```

---

### Git

**Using Pacman:**
```bash
sudo pacman -S git
```

**Verify:**
```bash
git --version
```

---

## 🔑 SSH Key Setup (Both Platforms)

### Generate SSH Key (if you don't have one)

**Windows (PowerShell):**
```powershell
# Generate key
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa

# View public key (needed for Terraform)
cat $env:USERPROFILE\.ssh\id_rsa.pub
```

**Arch Linux:**
```bash
# Generate key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# View public key
cat ~/.ssh/id_rsa.pub
```

**Note:** Copy the public key output - you'll need it for `terraform.tfvars`

---

## ✅ Verification Checklist

After installation, verify everything works:

**Windows:**
```powershell
terraform version
gcloud version
git --version
ssh -V
```

**Arch Linux:**
```bash
terraform version
gcloud version
ansible --version
git --version
ssh -V
```

---

## 🔧 Cross-Platform Compatibility

### Script Compatibility

Our scripts are designed to work on both platforms:

**Terraform files:** ✅ Work on both (Terraform is cross-platform)
**Shell scripts:** Use `#!/bin/bash` (works on Arch, WSL on Windows)
**PowerShell scripts:** Use `.ps1` extension (Windows only)

### Path Differences

**Windows:**
- SSH key: `C:\Users\YourName\.ssh\id_rsa.pub`
- Or: `~/.ssh/id_rsa.pub` (in PowerShell)

**Arch Linux:**
- SSH key: `~/.ssh/id_rsa.pub`

**Solution:** Use `~/.ssh/id_rsa.pub` in `terraform.tfvars` - it works on both!

---

## 🚀 Quick Start After Installation

1. **Authenticate with GCP:**
   ```bash
   # Windows (PowerShell)
   gcloud auth login
   
   # Arch Linux
   gcloud auth login
   ```

2. **Set your project:**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Navigate to terraform directory:**
   ```bash
   cd terraform
   ```

4. **Create terraform.tfvars:**
   ```bash
   # Windows
   copy terraform.tfvars.example terraform.tfvars
   
   # Arch Linux
   cp terraform.tfvars.example terraform.tfvars
   ```

5. **Edit terraform.tfvars** with your project ID

6. **Initialize Terraform:**
   ```bash
   terraform init
   ```

---

## 🐛 Troubleshooting

### Windows: "terraform: command not found"
- Check PATH: `$env:PATH`
- Restart PowerShell after adding to PATH
- Try: `refreshenv` (if using Chocolatey)

### Arch: "terraform: command not found"
- Check installation: `which terraform`
- Verify PATH: `echo $PATH`
- May need to restart terminal

### SSH Key Not Found
- Check path in `terraform.tfvars`
- Use `~/.ssh/id_rsa.pub` (works on both platforms)
- Generate key if missing (see SSH Key Setup above)

---

## 📚 Next Steps

Once all tools are installed:
1. ✅ Verify all tools work
2. ✅ Set up GCP authentication
3. ✅ Configure `terraform.tfvars`
4. ➡️ **Proceed to**: `terraform/README.md` for infrastructure setup

---

**Ready to install? Start with Terraform!** 🚀

