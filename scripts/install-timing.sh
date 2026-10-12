#!/usr/bin/env bash
# Shared, opt-in install timing. Labels must not contain commas or newlines.
dotfiles_timing_init() {
    [ "${DOTFILES_TIME_INSTALL:-0}" = 1 ] || return 0
    local report_dir
    report_dir="$HOME/.local/state/dotfiles/install-timings"
    mkdir -p "$report_dir"
    export DOTFILES_TIMING_REPORT="$report_dir/unix-$(date +%Y%m%d-%H%M%S)-$$.csv"
    printf 'step,seconds,result,exit_code\n' > "$DOTFILES_TIMING_REPORT"
    printf 'Install timing report: %s\n' "$DOTFILES_TIMING_REPORT"
}

dotfiles_timing_write() {
    [ "${DOTFILES_TIME_INSTALL:-0}" = 1 ] && [ -n "${DOTFILES_TIMING_REPORT:-}" ] || return 0
    printf '%s,%s,%s,%s\n' "$1" "$((SECONDS - $2))" "$3" "$4" >> "$DOTFILES_TIMING_REPORT"
}

dotfiles_timed_step() {
    local label started status result
    label="$1"
    shift
    if [ "${DOTFILES_TIME_INSTALL:-0}" != 1 ]; then
        "$@"
        return $?
    fi
    started=$SECONDS
    # Call external scripts with their own shell so their failure handling stays intact.
    if "$@"; then status=0; else status=$?; fi
    result=completed
    [ "$status" -eq 0 ] || result=nonzero-exit
    dotfiles_timing_write "$label" "$started" "$result" "$status"
    return "$status"
}
