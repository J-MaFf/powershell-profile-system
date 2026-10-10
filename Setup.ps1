# PowerShell Profile System Setup
#
# Installs the profile system into -InstallPath and points $PROFILE at it.
#
# By default it installs the newest GitHub release: it downloads the release's updater
# (tools/Update-FromGitHubRelease.ps1, from J-MaFf/release-kit), checks it against the SHA-256 and
# size in the release's release-manifest.json before running it, and lets it install every file,
# each checked the same way. No git needed. From then on Update-ProfileSystem.ps1 keeps it current,
# at most once a day.
#
# -Git clones the repository instead, for a machine you develop on. A git clone is never updated
# from releases: update it with git pull.
#
# Works in Windows PowerShell 5.1 and PowerShell 7.
param(
    [string]$InstallPath = "$env:USERPROFILE\.config\powershell-profile",
    [switch]$Force,
    [switch]$Git
)

$Repository = 'J-MaFf/powershell-profile-system'
$RepoUrl = "https://github.com/$Repository.git"

<#
.SYNOPSIS
    Downloads the latest release's updater, checks it against the release manifest, and returns its
    path in a new temporary folder.
#>
function Get-VerifiedUpdater {
    param ([Parameter(Mandatory = $true)][string]$Repository)

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    }
    $headers = @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'powershell-profile-system-setup' }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers $headers -TimeoutSec 30
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('profile-setup-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $temp

    $manifestAsset = @($release.assets | Where-Object { $_.name -eq 'release-manifest.json' }) | Select-Object -First 1
    $updaterAsset = @($release.assets | Where-Object { $_.name -eq 'Update-FromGitHubRelease.ps1' }) | Select-Object -First 1
    if (-not $manifestAsset -or -not $updaterAsset) {
        throw "Release $($release.tag_name) of $Repository has no release-manifest.json or Update-FromGitHubRelease.ps1."
    }
    $manifestPath = Join-Path $temp 'release-manifest.json'
    $updaterPath = Join-Path $temp 'Update-FromGitHubRelease.ps1'
    Invoke-WebRequest -Uri $manifestAsset.browser_download_url -Headers @{ 'User-Agent' = $headers['User-Agent'] } -OutFile $manifestPath -UseBasicParsing -TimeoutSec 30
    Invoke-WebRequest -Uri $updaterAsset.browser_download_url -Headers @{ 'User-Agent' = $headers['User-Agent'] } -OutFile $updaterPath -UseBasicParsing -TimeoutSec 30

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schema -ne 1 -or $manifest.repository -ne $Repository -or $manifest.tag -cne $release.tag_name) {
        throw "release-manifest.json of $($release.tag_name) is not this release's (schema '$($manifest.schema)', repository '$($manifest.repository)', tag '$($manifest.tag)')."
    }
    $entry = $manifest.files.'Update-FromGitHubRelease.ps1'
    $actual = (Get-FileHash -LiteralPath $updaterPath -Algorithm SHA256).Hash
    if (-not $entry -or $actual -ne $entry.sha256 -or (Get-Item -LiteralPath $updaterPath).Length -ne [long]$entry.size) {
        throw "The downloaded Update-FromGitHubRelease.ps1 does not match release-manifest.json of $($release.tag_name); not running it."
    }
    Write-Host "Updater of $($release.tag_name) checked against its manifest (SHA-256 $($actual.ToLowerInvariant()))." -ForegroundColor Gray
    return [pscustomobject]@{ Path = $updaterPath; Folder = $temp }
}

Write-Host 'PowerShell Profile System Setup' -ForegroundColor Cyan
Write-Host '===============================' -ForegroundColor Cyan

$updater = $null
try {
    if ((Test-Path $InstallPath) -and -not $Force) {
        Write-Host "Profile already installed at $InstallPath" -ForegroundColor Yellow
        Write-Host "Use -Force to reinstall" -ForegroundColor Yellow
        return
    }

    # Fetch and check the updater before anything is removed, so a failed download leaves the
    # current installation in place.
    if (-not $Git) {
        Write-Host "Installing the latest release of $Repository..." -ForegroundColor Cyan
        $updater = Get-VerifiedUpdater -Repository $Repository
    }

    if (Test-Path $InstallPath) {
        Write-Host "Removing existing installation..." -ForegroundColor Yellow
        Remove-Item $InstallPath -Recurse -Force
    }

    # Create parent directory
    $parentDir = Split-Path $InstallPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($Git) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw 'Git is required for -Git but not found. Install Git, or run Setup.ps1 without -Git.'
        }
        Write-Host "Cloning profile repository..." -ForegroundColor Cyan
        git clone $RepoUrl $InstallPath --quiet
    } else {
        . $updater.Path
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        $result = Update-FromGitHubRelease -Repository $Repository -InstallPath $InstallPath -TimeoutSec 60
        if ($result.Status -ne 'Updated') { throw "Install from $($result.Tag) failed: $($result.Message)" }
        Write-Host "Installed $($result.Tag): $($result.Updated.Count) files." -ForegroundColor Green
    }

    if (-not (Test-Path "$InstallPath\PSProfile.ps1")) {
        throw 'Installation failed - PSProfile.ps1 not found'
    }

    # Create profile content. The update logic lives in Update-ProfileSystem.ps1, which every
    # release ships, so this stub never needs to change.
    $profileContent = @"
# PowerShell Profile System
`$ProfileRepo = '$InstallPath'

# Update from the newest release at most once a day (skipped in VS Code and in a git clone).
if (Test-Path "`$ProfileRepo\Update-ProfileSystem.ps1") {
    & "`$ProfileRepo\Update-ProfileSystem.ps1" -InstallPath `$ProfileRepo
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

    $installKind = if ($Git) { '(git clone)' } else { '(latest release)' }
    Write-Host ''
    Write-Host 'PowerShell Profile System installed successfully!' -ForegroundColor Green
    Write-Host ''
    Write-Host 'What was installed:' -ForegroundColor Cyan
    Write-Host "  Profile system: $InstallPath $installKind" -ForegroundColor Gray
    Write-Host "  PowerShell profile: $PROFILE" -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor Cyan
    Write-Host '  - Restart PowerShell to load the new profile' -ForegroundColor Yellow
    Write-Host '  - Test with: Get-1PasswordMode' -ForegroundColor Yellow

} catch {
    Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running with -Force to reinstall" -ForegroundColor Yellow
} finally {
    if ($updater) { Remove-Item -LiteralPath $updater.Folder -Recurse -Force -ErrorAction SilentlyContinue }
}
