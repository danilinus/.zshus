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

# Дубликаты в PATH убираем, несуществующие каталоги не добавляем
typeset -U path PATH
for _zshus_dir in "$HOME/bin" "$HOME/.local/bin" /usr/local/bin /usr/local/bin/BashScripts; do
    [[ -d "$_zshus_dir" ]] && path+=("$_zshus_dir")
done
unset _zshus_dir

export PATH
export EDITOR='nano'

if [[ -d /usr/local/opt/binutils ]]; then
    export CPPFLAGS="-I/usr/local/opt/binutils/include"
    export LDFLAGS="-L/usr/local/opt/binutils/lib"
fi

# Android SDK из Windows (WSL)
if [[ -d /mnt/c/Users/danila/AppData/Local/Android/Sdk ]]; then
    export ANDROID_SDK_ROOT="/mnt/c/Users/danila/AppData/Local/Android/Sdk"
    export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/29.0.14206865"
fi
