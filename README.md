# zshus

Личный конфиг для zsh: информативный промпт, подсказки и подсветка, поиск по истории, обновление одной командой. Работает на Linux (Debian/Ubuntu/Arch/Fedora/Raspberry Pi OS), macOS, WSL и Termux.

## Возможности

- **Промпт** с пользователем, хостом и названием ОС. Цвет ОС выбирается автоматически, в терминалах с TrueColor используются точные цвета дистрибутива, иначе — ближайший 16/256-цветный.
- Код возврата последней команды, активное Python-окружение (venv/conda/pyenv), ветка git и `*` при незакоммиченных изменениях.
- Индикатор состояния самого конфига, например `[us*↑1↓2]`: `*` — незакоммиченные правки, `↑N` — коммиты, ещё не отправленные в `origin/main`, `↓N` — новые коммиты на GitHub. Локальное состояние обновляется на каждом промпте, `git fetch` выполняется в фоне не чаще раза в 10 минут.
- Плагины (git submodules): [fzf-tab](https://github.com/Aloxaf/fzf-tab), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
- Подсветка `man` через [bat](https://github.com/sharkdp/bat), если он установлен.
- Автоопределение Homebrew (macOS и Linux).
- Общая история между сессиями.

## Установка

Нужны `git` и `bash`. Zsh будет установлен автоматически, если его нет.

```bash
git clone --recurse-submodules https://github.com/danilinus/.zshus ~/.zshus
bash ~/.zshus/install.sh
```

Скрипт подтянет субмодули, добавит `source "$HOME/.zshus/zshus.zsh"` в начало `~/.zshrc` и при необходимости сменит оболочку на zsh. После установки перезапустите терминал.

## Обновление

```bash
us        # то же самое: zup, zshus
```

Скрипт предложит закоммитить локальные изменения, заберёт обновления с GitHub (`git pull`) и обновит субмодули.

## Команды

| Команда | Действие |
| --- | --- |
| `us`, `zup`, `zshus` | установить/обновить конфиг |
| `usreset` | сбросить репозиторий к `HEAD` (с подтверждением) |
| `ustime` | замерить время запуска shell |
| `usconfig`, `usexport`, `usalias`, `usbind` | открыть `zshus.zsh`, `exports.zsh`, `aliases.zsh`, `bindings.zsh` в `$EDITOR` |
| `zshconfig` | открыть `~/.zshrc` |
| `ll`, `la`, `..`, `...` | короткие алиасы для `ls` и `cd` |

## Горячие клавиши

| Клавиши | Действие |
| --- | --- |
| `↑` / `↓` | поиск по истории по введённому префиксу |
| `Ctrl+←` / `Ctrl+→` | переход по словам |
| `Home` / `End` | начало / конец строки |
| `Esc Esc` | добавить/убрать `sudo` в начале команды |
| `Ctrl+N` | перенос строки внутри команды |

## Настройка

- Машинно-специфичные настройки кладите в `~/.zshrc.local` — файл подключается в конце и не попадает в git.
- Цвета промпта переопределяются переменными `TITLE_COLOR`, `NAME_COLOR`, `PATH_COLOR`, `SYSTEM_COLOR`, `PLEA_COLOR` (задайте их до загрузки конфига).
- Интервал фонового `git fetch` задаётся в секундах переменной `ZSHUS_FETCH_INTERVAL` (по умолчанию 600).

## Структура

```
zshus.zsh       точка входа: подключает остальные файлы, опции, история, плагины
exports.zsh     переменные окружения, PATH, локаль
aliases.zsh     алиасы и команды us*
bindings.zsh    привязки клавиш
prompt.zsh      промпт, определение ОС и TrueColor, статус обновлений
brew.zsh        автоопределение Homebrew
install.sh      установка и обновление
has_local_changes.sh / has_remote_updates.sh   проверки для install.sh
plugins/        плагины (submodules)
```

## Проверка поддержки TrueColor

Функция `check_truecolor_support` (`prompt.zsh`) работает в два шага:

1. Быстрая проверка переменных `COLORTERM`, `TERM`, `TERM_PROGRAM`, `WT_SESSION`, а в tmux — `client_termfeatures`.
2. Если переменные ничего не говорят (типично для ssh: они не передаются на удалённую машину), опрашивается сам терминал. zshus включает цвет `38;2;1;2;3` и запрашивает текущие атрибуты через DECRQSS. Терминал с TrueColor возвращает тот же цвет. Следом отправляется DA1, на который отвечают все терминалы, поэтому даже без ответа на DECRQSS задержки нет.

Результат запоминается на сессию и экспортируется как `COLORTERM=truecolor` для дочерних программ. Чтобы проверка через ssh работала без опроса, можно передавать `COLORTERM` с клиента (`SendEnv COLORTERM` в `~/.ssh/config`, на сервере `AcceptEnv COLORTERM`).
