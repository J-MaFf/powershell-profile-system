# PowerShell Profile - Core Functions
# Simple, clean profile with essential functions

# Load custom modules
$ModulesDir = if ($PSCommandPath) { 
    Join-Path (Split-Path $PSCommandPath) "modules" 
} else { 
    # Fallback for when loaded via profile system
    Join-Path "$env:USERPROFILE\.config\powershell-profile" "modules" 
}

if (Test-Path $ModulesDir) {
    Get-ChildItem $ModulesDir -Directory | ForEach-Object {
        $manifestPath = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $manifestPath) {
            try {
                Import-Module $manifestPath -Force
                if (-not $IsVSCode) {
                    Write-Host "✅ Loaded module: $($_.Name)" -ForegroundColor Green
                }
            } catch {
                Write-Warning "Failed to load module $($_.Name): $($_.Exception.Message)"
            }
        }
    }
}

# Profile initialization - silent in VS Code
$IsVSCode = $null -ne $psEditor -or $env:TERM_PROGRAM -eq "vscode"

if (-not $IsVSCode) {
    Write-Host 'PowerShell profile loaded' -ForegroundColor Green
}