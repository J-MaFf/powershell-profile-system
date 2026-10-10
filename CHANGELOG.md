# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- Installs now update from tagged GitHub releases instead of running `git fetch` + `git pull origin main` on every shell start ([#13](https://github.com/J-MaFf/powershell-profile-system/issues/13)): `$PROFILE` runs the new `Update-ProfileSystem.ps1`, which at most once a day (never in VS Code, never in a git clone, off with `PSPROFILE_NO_UPDATE`) runs J-MaFf/release-kit's `Update-FromGitHubRelease` to replace only the files whose SHA-256 differs from the release manifest, each checked before any is replaced. A failed check keeps the installed files and prints one line.
- `Setup.ps1` installs the latest release by default, with no git needed: it checks the release's updater against the manifest before running it, and with `-Force` it downloads and checks before removing the old installation. `-Git` keeps the clone-based install for a development machine ([#13](https://github.com/J-MaFf/powershell-profile-system/issues/13)).
- The README one-liner installs from `releases/latest/download/Setup.ps1` (saved to a file first, since GitHub serves release files as binary) instead of raw `main` ([#13](https://github.com/J-MaFf/powershell-profile-system/issues/13)).

- `claude.yml` and the Windows lint steps in `windows-tests.yml` now call the shared reusable workflows in [J-MaFf/.github](https://github.com/J-MaFf/.github) instead of carrying their own copies; `windows-tests.yml` now has a `lint` job (shared ps-lint caller) plus a local `validate` job keeping the module-manifest validation and `PSProfile.ps1` smoke test ([#11](https://github.com/J-MaFf/powershell-profile-system/pull/11))

### Added

- Added Windows CI workflow (`windows-tests.yml`) on the self-hosted runner: parse check for all `.ps1`/`.psm1` files, PSScriptAnalyzer (fails on Error severity only), `Test-ModuleManifest` + `Import-Module` for both module manifests, and a `PSProfile.ps1` dot-source smoke test in a fresh `pwsh -NoProfile` process ([#9](https://github.com/J-MaFf/powershell-profile-system/pull/9))
- Added `STATUS.md` and `CHANGELOG.md` project documentation ([#9](https://github.com/J-MaFf/powershell-profile-system/pull/9))
