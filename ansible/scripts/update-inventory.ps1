# PowerShell script to update Ansible inventory from Terraform outputs

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $ScriptDir "..\..\terraform"
$InventoryFile = Join-Path $ScriptDir "..\inventory\hosts.yml"

Write-Host "🔄 Updating Ansible inventory from Terraform outputs..." -ForegroundColor Cyan

Set-Location $TerraformDir

# Check if Terraform has been applied
if (-not (Test-Path "terraform.tfstate")) {
    Write-Host "❌ Error: Terraform state not found. Run 'terraform apply' first." -ForegroundColor Red
    exit 1
}

# Get VM information from Terraform
$VmInfo = terraform output -json vm_instances 2>$null | ConvertFrom-Json

if (-not $VmInfo) {
    Write-Host "❌ Error: Could not get VM information from Terraform." -ForegroundColor Red
    exit 1
}

# Generate inventory file
$InventoryContent = @"
---
# Ansible Inventory
# Auto-generated from Terraform outputs
# Run: ansible/scripts/update-inventory.ps1 to regenerate

all:
  children:
"@

# Add each VM to all relevant groups based on role
foreach ($vm in $VmInfo.PSObject.Properties) {
    $vmData = $vm.Value
    $vmName = $vmData.name
    $vmHostEntry = "        $vmName`:`n          ansible_host: $($vmData.external_ip)`n          ansible_user: devops`n          role: $($vmData.role)`n          internal_ip: $($vmData.internal_ip)"
    
    # If all-in-one, add to all groups
    if ($vmData.role -eq "all-in-one") {
        $InventoryContent += "`n    load_balancer:`n      hosts:`n$vmHostEntry`n    web_servers:`n      hosts:`n$vmHostEntry`n    app_servers:`n      hosts:`n$vmHostEntry`n    jenkins:`n      hosts:`n$vmHostEntry"
    } else {
        # For specific roles, add to appropriate group
        $InventoryContent += "`n    $($vmData.role):`n      hosts:`n$vmHostEntry"
    }
}

$InventoryContent | Out-File -FilePath $InventoryFile -Encoding UTF8

Write-Host "✅ Inventory updated: $InventoryFile" -ForegroundColor Green
Write-Host ""
Write-Host "To verify, run: ansible-inventory --list" -ForegroundColor Yellow

