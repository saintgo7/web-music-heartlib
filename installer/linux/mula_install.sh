#!/bin/bash
#
# MuLa Studio Installer for Linux
# Supports: Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux
#
# Usage:
#   chmod +x mula_install.sh
#   ./mula_install.sh
#

set -e

VERSION="1.0.0"
INSTALL_DIR="$HOME/.mulastudio"
MODEL_DIR="$INSTALL_DIR/models"
BIN_DIR="$HOME/.local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}[STEP]${NC} ${BOLD}$1${NC}"; }

echo -e "${BOLD}"
echo "================================================================"
echo "   MuLa Studio Installer v${VERSION}"
echo "   HeartMuLa AI Music Generator"
echo "================================================================"
echo -e "${NC}"

#─────────────────────────────────────────
# System Check
#─────────────────────────────────────────
step "Checking system requirements"

# Architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    error "Only x86_64 architecture is supported (current: $ARCH)"
fi
log "Architecture: $ARCH"

# OS Detection
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    log "OS: $NAME $VERSION_ID"
fi

# Python check
if ! command -v python3 &> /dev/null; then
    warn "Python3 is not installed."
    echo ""
    echo "  Please install Python 3.10+ first:"
    echo "    Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
    echo "    Fedora:        sudo dnf install python3 python3-pip"
    echo "    Arch:          sudo pacman -S python python-pip"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
else
    PYTHON_VER=$(python3 --version)
    log "Python: $PYTHON_VER"
fi

# GPU Detection
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
    log "GPU: $GPU_NAME ($GPU_MEM)"
    GPU_MODE="cuda"
else
    warn "No NVIDIA GPU detected - CPU mode (slower generation)"
    GPU_MODE="cpu"
fi

# Disk space
FREE_GB=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | tr -d 'G')
if [[ "$FREE_GB" -lt 15 ]]; then
    error "Insufficient disk space! Need at least 15GB (available: ${FREE_GB}GB)"
fi
log "Disk space: ${FREE_GB}GB available"

# RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
log "RAM: ${RAM_GB}GB"
if [[ "$RAM_GB" -lt 8 ]]; then
    warn "RAM is less than 8GB. Performance may be limited."
fi

#─────────────────────────────────────────
# Confirmation
#─────────────────────────────────────────
echo ""
echo -e "${BOLD}Installation Summary:${NC}"
echo "  Install directory: $INSTALL_DIR"
echo "  GPU mode: $GPU_MODE"
echo "  Estimated time: 15-30 minutes"
echo "  Required space: ~15GB"
echo ""

read -p "Start installation? [Y/n] " -n 1 -r
echo
[[ $REPLY =~ ^[Nn]$ ]] && exit 0

#─────────────────────────────────────────
# Python Virtual Environment
#─────────────────────────────────────────
step "Creating Python virtual environment"

mkdir -p "$INSTALL_DIR"
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"

pip install --upgrade pip wheel setuptools
log "Virtual environment ready"

#─────────────────────────────────────────
# Install PyTorch
#─────────────────────────────────────────
step "Installing PyTorch (${GPU_MODE} mode)"

if [[ "$GPU_MODE" == "cuda" ]]; then
    echo "  Installing PyTorch with CUDA support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
else
    echo "  Installing PyTorch (CPU version)..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

log "PyTorch installed successfully"

#─────────────────────────────────────────
# Install Dependencies
#─────────────────────────────────────────
step "Installing additional dependencies"

pip install gradio huggingface_hub tqdm requests

echo "  Installing HeartMuLa (heartlib)..."
pip install git+https://github.com/saintgo7/web-music-heartlib.git

log "Dependencies installed successfully"

#─────────────────────────────────────────
# Download AI Models
#─────────────────────────────────────────
step "Downloading AI models (approximately 6GB)"

echo "  This may take 10-30 minutes depending on your connection..."

mkdir -p "$MODEL_DIR"

python3 << EOF
from huggingface_hub import snapshot_download
import os

model_dir = "$MODEL_DIR"

print("  [1/3] Downloading HeartMuLaGen...")
snapshot_download('HeartMuLa/HeartMuLaGen', local_dir=model_dir)

print("  [2/3] Downloading HeartMuLa-oss-3B...")
snapshot_download('HeartMuLa/HeartMuLa-oss-3B',
                  local_dir=os.path.join(model_dir, 'HeartMuLa-oss-3B'))

print("  [3/3] Downloading HeartCodec-oss...")
snapshot_download('HeartMuLa/HeartCodec-oss',
                  local_dir=os.path.join(model_dir, 'HeartCodec-oss'))

print("  Download complete!")
EOF

log "Models downloaded successfully"

#─────────────────────────────────────────
# Create Application Files
#─────────────────────────────────────────
step "Creating application files"

mkdir -p "$INSTALL_DIR/app"

# Create main.py
cat > "$INSTALL_DIR/app/main.py" << 'PYEOF'
#!/usr/bin/env python3
"""MuLa Studio - HeartMuLa AI Music Generator UI"""

import gradio as gr
import torch
import os
from pathlib import Path
from datetime import datetime

MODEL_DIR = Path.home() / ".mulastudio" / "models"
OUTPUT_DIR = Path.home() / "MuLaStudio_Outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if torch.cuda.is_available():
    DEVICE = "cuda"
    DEVICE_NAME = torch.cuda.get_device_name(0)
else:
    DEVICE = "cpu"
    DEVICE_NAME = "CPU"

model = None

def load_model():
    global model
    if model is None:
        try:
            from heartlib import HeartMuLaInfer
            model = HeartMuLaInfer(model_path=str(MODEL_DIR), version="3B")
        except Exception as e:
            return None, f"Error loading model: {str(e)}"
    return model, None

def generate(lyrics, tags, length, temp, cfg, progress=gr.Progress()):
    try:
        progress(0.1, "Loading model...")
        m, error = load_model()
        if error:
            return None, error

        progress(0.2, "Generating music...")
        output_path = OUTPUT_DIR / f"music_{datetime.now():%Y%m%d_%H%M%S}.mp3"

        m.generate(
            lyrics=lyrics,
            tags=tags,
            max_audio_length_ms=int(length * 1000),
            temperature=temp,
            cfg_scale=cfg,
            save_path=str(output_path)
        )

        progress(1.0, "Complete!")
        return str(output_path), f"Saved: {output_path.name}"
    except Exception as e:
        return None, f"Error: {str(e)}"

SAMPLE = """[Verse]
The morning light comes through the window
A brand new day is here

[Chorus]
We rise again, we start again
Every day is a new begin"""

with gr.Blocks(title="MuLa Studio", theme=gr.themes.Soft()) as app:
    gr.Markdown(f"# MuLa Studio\n**Device**: {DEVICE_NAME}")

    with gr.Row():
        with gr.Column(scale=2):
            lyrics = gr.Textbox(label="Lyrics", lines=12, value=SAMPLE)
            tags = gr.Textbox(label="Style Tags", value="piano,happy,pop")
        with gr.Column(scale=1):
            length = gr.Slider(30, 240, 120, step=10, label="Length(sec)")
            temp = gr.Slider(0.5, 1.5, 1.0, step=0.1, label="Temperature")
            cfg = gr.Slider(1.0, 3.0, 1.5, step=0.1, label="CFG Scale")
            btn = gr.Button("Generate Music", variant="primary", size="lg")

    status = gr.Textbox(label="Status", interactive=False)
    audio = gr.Audio(label="Generated Music", type="filepath")

    btn.click(generate, [lyrics, tags, length, temp, cfg], [audio, status])
    gr.Markdown("---\n*Powered by HeartMuLa (CC BY-NC 4.0)*")

if __name__ == "__main__":
    app.launch(server_name="127.0.0.1", server_port=7860, inbrowser=True)
PYEOF

chmod +x "$INSTALL_DIR/app/main.py"
log "Application files created"

#─────────────────────────────────────────
# Create Launcher Script
#─────────────────────────────────────────
step "Creating launcher"

mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/mulastudio" << EOF
#!/bin/bash
# MuLa Studio Launcher
source "$INSTALL_DIR/venv/bin/activate"
xdg-open "http://127.0.0.1:7860" 2>/dev/null &
python "$INSTALL_DIR/app/main.py"
EOF

chmod +x "$BIN_DIR/mulastudio"

# Create desktop entry
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/mulastudio.desktop" << EOF
[Desktop Entry]
Name=MuLa Studio
Comment=HeartMuLa AI Music Generator
Exec=$BIN_DIR/mulastudio
Icon=audio-x-generic
Terminal=true
Type=Application
Categories=Audio;Music;AudioVideo;
Keywords=music;ai;generator;heartmula;
EOF

# Copy to desktop if exists
for dir in "$HOME/Desktop" "$HOME/desktop"; do
    if [[ -d "$dir" ]]; then
        cp "$DESKTOP_DIR/mulastudio.desktop" "$dir/"
        chmod +x "$dir/mulastudio.desktop"
        log "Desktop shortcut created"
    fi
done

log "Launcher created"

# Check PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "~/.local/bin is not in PATH"
    echo "  Add this to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

#─────────────────────────────────────────
# Create Uninstaller
#─────────────────────────────────────────
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
echo "Uninstalling MuLa Studio..."

# Remove installation directory
rm -rf "$HOME/.mulastudio"

# Remove launcher
rm -f "$HOME/.local/bin/mulastudio"

# Remove desktop entries
rm -f "$HOME/.local/share/applications/mulastudio.desktop"
rm -f "$HOME/Desktop/mulastudio.desktop" 2>/dev/null
rm -f "$HOME/desktop/mulastudio.desktop" 2>/dev/null

echo ""
echo "MuLa Studio has been uninstalled!"
echo ""
echo "Note: Output files in ~/MuLaStudio_Outputs are preserved."
echo "      Delete manually if not needed."
UNINSTALL_EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

#─────────────────────────────────────────
# Complete
#─────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}   Installation Complete!${NC}"
echo ""
echo "   To run MuLa Studio:"
echo "     1. Terminal: mulastudio"
echo "     2. Desktop icon (if available)"
echo ""
echo "   Output files will be saved to: ~/MuLaStudio_Outputs"
echo ""
echo "   To uninstall: ~/.mulastudio/uninstall.sh"
echo -e "${GREEN}${BOLD}================================================================${NC}"

read -p "Launch MuLa Studio now? [Y/n] " -n 1 -r
echo
[[ ! $REPLY =~ ^[Nn]$ ]] && "$BIN_DIR/mulastudio"
