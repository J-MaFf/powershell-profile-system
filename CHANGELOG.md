# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added Windows CI workflow (`windows-tests.yml`) on the self-hosted runner: parse check for all `.ps1`/`.psm1` files, PSScriptAnalyzer (fails on Error severity only), `Test-ModuleManifest` + `Import-Module` for both module manifests, and a `PSProfile.ps1` dot-source smoke test in a fresh `pwsh -NoProfile` process ([#9](https://github.com/J-MaFf/powershell-profile-system/pull/9))
- Added `STATUS.md` and `CHANGELOG.md` project documentation ([#9](https://github.com/J-MaFf/powershell-profile-system/pull/9))
