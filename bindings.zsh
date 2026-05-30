# Навигация по истории (вверх/вниз)
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Навигация по словам (Ctrl + Стрелки)
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '\e[5C' forward-word
bindkey '\e[5D' backward-word
bindkey '^[[5C' forward-word
bindkey '^[[5D' backward-word

# Вставка sudo (ESC)
bindkey '\e\e' sudo-command-line

# Home и End
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[OF" end-of-line

# Ctrl + UP/DOWN
bindkey "^[^[[A" beginning-of-line
bindkey "^[^[[B" end-of-line

# Привязываем Ctrl+N к переносу строки
bindkey '^N' insert-linebreak
