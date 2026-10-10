# STATUS

## What This Is

A PowerShell profile management system: a core profile (`PSProfile.ps1`) with 1Password CLI mode switching, two utility modules (ActiveDirectoryUtils, PersonalUtils), and a `Setup.ps1` installer that wires the profile into `$PROFILE` on a new machine. Installs update themselves from tagged GitHub releases, checked file by file against a SHA-256 manifest, through J-MaFf/release-kit's shared updater.

## Current State — 2026-10-10

Working profile system; Windows CI validates every change on the self-hosted runner. The move from `git pull` on every start to release-based updates is in review ([#13](https://github.com/J-MaFf/powershell-profile-system/issues/13)); there is no release yet, so a release-based install cannot happen until the first tag (`v1.0.0`) once it merges. Existing git-based installs keep pulling `main` until they are reinstalled with `Setup.ps1 -Force`.

### Components

| File | Description |
| --- | --- |
| `PSProfile.ps1` | Core profile: 1Password service/regular account switching, module auto-loading, VS Code-aware output |
| `Update-ProfileSystem.ps1` | Run by `$PROFILE` before `PSProfile.ps1`: at most once a day (not in VS Code, not in a git clone, not with `PSPROFILE_NO_UPDATE`) updates the install from the newest release; never stops the profile loading; `-Force` checks now |
| `tools/Update-FromGitHubRelease.ps1` | The updater, copied unchanged from [J-MaFf/release-kit](https://github.com/J-MaFf/release-kit): manifest, hash compare, checked downloads, swap with rollback |
| `Setup.ps1` | New-machine installer: installs the latest release (default; checks the updater against the manifest first) or clones with `-Git`, and overwrites `$PROFILE` (never run in CI) |
| `modules/ActiveDirectoryUtils/` | AD helper module (`Get-ADUserInfo`, `Get-ADGroupMembers`, `Test-ADConnection`) |
| `modules/PersonalUtils/` | Personal utility module (`Get-SystemInfo`, `Start-ElevatedProcess`, `Test-Port`) |
| `tests/Update-ProfileSystem.Tests.ps1` | Pester tests of the update check with a stand-in updater (no network) |
| `.github/workflows/release.yml` | On a `vX.Y.Z` tag, publishes the install's files, `release-manifest.json` and attestations through `J-MaFf/release-kit/.github/workflows/release.yml@v1` |
| `.github/workflows/windows-tests.yml` | CI: a `lint` job calling the shared reusable `ps-lint.yml` in [J-MaFf/.github](https://github.com/J-MaFf/.github), a `pester` job on ubuntu, and a local `validate` job on the self-hosted runner (manifest validation + import, profile smoke test) |

### Resolved Issues

| Issue | Description | PR |
| --- | --- | --- |
| [#8](https://github.com/J-MaFf/powershell-profile-system/issues/8) | Add Windows CI (validate modules + profile smoke test) on the self-hosted runner | [#9](https://github.com/J-MaFf/powershell-profile-system/pull/9) |
| [#10](https://github.com/J-MaFf/powershell-profile-system/issues/10) | Adopt shared reusable workflows (`claude.yml`, `ps-lint.yml`) from J-MaFf/.github | [#11](https://github.com/J-MaFf/powershell-profile-system/pull/11) |

### Open Issues

| Issue | Description |
| --- | --- |
| [#13](https://github.com/J-MaFf/powershell-profile-system/issues/13) | Update from attested releases instead of git pull on every start |

## Natural Next Steps

- After #13 merges (and J-MaFf/release-kit has released `v1.1.0` with the updater): move the `[Unreleased]` entries under `[1.0.0]`, tag `v1.0.0`, then reinstall each machine with `Setup.ps1 -Force` to move it off `git pull`.
- Add Pester tests for the module functions (CI tests only the update check today)
- Fix the `$IsVSCode` referenced-before-assignment warning in `PSProfile.ps1` flagged by PSScriptAnalyzer
- Add a `required_status_checks` rule for the Windows Tests workflow once it has a track record

## Prerequisites to Run

- Windows with PowerShell 7+ (`pwsh`) or Windows PowerShell 5.1
- Run `Setup.ps1` to install the profile (overwrites `$PROFILE` — see README)
- Optional at runtime: 1Password CLI (`op`) and RSAT for the AD module — both guarded at call time
