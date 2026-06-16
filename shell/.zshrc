export PNPM_HOME="$HOME/Library/pnpm"
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH
export NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1

# PATH as zsh array (U = unique, prevents duplicates)
typeset -aU path
path=(
  $HOME/.local/bin
  $HOME/go/bin
  $HOME/.deno/bin
  $HOME/.console-ninja/.bin
  $JAVA_HOME/bin
  $BUN_INSTALL/bin
  $HOME/.air
  /opt/homebrew/bin/go/bin
  $HOME/.codeium/windsurf/bin
  /opt/homebrew/opt/postgresql@14/bin
  $HOME/.antigravity/antigravity/bin
  $PNPM_HOME
  $HOME/.iximiuz/labctl/bin
  /opt/homebrew/bin
  /usr/local/bin
  /usr/bin
  /bin
  $path
)
export PATH

# Zsh history filtering - runs before adding commands to history
zshaddhistory() {
  local line="${1%%$'\n'}"
  # skip if leading whitespace or matches noise pattern
  [[ "$line" =~ "^[[:space:]]" ]] && return 1
  [[ "$line" =~ "^(ls|cd|pwd|exit|clear|history|cd \.\.|security)$" ]] && return 1
  return 0
}

setopt autocd
setopt auto_pushd
setopt pushd_ignore_dups
setopt share_history
setopt append_history
setopt extended_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_reduce_blanks
setopt extended_glob
setopt interactive_comments
setopt no_beep
setopt nocaseglob
setopt hist_verify
setopt chase_links
WORDCHARS=${WORDCHARS//\/}

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
REPORTTIME=3
TIMEFMT="%U user %S system %P cpu %*E total"

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
alias dotfiles='/opt/homebrew/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias g='git'
alias code='code-insiders'
alias p='pnpm'
alias pi='pnpm i'
alias wd='windsurf -r'
alias rimraf='rm -rf'
alias mermaid='mmdc'
alias sniffly='uvx sniffly init'
alias ls='eza'
alias reset='stty sane'
alias dd='devin-desktop'
alias sudo='sudo '

# Docker aliases
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias mini='ssh nickytonline@jump@ssh.maisonlab.dev -p 2200'
alias tiny='ssh nickytonline@tiny@ssh.maisonlab.dev -p 2200'

rmmerged() {
  git branch --merged | grep -v "^\\*\\|master\\|main" | xargs -r -n 1 git branch -d
  git remote prune origin
}

nb() {
  if [ -z "$1" ]; then
    echo "Usage: nb <branch-name>"
    return 1
  fi

  gh_user="$(gh api user --jq .login)"
  branch="$1"
  git checkout -b "$gh_user/$branch"
}

glog() {
  git log --oneline --decorate --graph --color | less -R
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

cb() {
  if [ -z "$1" ]; then
    echo "Usage: cb <file> - Copy file contents to clipboard" >&2
    return 1
  fi
  cat "$@" | pbcopy
}

take() {
  mkdir -p "$1" && cd "$1"
}

export GPG_TTY=$(tty 2>/dev/null)
export STARSHIP_CONFIG=~/.config/starship.toml
export LESS="-R -F -X -i"
export LESSHISTFILE=-

# Initialize completion system (rebuild cache only once per day)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Cache labctl completion (regenerate only when binary updates)
if [[ ! -f ~/.zsh_labctl_cache || ~/.zsh_labctl_cache -ot "$HOME/.iximiuz/labctl/bin/labctl" ]]; then
  "$HOME/.iximiuz/labctl/bin/labctl" completion zsh > ~/.zsh_labctl_cache 2>/dev/null
fi
[[ -f ~/.zsh_labctl_cache ]] && source ~/.zsh_labctl_cache
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
eval "$(fzf --zsh)"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh_cache"

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# Other shell integrations - idempotent so source ~/.zshrc is safe
(( ! ${+functions[_atuin_precmd]} )) && eval "$(atuin init zsh --disable-up-arrow)"
(( ! ${+functions[__zoxide_pwd]} )) && eval "$(zoxide init zsh)"
(( ! ${+functions[_mise_hook]} )) && eval "$(mise activate zsh)"
(( ! ${+functions[prompt_starship_precmd]} )) && eval "$(starship init zsh)"



