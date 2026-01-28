#!/bin/bash
# WSL Development Environment Setup Script
# Created: 2026-01-27
#
# Purpose: Restore base dev environment after Windows reimage
# This sets up the essentials to get back to coding quickly.
#
# Quick install from fresh WSL (copy/paste this one-liner):
#   curl -fsSL https://raw.githubusercontent.com/mdc159/claude-code-templates/main/scripts/wsl-setup.sh | bash
#
# Or download and run manually:
#   curl -fsSL https://raw.githubusercontent.com/mdc159/claude-code-templates/main/scripts/wsl-setup.sh -o wsl-setup.sh
#   chmod +x wsl-setup.sh
#   ./wsl-setup.sh
#
# Note: Some steps require sudo and will prompt for password

set -e  # Exit on error

echo "=== WSL Dev Environment Setup ==="
echo ""

# --- Create projects directory ---
echo "[1/5] Creating projects directory..."
mkdir -p ~/projects
cd ~/projects
echo "Created ~/projects"

# --- Git Config ---
echo ""
echo "[2/6] Configuring Git..."
git config --global user.name "mdc159"
git config --global user.email "mike5150@protonmail.ch"
git config --global init.defaultBranch main
git config --global pull.rebase false
echo "Git configured: $(git config --global user.name) <$(git config --global user.email)>"

# --- SSH Setup for GitHub ---
echo ""
echo "[3/6] Setting up SSH for GitHub..."

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "mdc159@github" -f ~/.ssh/id_ed25519 -N ""
    echo ""
    echo "!!! ACTION REQUIRED !!!"
    echo "Add this key to GitHub (Settings > SSH and GPG Keys > New SSH Key):"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    read -p "Press Enter after adding the key to GitHub..."
else
    echo "SSH key already exists."
fi

# Auto-start SSH agent in .bashrc
if ! grep -q "ssh-agent" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'BASHRC'

# Auto-start SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
BASHRC
    echo "Added SSH agent auto-start to .bashrc"
fi

eval "$(ssh-agent -s)" > /dev/null
ssh-add ~/.ssh/id_ed25519 2>/dev/null
echo "SSH setup complete."

# --- Node.js 22 ---
echo ""
echo "[4/6] Installing Node.js 22..."

if ! command -v node &> /dev/null || [[ $(node -v | cut -d'.' -f1 | tr -d 'v') -lt 22 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js $(node -v) installed."
else
    echo "Node.js $(node -v) already installed."
fi

# --- AWS CLI ---
echo ""
echo "[5/6] Setting up AWS CLI..."

if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    cd ~/projects
    echo "AWS CLI installed."
else
    echo "AWS CLI already installed: $(aws --version | cut -d' ' -f1)"
fi

if ! aws sts get-caller-identity &> /dev/null 2>&1; then
    echo ""
    echo "!!! ACTION REQUIRED !!!"
    echo "Configure AWS CLI:"
    echo "  aws configure"
    echo "    - Region: us-east-2"
    echo "    - Output: json"
    read -p "Press Enter after configuring AWS CLI..."
else
    echo "AWS CLI configured."
fi

# --- Playwright MCP for Claude Code ---
echo ""
echo "[6/6] Installing Playwright MCP (browser automation)..."

if ! command -v npx &> /dev/null; then
    echo "npx not found, skipping Playwright. Install Node.js first."
else
    sudo npm install -g @playwright/mcp 2>/dev/null || echo "Playwright MCP install failed (may need manual sudo)"
    npx playwright install chromium 2>/dev/null || echo "Chromium install may need: npx playwright install chromium"
    sudo npx playwright install-deps chromium 2>/dev/null || echo "Browser deps may need: sudo npx playwright install-deps chromium"
    echo "Playwright setup complete."
fi

# --- Configure Claude Code MCP ---
mkdir -p ~/.claude

if [ ! -f ~/.claude/settings.json ]; then
    cat > ~/.claude/settings.json << 'EOF'
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
EOF
    echo "Created ~/.claude/settings.json with Playwright MCP"
fi

# --- Summary ---
echo ""
echo "==========================================="
echo "  WSL Dev Environment Setup Complete"
echo "==========================================="
echo ""
echo "Installed:"
echo "  - Git (mdc159 <mike5150@protonmail.ch>)"
echo "  - SSH key for GitHub (~/.ssh/id_ed25519)"
echo "  - Node.js $(node -v 2>/dev/null || echo 'pending')"
echo "  - AWS CLI"
echo "  - Playwright MCP for Claude Code"
echo ""
echo "Directory: ~/projects"
echo ""
echo "Next steps:"
echo "  1. source ~/.bashrc"
echo "  2. ssh -T git@github.com  (verify GitHub)"
echo "  3. aws sts get-caller-identity  (verify AWS)"
echo "  4. Clone your repos into ~/projects/"
echo ""
