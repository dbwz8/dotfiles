#!/usr/bin/env bash
# Run on the WSL client. SSH's host alias supplies Cloudflare's ProxyCommand.
set -u
host=${1:-weckerAA-remote}
session=${2:-running}
delay=${RECONNECT_DELAY_SECONDS:-3}
if [[ ! $host =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.@:-]*$ ||
      ! $session =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ||
      ! $delay =~ ^[0-9]+$ ]]; then
    printf 'Usage: %s [ssh-host-alias] [zellij-session]\n' "$0" >&2
    exit 2
fi
command -v ssh >/dev/null || { printf 'Install OpenSSH in WSL first.\n' >&2; exit 1; }
log_file="${RECONNECT_LOG_FILE:-/tmp/ssh-reconnect/reconnect.log}"
if ! (umask 077; mkdir -p -- "$(dirname -- "$log_file")" && : >> "$log_file"); then
    printf 'Cannot write reconnect log: %s\n' "$log_file" >&2
    exit 1
fi
log_event() {
    printf '%s pid=%s host=%s session=%s %s\n' \
        "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$$" "$host" "$session" "$*" >> "$log_file"
}
printf 'Reconnect log: %s\n' "$log_file" >&2
trap 'log_event "stopped by signal"; printf "\nReconnect stopped.\n" >&2; exit 0' INT TERM
attempt=0
while true; do
    attempt=$((attempt + 1))
    log_event "connecting attempt=$attempt"
    printf '[%s] Connecting to %s, session %s...\n' "$(date '+%H:%M:%S')" "$host" "$session" >&2
    # Keep normal host-key verification and interactive Cloudflare authentication.
    # An interactive login shell loads PATH setup from .zshrc/.bashrc too.
    ssh -tt \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=20 \
        "$host" "exec \"\$SHELL\" -lic 'exec zellij attach --create $session'"
    status=$?
    log_event "ssh exited attempt=$attempt status=$status"
    case $status in
        0) exit 0 ;; # Intentional Zellij detach or normal remote exit.
        130) exit 0 ;;
        255)
            log_event "retrying in ${delay}s"
            printf '[%s] SSH disconnected; retrying in %ss. Ctrl+C stops retries.\n' \
                "$(date '+%H:%M:%S')" "$delay" >&2
            sleep "$delay"
            ;;
        *)
            printf 'Remote command exited with status %s; stopping.\n' "$status" >&2
            exit "$status"
            ;;
    esac
done
