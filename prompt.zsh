get_system_color() {
    # Проверяем поддержку TrueColor
    local truecolor_support=false
    if [[ "$COLORTERM" =~ ^(truecolor|24bit)$ ]] || [[ "$TERM" =~ ^(xterm-kitty|alacritty|wezterm|foot) ]]; then
        truecolor_support=true
    fi

    local os_type=""

    if [[ "$(uname -o 2>/dev/null)" == "Android" ]] || \
       [[ -d /system/app ]] || \
       [[ -d /data/data/com.termux ]] || \
       [[ -n "$PREFIX" && "$PREFIX" == "/data/data/com.termux/files/usr" ]] || \
       getprop ro.build.version.sdk &>/dev/null; then
        os_type="android"
    elif grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
	os_type="wsl"
    elif grep -qi "raspbian" /etc/os-release 2>/dev/null; then
        os_type="raspbian"
    elif grep -qi "debian" /etc/os-release 2>/dev/null; then
        os_type="debian"
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        os_type="ubuntu"
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

    # Возвращаем цвет в зависимости от ОС и поддержки TrueColor
    case "$os_type" in
        raspbian)
            $truecolor_support && echo "38;2;200;50;80" || echo "31" ;;  # Малиновый красный
        debian)
            $truecolor_support && echo "38;2;215;0;85" || echo "31" ;;   # Debian red #D70055
        ubuntu)
            $truecolor_support && echo "38;2;233;84;32" || echo "38;5;208" ;;  # Ubuntu orange #E95420
        arch)
            $truecolor_support && echo "38;2;23;147;209" || echo "96" ;; # Arch blue #1793D1
        fedora)
            $truecolor_support && echo "38;2;60;110;180" || echo "94" ;; # Fedora blue #3C6EB4
        android)
            echo "92" ;; # Android green #A4C639
        windows|wsl)
            echo "94" ;;  # Windows blue
        macos)
            $truecolor_support && echo "38;2;160;90;210" || echo "95" ;; # macOS purple
        *)
            echo "37" ;;
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
  command git rev-parse --git-dir > /dev/null 2>&1 || return

  if ! command git diff --no-ext-diff --quiet --cached 2>/dev/null || \
     ! command git diff --no-ext-diff --quiet 2>/dev/null; then
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

# ---------- Prompt ----------
precmd() {
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

  PROMPT='
${TITLE_COLOR}╭─'"$(python_env)"'${NAME_COLOR}%n ${PLEA_COLOR}at ${SYSTEM_COLOR}%m ${PLEA_COLOR}in ${PATH_COLOR}%~${vcs_info_msg_0_}$(git_dirty)%f
${TITLE_COLOR}╰'"${EXIT}${SYMBOL}"' '
}
