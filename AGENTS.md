# AGENTS.md

Инструкции для AI-агентов, работающих с репозиторием. Пользовательская документация — в [README.md](README.md).

## Что это

Личный конфиг zsh, клонируется в `~/.zshus` и подключается из `~/.zshrc` строкой `source "$HOME/.zshus/zshus.zsh"`. Должен одинаково работать на Linux, macOS, WSL и Termux.

## Структура

- `zshus.zsh` — точка входа, порядок загрузки: `exports` → `aliases` → `bindings` → `prompt` → `brew`, затем опции, история, плагины, `~/.zshrc.local`.
- `prompt.zsh` — `precmd`, определение ОС (`get_system_name`), цвета (`check_truecolor_support`, `get_system_color`), статус репозитория (`zshus_status` на каждом промпте, `zshus_fetch` в фоне).
- `check_truecolor_support` кэширует результат в `ZSHUS_TRUECOLOR`; первый вызов должен быть в основном shell, не внутри `$(...)`. Не возвращать проверку через `tput colors`: 256 цветов — не TrueColor.
- `install.sh` — bash-скрипт установки и обновления (`us`).
- `has_local_changes.sh`, `has_remote_updates.sh` — используются в `install.sh`, работают через код возврата: `0` = «да, есть», `1` = «нет». Не менять семантику.
- `plugins/` — git submodules. **Не редактировать**, обновляются через `git submodule update`.

## Проверка изменений

Тестов нет, минимум для любой правки:

```bash
zsh -n prompt.zsh zshus.zsh exports.zsh aliases.zsh bindings.zsh brew.zsh
bash -n install.sh has_local_changes.sh has_remote_updates.sh
zsh -i -c exit        # не должно быть ни вывода, ни ошибок
```

Определение TrueColor опрашивает терминал, поэтому проверять его нужно в настоящем терминале (через `ssh -t`), а не в выводе без tty:

```bash
ssh -t <host> "env -u COLORTERM zsh -c 'source ~/.zshus/prompt.zsh; check_truecolor_support && echo yes || echo no'"
```

## Соглашения

- Файлы `*.zsh` — zsh; `install.sh` и `has_*.sh` — bash (`#!/usr/bin/env bash`). Не использовать bash-измы в zsh-файлах и наоборот.
- Комментарии и сообщения пользователю — на русском, как в существующем коде. Отступ — 4 пробела.
- Всё, что вызывается при старте shell, должно быть быстрым и тихим: без обращения к сети в основном потоке, без вывода в stderr. Внешние команды, которые есть не везде (`uname -o`, `getprop`, `tput`), вызывать с `2>/dev/null`; на macOS BSD-версии утилит не поддерживают GNU-флаги.
- В `PROMPT` непечатаемые последовательности оборачивать в `%{ %}`, а `$?` читать первой строкой `precmd`.
- Пути, зависящие от машины (Homebrew, Android SDK и т.п.), добавлять только если каталог существует. Личные настройки — в `~/.zshrc.local`, не в репозиторий.
- Не запускать `usreset`, `git clean`, `git reset --hard` в `~/.zshus` без явной просьбы: они удаляют локальные правки.

## Коммиты

- Одна проблема — один коммит.
- Заголовок короткий и обобщённый (`Fix TrueColor detection`), в теле — что было не так и что изменено.
- Не пушить без просьбы пользователя.
