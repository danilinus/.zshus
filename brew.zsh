#!/bin/bash

# Определяем путь к Homebrew в зависимости от ОС
setup_brew() {
    local brew_path=""

    # macOS: стандартный путь
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Intel Mac
        if [[ -x "/usr/local/bin/brew" ]]; then
            brew_path="/usr/local/bin/brew"
        # Apple Silicon Mac (M1/M2/M3)
        elif [[ -x "/opt/homebrew/bin/brew" ]]; then
            brew_path="/opt/homebrew/bin/brew"
        fi
    # Linux
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
        elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
            brew_path="$HOME/.linuxbrew/bin/brew"
        fi
    fi

    # Если brew найден - настраиваем
    if [[ -n "$brew_path" && -x "$brew_path" ]]; then
        # brew shellenv запускает brew (~50 мс), а вывод у него постоянный,
        # поэтому кэшируем его вместе с числом ядер. Кэш обновляется после обновления brew
        local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zshus/brew.zsh"
        if [[ ! -s "$cache" || "$brew_path" -nt "$cache" ]]; then
            local jobs=4
            # Количество ядер для компиляции
            if command -v nproc &>/dev/null; then
                jobs=$(nproc)
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                jobs=$(sysctl -n hw.ncpu)
            fi
            mkdir -p "${cache:h}"
            {
                "$brew_path" shellenv
                print -r -- "export HOMEBREW_MAKE_JOBS=$jobs"
            } >"$cache" 2>/dev/null
        fi
        source "$cache"

        # Оптимизация
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_INSTALL_CLEANUP=TRUE
    fi
}

# Запускаем настройку
setup_brew
