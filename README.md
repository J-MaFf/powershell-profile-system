# PowerShell Profile System

A simple PowerShell profile management system with 1Password CLI integration and VS Code extension compatibility, kept up to date from checked GitHub releases.

## ✨ Features

- **🚀 Release-based updates**: Installs pick up new tagged releases at most once a day; every file is checked against the release's SHA-256 manifest before it replaces anything ([J-MaFf/release-kit](https://github.com/J-MaFf/release-kit))
- **⚡ Fast startup**: Local files, minimal overhead, instant loading
- **🎨 VS Code compatible**: Silent loading in PowerShell extension without interference
- **🔐 1Password integration**: Seamless switching between service account and user modes
- **📱 Offline capable**: Works without internet after initial setup
- **🛠️ Simple architecture**: Clean, maintainable code without complex abstractions
- **🧠 Memory MCP integration**: Workspace-local knowledge graph storage for AI assistance ([setup guide](MEMORY_MCP_SERVER_SETUP.md))

## 🚀 Quick Start

### New Computer Setup

**Method 1: One-liner (Fastest)**

```powershell
$s = Join-Path $env:TEMP 'profile-setup.ps1'; iwr "https://github.com/J-MaFf/powershell-profile-system/releases/latest/download/Setup.ps1" -OutFile $s -UseBasicParsing; & $s; Remove-Item $s
```

(GitHub serves release files as binary, so `iex (iwr ...).Content` would hand `iex` bytes, not text: the one-liner saves the file and runs it.)

**Method 2: Download and Run (If antivirus blocks the one-liner)**

```powershell
# Download setup script first
Invoke-WebRequest "https://github.com/J-MaFf/powershell-profile-system/releases/latest/download/Setup.ps1" -OutFile "setup-temp.ps1"

# Review the script (optional but recommended)
Get-Content setup-temp.ps1

# Run setup
.\setup-temp.ps1

# Clean up
Remove-Item setup-temp.ps1
```

**Method 3: Git Clone (A machine you develop the profile on)**

```powershell
git clone https://github.com/J-MaFf/powershell-profile-system.git
cd powershell-profile-system
.\Setup.ps1 -Git
```

A `-Git` install is a clone you update yourself with `git pull`; it never updates from releases.

**What setup does:**
- 📦 Installs the latest release to `~/.config/powershell-profile`: it downloads the release's updater, checks it against the release manifest's SHA-256 before running it, and lets it install every file, each checked the same way (no git needed)
- 📁 Backs up any existing PowerShell profile
- ⚙️ Installs the profile loader into `$PROFILE`
- ✅ Configures automatic updates, at most once a day
- 🎯 Makes all functions immediately available (`Use-ServiceAccount`, etc.)

**Updates:**
- **Console PowerShell**: checks for a new release at most once a day, and prints a line only when it updated something or the check failed
- **VS Code**: Silent loading, no update check (no interference with extension)
- **Manual check**: `& ~/.config/powershell-profile/Update-ProfileSystem.ps1 -Force`

## 📚 Available Functions

### `Use-ServiceAccount`
Configures 1Password CLI to use service account token for automation and CI/CD scenarios.

```powershell
Use-ServiceAccount                    # Retrieves token from 1Password vault
Use-ServiceAccount -Token "ops_..."   # Uses provided token directly
```

### `Use-RegularAccount`
Switches back to regular 1Password user authentication for interactive use.

```powershell
Use-RegularAccount           # Switch to regular user mode
Use-RegularAccount -Verify   # Switch and verify authentication status
```

### `Get-1PasswordMode`
Shows current 1Password CLI authentication mode and provides guidance.

```powershell
Get-1PasswordMode
```

**Example output:**
```
🔍 1Password CLI Status
=====================
👤 Mode: Regular User
💡 Switch to service: Use-ServiceAccount
```

## 📖 Reference

- [PowerShell cheat sheet](docs/ps-cheat-sheet.md): everyday cmdlets and shortcuts.

## 🏗️ How It Works

### Architecture Overview

1. **Setup**: Installs the latest release to `~/.config/powershell-profile` (or clones the repository with `-Git`)
2. **Profile Loading**: Your PowerShell profile:
   - Runs `Update-ProfileSystem.ps1`, which checks for a new release at most once a day (console only)
   - Dot-sources `PSProfile.ps1` to load functions
3. **VS Code Optimization**: Skips the update check for faster extension loading
4. **Updates**: `tools/Update-FromGitHubRelease.ps1` (from [J-MaFf/release-kit](https://github.com/J-MaFf/release-kit)) compares every file of the newest release with the installed one by SHA-256, downloads only those that differ, checks each, and replaces them together. A failed check (offline, GitHub down) keeps the files you have and tries again the next day.

### File Structure

```
~/.config/powershell-profile/
├── PSProfile.ps1                       # Core functions and profile logic
├── Update-ProfileSystem.ps1            # Daily update check, run by $PROFILE
├── Setup.ps1                           # Installation script
├── tools/Update-FromGitHubRelease.ps1  # The updater, from J-MaFf/release-kit
├── modules/                            # ActiveDirectoryUtils, PersonalUtils
└── .update-state.json                  # When it last checked (not in releases)
```

### Profile Integration

The setup script creates/updates your PowerShell profile with this simple loader:

```powershell
# PowerShell Profile System
$ProfileRepo = 'C:\Users\{username}\.config\powershell-profile'

# Update from the newest release at most once a day (skipped in VS Code and in a git clone).
if (Test-Path "$ProfileRepo\Update-ProfileSystem.ps1") {
    & "$ProfileRepo\Update-ProfileSystem.ps1" -InstallPath $ProfileRepo
}

# Load the profile
if (Test-Path "$ProfileRepo\PSProfile.ps1") {
    . "$ProfileRepo\PSProfile.ps1"
}
```

The update logic lives in `Update-ProfileSystem.ps1`, which every release ships, so this stub never needs to change.

## 🔄 Updating

### Automatic Updates
The profile checks for a new release at most once a day (console mode only). Set `PSPROFILE_NO_UPDATE=1` to turn the check off.

### Manual Updates
```powershell
& "$env:USERPROFILE\.config\powershell-profile\Update-ProfileSystem.ps1" -Force
```

For a `-Git` install: `cd ~/.config/powershell-profile; git pull`.

### Force Reinstall
```powershell
Invoke-WebRequest "https://github.com/J-MaFf/powershell-profile-system/releases/latest/download/Setup.ps1" -OutFile "setup-temp.ps1"
.\setup-temp.ps1 -Force
Remove-Item setup-temp.ps1
```

`-Force` downloads and checks the new release before it removes the old installation.

### Moving an existing git-based install to releases
Installs made before releases are git clones whose `$PROFILE` runs `git pull`; they keep working as before. To switch one to releases, run `Setup.ps1 -Force` as above.

### Publishing a release (maintainers)
1. Move the `[Unreleased]` entries in `CHANGELOG.md` under `## [X.Y.Z] - YYYY-MM-DD` and merge that.
2. Tag the merge commit on `main` and push the tag: `git tag vX.Y.Z <commit> && git push origin vX.Y.Z`.

`.github/workflows/release.yml` then publishes the files listed in it, a `release-manifest.json` and an attestation for each, through `J-MaFf/release-kit`. A new file the profile needs must be added to that list. When release-kit releases a newer updater, copy its `Update-FromGitHubRelease.ps1` asset over `tools/Update-FromGitHubRelease.ps1`.

To check a release file yourself:
```powershell
gh attestation verify PSProfile.ps1 --repo J-MaFf/powershell-profile-system `
    --signer-workflow J-MaFf/release-kit/.github/workflows/release.yml
```

## 🎯 Use Cases

### Development Workflow
```powershell
# Start with regular user mode for interactive work
Get-1PasswordMode
Use-RegularAccount -Verify

# Switch to service account for automation
Use-ServiceAccount
# Now op commands work in automation context
```

### CI/CD Integration
```powershell
# In CI/CD pipelines
Use-ServiceAccount -Token $env:OP_SERVICE_ACCOUNT_TOKEN
# Automation-ready 1Password CLI
```

## 🛠️ Requirements

- **PowerShell 5.1+** or **PowerShell 7+**
- **Git** only for a `-Git` install
- **1Password CLI** (optional, for 1Password functions)
- **Internet connection** (for initial setup and updates)

## 🧠 Memory MCP Server Setup

This repository includes workspace-local Memory MCP server configuration for AI assistance with persistent knowledge graphs.

**Quick Setup:**
1. ✅ Configuration files are already in place (`.vscode/mcp.json`)
2. ⚠️ **Manual step required:** Remove Memory server from your global MCP config
3. 🔄 Restart VS Code to apply changes

**📖 Full Documentation:** See [MEMORY_MCP_SERVER_SETUP.md](MEMORY_MCP_SERVER_SETUP.md) for:
- Step-by-step removal of global Memory server configuration
- How workspace-local storage works
- Benefits and troubleshooting
- Configuration reference

## 🔧 Troubleshooting

### Antivirus Blocking Script Downloads
If you get "This script contains malicious content and has been blocked by your antivirus software":

**Solution 1: Download First, Then Execute**
```powershell
Invoke-WebRequest "https://github.com/J-MaFf/powershell-profile-system/releases/latest/download/Setup.ps1" -OutFile "setup.ps1"
.\setup.ps1
```

**Solution 2: Use Git Clone Method**
```powershell
git clone https://github.com/J-MaFf/powershell-profile-system.git
cd powershell-profile-system
.\Setup.ps1 -Git
```

**Solution 3: Add Windows Defender Exception**
- Open Windows Security → Virus & threat protection
- Add exclusion for PowerShell.exe or the specific URL

### VS Code Extension Issues
The profile automatically detects VS Code and uses silent loading to prevent extension interference.

### Update Check Failed
A line like `Profile system: update check failed (...)` means it could not reach GitHub or a download did not match the manifest. Your installed files are untouched; it tries again the next day, or run `Update-ProfileSystem.ps1 -Force`.

### 1Password CLI Not Found
The functions will display helpful error messages if 1Password CLI is not installed.

### Profile Not Loading
Check that the installation exists:
```powershell
Test-Path "$env:USERPROFILE\.config\powershell-profile\PSProfile.ps1"
```

## 🔄 Migration from Gist-Based System

If you're upgrading from an older gist-based profile system:

1. The setup script automatically backs up your existing profile
2. Your functions remain the same - just the loading mechanism changes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in both console and VS Code (`Invoke-Pester tests` covers the update check)
5. Submit a pull request

## 📝 Architecture Benefits

### Why Releases Over `git pull`?

| Feature | Releases | `git pull` on every start |
|---------|----------|---------------------------|
| **What reaches machines** | ✅ Only tagged releases | ❌ Whatever is on `main` |
| **Integrity** | ✅ SHA-256 per file, attestations | ❌ Nothing checked |
| **Needs git** | ✅ No | ❌ Yes |
| **Startup cost** | ⚡ One check a day | 🐌 A fetch every start |
| **Offline** | 🟢 Keeps working | 🟢 Keeps working |
| **Rate limits** | ✅ One API call a day, well inside 60/hour | ✅ None |

### Design Principles

1. **Simplicity**: Minimal code, maximum functionality
2. **Performance**: Fast loading, especially in VS Code
3. **Reliability**: Works offline, graceful error handling
4. **Maintainability**: Clean, readable, well-documented code
5. **Compatibility**: Works across PowerShell versions and editors

## 📄 License

MIT License - feel free to use, modify, and distribute.
