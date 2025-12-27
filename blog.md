# My Journey to a Fully Automated macOS Setup with Dotfiles, Homebrew, and mas

## The Problem: The Fresh Mac Setup Tax

We've all been there. You get a new Mac, or worse, you need to wipe and reinstall macOS. What follows is hours (or days) of:

- Downloading apps one by one
- Configuring shell settings from memory
- Trying to remember which VS Code extensions you had
- Setting up git preferences again
- Tweaking macOS settings to get your Dock *just right*
- Realizing three weeks later that you forgot to install that one crucial tool

I finally decided enough was enough. I wanted a setup where I could go from a fresh Mac to a fully productive development environment in under an hour, with minimal manual intervention.

## Enter Dotfiles: Your Mac in a Git Repo

The concept of dotfiles is simple: all those configuration files that start with a dot (`.zshrc`, `.gitconfig`, etc.) can be version-controlled and shared across machines. But I wanted to go further—I wanted to capture my *entire* Mac setup.

Here's what I ended up with:

```
~/dotfiles/
├── Brewfile              # Every app I use
├── install.sh            # One script to rule them all
├── macos-defaults.sh     # macOS system preferences
├── shell/                # Shell configs (.zshrc, etc.)
├── git/                  # Git configuration
├── ssh/                  # SSH config (no keys!)
└── config/               # App configs (starship, gh, atuin, etc.)
```

## The Magic of Homebrew: Package Management Done Right

If you're on macOS and not using Homebrew, you're missing out. Homebrew is like `apt` or `yum` for macOS, but it's so much more powerful.

What I didn't fully appreciate until this project was Homebrew's **Brewfile** feature. Instead of running `brew install` commands one by one, you can declare everything in a single file:

```ruby
# CLI tools
brew "git"
brew "ripgrep"
brew "fnm"  # Node version manager
brew "starship"  # Beautiful shell prompt

# Desktop apps (casks)
cask "visual-studio-code@insiders"
cask "raycast"
cask "1password"

# VS Code extensions
vscode "esbenp.prettier-vscode"
vscode "github.copilot"

# Go packages
go "github.com/air-verse/air"

# Rust crates
cargo "oha"
```

The killer feature? One command installs everything:

```bash
brew bundle --file=Brewfile
```

## The Discovery: mas - Mac App Store Automation

Here's where things got really interesting. I always thought Mac App Store apps couldn't be automated. Turns out, there's a tool called **`mas`** (Mac App Store CLI) that changes everything.

```ruby
# In your Brewfile
brew "mas"

# Then add Mac App Store apps
mas "Dato", id: 1470584107
mas "Keynote", id: 409183694
mas "Numbers", id: 409203825
mas "TestFlight", id: 899247664
```

When you run `brew bundle`, it installs `mas` first, then uses it to download and install Mac App Store apps automatically. Mind. Blown.

To find app IDs, just search on the Mac App Store website and grab the ID from the URL:

```
https://apps.apple.com/us/app/dato/1470584107
                                    ^^^^^^^^^^
```

## The Install Script: Orchestrating Everything

The heart of the system is a single `install.sh` script that automates the entire setup:

```bash
#!/usr/bin/env bash

# Install Xcode Command Line Tools first
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    read -n 1 -s -r  # Wait for completion
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Symlink all dotfiles
create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
# ... and more

# Install Rust (before brew bundle, so cargo packages work)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install everything from Brewfile
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Install Node.js LTS via fnm
fnm install --lts
npm install -g @openai/codex

# Apply macOS system preferences
./macos-defaults.sh
```

The script is idempotent and prompts for each major step, so you're always in control.

## Capturing macOS Preferences: The Often-Forgotten Part

One thing most dotfiles repos miss is macOS system preferences. Things like:

- Dock position and size
- Finder settings (show hidden files, extensions)
- Keyboard repeat rate
- Screenshot format and location
- Menu bar clock settings

All of these can be automated with `defaults write` commands:

```bash
# Position Dock on the right
defaults write com.apple.dock orientation -string "right"

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Fast keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 2

# Show analog clock with day of week
defaults write com.apple.menuextra.clock IsAnalog -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
```

I created a `macos-defaults.sh` script with both recommended defaults and my personal preferences, commented so I can pick and choose.

## Security: What NOT to Put in Your Dotfiles

This is crucial. Your dotfiles repo will likely be on GitHub, so **never commit**:

- API tokens or credentials
- SSH private keys
- `.npmrc` files with auth tokens
- Work-related hostnames or company names
- Personal email addresses (optional, but I prefer not to)

Instead, use:

```bash
# .gitignore
.npmrc
**/*_token
**/*_key
*.local
.ssh/config_local

# SSH config - use includes for private stuff
Include ~/.ssh/config_local  # Not in repo

Host github.com  # Safe to commit
  AddKeysToAgent yes
```

My install script now prompts for git user info instead of committing it:

```bash
read -p "Enter your name for git commits: " git_name
read -p "Enter your email for git commits: " git_email
git config --global user.name "$git_name"
git config --global user.email "$git_email"
```

## Bonus: Modern Git Signing with SSH

While setting this up, I learned you can sign git commits with SSH keys instead of GPG! No more dealing with GPG key expiration or complex setup:

```bash
# Tell git to use SSH for signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

# Add your SSH key as a "Signing Key" on GitHub
# (not just an authentication key!)
```

GitHub shows commits as "Verified" just like with GPG, but it's way simpler.

## The Result: Fresh Mac to Productive in 30 Minutes

Now when I get a new Mac, the process is:

1. **Clone the repo:**
   ```bash
   git clone https://github.com/nickytonline/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

3. **Say "yes" to the prompts** and watch the magic happen:
   - Xcode Command Line Tools install
   - Homebrew installs
   - 130+ apps download and install automatically
   - All dotfiles symlink
   - Rust, Node.js, and CLI tools set up
   - macOS preferences apply

4. **5 minutes of manual work:**
   - Generate/restore SSH keys
   - Sign into 1Password
   - Run `gh auth login`
   - Sign into a few apps (Slack, Raycast, etc.)

That's it. I'm fully productive.

## Key Learnings

1. **`mas` is a game-changer** - Automate Mac App Store apps
2. **Brewfile can install everything** - Not just brew packages, but casks, VS Code extensions, go packages, and cargo crates
3. **Symlinks > Copies** - Changes to your dotfiles are automatically tracked in git
4. **Security matters** - Use `.gitignore` and includes for sensitive data
5. **macOS defaults are scriptable** - Don't manually configure System Preferences ever again
6. **SSH signing is easier than GPG** - Modern git signing without the complexity

## The Full Setup

My complete dotfiles are on GitHub (private for now, but I might make them public). The key files:

- **Brewfile**: 130+ packages, apps, and tools
- **install.sh**: Automated setup script with prompts
- **macos-defaults.sh**: System preferences automation
- **Shell configs**: `.zshrc` with aliases, functions, and lazy-loading
- **Git config**: Aliases, signing, and credential helpers
- **SSH config**: With includes for private hosts
- **App configs**: Starship, atuin, gh CLI, and more

## Try It Yourself

Setting up dotfiles is easier than you think. Start small:

1. Create a `~/dotfiles` directory
2. Move your `.zshrc` there and symlink it: `ln -s ~/dotfiles/.zshrc ~/.zshrc`
3. Initialize a git repo: `git init`
4. Create a Brewfile: `brew bundle dump`
5. Build from there

Your future self (and your next Mac) will thank you.

## Resources

- [Homebrew](https://brew.sh) - Package manager for macOS
- [mas](https://github.com/mas-cli/mas) - Mac App Store CLI
- [GNU Stow](https://www.gnu.org/software/stow/) - Alternative to manual symlinks
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles) - Inspiration from others

---

*Have you automated your Mac setup? What tools or tricks have you discovered? Let me know in the comments!*
