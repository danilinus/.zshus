#!/usr/bin/env bash

git fetch origin >/dev/null 2>&1 || exit 1

LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    exit 0    # есть обновления
else
    exit 1    # обновлений нет
fi