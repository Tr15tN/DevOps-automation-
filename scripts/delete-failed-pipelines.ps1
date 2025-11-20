# Delete Failed GitLab Pipelines
# Usage: .\scripts\delete-failed-pipelines.ps1

param(
    [string]$GitLabUrl = "https://gitlab.com",
    [string]$ProjectId = "Tr15tN/automation-alchemy",
    [string]$Token = ""
)

if (-not $Token) {
    Write-Host "You need a GitLab Personal Access Token with 'api' scope" -ForegroundColor Yellow
    Write-Host "Get one from: $GitLabUrl/-/user_settings/personal_access_tokens" -ForegroundColor Yellow
    $Token = Read-Host "Enter your GitLab Personal Access Token"
}

$headers = @{
    "PRIVATE-TOKEN" = $Token
}

Write-Host "Fetching pipelines..." -ForegroundColor Cyan

# Get all pipelines
$pipelinesUrl = "$GitLabUrl/api/v4/projects/$([System.Web.HttpUtility]::UrlEncode($ProjectId))/pipelines?per_page=100"
$pipelines = Invoke-RestMethod -Uri $pipelinesUrl -Headers $headers -Method Get

$failedPipelines = $pipelines | Where-Object { $_.status -eq "failed" -or $_.status -eq "canceled" }

Write-Host "Found $($failedPipelines.Count) failed/canceled pipelines" -ForegroundColor Yellow

if ($failedPipelines.Count -eq 0) {
    Write-Host "No failed pipelines to delete!" -ForegroundColor Green
    exit 0
}

$confirm = Read-Host "Delete all $($failedPipelines.Count) failed pipelines? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit 0
}

$deleted = 0
foreach ($pipeline in $failedPipelines) {
    try {
        $deleteUrl = "$GitLabUrl/api/v4/projects/$([System.Web.HttpUtility]::UrlEncode($ProjectId))/pipelines/$($pipeline.id)"
        Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete | Out-Null
        Write-Host "Deleted pipeline #$($pipeline.id) ($($pipeline.status))" -ForegroundColor Green
        $deleted++
    }
    catch {
        Write-Host "Failed to delete pipeline #$($pipeline.id): $_" -ForegroundColor Red
    }
}

Write-Host "`nDeleted $deleted of $($failedPipelines.Count) pipelines" -ForegroundColor Cyan

