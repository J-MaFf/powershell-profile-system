# PowerShell Profile System Setup
param(
    [string]$InstallPath = "$env:USERPROFILE\.config\powershell-profile",
    [switch]$Force
)

$RepoUrl = 'https://github.com/J-MaFf/powershell-profile-system.git'

Write-Host 'PowerShell Profile System Setup' -ForegroundColor Cyan
Write-Host '===============================' -ForegroundColor Cyan

try {
    # Check git availability
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git is required but not found. Please install Git first.'
    }

    # Handle existing installation
    if (Test-Path $InstallPath) {
        if ($Force) {
            Write-Host "Removing existing installation..." -ForegroundColor Yellow
            Remove-Item $InstallPath -Recurse -Force
        } else {
            Write-Host "Profile already installed at $InstallPath" -ForegroundColor Orange
            Write-Host "Use -Force to reinstall" -ForegroundColor Yellow
            return
        }
    }

    # Create parent directory
    $parentDir = Split-Path $InstallPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Clone repository
    Write-Host "Cloning profile repository..." -ForegroundColor Cyan
    git clone $RepoUrl $InstallPath --quiet

    if (-not (Test-Path "$InstallPath\PSProfile.ps1")) {
        throw 'Installation failed - PSProfile.ps1 not found'
    }

    # Create profile content
    $profileContent = @"
# PowerShell Profile System - Git Based
`$ProfileRepo = '$InstallPath'

# Update profile repo (skip in VS Code for speed)  
if (-not (`$null -ne `$psEditor -or `$env:TERM_PROGRAM -eq "vscode")) {
    if (Test-Path `$ProfileRepo) {
        Push-Location `$ProfileRepo
        try {
            git fetch --quiet 2>`$null
            `$behind = git rev-list --count HEAD..origin/main 2>`$null
            if (`$behind -and `$behind -gt 0) {
                git pull origin main --quiet 2>`$null
            }
        } catch {
            # Ignore git errors
        }
        Pop-Location
    }
}

# Load the profile
if (Test-Path "`$ProfileRepo\PSProfile.ps1") {
    . "`$ProfileRepo\PSProfile.ps1"
}
"@

    # Backup existing profile
    if (Test-Path $PROFILE) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = "$PROFILE.backup.$timestamp"
        Copy-Item $PROFILE $backupPath
        Write-Host "Existing profile backed up to $backupPath" -ForegroundColor Yellow
    }

    # Create profile directory
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Write new profile
    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force

    Write-Host ''
    Write-Host 'PowerShell Profile System installed successfully!' -ForegroundColor Green
    Write-Host ''
    Write-Host 'What was installed:' -ForegroundColor Cyan
    Write-Host "  Profile repo: $InstallPath" -ForegroundColor Gray
    Write-Host "  PowerShell profile: $PROFILE" -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor Cyan
    Write-Host '  - Restart PowerShell to load the new profile' -ForegroundColor Yellow
    Write-Host '  - Test with: Get-1PasswordMode' -ForegroundColor Yellow

} catch {
    Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running with -Force to reinstall" -ForegroundColor Yellow
}