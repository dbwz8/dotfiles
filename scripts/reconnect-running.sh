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
trap 'printf "\nReconnect stopped.\n" >&2; exit 0' INT TERM
while true; do
    printf '[%s] Connecting to %s, session %s...\n' "$(date '+%H:%M:%S')" "$host" "$session" >&2
    # Keep normal host-key verification and interactive Cloudflare authentication.
    # The login shell loads the remote user's command search path.
    ssh -tt \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=20 \
        "$host" "exec \"\$SHELL\" -lc 'exec zellij attach $session'"
    status=$?
    case $status in
        0) exit 0 ;; # Intentional Zellij detach or normal remote exit.
        130) exit 0 ;;
        255)
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
