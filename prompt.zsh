# Спрашиваем сам терминал: включаем цвет 38;2;1;2;3 и запрашиваем текущий SGR (DECRQSS).
# Терминал с TrueColor вернёт этот же цвет, остальные — другой цвет или ничего.
# Следом отправляем DA1 (\e[c): на него отвечают все терминалы, поэтому таймаут
# не ждём, а читаем ответ до конца DA1. Работает и через ssh, где переменных окружения нет.
_zshus_query_truecolor() {
    [[ -t 0 && -t 1 && "$TERM" != (dumb|linux) ]] || return 1

    local stty_saved reply="" char
    stty_saved=$(stty -g 2>/dev/null) || return 1
    stty -echo -icanon 2>/dev/null

    print -rn -- $'\e[38;2;1;2;3m\eP$qm\e\\\e[0m\e[c'
    while read -rk 1 -t 0.5 -u 0 char; do
        reply+=$char
        [[ "$reply" == *$'\e[?'*c ]] && break
    done

    stty "$stty_saved" 2>/dev/null

    # Ответ: \eP1$r<SGR>m\e\\, разделители бывают как ";", так и ":"
    [[ "${reply//:/;}" == *'$r'*'38;2;'(|';'|'0;')'1;2;3'[\;m]* ]]
}

_zshus_detect_truecolor() {
    [[ "$COLORTERM" == (truecolor|24bit) ]] && return 0
    [[ "$TERM" =~ ^(xterm-kitty|xterm-ghostty|alacritty|wezterm|foot|contour|rio) ]] && return 0
    [[ "$TERM_PROGRAM" =~ ^(vscode|Hyper|Tabby|Warp|iTerm.app|ghostty|WezTerm)$ ]] && return 0
    [[ -n "$WT_SESSION" || "$TERM_PROGRAM" == "Windows Terminal" ]] && return 0
    if [[ -n "$TMUX" ]]; then
        [[ "$(tmux display-message -p '#{client_termfeatures}' 2>/dev/null)" == *RGB* ]]
        return
    fi
    # Переменных нет (ssh, Terminal.app и т.п.) — спрашиваем терминал.
    # tput colors тут не подходит: 256 цветов — это ещё не TrueColor
    _zshus_query_truecolor || return 1
    # Сообщаем результат дочерним программам (vim, bat, вложенный zsh)
    export COLORTERM=truecolor
}

# Результат кэшируется в ZSHUS_TRUECOLOR, терминал опрашивается один раз за сессию.
# Первый вызов должен быть в основном shell, а не в $(...), иначе кэш потеряется
check_truecolor_support() {
    if [[ -z "$ZSHUS_TRUECOLOR" ]]; then
        ZSHUS_TRUECOLOR=0
        _zshus_detect_truecolor && ZSHUS_TRUECOLOR=1
    fi
    (( ZSHUS_TRUECOLOR ))
}

get_system_name() {
    local os_type=""

    if [[ "$(uname -o 2>/dev/null)" == "Android" ]] ||
        [[ -d /system/app ]] ||
        [[ -d /data/data/com.termux ]] ||
        [[ -n "$PREFIX" && "$PREFIX" == "/data/data/com.termux/files/usr" ]] ||
        getprop ro.build.version.sdk &>/dev/null; then
        os_type="android"
    elif grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        os_type="wsl"
    elif [ -f /etc/rpi-issue ]; then
        os_type="raspbian"
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        os_type="ubuntu"
    elif grep -qi "debian" /etc/os-release 2>/dev/null; then
        os_type="debian"
    elif grep -qi "arch" /etc/os-release 2>/dev/null; then
        os_type="arch"
    elif grep -qi "fedora" /etc/os-release 2>/dev/null; then
        os_type="fedora"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        os_type="windows"
    elif [[ "$(uname)" == "Darwin" ]]; then
        os_type="macos"
    else
        os_type="unknown"
    fi
    echo "$os_type"
}

get_system_color() {
    # Проверяем поддержку TrueColor
    local truecolor_support=false
    if check_truecolor_support; then
        truecolor_support=true
    fi

    local os_type=${ZSHUS_SYSTEM_NAME:-$(get_system_name)}

    # Возвращаем цвет в зависимости от ОС и поддержки TrueColor
    case "$os_type" in
    raspbian)
        $truecolor_support && echo "38;2;200;50;80" || echo "31"
        ;; # Малиновый красный
    debian)
        $truecolor_support && echo "38;2;215;0;85" || echo "31"
        ;; # Debian red #D70055
    ubuntu)
        $truecolor_support && echo "38;2;233;84;32" || echo "38;5;208"
        ;; # Ubuntu orange #E95420
    arch)
        $truecolor_support && echo "38;2;23;147;209" || echo "96"
        ;; # Arch blue #1793D1
    fedora)
        $truecolor_support && echo "38;2;60;110;180" || echo "94"
        ;; # Fedora blue #3C6EB4
    android)
        echo "92"
        ;; # Android green #A4C639
    windows | wsl)
        echo "94"
        ;; # Windows blue
    macos)
        $truecolor_support && echo "38;2;160;90;210" || echo "95"
        ;; # macOS purple
    *)
        echo "37"
        ;;
    esac
}

# Применение цвета к тексту
apply_system_color() {
    local color_code=$(get_system_color)
    echo -ne "\033[${color_code}m"
}

# ---------- Git ----------
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{10}(%b)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{10}(%b|%a)%f'

# Вызывается после vcs_info: пустой vcs_info_msg_0_ значит, что мы не в репозитории
git_dirty() {
    [[ -n "$vcs_info_msg_0_" ]] || return
    if ! command git diff --quiet HEAD 2>/dev/null; then
        echo "%F{11}*%f"
    fi
}

# ---------- Python env ----------
# Результат в REPLY, чтобы не запускать $(...) на каждом промпте
python_env() {
    REPLY=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
        REPLY="%F{6}(${VIRTUAL_ENV:t})%f "
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        REPLY="%F{6}($CONDA_DEFAULT_ENV)%f "
    elif [[ -n "$PYENV_VERSION" ]]; then
        REPLY="%F{6}($PYENV_VERSION)%f "
    fi
}

# ---------- Статус репозитория zshus ----------
# Сеть нужна только для git fetch: он идёт в фоне не чаще раза в 10 минут.
# Остальное (правки, ↑/↓ относительно origin/main) — локальные git-команды,
# поэтому считается на каждом промпте и всегда соответствует текущему состоянию
: ${ZSHUS_FETCH_INTERVAL:=600}
typeset -i ZSHUS_FETCH_AT=-1

zshus_fetch() {
    local dir="${ZSHUS:-$HOME/.zshus}"
    (( ZSHUS_FETCH_AT >= 0 && SECONDS - ZSHUS_FETCH_AT < ZSHUS_FETCH_INTERVAL )) && return
    ZSHUS_FETCH_AT=$SECONDS

    # Другая сессия недавно уже обновила origin/main
    local -a fresh=("$dir/.git/FETCH_HEAD"(N.mm-$((ZSHUS_FETCH_INTERVAL / 60))))
    (( ${#fresh} )) && return

    GIT_TERMINAL_PROMPT=0 command git -C "$dir" fetch --quiet origin &>/dev/null &!
}

zshus_status() {
    local dir="${ZSHUS:-$HOME/.zshus}"
    [[ -d "$dir/.git" ]] || {
        echo " [.zshus not found]"
        return
    }

    local us_status="" counts ahead behind
    # --no-optional-locks: не мешаем git-командам, запущенным в ~/.zshus
    [[ -n "$(command git --no-optional-locks -C "$dir" status --porcelain 2>/dev/null)" ]] && us_status="*"

    # ↑ — локальные коммиты, которых нет в origin/main, ↓ — новые коммиты в origin/main
    counts=$(command git -C "$dir" rev-list --left-right --count HEAD...origin/main 2>/dev/null)
    read -r ahead behind <<<"$counts"
    (( ahead > 0 )) && us_status+="↑$ahead"
    (( behind > 0 )) && us_status+="↓$behind"

    [[ -n "$us_status" ]] && echo " [us${us_status}]"
}

# ---------- Асинхронная часть промпта ----------
# Всё, что вызывает git (ветка, *, статус zshus), считается в фоновом процессе.
# Промпт рисуется сразу с прошлыми значениями, а когда процесс ответит,
# zle вызовет _zshus_async_done и промпт перерисуется, только если что-то изменилось
typeset -gi _zshus_async_fd=0
typeset -g _zshus_async_pwd="" git_info="" git_stat="" zshus_stat=""

_zshus_async_worker() {
    vcs_info
    local dirty=$(git_dirty) us=$(zshus_status)
    # Пишем всё одним вызовом: обработчик просыпается на первых данных
    # и не должен ждать (блокируя ввод), пока считается остальное
    print -r -- "$vcs_info_msg_0_"$'\n'"$dirty"$'\n'"$us"
}

_zshus_async_start() {
    # Предыдущий запрос ещё не ответил — его результат уже не нужен
    if (( _zshus_async_fd )); then
        zle -F $_zshus_async_fd 2>/dev/null
        exec {_zshus_async_fd}<&-
        _zshus_async_fd=0
    fi

    # В другом каталоге ветка от старого каталога была бы неправдой
    if [[ "$PWD" != "$_zshus_async_pwd" ]]; then
        _zshus_async_pwd=$PWD
        git_info="" git_stat=""
    fi

    exec {_zshus_async_fd}< <(_zshus_async_worker)
    zle -F -w $_zshus_async_fd _zshus_async_done
}

_zshus_async_done() {
    local fd=$1 vcs="" dirty="" us=""
    {
        IFS= read -r vcs
        IFS= read -r dirty
        IFS= read -r us
    } <&$fd
    zle -F $fd
    exec {fd}<&-
    (( fd == _zshus_async_fd )) && _zshus_async_fd=0

    [[ "$vcs" == "$git_info" && "$dirty" == "$git_stat" && "$us" == "$zshus_stat" ]] && return
    git_info=$vcs git_stat=$dirty zshus_stat=$us
    _zshus_build_prompt
    zle reset-prompt
}
zle -N _zshus_async_done

_zshus_build_prompt() {
    PROMPT="
${TITLE_COLOR}${py_env}${NAME_COLOR}%n ${PLEA_COLOR}at ${SYSTEM_COLOR}%m (${ZSHUS_SYSTEM_NAME})${PLEA_COLOR}${zshus_stat} in ${PATH_COLOR}%~${git_info}${git_stat}%f
${TITLE_COLOR}${EXIT}${SYMBOL} "
}

# ---------- Prompt ----------
precmd() {
    local exit_code=$?
    zshus_fetch

    # error code
    if [[ $exit_code -ne 0 ]]; then
        EXIT="%F{9}[$exit_code]%f "
    else
        EXIT=""
    fi

    # root indicator
    if [[ $EUID -eq 0 ]]; then
        SYMBOL="%F{9}#%f"
    else
        SYMBOL="%F{10}$%f"
    fi

    : ${TITLE_COLOR:='%F{15}'}
    : ${NAME_COLOR:='%F{10}'}
    : ${PATH_COLOR:='%F{11}'}
    # ОС за время сессии не меняется, определяем её один раз
    : ${ZSHUS_SYSTEM_NAME:=$(get_system_name)}
    if [[ -z "$SYSTEM_COLOR" ]]; then
        check_truecolor_support # заполняет кэш в основном shell
        SYSTEM_COLOR="%{$(apply_system_color)%}"
    fi
    : ${PLEA_COLOR:='%F{8}'}
    python_env
    py_env=$REPLY

    if [[ -o zle ]]; then
        _zshus_async_start
    else
        # Без zle (нет терминала) перерисовать промпт нельзя — считаем сразу
        vcs_info
        git_info=$vcs_info_msg_0_
        git_stat=$(git_dirty)
        zshus_stat=$(zshus_status)
    fi
    _zshus_build_prompt
    print -Pn "\e]0;%n@%m: %~\a"
}
