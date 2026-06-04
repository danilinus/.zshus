#!/usr/bin/env bash

command -v git &> /dev/null || { echo "❌ git не установлен"; exit 1; }

# Проверка и установка Zsh
command -v zsh &> /dev/null || {
    echo "Устанавливаю Zsh..."
    if command -v apt &> /dev/null; then apt update && apt install zsh -y
    elif command -v dnf &> /dev/null; then dnf install zsh -y
    elif command -v pacman &> /dev/null; then pacman -S zsh --noconfirm
    elif command -v brew &> /dev/null; then brew install zsh -y
    else
        echo "Невозможно установить Zsh..."
        exit 1
    fi
}

UPDATE=false

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# Проверяем, есть ли локальные изменения
if ! git diff --quiet HEAD; then
    echo "⚠️  Обнаружены локальные изменения:"
    git status --short
    echo ""

    read -p "Закоммитить изменения перед обновлением? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Проверка настроек git
        if ! git config user.name &>/dev/null; then
            echo "❌ Git user не настроен. Выполните:"
            echo "   git config --global user.name 'Ваше Имя'"
            echo "   git config --global user.email 'email@example.com'"
            echo "ℹ️  Пропускаем коммит, ваши изменения сохранены локально"
        else
            git add .

            read -e -p "Сообщение коммита [WIP]: " msg

            # Если сообщение не пустое - делаем коммит и пуш
            if [[ -n "$msg" ]]; then
                git commit -m "$msg" 2>/dev/null && echo "  Закоммичено" || echo "  Не удалось закоммитить"
                git push origin main 2>/dev/null && echo "  Отправлено на GitHub" || echo "  Не удалось отправить"
            else
                echo "ℹ️  Сообщение пустое - коммит пропущен"
            fi
        fi
    fi
fi

# Забираем изменения из удалённого репозитория (без слияния)
git fetch origin

# Проверяем, есть ли новые изменения в удалённом репозитории
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    # Удалённые изменения есть, пытаемся их применить
    if git diff --quiet HEAD; then
        # Нет локальных изменений — просто обновляемся
        git pull --ff-only origin main
        echo "✅ Репозиторий обновлён"
    else
        # Есть локальные изменения — пробуем rebase
        echo "⚠️  Есть локальные изменения и новые коммиты на GitHub"

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
if git submodule update --init --recursive 2>/dev/null; then
    # Проверяем, обновились ли субмодули (появились новые файлы)
    if [ -n "$(git submodule status | grep -v '^ ')" ]; then
        UPDATE=true
    fi
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
    } > "$TMP_FILE"

    # Заменяем оригинальный файл
    mv "$TMP_FILE" "$ZSHRC_FILE"
    echo "🔧 Строка добавлена в начало .zshrc"
    UPDATE=true
fi

CURRENT_SHELL=$(basename "$SHELL")
ZSH_PATH=$(command -v zsh)
if [ "$CURRENT_SHELL" != "zsh" ]; then
    chsh -s "$ZSH_PATH" && echo "✅ Shell изменён на Zsh"
fi

echo ""
echo "🎉 Конфигурация zshus обновлена"
if [ "$UPDATE" = true ]; then
    echo "💡 Перезапустите терминал или выполните: source ~/.zshrc"
fi

