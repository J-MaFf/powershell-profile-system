# Tests for Update-ProfileSystem.ps1 (Pester 5 or 6). Each test gets its own install folder with a
# stand-in tools/Update-FromGitHubRelease.ps1 that records its calls and returns the result in
# $global:FakeUpdateResult, so no test reaches GitHub.

BeforeAll {
    $script:Loader = Join-Path (Split-Path -Parent $PSScriptRoot) 'Update-ProfileSystem.ps1'
    . $script:Loader

    function New-TestInstall {
        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $path 'tools') -Force
        Set-Content -LiteralPath (Join-Path $path 'tools/Update-FromGitHubRelease.ps1') -Value @'
function Update-FromGitHubRelease {
    param ($Repository, $InstallPath, $TimeoutSec)
    $global:FakeUpdateCalls += , ([pscustomobject]@{ Repository = $Repository; InstallPath = $InstallPath; TimeoutSec = $TimeoutSec })
    return $global:FakeUpdateResult
}
'@
        return $path
    }

    function Invoke-Loader {
        param ([string]$InstallPath, [switch]$Force)
        $global:FakeUpdateCalls = @()
        Invoke-ProfileSystemUpdate -InstallPath $InstallPath -Repository 'J-MaFf/powershell-profile-system' -IntervalHours 24 -TimeoutSec 5 -Force:$Force 6>&1 | Out-String
    }

    function Set-LastCheck ([string]$InstallPath, [datetime]$WhenUtc) {
        $state = @{ lastCheckUtc = $WhenUtc.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture); status = 'UpToDate'; tag = 'v1.0.0' }
        Set-Content -LiteralPath (Join-Path $InstallPath '.update-state.json') -Value ($state | ConvertTo-Json)
    }
}

Describe 'Update-ProfileSystem.ps1' {
    BeforeEach {
        $script:Install = New-TestInstall
        $global:FakeUpdateResult = [pscustomobject]@{ Status = 'UpToDate'; Tag = 'v1.0.0'; Updated = @(); Message = 'Up to date with v1.0.0.' }
        $script:SavedEnv = @{ PSPROFILE_NO_UPDATE = $env:PSPROFILE_NO_UPDATE; TERM_PROGRAM = $env:TERM_PROGRAM }
        $env:PSPROFILE_NO_UPDATE = $null
        $env:TERM_PROGRAM = $null
    }

    AfterEach {
        $env:PSPROFILE_NO_UPDATE = $script:SavedEnv.PSPROFILE_NO_UPDATE
        $env:TERM_PROGRAM = $script:SavedEnv.TERM_PROGRAM
    }

    It 'Checks on the first run, passes its settings on, records the check, and prints nothing when up to date' {
        $text = Invoke-Loader -InstallPath $script:Install

        $global:FakeUpdateCalls.Count | Should -Be 1
        $global:FakeUpdateCalls[0].Repository | Should -Be 'J-MaFf/powershell-profile-system'
        $global:FakeUpdateCalls[0].InstallPath | Should -Be $script:Install
        $global:FakeUpdateCalls[0].TimeoutSec | Should -Be 5
        $text.Trim() | Should -BeNullOrEmpty
        $state = Get-Content -Raw (Join-Path $script:Install '.update-state.json') | ConvertFrom-Json
        $state.status | Should -Be 'UpToDate'
        (Get-ProfileLastUpdateCheck -InstallPath $script:Install) | Should -BeGreaterThan ([datetime]::UtcNow.AddMinutes(-5))
    }

    It 'Does not check again within the interval' {
        Set-LastCheck $script:Install ([datetime]::UtcNow.AddHours(-2))

        $null = Invoke-Loader -InstallPath $script:Install

        $global:FakeUpdateCalls.Count | Should -Be 0
    }

    It 'Checks again once the interval has passed' {
        Set-LastCheck $script:Install ([datetime]::UtcNow.AddHours(-25))

        $null = Invoke-Loader -InstallPath $script:Install

        $global:FakeUpdateCalls.Count | Should -Be 1
    }

    It 'Checks when the recorded time is in the future (a clock that jumped)' {
        Set-LastCheck $script:Install ([datetime]::UtcNow.AddDays(3))

        $null = Invoke-Loader -InstallPath $script:Install

        $global:FakeUpdateCalls.Count | Should -Be 1
    }

    It 'Checks when the state file is unreadable' {
        Set-Content -LiteralPath (Join-Path $script:Install '.update-state.json') -Value 'not json'

        $null = Invoke-Loader -InstallPath $script:Install

        $global:FakeUpdateCalls.Count | Should -Be 1
    }

    It 'With -Force, checks within the interval and says the result' {
        Set-LastCheck $script:Install ([datetime]::UtcNow.AddHours(-1))

        $text = Invoke-Loader -InstallPath $script:Install -Force

        $global:FakeUpdateCalls.Count | Should -Be 1
        $text | Should -Match 'Up to date with v1\.0\.0'
    }

    It 'Says which files it updated' {
        $global:FakeUpdateResult = [pscustomobject]@{ Status = 'Updated'; Tag = 'v1.1.0'; Updated = @('PSProfile.ps1', 'modules/PersonalUtils/PersonalUtils.psm1'); Message = 'Updated 2 file(s) to v1.1.0.' }

        $text = Invoke-Loader -InstallPath $script:Install

        $text | Should -Match 'Profile system updated to v1\.1\.0: PSProfile\.ps1, modules/PersonalUtils/PersonalUtils\.psm1'
    }

    It 'Prints one line on a failed check, records it, and does not throw' {
        $global:FakeUpdateResult = [pscustomobject]@{ Status = 'Failed'; Tag = $null; Updated = @(); Message = 'No such host is known.' }

        { $script:text = Invoke-Loader -InstallPath $script:Install } | Should -Not -Throw

        $script:text | Should -Match 'update check failed \(No such host is known\.\)\. Next try in 24 h'
        (Get-Content -Raw (Join-Path $script:Install '.update-state.json') | ConvertFrom-Json).status | Should -Be 'Failed'
    }

    It 'Does not throw when the updater itself throws' {
        Set-Content -LiteralPath (Join-Path $script:Install 'tools/Update-FromGitHubRelease.ps1') -Value 'function Update-FromGitHubRelease { throw "boom" }'

        { $script:text = Invoke-Loader -InstallPath $script:Install } | Should -Not -Throw

        $script:text | Should -Match 'update check failed \(boom\)'
    }

    It 'Says to reinstall when the updater is missing' {
        Remove-Item -LiteralPath (Join-Path $script:Install 'tools/Update-FromGitHubRelease.ps1')

        $text = Invoke-Loader -InstallPath $script:Install

        $text | Should -Match 'no updater at .*Setup\.ps1 -Force'
    }

    It 'Skips <Case> silently, and says why with -Force when it still skips' -ForEach @(
        @{ Case = 'a git clone'; Arrange = { param ($p) $null = New-Item -ItemType Directory -Path (Join-Path $p '.git') }; ForceSkips = $true; Why = 'git clone' }
        @{ Case = 'PSPROFILE_NO_UPDATE'; Arrange = { param ($p) $env:PSPROFILE_NO_UPDATE = '1' }; ForceSkips = $true; Why = 'PSPROFILE_NO_UPDATE' }
        @{ Case = 'VS Code'; Arrange = { param ($p) $env:TERM_PROGRAM = 'vscode' }; ForceSkips = $false; Why = '' }
    ) {
        & $Arrange $script:Install

        $text = Invoke-Loader -InstallPath $script:Install
        $global:FakeUpdateCalls.Count | Should -Be 0
        $text.Trim() | Should -BeNullOrEmpty

        $forced = Invoke-Loader -InstallPath $script:Install -Force
        if ($ForceSkips) {
            $global:FakeUpdateCalls.Count | Should -Be 0
            $forced | Should -Match "not updating \(.*$Why"
        }
        else {
            $global:FakeUpdateCalls.Count | Should -Be 1
        }
    }

    It 'Runs the update when run as a script, and only defines functions when dot-sourced' {
        $global:FakeUpdateCalls = @()
        . $script:Loader -InstallPath $script:Install
        $global:FakeUpdateCalls.Count | Should -Be 0

        & $script:Loader -InstallPath $script:Install 6>$null
        $global:FakeUpdateCalls.Count | Should -Be 1
    }
}
