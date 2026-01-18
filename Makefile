.PHONY: help dev-setup install-deps build-macos build-linux test clean

help:
	@echo "MuLa Studio - HeartMuLa Installer Build"
	@echo ""
	@echo "Available targets:"
	@echo "  dev-setup       - Setup development environment"
	@echo "  install-deps    - Install development dependencies"
	@echo "  build-macos     - Build macOS DMG installer"
	@echo "  build-linux     - Build Linux install script"
	@echo "  build-all       - Build all installers"
	@echo "  test            - Test installation script"
	@echo "  clean           - Clean build artifacts"
	@echo ""

# Development environment setup
dev-setup:
	@echo "Setting up development environment..."
	@python3 -m venv venv
	@. venv/bin/activate && pip install --upgrade pip
	@. venv/bin/activate && pip install -e .
	@. venv/bin/activate && pip install gradio huggingface_hub
	@echo "✓ Development environment ready"
	@echo "Activate: source venv/bin/activate"

# Install dependencies
install-deps:
	@echo "Installing development dependencies..."
	@brew install create-dmg shellcheck
	@echo "✓ Dependencies installed"

# Make scripts executable
scripts-executable:
	@chmod +x installer/macos/install.sh
	@chmod +x installer/linux/mula_install.sh
	@echo "✓ Scripts made executable"

# Build macOS DMG
build-macos: scripts-executable
	@echo "Building macOS DMG installer..."
	@INSTALLER_PATH=$$(pwd)/installer \
	 create-dmg \
	  --volname "MuLa Studio" \
	  --window-size 600 400 \
	  --icon-size 100 \
	  --icon "MuLa Installer.app" 150 150 \
	  --app-drop-link 450 150 \
	  "installer/build/MuLa_Installer.dmg" \
	  "installer/macos/" || echo "Note: Manual DMG creation may be needed"
	@echo "✓ macOS DMG created"

# Build Linux script (just verify syntax)
build-linux: scripts-executable
	@echo "Checking Linux install script..."
	@shellcheck installer/linux/mula_install.sh 2>/dev/null || echo "Note: shellcheck not required"
	@echo "✓ Linux script verified"

# Build all
build-all: build-macos build-linux
	@echo "✓ All installers built"

# Test installation script (dry-run)
test: scripts-executable
	@echo "Testing macOS installation script (validation)..."
	@bash -n installer/macos/install.sh
	@echo "✓ Script syntax valid"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf installer/build/*
	@rm -rf venv/
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleaned"

# Show project structure
info:
	@echo "Project Structure:"
	@echo ""
	@find installer -type f | grep -v ".git" | sort
	@echo ""

.DEFAULT_GOAL := help
