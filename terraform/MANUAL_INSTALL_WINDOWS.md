# Manual Terraform Installation - Windows AMD64

## 📥 Step-by-Step Instructions

### Step 1: Download Terraform
1. Go to: https://releases.hashicorp.com/terraform/
2. Find the latest version (e.g., `terraform_1.13.5_windows_amd64.zip`)
3. Download: **terraform_X.X.X_windows_amd64.zip** (64-bit version)

### Step 2: Extract Terraform
1. Extract the ZIP file
2. You'll get `terraform.exe`
3. Create a folder: `C:\terraform` (or any location you prefer)
4. Copy `terraform.exe` to that folder

### Step 3: Add to PATH
1. Press `Win + R`, type: `sysdm.cpl`, press Enter
2. Click "Environment Variables"
3. Under "User variables", find "Path" and click "Edit"
4. Click "New" and add: `C:\terraform` (or your chosen path)
5. Click "OK" on all dialogs

### Step 4: Verify Installation
1. **Close and reopen PowerShell** (important for PATH to update)
2. Run: `terraform version`
3. You should see: `Terraform vX.X.X`

---

## ✅ Verification

After installation, run:
```powershell
terraform version
```

Expected output:
```
Terraform v1.13.5
on windows_amd64
```

---

## 🚀 Next Steps

Once Terraform is installed:
1. Navigate to terraform directory: `cd terraform`
2. Create config: `copy terraform.tfvars.example terraform.tfvars`
3. Edit `terraform.tfvars` with your GCP project ID
4. Run: `terraform init`

---

**Need help? Let me know once you've installed it!** 🎯

