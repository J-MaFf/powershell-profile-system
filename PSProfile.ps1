# PowerShell Profile - Core Functions
# Simple, clean profile with essential functions

function Use-ServiceAccount {
    <#
    .SYNOPSIS
        Configures environment to use 1Password service account token for automation
    .EXAMPLE
        Use-ServiceAccount
    #>
    param([string]$Token)

    try {
        if (-not (Get-Command op -ErrorAction SilentlyContinue)) {
            Write-Host '❌ 1Password CLI not available' -ForegroundColor Red
            return
        }

        if ([string]::IsNullOrWhiteSpace($Token)) {
            Write-Host '🔍 Retrieving service account token from 1Password...' -ForegroundColor Cyan
            
            # Clear any existing service account token to access 1Password
            $tempToken = $env:OP_SERVICE_ACCOUNT_TOKEN
            if ($tempToken) {
                Remove-Item env:OP_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
            }

            try {
                $Token = op read 'op://Home Server/nudybdh43mxz6f4z4bhmllhxau/credential' 2>$null
                
                if ([string]::IsNullOrWhiteSpace($Token)) {
                    throw 'Service account token not found in 1Password'
                }
                
                Write-Host '✅ Service account token retrieved' -ForegroundColor Green
            } catch {
                if ($tempToken) {
                    $env:OP_SERVICE_ACCOUNT_TOKEN = $tempToken
                }
                throw "Failed to retrieve token: $($_.Exception.Message)"
            }
        }

        $env:OP_SERVICE_ACCOUNT_TOKEN = $Token.Trim()
        
        # Test the token
        $null = op account list --format json 2>$null
        Write-Host '✅ Service account configured successfully' -ForegroundColor Green
        Write-Host '🤖 Now in service account mode' -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Failed to configure service account: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item env:OP_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
    }
}

function Use-RegularAccount {
    <#
    .SYNOPSIS
        Switches back to regular 1Password user authentication
    .EXAMPLE
        Use-RegularAccount -Verify
    #>
    param([switch]$Verify)

    try {
        if ($env:OP_SERVICE_ACCOUNT_TOKEN) {
            Write-Host '🔄 Switching to regular user mode...' -ForegroundColor Yellow
            Remove-Item env:OP_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
        } else {
            Write-Host '✅ Already in regular user mode' -ForegroundColor Green
        }

        if ($Verify) {
            Write-Host '🔍 Verifying regular user authentication...' -ForegroundColor Cyan
            $accounts = op account list --format json 2>$null | ConvertFrom-Json
            
            if ($accounts) {
                Write-Host '✅ Regular user authentication verified' -ForegroundColor Green
                Write-Host "📱 Available accounts: $($accounts.Count)" -ForegroundColor Cyan
            } else {
                Write-Host '⚠️ No accounts found. Try: op signin' -ForegroundColor Orange
            }
        }

        Write-Host '🎯 Regular user mode configured' -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to configure regular mode: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-1PasswordMode {
    <#
    .SYNOPSIS
        Shows current 1Password CLI authentication mode
    .EXAMPLE
        Get-1PasswordMode
    #>
    Write-Host '🔍 1Password CLI Status' -ForegroundColor Cyan
    Write-Host '=====================' -ForegroundColor Cyan

    if (-not (Get-Command op -ErrorAction SilentlyContinue)) {
        Write-Host '❌ 1Password CLI not available' -ForegroundColor Red
        return
    }

    if ($env:OP_SERVICE_ACCOUNT_TOKEN) {
        Write-Host '🤖 Mode: Service Account' -ForegroundColor Yellow
        Write-Host '💡 Switch to regular: Use-RegularAccount' -ForegroundColor Cyan
    } else {
        Write-Host '👤 Mode: Regular User' -ForegroundColor Green
        Write-Host '💡 Switch to service: Use-ServiceAccount' -ForegroundColor Cyan
    }
}

# Profile initialization - silent in VS Code
$IsVSCode = $null -ne $psEditor -or $env:TERM_PROGRAM -eq "vscode"

if (-not $IsVSCode) {
    Write-Host '✅ PowerShell profile loaded' -ForegroundColor Green
}