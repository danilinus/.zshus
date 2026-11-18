# Подавление предупреждений setlocal для Termux
if [[ "$(uname -o 2>/dev/null)" != "Android" ]]; then
    # export всегда успешен, поэтому наличие локали проверяем через locale -a
    if locale -a 2>/dev/null | grep -qiE '^ru_RU\.utf-?8$'; then
        _zshus_lang="ru_RU.UTF-8"
    elif locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then
        _zshus_lang="C.UTF-8"
    fi
    if [[ -n "$_zshus_lang" ]]; then
        export LANG="$_zshus_lang"
        export LC_ALL="$_zshus_lang"
    fi
    unset _zshus_lang
fi

PATH="$PATH:$HOME/bin"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:/usr/local/bin"
PATH="$PATH:/usr/local/bin/BashScripts"

export PATH="$PATH"
export CPPFLAGS="-I/usr/local/opt/binutils/include"
export LDFLAGS="-I/usr/local/opt/binutils/lib"
export EDITOR='nano'
export ANDROID_SDK_ROOT="/mnt/c/Users/danila/AppData/Local/Android/Sdk"
export ANDROID_NDK_ROOT="/mnt/c/Users/danila/AppData/Local/Android/Sdk/ndk/29.0.14206865"
