#!/usr/bin/env bash
set -euo pipefail

script_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
server_mode="${AIDER_SERVER_MODE:-ssh}"
remote_host="${AIDER_REMOTE_HOST:-weckerAA}"
local_bind="${AIDER_REMOTE_LOCAL_BIND:-127.0.0.1}"
local_port="${AIDER_REMOTE_LOCAL_PORT:-18023}"
remote_bind="${AIDER_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${AIDER_REMOTE_PORT:-8023}"
local_direct_port="${AIDER_LOCAL_PORT:-$remote_port}"
model="${AIDER_MODEL:-qwen3-coder-next}"
api_key="${AIDER_OPENAI_API_KEY:-local-vllm}"
wait_seconds="${AIDER_REMOTE_TUNNEL_WAIT_SECONDS:-30}"

aider_bin() {
    if [[ -n "${AIDER_BIN:-}" && -x "$AIDER_BIN" ]]; then
        printf '%s\n' "$AIDER_BIN"
        return 0
    fi

    for candidate in \
        "$HOME/.local/bin/aider" \
        "/opt/homebrew/bin/aider" \
        "/usr/local/bin/aider"; do
        if [[ -x "$candidate" && ! "$candidate" -ef "$script_path" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    aider_cmd="$(command -v aider 2>/dev/null || true)"
    if [[ -n "$aider_cmd" && -x "$aider_cmd" && ! "$aider_cmd" -ef "$script_path" ]]; then
        printf '%s\n' "$aider_cmd"
        return 0
    fi

    return 1
}

qualified_model() {
    case "$model" in
        */*) printf '%s\n' "$model" ;;
        *) printf 'openai/%s\n' "$model" ;;
    esac
}

has_model_arg() {
    for arg in "$@"; do
        case "$arg" in
            --model|--model=*|-m)
                return 0
                ;;
        esac
    done

    return 1
}

real_aider="$(aider_bin)" || {
    printf '%s\n' "Aider is not installed. Run sync-uv-tools or rerun ~/dotfiles/install." >&2
    exit 1
}

parsed_args=()
while (($#)); do
    case "$1" in
        --local)
            server_mode="local"
            shift
            ;;
        --remote)
            server_mode="ssh"
            remote_host="${AIDER_REMOTE_HOST_REMOTE:-weckerAA-remote}"
            shift
            ;;
        *)
            parsed_args+=("$1")
            shift
            ;;
    esac
done
set -- "${parsed_args[@]}"

case "${1:-}" in
    -h|--help|--version)
        exec "$real_aider" "$@"
        ;;
esac

case "$server_mode" in
    local)
        base_url="http://127.0.0.1:${local_direct_port}/v1"
        ;;
    ssh)
        base_url="http://${local_bind}:${local_port}/v1"
        ;;
    *)
        printf '%s\n' "Unknown Aider server mode: ${server_mode}" >&2
        exit 1
        ;;
esac

endpoint_ok() {
    curl -fsS --max-time 2 "${base_url}/models" >/dev/null 2>&1
}

if [[ "$server_mode" = "ssh" ]] && ! command -v ssh >/dev/null 2>&1; then
    printf '%s\n' "ssh is required to open the Aider tunnel to ${remote_host}." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to check the Aider model endpoint." >&2
    exit 1
fi

if [[ "$server_mode" = "ssh" ]] && ! endpoint_ok; then
    printf '%s\n' "Opening SSH tunnel to ${remote_host} for Aider..."
    ssh -f -N \
        -o ExitOnForwardFailure=yes \
        -L "${local_bind}:${local_port}:${remote_bind}:${remote_port}" \
        "${remote_host}"

    elapsed=0
    while [ "$elapsed" -lt "$wait_seconds" ]; do
        if endpoint_ok; then
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
fi

if ! endpoint_ok; then
    printf '%s\n' "Aider model endpoint did not become ready at ${base_url}." >&2
    if [[ "$server_mode" = "ssh" ]]; then
        printf '%s\n' "Check SSH access to ${remote_host} and the remote service on ${remote_bind}:${remote_port}." >&2
    else
        printf '%s\n' "Check the local service on 127.0.0.1:${local_direct_port}." >&2
    fi
    exit 1
fi

export OPENAI_API_KEY="${api_key}"
export OPENAI_API_BASE="${base_url}"
export OPENAI_BASE_URL="${base_url}"

if ! has_model_arg "$@"; then
    set -- --model "$(qualified_model)" "$@"
fi

exec "$real_aider" "$@"
