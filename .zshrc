# Suppress "Last login" message
[ ! -f ~/.hushlogin ] && touch ~/.hushlogin

export PATH="/usr/local/bin:/Users/gokul/Downloads/Apps/flutter/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# History settings (powers autosuggestions + substring search)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # share across sessions
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_REDUCE_BLANKS     # trim whitespace

export CLAUDE_CODE_NO_FLICKER=1

yolo() {
  if [ -n "$1" ]; then
    if [ -n "$2" ]; then
      # Custom base branch: create worktree manually then launch claude in it
      local repo_root="$(git rev-parse --show-toplevel)"
      local worktree_dir="$repo_root/.claude/worktrees/$1"
      git worktree add -b "worktree-$1" "$worktree_dir" "$2" && \
        (cd "$worktree_dir" && claude --dangerously-skip-permissions)
    else
      claude --dangerously-skip-permissions -w "$1"
    fi
  else
    claude --dangerously-skip-permissions
  fi
}
alias cls="clear"
mkcd() { mkdir -p "$1" && cd "$1"; }

# eza aliases (modern ls replacement)
alias ls="eza"
alias ll="eza -l --git"
alias la="eza -la --git"
alias lt="eza --tree --level=2"
alias pogo="ssh -i ~/.ssh/pi5 pogo@192.168.0.190"

# zsh-completions (adds fpath before compinit)
fpath=(~/.zsh/zsh-completions/src $fpath)

# Initialize completion system (required before fzf-tab)
autoload -Uz compinit && compinit

# fzf-tab (must be loaded AFTER compinit, BEFORE other plugins)
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# zoxide (replaces z.sh)
eval "$(zoxide init zsh)"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# Use fd instead of find for fzf (faster, respects .gitignore)
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"

# fzf keybindings + completion
source <(fzf --zsh)
bindkey '^H' fzf-history-widget      # Ctrl+H — fuzzy history search
bindkey '^F' fzf-file-widget         # Ctrl+F — fuzzy file search
bindkey '^G' fzf-cd-widget           # Ctrl+G — fuzzy cd into directory

# Starship prompt
eval "$(starship init zsh)"

# System info splash
fastfetch

# Use Arc Browser for Flutter web development
export CHROME_EXECUTABLE="/Applications/Arc.app/Contents/MacOS/Arc"

# bun completions
[ -s "/Users/gokul/.bun/_bun" ] && source "/Users/gokul/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Google Cloud SDK
source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
