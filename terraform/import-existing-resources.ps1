# Script to import existing GCP resources into Terraform state
# This fixes the "already exists" errors when applying Terraform

$ErrorActionPreference = "Stop"

Write-Host "🔧 Importing existing GCP resources into Terraform state..." -ForegroundColor Cyan

# Change to terraform directory
Set-Location $PSScriptRoot

# Project ID from terraform.tfvars
$PROJECT_ID = "automation-alchemy"

# Import the VPC network
Write-Host "`n📡 Importing VPC network..." -ForegroundColor Yellow
$NETWORK_NAME = "automation-alchemy-vpc"
$NETWORK_ID = "projects/$PROJECT_ID/global/networks/$NETWORK_NAME"

terraform import google_compute_network.main $NETWORK_ID
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to import VPC network" -ForegroundColor Red
    exit 1
}
Write-Host "✅ VPC network imported successfully" -ForegroundColor Green

# Import the service account
Write-Host "`n👤 Importing service account..." -ForegroundColor Yellow
$SERVICE_ACCOUNT_ID = "automation-alchemy-vm-sa"
$SERVICE_ACCOUNT_EMAIL = "$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com"
$SERVICE_ACCOUNT_FULL_ID = "projects/$PROJECT_ID/serviceAccounts/$SERVICE_ACCOUNT_EMAIL"

terraform import google_service_account.vm_service_account $SERVICE_ACCOUNT_FULL_ID
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to import service account" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Service account imported successfully" -ForegroundColor Green

Write-Host "`n✅ All resources imported successfully!" -ForegroundColor Green
Write-Host "`nYou can now run 'terraform apply' to continue with the deployment." -ForegroundColor Cyan



