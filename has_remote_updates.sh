#!/usr/bin/env bash

GIT_TERMINAL_PROMPT=0 git fetch origin >/dev/null 2>&1 || exit 1

# Обновление есть только если origin/main содержит коммиты, которых нет локально
# (локальные неотправленные коммиты обновлением не считаются)
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null) || exit 1

if [ "$BEHIND" -gt 0 ]; then
    exit 0    # есть обновления
else
    exit 1    # обновлений нет
fi
