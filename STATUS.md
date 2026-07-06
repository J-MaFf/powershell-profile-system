# STATUS

## What This Is

A git-based PowerShell profile management system: a core profile (`PSProfile.ps1`) with 1Password CLI mode switching, two utility modules (ActiveDirectoryUtils, PersonalUtils), and a `Setup.ps1` installer that wires the profile into `$PROFILE` on a new machine.

## Current State — 2026-07-06

Working profile system; Windows CI added to validate every change on the self-hosted runner. No known open issues.

### Components

| File | Description |
| --- | --- |
| `PSProfile.ps1` | Core profile: 1Password service/regular account switching, module auto-loading, VS Code-aware output |
| `Setup.ps1` | New-machine installer — overwrites `$PROFILE`, clones the repo (never run in CI) |
| `modules/ActiveDirectoryUtils/` | AD helper module (`Get-ADUserInfo`, `Get-ADGroupMembers`, `Test-ADConnection`) |
| `modules/PersonalUtils/` | Personal utility module (`Get-SystemInfo`, `Start-ElevatedProcess`, `Test-Port`) |
| `.github/workflows/windows-tests.yml` | Windows CI on the self-hosted runner: parse check, PSScriptAnalyzer, manifest validation + import, profile smoke test |

### Resolved Issues

| Issue | Description | PR |
| --- | --- | --- |
| [#8](https://github.com/J-MaFf/powershell-profile-system/issues/8) | Add Windows CI (validate modules + profile smoke test) on the self-hosted runner | (PR pending) |

### Open Issues

None.

## Natural Next Steps

- Add Pester tests for the module functions (currently no test suite; CI validates parse/lint/import only)
- Fix the `$IsVSCode` referenced-before-assignment warning in `PSProfile.ps1` flagged by PSScriptAnalyzer
- Add a `required_status_checks` rule for the Windows Tests workflow once it has a track record

## Prerequisites to Run

- Windows with PowerShell 7+ (`pwsh`)
- Run `Setup.ps1` to install the profile (overwrites `$PROFILE` — see README)
- Optional at runtime: 1Password CLI (`op`) and RSAT for the AD module — both guarded at call time
