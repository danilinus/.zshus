#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

echo "🚀 Обновление конфигурации zshus..."

# Проверяем, есть ли локальные изменения
if ! git diff --quiet HEAD; then
    echo ""
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
            exit 1
        fi

        git add .
        read -p "Сообщение коммита [WIP]: " msg
	git commit -m "${msg:-WIP before update}" 2>/dev/null && echo "✅ Закоммичено" || echo "⚠️  Не удалось закоммитить"
        git push origin main 2>/dev/null && echo "✅ Отправлено на GitHub" || echo "⚠️  Не удалось отправить (продолжаем)"
    fi
fi

# Пытаемся обновиться (rebase покажет конфликты)

echo "📥 Обновление из репозитория..."

if ! git pull --rebase origin main 2>&1; then
    # Отменяем rebase при конфликте
    git rebase --abort 2>/dev/null
    echo ""
    echo "❌ Конфликт с удалёнными изменениями!"
    echo "   Решение: git stash или git reset --hard origin/main"
    exit 1
fi

# Обновляем субмодули
git submodule update --init --recursive 2>/dev/null || true

# Проверяем и добавляем source в .zshrc
ZSHRC_FILE="$HOME/.zshrc"
SOURCE_LINE="source \"\$HOME/.zshus/zshus.zsh\""

echo ""

# Создаём .zshrc если его нет
if [ ! -f "$ZSHRC_FILE" ]; then
    touch "$ZSHRC_FILE"
    echo "✅ Создан файл $ZSHRC_FILE"
fi

# Проверяем, есть ли уже наша строка
if ! grep -q "\.zshus/zshus\.zsh" "$ZSHRC_FILE"; then
    echo "🔧 Добавляем source в .zshrc..."

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

    echo "✅ Строка добавлена в начало .zshrc"
fi

echo ""
echo "🎉 Конфигурация zshus обновлена"
echo ""
echo "💡 Перезапустите терминал или выполните: source ~/.zshrc"
