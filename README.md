# Dotfiles

My personal dotfiles and system configuration for macOS.

## Contents

- `Brewfile` - Homebrew packages, casks, and Mac App Store apps
- `shell/` - Shell configuration files (.zshrc, .zshenv, .zprofile, .bashrc, .profile)
- `git/` - Git configuration
- `ssh/` - SSH configuration (not keys!)
- `config/` - Application configs (starship, gh, atuin, etc.)
- `.npmrc` - npm configuration
- `install.sh` - Bootstrap script to set up a new machine
- `macos-defaults.sh` - macOS system preferences and settings

## Fresh macOS Installation

### Prerequisites

Before starting, make sure you have:
- Signed into your Apple ID
- Installed pending macOS updates

### Installation Steps

1. **Clone this repository:**
   ```bash
   git clone https://github.com/nickytonline/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Run the install script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

   The install script will:
   - Install Xcode Command Line Tools
   - Install Homebrew
   - Create symlinks for all dotfiles
   - Install Rust via rustup
   - Install all packages from Brewfile (brew, casks, Mac App Store apps)
   - Install Node.js LTS via fnm
   - Install OpenAI Codex CLI via npm

3. **Apply macOS system preferences (optional):**
   ```bash
   chmod +x macos-defaults.sh
   ./macos-defaults.sh
   ```

   This configures:
   - Finder settings (show hidden files, extensions, path bar)
   - Dock settings (size, autohide, animations)
   - Keyboard settings (fast repeat rate, disable auto-correct)
   - Trackpad settings (tap to click)
   - Screenshot settings (PNG format, no shadow)
   - Safari settings (show full URL, enable dev tools)
   - And more...

4. **Restart your shell:**
   ```bash
   exec zsh
   ```

### Manual Steps

Some things need to be set up manually:

#### SSH Keys
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add to GitHub
cat ~/.ssh/id_ed25519.pub | pbcopy
# Then go to: https://github.com/settings/ssh/new
```

#### GPG Keys
```bash
# Import existing GPG keys or create new ones
gpg --import /path/to/private-key.asc

# List keys
gpg --list-secret-keys --keyid-format=long

# Configure git to use GPG key
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

#### 1Password
- Sign in to 1Password
- Enable 1Password CLI integration
- Set up SSH agent integration (Settings → Developer → SSH Agent)

#### App-Specific Setup
- **Raycast**: Sign in and sync settings
- **Bartender**: Configure menu bar items
- **CleanShot X**: Sign in and configure shortcuts
- **GitHub CLI**: `gh auth login`
- **Linear**: Sign in
- **Slack**: Sign in to workspaces
- **Discord**: Sign in
- **Spotify**: Sign in

#### macOS Settings Not in Script
- System Settings → Desktop & Dock → Hot Corners
- System Settings → Trackpad → More Gestures
- System Settings → Sound → Sound Effects (customize)
- System Settings → Displays → Arrangement (if multiple monitors)
- System Settings → Privacy & Security → Full Disk Access (grant to apps)

## Maintenance

### Update Brewfile
After installing/uninstalling apps:
```bash
cd ~/dotfiles
brew bundle dump --force
git add Brewfile
git commit -m "Update Brewfile"
git push
```

### Update Dotfiles
After making changes to your config files:
```bash
cd ~/dotfiles
git add -A
git commit -m "Update dotfiles"
git push
```

### Sync Config Changes
Since your dotfiles are symlinked, any changes you make to `~/.zshrc`, `~/.gitconfig`, etc. are automatically reflected in the repo. Just commit and push!

### Update Installed Software
```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Rust
rustup update

# Update Node.js (via fnm)
fnm install --lts
fnm use lts-latest

# Update global npm packages
npm update -g

# Update macOS App Store apps
mas upgrade
```

## File Structure

```
~/dotfiles/
├── Brewfile              # Homebrew packages and apps
├── README.md             # This file
├── install.sh            # Installation script
├── macos-defaults.sh     # macOS preferences
├── .npmrc                # npm configuration
├── .gitignore            # Git ignore rules
├── shell/                # Shell configs
│   ├── .zshrc
│   ├── .zshenv
│   ├── .zprofile
│   ├── .bashrc
│   └── .profile
├── git/                  # Git config
│   └── .gitconfig
├── ssh/                  # SSH config (no keys!)
│   └── config
└── config/               # App configs
    ├── starship.toml     # Prompt configuration
    ├── gh/               # GitHub CLI
    └── atuin/            # Shell history sync
```

## Philosophy

- **Symlinks over copies**: Changes to dotfiles are automatically tracked
- **Comprehensive but flexible**: Install script prompts for each major step
- **Security conscious**: Never commit secrets, tokens, or private keys
- **Reproducible**: Fresh Mac → run install.sh → productive environment
