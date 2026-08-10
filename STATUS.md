# STATUS

## What This Is

A git-based PowerShell profile management system: a core profile (`PSProfile.ps1`) with 1Password CLI mode switching, two utility modules (ActiveDirectoryUtils, PersonalUtils), and a `Setup.ps1` installer that wires the profile into `$PROFILE` on a new machine.

## Current State — 2026-08-10

Working profile system; Windows CI validates every change on the self-hosted runner. The lint steps (parse check + PSScriptAnalyzer) now come from the shared reusable `ps-lint.yml` in [J-MaFf/.github](https://github.com/J-MaFf/.github), with the repo-specific validation kept in a local job. No known open issues.

### Components

| File | Description |
| --- | --- |
| `PSProfile.ps1` | Core profile: 1Password service/regular account switching, module auto-loading, VS Code-aware output |
| `Setup.ps1` | New-machine installer — overwrites `$PROFILE`, clones the repo (never run in CI) |
| `modules/ActiveDirectoryUtils/` | AD helper module (`Get-ADUserInfo`, `Get-ADGroupMembers`, `Test-ADConnection`) |
| `modules/PersonalUtils/` | Personal utility module (`Get-SystemInfo`, `Start-ElevatedProcess`, `Test-Port`) |
| `.github/workflows/windows-tests.yml` | Windows CI on the self-hosted runner: a `lint` job calling the shared reusable `ps-lint.yml` in [J-MaFf/.github](https://github.com/J-MaFf/.github) (parse check + PSScriptAnalyzer), plus a local `validate` job (manifest validation + import, profile smoke test) |

### Resolved Issues

| Issue | Description | PR |
| --- | --- | --- |
| [#8](https://github.com/J-MaFf/powershell-profile-system/issues/8) | Add Windows CI (validate modules + profile smoke test) on the self-hosted runner | [#9](https://github.com/J-MaFf/powershell-profile-system/pull/9) |
| [#10](https://github.com/J-MaFf/powershell-profile-system/issues/10) | Adopt shared reusable workflows (`claude.yml`, `ps-lint.yml`) from J-MaFf/.github | [#11](https://github.com/J-MaFf/powershell-profile-system/pull/11) |

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
