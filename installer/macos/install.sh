#!/bin/bash
#
# MuLa Studio Installer for macOS
# Supports: macOS 12+ (Intel & Apple Silicon)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="$HOME/.mulastudio"
MODEL_DIR="$INSTALL_DIR/models"
VENV_DIR="$INSTALL_DIR/venv"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}[STEP]${NC} ${BOLD}$1${NC}"; }

# GUI dialogs (macOS native)
notify() {
    osascript -e "display notification \"$1\" with title \"MuLa Studio\""
}

dialog() {
    osascript -e "display dialog \"$1\" with title \"MuLa Studio\" buttons {\"OK\"} default button 1"
}

#─────────────────────────────────────────
# System Check
#─────────────────────────────────────────
check_system() {
    step "Checking system"

    # macOS version
    OS_VERSION=$(sw_vers -productVersion)
    log "macOS: $OS_VERSION"

    # Architecture (Intel vs Apple Silicon)
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        log "Apple Silicon detected (MPS acceleration)"
        GPU_MODE="mps"
    else
        log "Intel Mac detected"
        GPU_MODE="cpu"
    fi

    # Disk space
    FREE_SPACE=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$FREE_SPACE" -lt 15 ]]; then
        error "Insufficient disk space! Need 15GB minimum (available: ${FREE_SPACE}GB)"
    fi
    log "Available space: ${FREE_SPACE}GB"

    # RAM
    RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1073741824)}')
    log "RAM: ${RAM_GB}GB"
    if [[ "$RAM_GB" -lt 8 ]]; then
        warn "RAM is less than 8GB. Performance may be limited."
    fi
}

#─────────────────────────────────────────
# Python Environment Setup
#─────────────────────────────────────────
install_python_env() {
    step "Setting up Python environment"

    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        error "Python3 is required. Please install Python 3.10+ first."
    fi

    PYTHON_VER=$(python3 --version)
    log "Using: $PYTHON_VER"

    # Create virtual environment
    log "Creating virtual environment..."
    mkdir -p "$INSTALL_DIR"
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"

    pip install --upgrade pip wheel setuptools
    log "Virtual environment ready"
}

#─────────────────────────────────────────
# Install Dependencies
#─────────────────────────────────────────
install_dependencies() {
    step "Installing dependencies"

    source "$VENV_DIR/bin/activate"

    log "Installing PyTorch (${GPU_MODE} mode)..."
    if [[ "$GPU_MODE" == "mps" ]]; then
        pip install torch torchvision torchaudio
    else
        pip install torch torchvision torchaudio
    fi

    log "Installing additional packages..."
    pip install gradio huggingface_hub tqdm

    log "Installing HeartMuLa (heartlib)..."
    pip install git+https://github.com/saintgo7/web-music-heartlib.git
}

#─────────────────────────────────────────
# Download Models
#─────────────────────────────────────────
download_models() {
    step "Downloading AI models (approximately 6GB)"

    source "$VENV_DIR/bin/activate"
    mkdir -p "$MODEL_DIR"

    notify "Downloading models... This may take 10-30 minutes"

    python3 << 'EOF'
from huggingface_hub import snapshot_download
import os

model_dir = os.environ.get('MODEL_DIR')

print("  [1/3] HeartMuLaGen...")
snapshot_download('HeartMuLa/HeartMuLaGen', local_dir=model_dir)

print("  [2/3] HeartMuLa-oss-3B...")
snapshot_download('HeartMuLa/HeartMuLa-oss-3B',
                  local_dir=os.path.join(model_dir, 'HeartMuLa-oss-3B'))

print("  [3/3] HeartCodec-oss...")
snapshot_download('HeartMuLa/HeartCodec-oss',
                  local_dir=os.path.join(model_dir, 'HeartCodec-oss'))

print("✓ Complete!")
EOF

    log "Models downloaded successfully"
}

#─────────────────────────────────────────
# Create App Files
#─────────────────────────────────────────
create_app() {
    step "Creating application files"

    mkdir -p "$INSTALL_DIR/app"

    # Copy main.py from installer resources
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$SCRIPT_DIR/../app/main.py" ]]; then
        cp "$SCRIPT_DIR/../app/main.py" "$INSTALL_DIR/app/"
    else
        # Fallback: create basic app
        log "Creating basic Gradio app..."
        cat > "$INSTALL_DIR/app/main.py" << 'PYEOF'
#!/usr/bin/env python3
import gradio as gr
from pathlib import Path

gr.Markdown("# MuLa Studio\nHeartMuLa AI Music Generator").launch(
    server_name="127.0.0.1",
    server_port=7860,
    inbrowser=True
)
PYEOF
    fi

    chmod +x "$INSTALL_DIR/app/main.py"
    log "App files created"
}

#─────────────────────────────────────────
# Create Launcher Script
#─────────────────────────────────────────
create_launcher() {
    step "Creating launcher"

    cat > "$INSTALL_DIR/run.command" << EOF
#!/bin/bash
source "$VENV_DIR/bin/activate"
open "http://127.0.0.1:7860" 2>/dev/null &
python "$INSTALL_DIR/app/main.py"
EOF

    chmod +x "$INSTALL_DIR/run.command"
    log "Launcher created"

    # Create desktop shortcut
    if [[ -d "$HOME/Desktop" ]]; then
        ln -sf "$INSTALL_DIR/run.command" "$HOME/Desktop/MuLa Studio"
        log "Desktop shortcut created"
    fi
}

#─────────────────────────────────────────
# Create Uninstaller
#─────────────────────────────────────────
create_uninstaller() {
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
echo "Uninstalling MuLa Studio..."
rm -rf "$HOME/.mulastudio"
rm -f "$HOME/Desktop/MuLa Studio"
echo "✓ Uninstall complete!"
echo "Note: Output files in ~/Documents/MuLaStudio_Outputs are preserved"
EOF

    chmod +x "$INSTALL_DIR/uninstall.sh"
    log "Uninstaller created"
}

#─────────────────────────────────────────
# Main Installation Flow
#─────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║   MuLa Studio Installer                               ║${NC}"
    echo -e "${BOLD}║   HeartMuLa AI Music Generator                        ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Start installation? (This will take 15-30 minutes) [Y/n] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0

    check_system
    install_python_env
    install_dependencies
    download_models
    create_app
    create_launcher
    create_uninstaller

    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}✓ Installation Complete!${NC}"
    echo ""
    echo "  To run MuLa Studio:"
    echo "    1. Double-click 'MuLa Studio' on Desktop"
    echo "    2. Or run: ~/.mulastudio/run.command"
    echo ""
    echo "  To uninstall: ~/.mulastudio/uninstall.sh"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"

    read -p "Launch now? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && open "$INSTALL_DIR/run.command"
}

# Run installer
main "$@"
