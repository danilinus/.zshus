# Homebrew configuration
if command -v brew &> /dev/null; then
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=TRUE

    # Parallel jobs: nproc on Linux/WSL, sysctl on macOS
    if command -v nproc &> /dev/null; then
        export HOMEBREW_MAKE_JOBS=$(nproc)
    else
        export HOMEBREW_MAKE_JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    fi

    # Initialize brew (works with any standard installation)
    eval "$(brew shellenv zsh 2>/dev/null)"
fi
