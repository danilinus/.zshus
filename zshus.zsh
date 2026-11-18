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
    # compinit не перезаписывает дамп, если набор функций не изменился,
    # без touch полная проверка шла бы при каждом запуске
    touch "$_zshus_zcompdump"
fi
# Скомпилированный дамп (.zwc) загружается быстрее, compinit подхватит его сам
[[ "$_zshus_zcompdump.zwc" -nt "$_zshus_zcompdump" ]] || zcompile "$_zshus_zcompdump" 2>/dev/null
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

# Иначе виджеты перепривязываются перед каждым промптом (~50 мс на rpi)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
source "$ZSHUS/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# Плагин привязывает виджеты в precmd, т.е. до первого промпта — запустим сами позже
add-zsh-hook -d precmd _zsh_autosuggest_start

# Привязка виджетов autosuggestions (~80 мс на rpi) и загрузка
# zsh-syntax-highlighting (~15 мс) откладываются до отрисовки первого промпта:
# /dev/null всегда готов к чтению, и zle вызовет обработчик, как только начнёт
# ждать ввода. Нажатые за это время клавиши не теряются. Заодно оба плагина видят
# виджеты из ~/.zshrc, а highlighting загружается последним, как он требует
_zshus_load_deferred() {
    _zsh_autosuggest_start
    source "$ZSHUS/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}

if [[ -o zle ]]; then
    _zshus_load_deferred_widget() {
        local fd=$1
        zle -F $fd
        exec {fd}<&-
        _zshus_load_deferred
        zle -R
    }
    zle -N _zshus_load_deferred_widget
    exec {_zshus_fd}</dev/null
    zle -F -w $_zshus_fd _zshus_load_deferred_widget
    unset _zshus_fd
else
    _zshus_load_deferred
fi

# ---------- Local overrides ----------

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
