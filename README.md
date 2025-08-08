# PowerShell Profile System

A simple, git-based PowerShell profile management system with 1Password CLI integration and VS Code extension compatibility.

## ✨ Features

- **🚀 Git-based updates**: No API calls, just `git pull` for reliable updates
- **⚡ Fast startup**: Local files, minimal overhead, instant loading
- **🎨 VS Code compatible**: Silent loading in PowerShell extension without interference
- **🔐 1Password integration**: Seamless switching between service account and user modes
- **📱 Offline capable**: Works without internet after initial setup
- **🛠️ Simple architecture**: Clean, maintainable code without complex abstractions

## 🚀 Quick Start

### New Computer Setup

**Method 1: One-liner (Fastest)**

```powershell
iex (iwr "https://raw.githubusercontent.com/J-MaFf/powershell-profile-system/main/Setup.ps1" -UseBasicParsing).Content
```

**Method 2: Git Clone (If antivirus blocks one-liner)**

```powershell
# Clone the repository
git clone https://github.com/J-MaFf/powershell-profile-system.git
cd powershell-profile-system

# Run setup
.\Setup.ps1
```

**Method 3: Download and Run (Alternative for restricted environments)**

```powershell
# Download setup script first
Invoke-WebRequest "https://raw.githubusercontent.com/J-MaFf/powershell-profile-system/main/Setup.ps1" -OutFile "setup-temp.ps1"

# Review the script (optional but recommended)
Get-Content setup-temp.ps1

# Run setup
.\setup-temp.ps1

# Clean up
Remove-Item setup-temp.ps1
```

**What setup does:**
- 🔄 Clones your profile repo to `~/.config/powershell-profile`
- 📁 Backs up any existing PowerShell profile
- ⚙️ Installs the new git-based profile loader
- ✅ Configures automatic updates on PowerShell startup
- 🎯 Makes all functions immediately available (`Use-ServiceAccount`, etc.)

**All methods enable autonomous updates:**
- **Console PowerShell**: Auto-updates every startup + shows loading messages
- **VS Code**: Silent loading (no interference with extension)
- **Manual updates**: `cd ~/.config/powershell-profile && git pull`

### Manual Installation (Step-by-step)

```powershell
git clone https://github.com/J-MaFf/powershell-profile-system.git
cd powershell-profile-system
.\Setup.ps1
```

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

## 🏗️ How It Works

### Architecture Overview

1. **Setup**: Clones this repository to `~/.config/powershell-profile`
2. **Profile Loading**: Your PowerShell profile automatically:
   - Runs `git pull` to check for updates (console only)
   - Dot-sources `PSProfile.ps1` to load functions
3. **VS Code Optimization**: Skips git operations for faster extension loading
4. **Updates**: Automatic on PowerShell startup, or manual via `git pull`

### File Structure

```
~/.config/powershell-profile/
├── PSProfile.ps1          # Core functions and profile logic
├── Setup.ps1              # Installation script
├── README.md              # This file
└── .git/                  # Git repository data
```

### Profile Integration

The setup script creates/updates your PowerShell profile with this simple loader:

```powershell
# PowerShell Profile System - Git Based
$ProfileRepo = 'C:\Users\{username}\.config\powershell-profile'

# Update profile repo (skip in VS Code for speed)  
if (-not ($null -ne $psEditor -or $env:TERM_PROGRAM -eq "vscode")) {
    if (Test-Path $ProfileRepo) {
        Push-Location $ProfileRepo
        try {
            git fetch --quiet 2>$null
            $behind = git rev-list --count HEAD..origin/main 2>$null
            if ($behind -and $behind -gt 0) {
                git pull origin main --quiet 2>$null
            }
        } catch {
            # Ignore git errors
        }
        Pop-Location
    }
}

# Load the profile
if (Test-Path "$ProfileRepo\PSProfile.ps1") {
    . "$ProfileRepo\PSProfile.ps1"
}
```

## 🔄 Updating

### Automatic Updates
The profile checks for updates every time you start PowerShell (console mode only).

### Manual Updates
```powershell
cd ~/.config/powershell-profile
git pull
```

### Force Reinstall
```powershell
# If using git clone method
.\Setup.ps1 -Force

# If using download method  
Invoke-WebRequest "https://raw.githubusercontent.com/J-MaFf/powershell-profile-system/main/Setup.ps1" -OutFile "setup-temp.ps1"
.\setup-temp.ps1 -Force
Remove-Item setup-temp.ps1
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
- **Git** (for updates and installation)
- **1Password CLI** (optional, for 1Password functions)
- **Internet connection** (for initial setup and updates)

## 🔧 Troubleshooting

### Antivirus Blocking Script Downloads
If you get "This script contains malicious content and has been blocked by your antivirus software":

**Solution 1: Use Git Clone Method (Recommended)**
```powershell
git clone https://github.com/J-MaFf/powershell-profile-system.git
cd powershell-profile-system
.\Setup.ps1
```

**Solution 2: Download First, Then Execute**
```powershell
Invoke-WebRequest "https://raw.githubusercontent.com/J-MaFf/powershell-profile-system/main/Setup.ps1" -OutFile "setup.ps1"
.\setup.ps1
```

**Solution 3: Add Windows Defender Exception**
- Open Windows Security → Virus & threat protection
- Add exclusion for PowerShell.exe or the specific URL

### VS Code Extension Issues
The profile automatically detects VS Code and uses silent loading to prevent extension interference.

### Git Authentication
If you have git authentication issues, the profile will gracefully fall back to the cached version.

### 1Password CLI Not Found
The functions will display helpful error messages if 1Password CLI is not installed.

### Profile Not Loading
Check that the repository exists:
```powershell
Test-Path "$env:USERPROFILE\.config\powershell-profile\PSProfile.ps1"
```

## 🔄 Migration from Gist-Based System

If you're upgrading from an older gist-based profile system:

1. The setup script automatically backs up your existing profile
2. Your functions remain the same - just the loading mechanism changes
3. Enjoy faster, more reliable updates with git!

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in both console and VS Code
5. Submit a pull request

## 📝 Architecture Benefits

### Why Git Over Gist API?

| Feature | Git-Based | Gist API |
|---------|-----------|----------|
| **Speed** | ⚡ Instant (local files) | 🐌 Network dependent |
| **Reliability** | 🟢 Always works offline | 🔴 Fails without internet |
| **Rate Limits** | ✅ None | ❌ 60 requests/hour |
| **Version Control** | ✅ Full git history | ❌ Limited versioning |
| **Branching** | ✅ Test branches | ❌ Single version |
| **CI/CD** | ✅ Automated testing | ❌ Manual process |

### Design Principles

1. **Simplicity**: Minimal code, maximum functionality
2. **Performance**: Fast loading, especially in VS Code
3. **Reliability**: Works offline, graceful error handling
4. **Maintainability**: Clean, readable, well-documented code
5. **Compatibility**: Works across PowerShell versions and editors

## 📄 License

MIT License - feel free to use, modify, and distribute.
