alias zshconfig='$EDITOR $HOME/.zshrc'
alias ll="ls -l"
alias la="ls -al"
alias ..="cd .."
alias ...="cd ../.."

# Обновление zshus конфига
alias zshus='bash "$HOME/.zshus/install.sh"'
# Вариации
alias zup='zshus'
alias us='zshus'

alias usconfig='$EDITOR "$HOME/.zshus/zshus.zsh"'
alias usexport='$EDITOR "$HOME/.zshus/exports.zsh"'
alias usalias='$EDITOR "$HOME/.zshus/aliases.zsh"'
alias usbind='$EDITOR "$HOME/.zshus/bindings.zsh"'

# Проверка скорости конфига
alias ustime='time zsh -i -c exit'

# Восстановить локальный репозиторий
alias usreset='git -C $HOME/.zshus clean -fd && git -C $HOME/.zshus reset --hard HEAD'
