#!/usr/bin/env bash
set -euo pipefail

resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local dir

    while [[ -L "${source}" ]]; do
        dir="$(cd -P "$(dirname "${source}")" && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done

    dir="$(cd -P "$(dirname "${source}")" && pwd)"
    printf '%s/%s\n' "${dir}" "$(basename "${source}")"
}

script_path="$(resolve_script_path)"
script_dir="$(cd -P "$(dirname "${script_path}")" && pwd)"
qwen_config_source="$(cd -P "${script_dir}/../configs/qwen/qwen" && pwd)/settings.json"
qwen_config_target="${HOME}/.qwen/settings.json"
server_mode="${QWEN_SERVER_MODE:-ssh}"
remote_host="${QWEN_REMOTE_HOST:-weckerAA}"
local_bind="${QWEN_REMOTE_LOCAL_BIND:-127.0.0.1}"
local_port="${QWEN_REMOTE_LOCAL_PORT:-18023}"
remote_bind="${QWEN_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${QWEN_REMOTE_PORT:-8023}"
local_direct_port="${QWEN_LOCAL_PORT:-$remote_port}"
model="${QWEN_REMOTE_MODEL:-qwen3.6-27b}"
api_key="${QWEN_REMOTE_API_KEY:-local-vllm}"
wait_seconds="${QWEN_REMOTE_TUNNEL_WAIT_SECONDS:-30}"
max_output_tokens="${QWEN_CODE_MAX_OUTPUT_TOKENS:-8192}"
safe_mode="${QWEN_CODE_SAFE_MODE:-0}"
thinking_mode=0
has_system_prompt_override=0
thinking_append_system_prompt="${QWEN_THINKING_APPEND_SYSTEM_PROMPT:-When asked to implement, fix, refactor, add, or write code, modify the working tree with Qwen Code edit/write_file tools before answering. Do not put code blocks, patches, or replacement file contents in the final answer unless the user explicitly asks for snippets. If you cannot edit files, say so explicitly instead of showing code.}"
workspace_root="$(pwd -P)"
workspace_append_system_prompt="${QWEN_WORKSPACE_APPEND_SYSTEM_PROMPT:-}"
if [[ -z "$workspace_append_system_prompt" ]]; then
    workspace_append_system_prompt="The current workspace root is ${workspace_root}. Your home directory is ${HOME}; expand a path beginning with ~/ as ${HOME}/. Resolve every other relative workspace path against the workspace root before calling a tool. When a tool requires an absolute file path, always provide that resolved absolute path. If a tool reports invalid arguments, correct them and continue the user's request; do not treat the request as missing."
fi

ensure_managed_config_link() {
    local backup_root backup_path suffix

    if [[ -L "${qwen_config_target}" && "${qwen_config_target}" -ef "${qwen_config_source}" ]]; then
        return 0
    fi

    if [[ -e "${qwen_config_target}" || -L "${qwen_config_target}" ]]; then
        backup_root="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
        backup_path="${backup_root}/.qwen/settings.json"
        suffix=1
        while [[ -e "${backup_path}" || -L "${backup_path}" ]]; do
            backup_path="${backup_root}/.qwen/settings.json.${suffix}"
            suffix=$((suffix + 1))
        done
        mkdir -p "$(dirname "${backup_path}")"
        printf 'Backing up unmanaged Qwen settings %s -> %s\n' "${qwen_config_target}" "${backup_path}" >&2
        mv "${qwen_config_target}" "${backup_path}"
    fi

    mkdir -p "$(dirname "${qwen_config_target}")"
    rm -f "${qwen_config_target}"
    ln -s "${qwen_config_source}" "${qwen_config_target}"
}
tunnel_pid=""

cleanup_owned_tunnel() {
    if [[ -n "${tunnel_pid}" ]] && kill -0 "${tunnel_pid}" 2>/dev/null; then
        kill "${tunnel_pid}" 2>/dev/null || true
        wait "${tunnel_pid}" 2>/dev/null || true
    fi
    tunnel_pid=""
}


restore_managed_config_link() {
    local exit_status=$? temporary_config

    trap - EXIT
    cleanup_owned_tunnel
    if [[ -f "${qwen_config_target}" && ! -L "${qwen_config_target}" ]]; then
        temporary_config="$(mktemp "${qwen_config_source}.tmp.XXXXXX")"
        printf 'Persisting Qwen settings %s -> %s\n' "${qwen_config_target}" "${qwen_config_source}" >&2
        cp -p "${qwen_config_target}" "${temporary_config}"
        mv "${temporary_config}" "${qwen_config_source}"
        rm -f "${qwen_config_target}"
        ln -s "${qwen_config_source}" "${qwen_config_target}"
    else
        ensure_managed_config_link
    fi
    exit "${exit_status}"
}

ensure_managed_config_link
trap restore_managed_config_link EXIT

trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
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
            model="${QWEN_CODER_MODEL:-qwen3.6-27b}"
            shift
            ;;
        --thinking)
            model="${QWEN_THINKING_MODEL:-${QWEN_DEBUG_MODEL:-qwq-32b}}"
            thinking_mode=1
            shift
            ;;
        --system-prompt|--append-system-prompt)
            has_system_prompt_override=1
            parsed_args+=("$1")
            shift
            if (($#)); then
                parsed_args+=("$1")
                shift
            fi
            ;;
        --system-prompt=*|--append-system-prompt=*)
            has_system_prompt_override=1
            parsed_args+=("$1")
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
        "$real_qwen" "$@"
        exit $?
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
    curl -fsS --max-time 2 \
        -H "Authorization: Bearer ${api_key}" \
        "${base_url}/models" >/dev/null 2>&1
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
    ssh -N \
        -o ExitOnForwardFailure=yes \
        -L "${local_bind}:${local_port}:${remote_bind}:${remote_port}" \
        "${remote_host}" &
    tunnel_pid=$!

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

if [[ "$has_system_prompt_override" = "0" ]]; then
    system_prompt="$workspace_append_system_prompt"
    if [[ "$thinking_mode" = "1" ]]; then
        system_prompt="${thinking_append_system_prompt}

${workspace_append_system_prompt}"
    fi
    set -- --append-system-prompt "$system_prompt" "$@"
fi

if should_add_safe_mode "$@"; then
    set -- --safe-mode "$@"
fi

"$real_qwen" --model "$model" "$@"
