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
        eval "$($brew_path shellenv)"

        # Оптимизация
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_INSTALL_CLEANUP=TRUE

        # Количество ядер для компиляции
        if command -v nproc &> /dev/null; then
            export HOMEBREW_MAKE_JOBS=$(nproc)
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            export HOMEBREW_MAKE_JOBS=$(sysctl -n hw.ncpu)
        else
            export HOMEBREW_MAKE_JOBS=4
        fi
    fi
}

# Запускаем настройку
setup_brew
