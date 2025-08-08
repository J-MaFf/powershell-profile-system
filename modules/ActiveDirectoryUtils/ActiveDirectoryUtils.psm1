# ActiveDirectoryUtils Module
# Active Directory helper functions and utilities

function Get-ADUserInfo {
    <#
    .SYNOPSIS
        Gets detailed information about an Active Directory user
    .PARAMETER Identity
        The user identity (SamAccountName, UserPrincipalName, or DistinguishedName)
    .EXAMPLE
        Get-ADUserInfo -Identity "jmaffiola"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    try {
        # Check if AD module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            throw "ActiveDirectory module not available. Install RSAT tools."
        }

        Import-Module ActiveDirectory -ErrorAction Stop
        
        $user = Get-ADUser -Identity $Identity -Properties * -ErrorAction Stop
        
        return [PSCustomObject]@{
            Name = $user.Name
            SamAccountName = $user.SamAccountName
            UserPrincipalName = $user.UserPrincipalName
            Department = $user.Department
            Title = $user.Title
            Manager = $user.Manager
            LastLogon = $user.LastLogonDate
            Enabled = $user.Enabled
            PasswordExpired = $user.PasswordExpired
            DistinguishedName = $user.DistinguishedName
        }
    }
    catch {
        Write-Error "Failed to get user info for '$Identity': $($_.Exception.Message)"
    }
}

function Get-ADGroupMembers {
    <#
    .SYNOPSIS
        Gets members of an Active Directory group with detailed information
    .PARAMETER GroupName
        The name of the AD group
    .EXAMPLE
        Get-ADGroupMembers -GroupName "IT Administrators"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )

    try {
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            throw "ActiveDirectory module not available. Install RSAT tools."
        }

        Import-Module ActiveDirectory -ErrorAction Stop
        
        $members = Get-ADGroupMember -Identity $GroupName -ErrorAction Stop
        
        return $members | ForEach-Object {
            $user = Get-ADUser -Identity $_.SamAccountName -Properties Department, Title -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                Name = $_.Name
                SamAccountName = $_.SamAccountName
                ObjectClass = $_.objectClass
                Department = $user.Department
                Title = $user.Title
            }
        }
    }
    catch {
        Write-Error "Failed to get group members for '$GroupName': $($_.Exception.Message)"
    }
}

function Test-ADConnection {
    <#
    .SYNOPSIS
        Tests connection to Active Directory
    .EXAMPLE
        Test-ADConnection
    #>
    [CmdletBinding()]
    param()

    try {
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Warning "ActiveDirectory module not available"
            return $false
        }

        Import-Module ActiveDirectory -ErrorAction Stop
        
        # Try to get domain information
        $domain = Get-ADDomain -ErrorAction Stop
        Write-Host "✅ Connected to domain: $($domain.DNSRoot)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "❌ AD Connection failed: $($_.Exception.Message)"
        return $false
    }
}