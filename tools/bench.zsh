# Замер zshus в настоящем интерактивном zsh через псевдотерминал (zpty).
# Конфиг грузится как обычно (~/.zshrc), дополнительно в конец precmd
# добавляется вывод метки: по ней понятно, что промпт готов к отрисовке.
# usage: zsh -f bench.zsh [runs]
zmodload zsh/zpty zsh/datetime
RUNS=${1:-10}
BZ=$(mktemp -d)
print 'source ~/.zshenv' >$BZ/.zshenv
print -l 'source ~/.zshrc' '_bm() { print BENCH_PROMPT }' 'precmd_functions+=(_bm)' \
    '(( $+functions[_zshus_load_deferred] )) && functions[_zshus_load_deferred]+=$'"'"'\nprint BENCH_READY'"'" \
    '(( $+functions[_zshus_async_done] )) && functions[_zshus_async_done]="print BENCH_ASYNC; ${functions[_zshus_async_done]}"' \
    >$BZ/.zshrc
NEW=$(zsh -ic '(( $+functions[_zshus_load_deferred] )) && print 1' 2>/dev/null)

# Ждём, пока загрузятся отложенные плагины и придёт асинхронный статус
wait_ready() {
    local line ready=0 async=0
    while (( ! ready || ! async )) && zpty -r b line; do
        [[ $line == *BENCH_READY* ]] && ready=1
        [[ $line == *BENCH_ASYNC* ]] && async=1
    done
}

ms() { printf '%.1f' $(( ($2 - $1) * 1000 )) }
median() { local -a s=(${(on)@}); print -- ${s[$(( (${#s} + 1) / 2 ))]} }
wait_prompt() { zpty -r -m b out '*BENCH_PROMPT*' }

run() {
    local dir=$1 s
    s=$EPOCHREALTIME
    # COLORTERM задан: zpty не отвечает на запрос TrueColor
    zpty b "cd $dir && ZDOTDIR=$BZ TERM=xterm-256color COLORTERM=truecolor exec zsh -i"
    wait_prompt
    start+=($(ms $s $EPOCHREALTIME))
    if [[ -n $NEW ]]; then
        wait_ready
        full+=($(ms $s $EPOCHREALTIME))
    fi
    sleep 0.5 # отложенная загрузка и асинхронный статус успевают завершиться

    repeat 3 {
        s=$EPOCHREALTIME
        zpty -w b ':'
        wait_prompt
        lat+=($(ms $s $EPOCHREALTIME))
    }
    zpty -d b
}

for dir in ~ ~/.zshus; do
    local -a start=() lat=() full=()
    repeat $RUNS run $dir
    printf '%-9s старт до первого промпта: %6s мс   всё загружено: %6s мс   промпт после команды: %6s мс\n' \
        ${dir/#$HOME/\~} $(median $start) $(median ${full:--}) $(median $lat)
done

local -a cold=() warm=()
repeat 3 {
    rm -rf ${XDG_CACHE_HOME:-$HOME/.cache}/zshus*
    s=$EPOCHREALTIME; zsh -i -c exit; cold+=($(ms $s $EPOCHREALTIME))
}
repeat $RUNS { s=$EPOCHREALTIME; zsh -i -c exit; warm+=($(ms $s $EPOCHREALTIME)) }
printf 'zsh -i -c exit: пустой кэш zshus %s мс, обычный запуск %s мс\n' $(median $cold) $(median $warm)
rm -rf $BZ
