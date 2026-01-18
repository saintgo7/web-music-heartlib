# MuLa Studio - Installer Development Guide

## Overview

**MuLa Studio** is a one-click installer for **HeartMuLa AI Music Generator**, enabling non-developers to install and use HeartMuLa with a single click.

This document covers the development environment setup and build process for macOS, Linux, and Windows installers.

---

## Project Structure

```
web-music-heartlib/
├── installer/
│   ├── app/                  # Application files
│   │   └── main.py          # Gradio UI app
│   ├── macos/               # macOS installer
│   │   ├── install.sh       # Installation script
│   │   └── build.sh         # DMG builder (optional)
│   ├── linux/               # Linux installer
│   │   └── mula_install.sh  # Installation script
│   ├── windows/             # Windows installer (future)
│   │   └── MuLaInstaller.nsi # NSIS script
│   ├── resources/           # Assets (icons, etc.)
│   └── build/               # Build output
├── src/                     # HeartMuLa library source
├── examples/                # Usage examples
├── pyproject.toml           # Python package config
├── Makefile                 # Build automation
└── INSTALLER_DEV.md         # This file
```

---

## Development Environment Setup (macOS)

### Prerequisites

- macOS 12 or later (Intel or Apple Silicon)
- Homebrew installed
- Python 3.9+ (3.10 recommended)
- Git

### Quick Setup

```bash
cd /Users/saint/01_DEV/web-music-heartlib

# Install dependencies
brew install create-dmg

# Setup Python development environment
make dev-setup

# Activate virtual environment
source venv/bin/activate
```

### Manual Setup (Alternative)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip wheel setuptools
pip install -e .                    # Install heartlib
pip install gradio huggingface_hub  # UI dependencies

# Install system tools
brew install create-dmg
```

---

## macOS Installer Development

### Directory: `installer/macos/`

#### File: `install.sh`

The main installation script that:
1. Checks system requirements (macOS version, disk space, RAM)
2. Detects architecture (Intel vs Apple Silicon)
3. Creates Python virtual environment
4. Installs PyTorch (with GPU acceleration if available)
5. Downloads AI models (~6GB)
6. Creates app launcher
7. Generates desktop shortcut

#### Usage

```bash
# Make executable
chmod +x installer/macos/install.sh

# Run installation
./installer/macos/install.sh
```

#### Testing

```bash
# Validate script syntax
bash -n installer/macos/install.sh

# Test with make
make test
```

#### Key Features

- **Automatic device detection**: CPU, Apple Silicon (MPS), or NVIDIA GPU
- **GUI dialogs**: Native macOS notifications
- **Automatic launcher**: Desktop shortcut creation
- **Uninstaller**: `~/.mulastudio/uninstall.sh`

#### Environment Variables

The script uses:
- `$INSTALL_DIR` = `~/.mulastudio`
- `$MODEL_DIR` = `~/.mulastudio/models`
- `$VENV_DIR` = `~/.mulastudio/venv`
- `$GPU_MODE` = `cpu`, `mps`, or `cuda`

---

## Linux Installer Development

### Directory: `installer/linux/`

#### File: `mula_install.sh`

Similar to macOS, supports:
- Ubuntu 20.04+
- Debian 11+
- Fedora 35+
- Arch Linux

#### Creation Status

To be created (template available in DEV.md)

---

## Windows Installer Development (Future)

### Directory: `installer/windows/`

#### File: `MuLaInstaller.nsi`

NSIS (Nullsoft Scriptable Install System) installer for Windows.

**Requirements**: NSIS 3.x (runs on Windows)

#### Key Features
- x64 and x86 builds
- NVIDIA GPU detection
- Embedded Python 3.10
- Automatic PyTorch installation

---

## Application Development

### Directory: `installer/app/`

#### File: `main.py`

Gradio-based web UI for HeartMuLa music generation.

**Features**:
- Lyrics input (multi-line)
- Style tags (comma-separated)
- Duration control
- Temperature and CFG scale sliders
- Real-time progress display
- Audio output playback

**Running locally** (for development):

```bash
# Activate environment
source venv/bin/activate

# Run app directly
python installer/app/main.py

# Or use the launcher
~/.mulastudio/run.command
```

**Output**: Saves generated music to `~/Documents/MuLaStudio_Outputs/`

---

## Build Automation

### Makefile Targets

```bash
# Show help
make help

# Setup development environment
make dev-setup

# Install system dependencies
make install-deps

# Validate scripts
make test

# Build macOS DMG
make build-macos

# Build Linux script verification
make build-linux

# Build all
make build-all

# Clean artifacts
make clean

# Show project info
make info
```

---

## Installation Process Overview

### What Gets Installed

After running the installer, user's system will have:

```
~/.mulastudio/
├── venv/                     # Python virtual environment
│   ├── bin/
│   │   ├── python3
│   │   ├── pip
│   │   └── ...
│   └── lib/
│       └── python3.x/
│           └── site-packages/
│               ├── torch/    # PyTorch
│               ├── gradio/   # Web UI
│               ├── heartlib/ # HeartMuLa library
│               └── ...
├── models/                   # AI models (~6GB)
│   ├── HeartMuLaGen/
│   ├── HeartMuLa-oss-3B/
│   └── HeartCodec-oss/
├── app/
│   └── main.py              # Gradio UI application
├── run.command              # Launcher script (macOS)
└── uninstall.sh             # Uninstaller script
```

### Desktop Integration

- **macOS**: Desktop shortcut named "MuLa Studio"
- **Linux**: Desktop entry in `~/.local/share/applications/`
- **Windows**: Start Menu entry

---

## Testing Checklist

### Installation Tests

- [ ] Clean system installation succeeds
- [ ] System requirements check works (disk space, RAM)
- [ ] GPU detection works correctly
- [ ] PyTorch installs with correct backend (CPU/MPS/CUDA)
- [ ] Models download successfully (~6GB)
- [ ] Desktop shortcut created
- [ ] Application launches correctly

### Application Tests

- [ ] Gradio UI loads in browser
- [ ] Model loads successfully
- [ ] Music generation completes (may take 2-5 min on GPU)
- [ ] Audio output playable
- [ ] Output files saved to correct location
- [ ] Uninstallation removes files properly

---

## Troubleshooting

### Common Issues

#### 1. Python not found
```bash
# Install Python 3.10
brew install python@3.10
# Link it
brew link python@3.10
```

#### 2. Insufficient disk space
- Need minimum 15GB free space
- Models alone require ~6GB
- Recommend 20GB+ for safety

#### 3. GPU not detected on macOS
- Apple Silicon should auto-detect (MPS)
- Intel Mac fallback to CPU (slower)
- NVIDIA GPUs not supported on macOS native

#### 4. Model download failures
- Check internet connection
- Try again (downloads are resumable)
- Verify HuggingFace can be accessed

#### 5. Gradio UI not accessible
```bash
# Check if port 7860 is in use
lsof -i :7860

# Try killing existing process
kill -9 <PID>

# Try alternate port (edit main.py)
server_port=7861
```

---

## Development Workflow

### Making Changes

1. **App UI changes**:
   ```bash
   # Edit installer/app/main.py
   source venv/bin/activate
   python installer/app/main.py
   # Test in browser
   ```

2. **Script changes**:
   ```bash
   # Edit installer/macos/install.sh
   bash -n installer/macos/install.sh  # Validate syntax
   chmod +x installer/macos/install.sh
   # Test in VM or container
   ```

3. **Commit changes**:
   ```bash
   git add installer/ Makefile INSTALLER_DEV.md
   git commit -m "chore: update installer scripts"
   ```

### Building Release

```bash
# Prepare build
make clean
make install-deps

# Test everything
make test

# Build all platforms
make build-all

# Results in installer/build/
ls -lh installer/build/
```

---

## Next Steps

### Phase 1: macOS (Current)
- ✅ Virtual environment setup
- ✅ Install script (`install.sh`)
- ✅ Application UI (`main.py`)
- ⏳ Test on real Mac (Intel & Apple Silicon)
- ⏳ Create DMG bundle

### Phase 2: Linux
- ⏳ Create `mula_install.sh`
- ⏳ Test on Ubuntu, Fedora, Arch
- ⏳ Desktop integration

### Phase 3: Windows
- ⏳ Create NSIS script (`MuLaInstaller.nsi`)
- ⏳ Build x64 and x86 versions
- ⏳ GPU detection for Windows

### Phase 4: Release
- ⏳ Finalize all platforms
- ⏳ Create README for end-users
- ⏳ Upload to GitHub Releases
- ⏳ Version 1.0.0

---

## References

- **HeartMuLa**: https://github.com/HeartMuLa/heartlib
- **Gradio Docs**: https://www.gradio.app/
- **create-dmg**: https://github.com/create-dmg/create-dmg
- **NSIS**: https://nsis.sourceforge.io/

---

## Contact

For questions or issues:
- GitHub: https://github.com/saintgo7/web-music-heartlib
- Email: heartmula.ai@gmail.com

---

**Document Version**: 1.0
**Last Updated**: 2026-01-18
**Status**: Active Development
