#!/usr/bin/env bash
set -euo pipefail

script_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
server_mode="${QWEN_SERVER_MODE:-ssh}"
remote_host="${QWEN_REMOTE_HOST:-weckerAA}"
local_bind="${QWEN_REMOTE_LOCAL_BIND:-127.0.0.1}"
local_port="${QWEN_REMOTE_LOCAL_PORT:-18023}"
remote_bind="${QWEN_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${QWEN_REMOTE_PORT:-8023}"
local_direct_port="${QWEN_LOCAL_PORT:-$remote_port}"
model="${QWEN_REMOTE_MODEL:-qwen3-coder-next}"
api_key="${QWEN_REMOTE_API_KEY:-local-vllm}"
wait_seconds="${QWEN_REMOTE_TUNNEL_WAIT_SECONDS:-30}"
max_output_tokens="${QWEN_CODE_MAX_OUTPUT_TOKENS:-8192}"
safe_mode="${QWEN_CODE_SAFE_MODE:-0}"

qwen_bin() {
    if [[ -n "${QWEN_CODE_BIN:-}" && -x "$QWEN_CODE_BIN" ]]; then
        printf '%s\n' "$QWEN_CODE_BIN"
        return 0
    fi

    for candidate in \
        "$HOME/.local/lib/qwen-code/bin/qwen" \
        "/opt/homebrew/bin/qwen" \
        "/usr/local/bin/qwen"; do
        if [[ -x "$candidate" && ! "$candidate" -ef "$script_path" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    qwen_cmd="$(command -v qwen 2>/dev/null || true)"
    if [[ -n "$qwen_cmd" && -x "$qwen_cmd" && ! "$qwen_cmd" -ef "$script_path" ]]; then
        printf '%s\n' "$qwen_cmd"
        return 0
    fi

    return 1
}

real_qwen="$(qwen_bin)" || {
    printf '%s\n' "Qwen Code is not installed. Run install-qwen-code or rerun ~/dotfiles/install." >&2
    exit 1
}

parsed_args=()
while (($#)); do
    case "$1" in
        --coding)
            model="${QWEN_CODER_MODEL:-qwen3-coder-next}"
            shift
            ;;
        --thinking)
            model="${QWEN_DEBUG_MODEL:-qwq-32b}"
            shift
            ;;
        --local)
            server_mode="local"
            shift
            ;;
        --remote)
            server_mode="ssh"
            remote_host="${QWEN_REMOTE_HOST_REMOTE:-weckerAA-remote}"
            shift
            ;;
        *)
            parsed_args+=("$1")
            shift
            ;;
    esac
done
set -- "${parsed_args[@]}"

should_add_safe_mode() {
    case "$safe_mode" in
        0|false|FALSE|no|NO)
            return 1
            ;;
    esac

    case "${1:-}" in
        auth|channel|extensions|hooks|mcp|review|serve|sessions|-v|--version|-h|--help)
            return 1
            ;;
    esac

    for arg in "$@"; do
        if [ "$arg" = "--safe-mode" ]; then
            return 1
        fi
    done

    return 0
}

case "${1:-}" in
    auth|channel|extensions|hooks|mcp|review|serve|sessions|-v|--version|-h|--help)
        exec "$real_qwen" "$@"
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
        printf '%s\n' "Unknown Qwen server mode: ${server_mode}" >&2
        exit 1
        ;;
esac

endpoint_ok() {
    curl -fsS --max-time 2 "${base_url}/models" >/dev/null 2>&1
}

if [[ "$server_mode" = "ssh" ]] && ! command -v ssh >/dev/null 2>&1; then
    printf '%s\n' "ssh is required to open the Qwen Code tunnel to ${remote_host}." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to check the Qwen Code model endpoint." >&2
    exit 1
fi

if [[ "$server_mode" = "ssh" ]] && ! endpoint_ok; then
    printf '%s\n' "Opening SSH tunnel to ${remote_host} for Qwen Code..."
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
    printf '%s\n' "Qwen Code model endpoint did not become ready at ${base_url}." >&2
    if [[ "$server_mode" = "ssh" ]]; then
        printf '%s\n' "Check SSH access to ${remote_host} and the remote service on ${remote_bind}:${remote_port}." >&2
    else
        printf '%s\n' "Check the local service on 127.0.0.1:${local_direct_port}." >&2
    fi
    exit 1
fi

export OPENAI_API_KEY="${api_key}"
export OPENAI_BASE_URL="${base_url}"
export OPENAI_MODEL="${model}"
export QWEN_MODEL="${model}"
export QWEN_CODE_MAX_OUTPUT_TOKENS="${max_output_tokens}"

if should_add_safe_mode "$@"; then
    set -- --safe-mode "$@"
fi

exec "$real_qwen" --model "$model" "$@"
