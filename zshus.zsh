export ZSHUS="$HOME/.zshus"

source "$ZSHUS/exports.zsh"
source "$ZSHUS/aliases.zsh"
source "$ZSHUS/bindings.zsh"
source "$ZSHUS/prompt.zsh"

source "$ZSHUS/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSHUS/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSHUS/plugins/fzf-tab/fzf-tab.plugin.zsh"

source "$ZSHUS/brew.zsh"

# man with syntax highlighting using bat (if installed)
if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat --language=man --plain --theme=default'"
    export MANROFFOPT="-c"
fi

# ---------- Fast completion ----------
autoload -Uz compinit
compinit -C

setopt PROMPT_SUBST

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# ---------- History file ----------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
