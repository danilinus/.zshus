#!/usr/bin/env bash

command -v git &>/dev/null || {
    echo "❌ git не установлен"
    exit 1
}

# Проверка и установка Zsh
command -v zsh &>/dev/null || {
    echo "Устанавливаю Zsh..."
    if command -v apt &>/dev/null; then
        apt update && apt install zsh -y
    elif command -v dnf &>/dev/null; then
        dnf install zsh -y
    elif command -v pacman &>/dev/null; then
        pacman -S zsh --noconfirm
    elif command -v brew &>/dev/null; then
        brew install zsh
    else
        echo "Невозможно установить Zsh..."
        exit 1
    fi
}

UPDATE=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "❌ Текущий каталог не является git-репозиторием"
    exit 1
}

# Проверяем, есть ли локальные изменения
if bash "$SCRIPT_DIR/has_local_changes.sh"; then
    echo "⚠️ Обнаружены локальные изменения:"
    git status --short
    echo ""

    read -r -n 1 -p "Закоммитить изменения перед обновлением? [y/N]: " reply
    echo

    if [[ $reply =~ ^[Yy]$ ]]; then
        # Проверка настроек git
        if ! git config user.name &>/dev/null || ! git config user.email &>/dev/null; then
            echo "❌ Не настроены user.name или user.email. Выполните:"
            echo "   git config --global user.name 'Ваше Имя'"
            echo "   git config --global user.email 'email@example.com'"
            echo "ℹ️  Пропускаем коммит, ваши изменения сохранены локально"
        else
            git add -A

            read -e -p "Сообщение коммита [WIP]: " msg

            # Если сообщение не пустое - делаем коммит и пуш
            if [[ -n "$msg" ]]; then
                echo "📤 Отправка изменений..."
                git commit -m "$msg" 2>/dev/null && echo "  Закоммичено" || echo "  Не удалось закоммитить"
                git push origin main 2>/dev/null && echo "  Отправлено на GitHub" || echo "  Не удалось отправить"
            else
                echo "ℹ️ Сообщение пустое - коммит пропущен"
            fi
        fi
    fi
fi

# Забираем изменения из удалённого репозитория (без слияния)
if bash "$SCRIPT_DIR/has_remote_updates.sh"; then
    # Удалённые изменения есть, пытаемся их применить
    COMMITS=$(git rev-list --count HEAD..origin/main)
    echo "⬇️ Доступно обновление ($COMMITS коммитов)"

    if bash "$SCRIPT_DIR/has_local_changes.sh"; then
        # Нет локальных изменений — просто обновляемся
        git pull --ff-only origin main
        echo "✅ Репозиторий обновлён"
        UPDATE=true
    else
        # Есть локальные изменения — пробуем rebase
        echo "⚠️ Есть локальные изменения"

        if git pull --rebase origin main 2>/dev/null; then
            echo "✅ Репозиторий обновлён, ваши изменения сохранены"
            UPDATE=true
        else
            git rebase --abort 2>/dev/null
            echo "❌ Конфликт! Ваши изменения конфликтуют с новыми"
            echo "   Решение: git stash или git reset --hard origin/main"
            echo "ℹ️  Пропускаем обновление, ваши изменения сохранены локально"
        fi
    fi
else
    echo "✅ Репозиторий уже актуален (нет новых изменений)"
fi

# Обновляем субмодули и проверяем, были ли изменения
if git submodule update --init --recursive | grep -q .; then
    echo "✅ Субмодули обновлены"
    UPDATE=true
fi

# Проверяем и добавляем source в .zshrc
ZSHRC_FILE="$HOME/.zshrc"
SOURCE_LINE="source \"\$HOME/.zshus/zshus.zsh\""

# Создаём .zshrc если его нет
if [ ! -f "$ZSHRC_FILE" ]; then
    touch "$ZSHRC_FILE"
    echo "✅ Создан файл $ZSHRC_FILE"
fi

# Проверяем, есть ли строка
if ! grep -Fq "$SOURCE_LINE" "$ZSHRC_FILE"; then
    # Создаём временный файл
    TMP_FILE="${TMPDIR:-/tmp}/zshrc_temp.$$.$RANDOM"

    # Добавляем маркер и source в начало файла
    {
        echo "# === zshus config ==="
        echo "$SOURCE_LINE"
        echo ""
        cat "$ZSHRC_FILE"
    } >"$TMP_FILE"

    # Заменяем оригинальный файл
    mv "$TMP_FILE" "$ZSHRC_FILE"
    echo "🔧 Строка добавлена в начало .zshrc"
    UPDATE=true
fi

CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    ZSH_PATH=$(command -v zsh)
    if chsh -s "$ZSH_PATH"; then
        echo "✅ Shell изменён на Zsh"
        UPDATE=true
    fi
fi

echo ""
if [ "$UPDATE" = true ]; then
    echo "🎉 Конфигурация zshus обновлена"
    echo "💡 Перезапустите терминал или выполните: source ~/.zshrc"
else
    echo "✅ Конфигурация zshus уже актуальна"
fi
