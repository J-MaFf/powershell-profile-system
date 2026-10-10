<#
.SYNOPSIS
    Updates the profile system from its newest GitHub release, at most once a day.
.DESCRIPTION
    $PROFILE (written by Setup.ps1) runs this before it loads PSProfile.ps1. It runs
    tools/Update-FromGitHubRelease.ps1 (from J-MaFf/release-kit), which compares every file of the
    release with the one here by SHA-256 and replaces only those that differ, each checked before
    any is replaced.

    It does nothing, and says nothing:
      - when the last check was less than -IntervalHours ago (the time is kept in
        .update-state.json in the install folder);
      - in VS Code, to keep its terminal fast;
      - when PSPROFILE_NO_UPDATE is set;
      - in a git clone (Setup.ps1 -Git): update that with git pull.

    A failed check (offline, GitHub down) never stops the profile from loading: it keeps the files
    there are, prints one line, and tries again after the interval. Run it with -Force to check now.
    Works in Windows PowerShell 5.1 and PowerShell 7.
.PARAMETER InstallPath
    The install folder. Default: this script's folder.
.PARAMETER Repository
    The GitHub repository the releases come from.
.PARAMETER IntervalHours
    How long after a check the next one is due.
.PARAMETER TimeoutSec
    Time limit of each web request, so a slow network delays the shell only so much.
.PARAMETER Force
    Check now, even within the interval or in VS Code, and say what happened.
.EXAMPLE
    & "$env:USERPROFILE\.config\powershell-profile\Update-ProfileSystem.ps1" -Force
#>
[CmdletBinding()]
param (
    [string]$InstallPath = $PSScriptRoot,

    [string]$Repository = 'J-MaFf/powershell-profile-system',

    [double]$IntervalHours = 24,

    [int]$TimeoutSec = 5,

    [switch]$Force
)

<#
.SYNOPSIS
    Why this run should not check for an update, or $null when it should.
#>
function Get-ProfileUpdateSkipReason {
    param (
        [Parameter(Mandatory = $true)][string]$InstallPath,
        [Parameter(Mandatory = $true)][double]$IntervalHours,
        [Parameter(Mandatory = $true)][datetime]$NowUtc,
        [switch]$Force,
        [switch]$InVSCode
    )

    if ($env:PSPROFILE_NO_UPDATE) { return 'PSPROFILE_NO_UPDATE is set' }
    if (Test-Path -LiteralPath (Join-Path $InstallPath '.git')) { return 'it is a git clone; update it with git pull' }
    if ($Force) { return $null }
    if ($InVSCode) { return 'in VS Code' }
    $last = Get-ProfileLastUpdateCheck -InstallPath $InstallPath
    if ($last -and ($NowUtc - $last).TotalHours -lt $IntervalHours -and $last -le $NowUtc) {
        return 'checked less than the interval ago'
    }
    return $null
}

<#
.SYNOPSIS
    The UTC time of the last check, from .update-state.json, or $null.
#>
function Get-ProfileLastUpdateCheck {
    param ([Parameter(Mandatory = $true)][string]$InstallPath)

    $path = Join-Path $InstallPath '.update-state.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $state = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        return [datetime]::Parse([string]$state.lastCheckUtc, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal)
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Records a check in .update-state.json.
#>
function Save-ProfileUpdateCheck {
    param ([Parameter(Mandatory = $true)][string]$InstallPath, [Parameter(Mandatory = $true)][datetime]$NowUtc, $Result)

    $state = [ordered]@{
        lastCheckUtc = $NowUtc.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
        status       = [string]$Result.Status
        tag          = [string]$Result.Tag
    }
    [System.IO.File]::WriteAllText((Join-Path $InstallPath '.update-state.json'), ($state | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
}

<#
.SYNOPSIS
    Checks for an update unless there is a reason not to, and prints one line when something
    happened. Never throws.
#>
function Invoke-ProfileSystemUpdate {
    param (
        [Parameter(Mandatory = $true)][string]$InstallPath,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][double]$IntervalHours,
        [Parameter(Mandatory = $true)][int]$TimeoutSec,
        [switch]$Force
    )

    try {
        $now = [datetime]::UtcNow
        $inVSCode = ($null -ne (Get-Variable -Name psEditor -ValueOnly -ErrorAction SilentlyContinue)) -or $env:TERM_PROGRAM -eq 'vscode'
        $reason = Get-ProfileUpdateSkipReason -InstallPath $InstallPath -IntervalHours $IntervalHours -NowUtc $now -Force:$Force -InVSCode:$inVSCode
        if ($reason) {
            if ($Force) { Write-Host "Profile system: not updating ($reason)." -ForegroundColor Yellow }
            return
        }

        $updater = Join-Path $InstallPath 'tools/Update-FromGitHubRelease.ps1'
        if (-not (Test-Path -LiteralPath $updater)) {
            Write-Host "Profile system: no updater at $updater; run Setup.ps1 -Force to reinstall." -ForegroundColor DarkYellow
            return
        }
        . $updater
        $result = Update-FromGitHubRelease -Repository $Repository -InstallPath $InstallPath -TimeoutSec $TimeoutSec -WarningAction SilentlyContinue
        Save-ProfileUpdateCheck -InstallPath $InstallPath -NowUtc $now -Result $result

        switch ($result.Status) {
            'Updated' { Write-Host "Profile system updated to $($result.Tag): $($result.Updated -join ', ')" -ForegroundColor Green }
            'Failed' { Write-Host "Profile system: update check failed ($($result.Message)). Next try in $IntervalHours h, or run Update-ProfileSystem.ps1 -Force." -ForegroundColor DarkYellow }
            default { if ($Force) { Write-Host "Profile system: $($result.Message)" -ForegroundColor Green } }
        }
    }
    catch {
        Write-Host "Profile system: update check failed ($($_.Exception.Message))." -ForegroundColor DarkYellow
    }
}

# Dot-sourced (as the tests do), it only defines the functions.
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ProfileSystemUpdate -InstallPath $InstallPath -Repository $Repository -IntervalHours $IntervalHours -TimeoutSec $TimeoutSec -Force:$Force
}
