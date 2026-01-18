# MuLa Studio Installer

One-click installer for HeartMuLa AI Music Generator.

## Overview

This directory contains installer scripts and build configurations for:
- **Windows** (x64/x86) - NSIS installer
- **macOS** (Intel/Apple Silicon) - Shell script + DMG
- **Linux** (Ubuntu, Fedora, Arch) - Shell script

## Directory Structure

```
installer/
├── README.md                  # This file
├── app/
│   ├── main.py               # Gradio application
│   └── download_models.py    # Model downloader script
├── windows/
│   ├── MuLaInstaller_x64.nsi # NSIS script for Windows x64
│   └── build_windows.bat     # Windows build script
├── macos/
│   └── install.sh            # macOS installation script
└── linux/
    └── mula_install.sh       # Linux installation script
```

## Building

### Windows

Prerequisites:
- [NSIS 3.x](https://nsis.sourceforge.io/Download)
- Windows 10/11

```batch
cd installer\windows
build_windows.bat 1.0.0
```

Output: `dist/MuLa_Setup_x64.exe`

### macOS

Prerequisites:
- macOS 12+
- [create-dmg](https://github.com/create-dmg/create-dmg) (optional, for DMG)

```bash
cd installer/macos
chmod +x install.sh
./install.sh
```

### Linux

Prerequisites:
- Python 3.10+
- Ubuntu 20.04+, Fedora 35+, or Arch Linux

```bash
cd installer/linux
chmod +x mula_install.sh
./mula_install.sh
```

## GitHub Actions

Automated builds are configured in `.github/workflows/build-installers.yml`.

Trigger a build:
1. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`
2. Or manually trigger from GitHub Actions

## System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| RAM | 8GB | 16GB+ |
| Storage | 15GB | 20GB+ |
| GPU | - | NVIDIA RTX 2060+ |
| OS | Windows 10 / macOS 12 / Ubuntu 20.04 | Latest |

## What Gets Installed

The installer creates:

```
~/.mulastudio/  (or %LOCALAPPDATA%\MuLaStudio on Windows)
├── python/           # Embedded Python (Windows only)
├── venv/             # Virtual environment (macOS/Linux)
├── app/
│   └── main.py       # Gradio application
├── models/           # AI models (~6GB)
│   ├── HeartMuLaGen/
│   ├── HeartMuLa-oss-3B/
│   └── HeartCodec-oss/
└── run.bat/run.sh    # Launch script
```

Output files are saved to:
- Windows: `%USERPROFILE%\Documents\MuLaStudio_Outputs`
- macOS/Linux: `~/Documents/MuLaStudio_Outputs` or `~/MuLaStudio_Outputs`

## Development

### Testing Locally

1. **Windows**: Build and test on a clean Windows VM
2. **macOS**: Test on both Intel and Apple Silicon Macs
3. **Linux**: Test on Ubuntu, Fedora, and Arch

### Adding New Features

1. Modify the installer script
2. Test locally
3. Update version number
4. Create a PR

## Troubleshooting

### Common Issues

**Windows: NSIS not found**
```
Install NSIS: choco install nsis
```

**macOS: Permission denied**
```bash
chmod +x install.sh
```

**Linux: Python not found**
```bash
# Ubuntu/Debian
sudo apt install python3 python3-pip python3-venv

# Fedora
sudo dnf install python3 python3-pip

# Arch
sudo pacman -S python python-pip
```

**Download timeout**
- Check internet connection
- Try again later (HuggingFace may be busy)
- Use a VPN if in a restricted region

### Logs

- Windows: `%LOCALAPPDATA%\MuLaStudio\logs\`
- macOS/Linux: `~/.mulastudio/logs/`

## License

CC BY-NC 4.0

## Contact

- Website: https://music.abada.kr
- GitHub: https://github.com/saintgo7/web-music-heartlib
- Issues: https://github.com/saintgo7/web-music-heartlib/issues
