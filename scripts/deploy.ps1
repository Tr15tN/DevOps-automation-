# One-Click Deployment Script for Automation Alchemy
# Interactive deployment and testing script

# Don't stop on errors - we want to catch and display them
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$TerraformDir = Join-Path $ProjectRoot "terraform"
$AnsibleDir = Join-Path $ProjectRoot "ansible"
$TestsDir = Join-Path $ProjectRoot "tests"

# Colors for output
function Write-Step { param($Message) Write-Host "`n[STEP] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }

# Get VM IP from Terraform
function Get-VmIp {
    Push-Location $TerraformDir
    try {
        $VmOutput = terraform output -json vm_instances 2>$null | ConvertFrom-Json
        if ($VmOutput) {
            $FirstVm = ($VmOutput.PSObject.Properties | Select-Object -First 1).Value
            return $FirstVm.external_ip
        }
    } catch {
        return $null
    } finally {
        Pop-Location
    }
    return $null
}

# Validate Prerequisites
function Test-Prerequisites {
    param(
        [bool]$SkipTerraform = $false,
        [bool]$SkipAnsible = $false
    )
    
    Write-Step "Validating Prerequisites"
    $PrerequisitesMet = $true
    
    # Check Terraform
    if (-not $SkipTerraform) {
        if (Get-Command terraform -ErrorAction SilentlyContinue) {
            $TerraformVersion = (terraform version -json | ConvertFrom-Json).terraform_version
            Write-Success "Terraform found: v$TerraformVersion"
        } else {
            Write-Error "Terraform not found. Install from: https://www.terraform.io/downloads"
            $PrerequisitesMet = $false
        }
    }
    
    # Check gcloud CLI
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        $GcloudVersion = (gcloud version --format="json" | ConvertFrom-Json).Google_Cloud_SDK
        Write-Success "gcloud CLI found: $GcloudVersion"
        
        try {
            $null = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1
            Write-Success "GCP authentication verified"
        } catch {
            Write-Warning "GCP not authenticated. Run: gcloud auth login"
            $PrerequisitesMet = $false
        }
    } else {
        Write-Warning "gcloud CLI not found (optional but recommended)"
    }
    
    # Check Ansible
    if (-not $SkipAnsible) {
        if (Get-Command ansible -ErrorAction SilentlyContinue) {
            $AnsibleVersion = (ansible --version | Select-Object -First 1)
            Write-Success "Ansible found: $AnsibleVersion"
            
            # Warn about Windows compatibility
            $IsWindows = $PSVersionTable.Platform -eq "Win32NT" -or $env:OS -like "*Windows*"
            if ($IsWindows) {
                $HasBash = Get-Command bash -ErrorAction SilentlyContinue
                $HasWsl = Get-Command wsl -ErrorAction SilentlyContinue
                if ($HasBash -or $HasWsl) {
                    Write-Info "Windows detected. Will use bash/WSL for Ansible (better compatibility)"
                } else {
                    Write-Warning "Windows detected. Ansible may have compatibility issues on Windows."
                    Write-Info "Consider using WSL or Git Bash for Ansible operations."
                }
            }
        } else {
            Write-Error "Ansible not found. Install from: https://docs.ansible.com/ansible/latest/installation_guide/index.html"
            $PrerequisitesMet = $false
        }
    }
    
    if (-not $PrerequisitesMet) {
        Write-Error "Prerequisites not met. Please install missing tools and try again."
        return $false
    }
    
    Write-Success "All prerequisites met!"
    return $true
}

# Check Terraform Configuration
function Test-TerraformConfig {
    Write-Step "Checking Terraform Configuration"
    
    Push-Location $TerraformDir
    
    $TfVarsFile = Join-Path $TerraformDir "terraform.tfvars"
    $TfVarsExample = Join-Path $TerraformDir "terraform.tfvars.example"
    
    if (-not (Test-Path $TfVarsFile)) {
        if (Test-Path $TfVarsExample) {
            Write-Warning "terraform.tfvars not found. Creating from example..."
            Copy-Item $TfVarsExample $TfVarsFile
            Write-Success "Created terraform.tfvars"
            Write-Warning "IMPORTANT: Edit terraform/terraform.tfvars and set your project_id!"
            $response = Read-Host "Press Enter after you've edited terraform.tfvars (or Ctrl+C to cancel)"
        } else {
            Write-Error "terraform.tfvars not found and no example file available"
            Pop-Location
            return $false
        }
    }
    
    # Check SSH key
    $TfVarsContent = Get-Content $TfVarsFile -Raw
    $SshKeyMatch = [regex]::Match($TfVarsContent, 'ssh_public_key_path\s*=\s*"([^"]+)"')
    if ($SshKeyMatch.Success) {
        $SshKeyPath = $SshKeyMatch.Groups[1].Value
        if ($SshKeyPath -like "~/*") {
            $SshKeyPath = $SshKeyPath -replace "~", $env:USERPROFILE
        }
        
        if (-not (Test-Path $SshKeyPath)) {
            Write-Warning "SSH key not found at: $SshKeyPath"
            $GenerateKey = Read-Host "Generate SSH key? (y/n)"
            if ($GenerateKey -eq "y" -or $GenerateKey -eq "Y") {
                $PrivateKeyPath = $SshKeyPath -replace "\.pub$", ""
                ssh-keygen -t rsa -b 4096 -f $PrivateKeyPath -N '""'
                Write-Success "SSH key generated"
            } else {
                Write-Error "SSH key required. Exiting."
                Pop-Location
                return $false
            }
        } else {
            Write-Success "SSH key found: $SshKeyPath"
        }
    }
    
    Pop-Location
    return $true
}

# Run Terraform Operations
function Invoke-TerraformDeploy {
    param([bool]$Destroy = $false)
    
    Write-Step "Terraform Operations"
    
    Push-Location $TerraformDir
    
    Write-Info "Initializing Terraform..."
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform init failed"
        Pop-Location
        return $false
    }
    Write-Success "Terraform initialized"
    
    if ($Destroy) {
        Write-Warning "DESTROYING infrastructure..."
        $Confirm = Read-Host "Are you sure you want to destroy all resources? (type 'yes' to confirm)"
        if ($Confirm -eq "yes") {
            terraform destroy -auto-approve
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform destroy failed"
                Pop-Location
                return $false
            }
            Write-Success "Infrastructure destroyed"
            Pop-Location
            return $true
        } else {
            Write-Info "Destroy cancelled"
            Pop-Location
            return $false
        }
    } else {
        Write-Info "Planning Terraform changes..."
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform plan failed"
            Pop-Location
            return $false
        }
        
        Write-Info "Applying Terraform changes..."
        terraform apply tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform apply failed"
            Pop-Location
            return $false
        }
        Write-Success "Infrastructure provisioned successfully"
        
        Write-Info "Retrieving VM information..."
        $VmOutput = terraform output -json vm_instances 2>$null | ConvertFrom-Json
        if ($VmOutput) {
            Write-Success "VM information retrieved"
            $VmOutput.PSObject.Properties | ForEach-Object {
                $Vm = $_.Value
                Write-Info "  VM: $($Vm.name) - IP: $($Vm.external_ip)"
            }
        }
    }
    
    Pop-Location
    return $true
}

# Update Ansible Inventory
function Update-AnsibleInventory {
    Write-Step "Updating Ansible Inventory"
    
    $InventoryScript = Join-Path $AnsibleDir "scripts\update-inventory.sh"
    if (Test-Path $InventoryScript) {
        Write-Info "Running inventory update script..."
        if (Get-Command bash -ErrorAction SilentlyContinue) {
            bash $InventoryScript
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Ansible inventory updated"
                return $true
            } else {
                Write-Warning "Inventory update script failed. You may need to update inventory manually."
                return $false
            }
        } else {
            Write-Warning "bash not found. Skipping automatic inventory update."
            Write-Info "Please run: ansible/scripts/update-inventory.sh manually"
            return $false
        }
    } else {
        Write-Warning "Inventory update script not found. Please update ansible/inventory/hosts.yml manually"
        return $false
    }
}

# Run Ansible Deployment
function Invoke-AnsibleDeploy {
    Write-Step "Deploying with Ansible"
    
    Push-Location $AnsibleDir
    
    $InventoryFile = Join-Path $AnsibleDir "inventory\hosts.yml"
    if (-not (Test-Path $InventoryFile)) {
        Write-Error "Ansible inventory not found: $InventoryFile"
        Write-Info "Please run: ansible/scripts/update-inventory.sh"
        Pop-Location
        return $false
    }
    
    # Check if we're on Windows
    $IsWindows = $PSVersionTable.Platform -eq "Win32NT" -or $env:OS -like "*Windows*"
    $HasBash = Get-Command bash -ErrorAction SilentlyContinue
    $HasWsl = Get-Command wsl -ErrorAction SilentlyContinue
    
    Write-Info "Running Ansible playbooks..."
    
    # Try to run Ansible directly first
    $ansibleOutput = ansible-playbook playbooks/site.yml -i inventory/hosts.yml 2>&1 | Tee-Object -Variable allOutput
    $ansibleExitCode = $LASTEXITCODE
    $allOutputString = $allOutput | Out-String
    
    # Check for the specific Windows compatibility error
    if ($allOutputString -match "OSError.*WinError.*Incorrect function" -or 
        $allOutputString -match "os\.get_blocking" -or
        $allOutputString -match "check_blocking_io") {
        
        Write-Error "Ansible encountered a Windows compatibility issue"
        Write-Warning "This is a known issue: Ansible's os.get_blocking() doesn't work on Windows PowerShell"
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "SOLUTIONS:" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1: Use WSL (Recommended)" -ForegroundColor Cyan
        Write-Host "  1. Install WSL if needed: wsl --install" -ForegroundColor White
        Write-Host "  2. Open WSL: wsl" -ForegroundColor White
        Write-Host "  3. Navigate to project: cd /mnt/c/automation-alchemy" -ForegroundColor White
        Write-Host "  4. Run: ./scripts/deploy.sh" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2: Use Git Bash" -ForegroundColor Cyan
        Write-Host "  1. Open Git Bash" -ForegroundColor White
        Write-Host "  2. Navigate to: cd /c/automation-alchemy" -ForegroundColor White
        Write-Host "  3. Run: ./scripts/deploy.sh" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 3: Run Ansible manually from WSL/Git Bash" -ForegroundColor Cyan
        Write-Host "  cd ansible" -ForegroundColor White
        Write-Host "  ansible-playbook playbooks/site.yml -i inventory/hosts.yml" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 4: Skip Ansible (Infrastructure only)" -ForegroundColor Cyan
        Write-Host "  Use option [2] Terraform Only, then configure VMs manually via SSH" -ForegroundColor White
        Write-Host ""
        
        Pop-Location
        return $false
    }
    
    if ($ansibleExitCode -ne 0) {
        Write-Error "Ansible deployment failed (exit code: $ansibleExitCode)"
        Write-Info "Check the error output above for details"
        Pop-Location
        return $false
    }
    
    Write-Success "Ansible deployment completed"
    
    Pop-Location
    return $true
}

# Verify Deployment
function Test-Deployment {
    Write-Step "Verifying Deployment"
    
    $VmIp = Get-VmIp
    if (-not $VmIp) {
        Write-Warning "Could not retrieve VM IP from Terraform output"
        return $false
    }
    
    Write-Info "Testing application health..."
    $HealthUrl = "http://${VmIp}:8080/health"
    
    try {
        $Response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 10 -UseBasicParsing
        if ($Response.StatusCode -eq 200) {
            Write-Success "Application is healthy!"
            Write-Host "`nApplication URLs:" -ForegroundColor Cyan
            Write-Host "   Load Balancer: http://${VmIp}:8080" -ForegroundColor White
            Write-Host "   App Server:    http://${VmIp}:3000" -ForegroundColor White
            Write-Host "   Web Server 1:  http://${VmIp}:8081" -ForegroundColor White
            Write-Host "   Web Server 2:  http://${VmIp}:8082" -ForegroundColor White
            Write-Host "   Netdata:       http://${VmIp}:19999" -ForegroundColor White
            return $true
        } else {
            Write-Warning "Application returned status code: $($Response.StatusCode)"
            return $false
        }
    } catch {
        Write-Warning "Could not reach application at $HealthUrl"
        Write-Info "The application may still be starting. Wait a few minutes and check manually."
        return $false
    }
}

# Run Tests
function Invoke-Tests {
    param([string]$TestType = "all")
    
    $VmIp = Get-VmIp
    if (-not $VmIp) {
        Write-Warning "Could not retrieve VM IP. Please deploy infrastructure first."
        return $false
    }
    
    Write-Step "Running Tests: $TestType"
    
    $BaseUrl = "http://${VmIp}:8080"
    
    switch ($TestType.ToLower()) {
        "integration" {
            Write-Info "Running integration tests..."
            $env:BASE_URL = $BaseUrl
            $env:VM_IP = $VmIp
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                bash (Join-Path $TestsDir "integration-test.sh")
            } else {
                Write-Error "bash not found. Cannot run integration tests."
                return $false
            }
        }
        "performance" {
            Write-Info "Running performance tests..."
            $env:TARGET_URL = $BaseUrl
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                bash (Join-Path $TestsDir "performance-test.sh")
            } else {
                Write-Error "bash not found. Cannot run performance tests."
                return $false
            }
        }
        "security" {
            Write-Info "Running security tests..."
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                bash (Join-Path $TestsDir "security-scan.sh")
            } else {
                Write-Error "bash not found. Cannot run security tests."
                return $false
            }
        }
        "code-quality" {
            Write-Info "Running code quality tests..."
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                bash (Join-Path $TestsDir "code-quality.sh")
            } else {
                Write-Error "bash not found. Cannot run code quality tests."
                return $false
            }
        }
        "all" {
            Write-Info "Running all tests..."
            $env:BASE_URL = $BaseUrl
            $env:VM_IP = $VmIp
            $env:TARGET_URL = $BaseUrl
            
            $TestScripts = @(
                "code-quality.sh",
                "security-scan.sh",
                "integration-test.sh",
                "performance-test.sh"
            )
            
            foreach ($Script in $TestScripts) {
                $ScriptPath = Join-Path $TestsDir $Script
                if (Test-Path $ScriptPath) {
                    Write-Info "Running $Script..."
                    if (Get-Command bash -ErrorAction SilentlyContinue) {
                        bash $ScriptPath
                    }
                }
            }
        }
        default {
            Write-Error "Unknown test type: $TestType"
            return $false
        }
    }
    
    return $true
}

# Full Deployment
function Start-FullDeployment {
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "     Automation Alchemy - Full Deployment" -ForegroundColor Cyan
    Write-Host "     Terraform -> Ansible -> Deploy" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Prerequisites)) {
        return $false
    }
    
    if (-not (Test-TerraformConfig)) {
        return $false
    }
    
    if (-not (Invoke-TerraformDeploy)) {
        return $false
    }
    
    if (-not (Update-AnsibleInventory)) {
        Write-Warning "Inventory update failed, but continuing..."
    }
    
    if (-not (Invoke-AnsibleDeploy)) {
        return $false
    }
    
    Test-Deployment
    
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "           Deployment Completed Successfully!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

# Main Menu
function Show-MainMenu {
    param([switch]$ClearScreen)
    
    if ($ClearScreen) {
        Clear-Host
    } else {
        Write-Host "`n" -NoNewline
        Write-Host "================================================================" -ForegroundColor DarkGray
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "     Automation Alchemy - Deployment & Testing Menu" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Full Deployment (Terraform + Ansible)" -ForegroundColor White
    Write-Host "  [2] Terraform Only (Infrastructure)" -ForegroundColor White
    Write-Host "  [3] Ansible Only (Configuration)" -ForegroundColor White
    Write-Host "  [4] Destroy Infrastructure" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [5] Run All Tests" -ForegroundColor Green
    Write-Host "  [6] Integration Tests" -ForegroundColor Green
    Write-Host "  [7] Performance Tests" -ForegroundColor Green
    Write-Host "  [8] Security Tests" -ForegroundColor Green
    Write-Host "  [9] Code Quality Tests" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
}

# Interactive Menu Loop
function Start-InteractiveMenu {
    $firstRun = $true
    
    while ($true) {
        # Only clear screen on first run
        if ($firstRun) {
            Show-MainMenu -ClearScreen
            $firstRun = $false
        } else {
            Show-MainMenu
        }
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                try {
                    if (Start-FullDeployment) {
                        Write-Host "`nPress any key to return to menu..."
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    } else {
                        Write-Host "`n[ERROR] Deployment failed. Check errors above." -ForegroundColor Red
                        Write-Host "Press any key to return to menu..."
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                    Write-Host "Press any key to return to menu..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "2" {
                try {
                    if (Test-Prerequisites -SkipAnsible $true) {
                        if (Test-TerraformConfig) {
                            Invoke-TerraformDeploy
                        }
                    }
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                try {
                    if (Test-Prerequisites -SkipTerraform $true) {
                        if (Update-AnsibleInventory) {
                            Invoke-AnsibleDeploy
                        }
                    }
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                try {
                    Write-Warning "This will destroy all infrastructure!"
                    $confirm = Read-Host "Type 'yes' to confirm"
                    if ($confirm -eq "yes") {
                        if (Test-Prerequisites -SkipAnsible $true) {
                            Invoke-TerraformDeploy -Destroy $true
                        }
                    }
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                try {
                    Invoke-Tests -TestType "all"
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                try {
                    Invoke-Tests -TestType "integration"
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" {
                try {
                    Invoke-Tests -TestType "performance"
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" {
                try {
                    Invoke-Tests -TestType "security"
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "9" {
                try {
                    Invoke-Tests -TestType "code-quality"
                } catch {
                    Write-Host "`n[ERROR] Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
                }
                Write-Host "`nPress any key to return to menu..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                Write-Host "`nGoodbye!" -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Warning "Invalid option. Please try again."
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Start interactive menu
Start-InteractiveMenu
