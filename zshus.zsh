export ZSHUS="$HOME/.zshus"

source "$ZSHUS/exports.zsh"
source "$ZSHUS/aliases.zsh"
source "$ZSHUS/bindings.zsh"
source "$ZSHUS/prompt.zsh"

source "$ZSHUS/brew.zsh"

# man with syntax highlighting using bat (if installed)
if command -v bat &>/dev/null; then
    export MANPAGER="sh -c 'col -bx | bat --language=man --plain --theme=default'"
    export MANROFFOPT="-c"
fi

# ignore comments
setopt INTERACTIVE_COMMENTS

# ---------- Fast completion ----------
autoload -Uz compinit
# полная проверка дампа раз в сутки, в остальное время быстрый запуск (-C)
_zshus_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zshus.zcompdump"
_zshus_fresh=("$_zshus_zcompdump"(N.mh-24))
if (( ${#_zshus_fresh} )); then
    compinit -C -d "$_zshus_zcompdump"
else
    compinit -d "$_zshus_zcompdump"
fi
unset _zshus_zcompdump _zshus_fresh

setopt PROMPT_SUBST

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# ---------- New Line ----------
function insert-linebreak {
    LBUFFER+=$'\n'
}

zle -N insert-linebreak

# ---------- sudo at start ----------
sudo-command-line() {
    if [[ $BUFFER == sudo\ * ]]; then
        ((CURSOR -= 5))
        BUFFER="${BUFFER#sudo }"
    else
        BUFFER="sudo $BUFFER"
        ((CURSOR += 5))
    fi
    zle reset-prompt
}

zle -N sudo-command-line

# ---------- History file ----------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# ---------- Plugins ----------

source "$ZSHUS/plugins/fzf-tab/fzf-tab.plugin.zsh"
source "$ZSHUS/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSHUS/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
