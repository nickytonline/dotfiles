export PNPM_HOME="$HOME/Library/pnpm"
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.deno/bin:$HOME/.console-ninja/.bin:$JAVA_HOME/bin:$BUN_INSTALL/bin:$HOME/.air:/opt/homebrew/bin/go/bin:$HOME/.codeium/windsurf/bin:/opt/homebrew/opt/postgresql@14/bin:$HOME/.antigravity/antigravity/bin:$PNPM_HOME:$PATH"

# Set your work GitHub org (e.g., "mycompany") for nb/db branch functions
# Leave empty to use simple branch names without org prefix
export WORK_ORG=""
export GH_USER=""

# Zsh history filtering - runs before adding commands to history
zshaddhistory() {
  local line="${1%%$'\n'}"
  [[ "$line" =~ "^(ls|cd|pwd|exit|security|cd \.\.)$" ]] && return 1
  return 0
}

setopt autocd
setopt share_history

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Homebrew caching - regenerates cache only when Homebrew updates
if [[ ! -f ~/.zsh_brew_cache || ~/.zsh_brew_cache -ot /opt/homebrew/bin/brew ]]; then
  /opt/homebrew/bin/brew shellenv > ~/.zsh_brew_cache
fi
source ~/.zsh_brew_cache

# Because HomeBrew auto-updates are annoying
export HOMEBREW_NO_AUTO_UPDATE=1

# Lazy load Cargo - defers initialization until first use
cargo() {
  unset -f cargo rustc rustup
  source $HOME/.cargo/env
  cargo "$@"
}
rustc() {
  unset -f cargo rustc rustup
  source $HOME/.cargo/env
  rustc "$@"
}
rustup() {
  unset -f cargo rustc rustup
  source $HOME/.cargo/env
  rustup "$@"
}

# Aliases
alias flushdns='sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder'
alias zshconfig='code ~/.zshrc'
alias nr='npm run'
alias ni='npm i'
alias '$'=''
alias dt='deno task'
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
alias dotfiles='/opt/homebrew/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias g='git'
alias d='deno'
alias c='cursor -r'
alias code='code-insiders'
alias p='pnpm'
alias pi='pnpm i'
alias wd='windsurf -r'
alias rimraf='rm -rf'
alias mermaid='mmdc'
alias sniffly='uvx sniffly init'

# Docker aliases
alias du='docker compose up -d'
alias dd='docker compose down'

alias gt='@g'

rmmerged() {
  git branch --merged | grep -v "*" | grep -v "master" | xargs -n 1 git branch -d && git remote prune origin
}

nb() {
  if [ -z "$1" ]; then
    echo "Usage: nb <branch-name>"
    return 1
  fi

  branch="$1"

  if [ -n "$WORK_ORG" ]; then
    # Check if current repo is the work org, if so use username prefix
    if git remote -v | grep -q "git@github.com:$WORK_ORG/"; then
      git checkout -b "$GH_USER/$branch"
    else
      git checkout -b "$branch"
    fi
  else
    echo "ℹ️  WORK_ORG not set. Creating branch without org prefix."
    echo "   Set WORK_ORG in your ~/.zshrc if you want org-specific branch names."
    git checkout -b "$branch"
  fi
}

db() {
  if [ -z "$1" ]; then
    echo "Usage: db <branch-name>"
    return 1
  fi

  branch="$1"

  if [ -n "$WORK_ORG" ]; then
    # Check if current repo is the work org, if so use username prefix
    if git remote -v | grep -q "git@github.com:$WORK_ORG/"; then
      git branch -D "$(git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '')/$branch"
    else
      git branch -D "$branch"
    fi
  else
    echo "ℹ️  WORK_ORG not set. Deleting branch without org prefix."
    echo "   Set WORK_ORG in your ~/.zshrc if you want org-specific branch names."
    git branch -D "$branch"
  fi
}

glog() {
  git log --oneline --decorate --graph --color | less -R
}

openai_key() {
  export OPENAI_API_KEY=$(security find-generic-password -a $USER -s openai_api_key -w)
}

cpr() {
  pr="$1"
  remote="${2:-origin}"
  branch=$(gh pr view "$pr" --json headRefName -q .headRefName)
  git fetch "$remote" "$branch"
  git worktree add "../$branch" "$branch"
  cd "../$branch" || return
  echo "Switched to new worktree for PR #$pr: $branch"
}

export GPG_TTY=$(tty)
export STARSHIP_CONFIG=~/.config/starship.toml


# Pyenv lazy loading - defers initialization until first use
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
pyenv() {
  unset -f pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# Initialize completion system
autoload -Uz compinit && compinit -C

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Lazy load Starship - defers initialization until first prompt
starship_init() {
  eval "$(starship init zsh)"
  precmd_functions=(${precmd_functions:#starship_init})
}
precmd_functions+=(starship_init)
PROMPT='$(goose term info) %~ $ '

eval "$(atuin init zsh --disable-up-arrow)"
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(zoxide init zsh)"
eval "$(goose term init zsh)"
