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
# Resolve the same Access application as SSH without starting its ProxyCommand.
access_url=
service_token_mode=0
ssh_config=$(ssh -G "$host") || exit 1
if [[ $ssh_config == *'cloudflare-ssh.sh '* ]]; then
    service_token_mode=1
fi
if [[ $ssh_config == *'cloudflared access ssh '* || $service_token_mode == 1 ]]; then
    command -v cloudflared >/dev/null || { printf 'Install cloudflared first.\n' >&2; exit 1; }
    command -v timeout >/dev/null || { printf 'Install timeout first.\n' >&2; exit 1; }
    access_hostname=$(awk '$1 == "hostname" { print $2; exit }' <<< "$ssh_config")
    access_url="https://$access_hostname"
fi
unset ssh_config
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
ensure_access_login() {
    local cached_token
    # Unlike `access ssh`, `access token` only reads a cached token; it never
    # starts browser authentication. Require nonempty output as well as success.
    while true; do
        if cached_token=$(timeout 20 cloudflared access token --app "$access_url" 2>/dev/null) &&
            [[ -n $cached_token ]]; then
            unset cached_token
            return 0
        fi
        unset cached_token
        log_event "paused: Cloudflare login unavailable"
        printf '\nCannot confirm a cached Cloudflare login (expired, missing, or application unreachable).\n' >&2
        printf 'Automatic retries are paused to prevent repeated browser login pages.\n' >&2
        if [[ ! -t 0 ]]; then
            printf 'Restart this command in a terminal to log in.\n' >&2
            return 1
        fi
        read -r -p 'Press Enter to start one browser login, or Ctrl+C to stop: ' || return 1
        log_event "Cloudflare login requested by user"
        # No SSH ConnectTimeout here: allow time to finish Google authentication.
        # Suppress JWT output, and never retry browser login without another Enter.
        if cloudflared access login --quiet "$access_url" >/dev/null; then
            log_event "Cloudflare login completed; checking cached token"
        else
            log_event "Cloudflare login failed"
        fi
    done
}
attempt=0
short_failures=0
while true; do
    if [[ $service_token_mode == 1 ]]; then
        script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        bash "$script_dir/cloudflare-ssh.sh" --check "$access_hostname" || exit 1
    elif [[ -n $access_url ]]; then
        ensure_access_login || exit 1
    fi
    attempt=$((attempt + 1))
    log_event "connecting attempt=$attempt"
    printf '[%s] Connecting to %s, session %s...\n' "$(date '+%H:%M:%S')" "$host" "$session" >&2
    # Keep normal host-key verification; check Cloudflare login before each try.
    # An interactive login shell loads PATH setup from .zshrc/.bashrc too.
    started=$SECONDS
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
            if [[ $service_token_mode == 1 ]]; then
                if (( SECONDS - started < 60 )); then
                    short_failures=$((short_failures + 1))
                else
                    short_failures=0
                fi
                if (( short_failures >= 3 )); then
                    log_event "paused: three short service-token connection failures"
                    printf 'Repeated short failures; check the service token, Access policy, and network.\n' >&2
                    if [[ ! -t 0 ]]; then exit 1; fi
                    read -r -p 'Press Enter to retry, or Ctrl+C to stop: ' || exit 1
                    short_failures=0
                fi
            fi
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
