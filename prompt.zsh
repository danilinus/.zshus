check_truecolor_support() {
    [[ "$COLORTERM" =~ ^(truecolor|24bit)$ ]] && return 0
    [[ "$TERM" =~ ^(xterm-kitty|alacritty|wezterm|foot|contour|rio) ]] && return 0
    [[ "$TERM_PROGRAM" =~ ^(vscode|Hyper|Tabby|Warp)$ ]] && return 0
    [[ -n "$WT_SESSION" || "$TERM_PROGRAM" == "Windows Terminal" ]] && return 0
    command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null) -ge 256 ]] && return 0
    return 1
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

    local os_type=$(get_system_name)

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

git_dirty() {
    command git rev-parse --git-dir >/dev/null 2>&1 || return
    if ! command git diff-index --quiet --cached HEAD 2>/dev/null; then
        echo "%F{11}*%f"
    fi
}

# ---------- Python env ----------
python_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "%F{6}($(basename $VIRTUAL_ENV))%f "
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        echo "%F{6}($CONDA_DEFAULT_ENV)%f "
    elif [[ -n "$PYENV_VERSION" ]]; then
        echo "%F{6}($PYENV_VERSION)%f "
    fi
}

# ---------- Фоновая проверка обновления ----------
ZSHUS_STATUS_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/zshus.status"
ZSHUS_CHECK_PID=0
ZSHUS_CHECK_DONE=0

zshus_start_check() {
    [[ -f "$ZSHUS_STATUS_FILE" && $ZSHUS_CHECK_DONE -eq 1 ]] && return
    [[ $ZSHUS_CHECK_PID -ne 0 ]] && kill -0 $ZSHUS_CHECK_PID 2>/dev/null && return

    ZSHUS_CHECK_DONE=1

    {
        us_status=""
        cd "$HOME/.zshus" 2>/dev/null && {
            if bash "./has_local_changes.sh" 2>/dev/null; then
                us_status="*"
            fi
            if bash "./has_remote_updates.sh" 2>/dev/null; then
                us_status="${us_status}↓$(git rev-list --count HEAD..origin/main)"
            fi
        } || us_status="[.zshus not found]"
        echo "$us_status" >"$ZSHUS_STATUS_FILE"
    } 2>/dev/null &!
    ZSHUS_CHECK_PID=$!
}

zshus_status() {
    [[ -f "$ZSHUS_STATUS_FILE" ]] || return

    local us_status=$(<"$ZSHUS_STATUS_FILE")

    [[ -z "$us_status" ]] && return

    echo " [us${us_status}]"
}

# ---------- Prompt ----------
precmd() {
    zshus_start_check

    local exit_code=$?
    vcs_info

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
    : ${SYSTEM_COLOR:=$(apply_system_color)}
    : ${PLEA_COLOR:='%F{8}'}
    py_env=$(python_env)
    git_stat=$(git_dirty)
    sys_nam=$(get_system_name)
    zshus_stat=$(zshus_status)
    PROMPT="
${TITLE_COLOR}${py_env}${NAME_COLOR}%n ${PLEA_COLOR}at ${SYSTEM_COLOR}%m (${sys_nam})${PLEA_COLOR}${zshus_stat} in ${PATH_COLOR}%~${vcs_info_msg_0_}${git_stat}%f
${TITLE_COLOR}${EXIT}${SYMBOL} "
}
