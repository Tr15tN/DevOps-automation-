# Manual Terraform Installation Script for Windows
# No admin rights required - installs to user directory

$ErrorActionPreference = "Stop"

Write-Host "🔧 Installing Terraform (AMD64) for Windows..." -ForegroundColor Cyan

# Create terraform directory in user's local folder
$TerraformDir = "$env:LOCALAPPDATA\terraform"
$TerraformExe = "$TerraformDir\terraform.exe"

# Check if already installed
if (Test-Path $TerraformExe) {
    Write-Host "✅ Terraform is already installed at: $TerraformExe" -ForegroundColor Green
    & $TerraformExe version
    exit 0
}

# Create directory
New-Item -ItemType Directory -Force -Path $TerraformDir | Out-Null

# Get latest Terraform version
Write-Host "📥 Fetching latest Terraform version..." -ForegroundColor Yellow
$LatestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/hashicorp/terraform/releases/latest").tag_name -replace 'v', ''
Write-Host "   Latest version: $LatestVersion" -ForegroundColor Gray

# Download Terraform
$DownloadUrl = "https://releases.hashicorp.com/terraform/${LatestVersion}/terraform_${LatestVersion}_windows_amd64.zip"
$ZipFile = "$env:TEMP\terraform_${LatestVersion}_windows_amd64.zip"

Write-Host "📥 Downloading Terraform from: $DownloadUrl" -ForegroundColor Yellow
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -UseBasicParsing

# Extract
Write-Host "📦 Extracting Terraform..." -ForegroundColor Yellow
Expand-Archive -Path $ZipFile -DestinationPath $TerraformDir -Force

# Clean up
Remove-Item $ZipFile -Force

# Add to PATH (user-level)
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($UserPath -notlike "*$TerraformDir*") {
    Write-Host "🔧 Adding Terraform to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable('Path', "$UserPath;$TerraformDir", 'User')
    $env:Path += ";$TerraformDir"
}

# Verify installation
Write-Host "✅ Terraform installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Location: $TerraformExe" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Note: You may need to restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "Testing installation..." -ForegroundColor Yellow
& $TerraformExe version

