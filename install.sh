#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Get the dotfiles directory
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install Xcode Command Line Tools (required for Homebrew and development)
if ! xcode-select -p &> /dev/null; then
    echo -e "${YELLOW}Xcode Command Line Tools not found. Installing...${NC}"
    xcode-select --install
    echo -e "${YELLOW}Please complete the Xcode Command Line Tools installation in the dialog.${NC}"
    echo -e "${YELLOW}After installation completes, press any key to continue...${NC}"
    read -n 1 -s -r
else
    echo -e "${GREEN}Xcode Command Line Tools already installed${NC}"
fi

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo -e "${YELLOW}  $target already exists${NC}"
        read -p "  Overwrite? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$target"
        else
            echo -e "${YELLOW}  Skipped $target${NC}"
            return
        fi
    fi

    # Remove extended attributes from source file (e.g., com.apple.provenance)
    # These can prevent files from being readable through symlinks
    xattr -c "$source" 2>/dev/null || true

    ln -s "$source" "$target"
    echo -e "${GREEN}  Linked: $target -> $source${NC}"
}

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}Homebrew already installed${NC}"
fi

# Link shell configs
echo -e "\n${GREEN}Linking shell configuration files...${NC}"
create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/shell/.zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/shell/.zprofile" "$HOME/.zprofile"
create_symlink "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
create_symlink "$DOTFILES_DIR/shell/.profile" "$HOME/.profile"

# Link git config
echo -e "\n${GREEN}Linking git configuration...${NC}"
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Link SSH config
echo -e "\n${GREEN}Linking SSH configuration...${NC}"
mkdir -p "$HOME/.ssh"
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    create_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    if [ -L "$HOME/.ssh/config" ]; then
        chmod 600 "$HOME/.ssh/config"
    fi
fi

# Link .npmrc
echo -e "\n${GREEN}Linking npm configuration...${NC}"
if [ -f "$DOTFILES_DIR/.npmrc" ]; then
    create_symlink "$DOTFILES_DIR/.npmrc" "$HOME/.npmrc"
fi

# Link .config files (if any exist in the repo)
if [ -d "$DOTFILES_DIR/config" ] && [ "$(ls -A $DOTFILES_DIR/config)" ]; then
    echo -e "\n${GREEN}Linking .config files...${NC}"
    mkdir -p "$HOME/.config"
    for config in "$DOTFILES_DIR/config"/*; do
        if [ -e "$config" ]; then
            config_name=$(basename "$config")
            create_symlink "$config" "$HOME/.config/$config_name"
        fi
    done
fi

# Install Rust via rustup (before brew bundle, so cargo packages can install)
if ! command -v rustup &> /dev/null; then
    echo -e "\n${GREEN}Installing Rust via rustup...${NC}"
    read -p "Install Rust? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        echo -e "${GREEN}Rust installed successfully!${NC}"
    else
        echo -e "${YELLOW}Skipped Rust installation${NC}"
    fi
else
    echo -e "${GREEN}Rust already installed${NC}"
fi

# Install Homebrew packages
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo -e "\n${GREEN}Installing Homebrew packages from Brewfile...${NC}"
    read -p "Install Homebrew packages? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew bundle --file="$DOTFILES_DIR/Brewfile"

        # Configure TouchID for sudo via Mole
        if command -v mo &> /dev/null; then
            echo -e "\n${GREEN}Setting up TouchID for sudo commands...${NC}"
            mo touchid
        fi
    else
        echo -e "${YELLOW}Skipped Homebrew package installation${NC}"
    fi
fi

# Install Node.js LTS via fnm and OpenAI Codex CLI
if command -v fnm &> /dev/null; then
    echo -e "\n${GREEN}Installing Node.js LTS via fnm...${NC}"
    read -p "Install Node.js LTS and OpenAI Codex CLI? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Install and use LTS Node.js
        fnm install --lts
        fnm use lts-latest
        eval "$(fnm env --shell bash)"

        # Install OpenAI Codex CLI
        echo -e "${GREEN}Installing @openai/codex...${NC}"
        npm install -g @openai/codex
        echo -e "${GREEN}Node.js LTS and OpenAI Codex CLI installed successfully!${NC}"
    else
        echo -e "${YELLOW}Skipped Node.js and Codex CLI installation${NC}"
    fi
else
    echo -e "${YELLOW}fnm not found. Install Homebrew packages first.${NC}"
fi

# Apply macOS system preferences
if [ -f "$DOTFILES_DIR/macos-defaults.sh" ]; then
    echo -e "\n${GREEN}Apply macOS system preferences?${NC}"
    echo -e "This will configure Finder, Dock, keyboard, screenshots, and more."
    read -p "Run macos-defaults.sh? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x "$DOTFILES_DIR/macos-defaults.sh"
        "$DOTFILES_DIR/macos-defaults.sh"
    else
        echo -e "${YELLOW}Skipped macOS defaults. You can run it later with: ./macos-defaults.sh${NC}"
    fi
fi

echo -e "\n${GREEN}Dotfiles installation complete!${NC}"
echo -e "${YELLOW}Note: You may need to restart your shell for changes to take effect.${NC}"

echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}IMPORTANT: Manual steps required${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${GREEN}2. Generate SSH keys (if needed):${NC}"
echo -e "   ${YELLOW}ssh-keygen -t ed25519 -C \"your_email@example.com\"${NC}"
echo -e "   Then add to GitHub: https://github.com/settings/ssh/new"

echo -e "\n${GREEN}3. Download and install CapCut:${NC}"
echo -e "   https://www.capcut.com/activity/download_pc"

echo -e "\n${GREEN}4. Sign in to apps:${NC}"
echo -e "   - 1Password (enable CLI and SSH agent integration)"
echo -e "   - GitHub CLI: ${YELLOW}gh auth login${NC}"
echo -e "   - Raycast, Bartender, CleanShot X, Linear, Slack, etc."

echo -e "\n${GREEN}5. Restart your shell:${NC}"
echo -e "   ${YELLOW}exec zsh${NC}"
echo -e "\n${YELLOW}consider rebooting for some macOS settings to take effect${NC}"
echo -e "${YELLOW}========================================${NC}\n"
