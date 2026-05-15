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

  TITLE_COLOR='%F{15}'
  NAME_COLOR='%F{10}'
  PATH_COLOR='%F{11}'
  SYSTEM_COLOR='%F{12}'
  PLEA_COLOR='%F{8}'

  PROMPT='
${TITLE_COLOR}╭─'"$(python_env)"'${NAME_COLOR}%n ${PLEA_COLOR}at ${SYSTEM_COLOR}%m ${PLEA_COLOR}in ${PATH_COLOR}%~${vcs_info_msg_0_}$(git_dirty)%f
${TITLE_COLOR}╰'"${EXIT}${SYMBOL}"' '
}
