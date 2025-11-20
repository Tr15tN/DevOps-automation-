# Terraform Installation - Quick Reference

## 🪟 Windows (AMD64 - 64-bit)

**You need: AMD64 binary** (64-bit Windows)

### Quick Install (Chocolatey)
```powershell
choco install terraform -y
```

### Manual Install
1. Download: https://releases.hashicorp.com/terraform/
2. Choose: **Windows AMD64** (64-bit)
3. Extract `terraform.exe` to `C:\terraform`
4. Add to PATH: `C:\terraform`
5. Restart PowerShell

### Verify
```powershell
terraform version
```

---

## 🐧 Arch Linux

### Quick Install (AUR)
```bash
yay -S terraform
```

### Manual Install
```bash
cd /tmp
wget https://releases.hashicorp.com/terraform/$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')/terraform_$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')_linux_amd64.zip
unzip terraform_*_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Verify
```bash
terraform version
```

---

## ✅ After Installation

1. **Navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Create config:**
   ```bash
   # Windows
   copy terraform.tfvars.example terraform.tfvars
   
   # Arch Linux
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars** - Set your `project_id`

4. **Initialize:**
   ```bash
   terraform init
   ```

---

**See `../docs/INSTALLATION_GUIDE.md` for complete setup instructions!**

