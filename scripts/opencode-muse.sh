#!/usr/bin/env bash
# Run OpenCode against Muse Glimmer through the private agents router.
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
while [[ -L "${script_path}" ]]; do
    script_dir="$(cd -P "$(dirname "${script_path}")" && pwd)"
    script_path="$(readlink "${script_path}")"
    [[ "${script_path}" = /* ]] || script_path="${script_dir}/${script_path}"
done
script_dir="$(cd -P "$(dirname "${script_path}")" && pwd)"
dotfiles_root="$(cd -P "${script_dir}/.." && pwd)"
config_path="${OPENCODE_MUSE_CONFIG:-${dotfiles_root}/configs/opencode/opencode-muse.json}"
remote_host="${OPENCODE_MUSE_REMOTE_HOST:-weckerAA}"
remote_bind="${OPENCODE_MUSE_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${OPENCODE_MUSE_REMOTE_PORT:-8022}"
local_bind="${OPENCODE_MUSE_LOCAL_BIND:-127.0.0.1}"
local_port="${OPENCODE_MUSE_LOCAL_PORT:-18022}"
api_key="${OPENCODE_MUSE_API_KEY:-local-vllm}"
wait_seconds="${OPENCODE_MUSE_TUNNEL_WAIT_SECONDS:-30}"
tunnel_pid=""

cleanup() {
    if [[ -n "${tunnel_pid}" ]] && kill -0 "${tunnel_pid}" 2>/dev/null; then
        kill "${tunnel_pid}" 2>/dev/null || true
        wait "${tunnel_pid}" 2>/dev/null || true
    fi
}

trap cleanup EXIT HUP INT TERM

opencode_bin() {
    local candidate
    for candidate in "${OPENCODE_BIN:-}" "$HOME/.opencode/bin/opencode" /opt/homebrew/bin/opencode /usr/local/bin/opencode; do
        if [[ -n "${candidate}" && -x "${candidate}" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done
    command -v opencode 2>/dev/null || return 1
}

real_opencode="$(opencode_bin)" || {
    printf '%s\n' 'OpenCode is not installed. Run install-opencode or rerun ~/git/dotfiles/install.' >&2
    exit 1
}
command -v ssh >/dev/null 2>&1 || {
    printf '%s\n' "ssh is required to reach Muse at ${remote_host}." >&2
    exit 1
}
command -v curl >/dev/null 2>&1 || {
    printf '%s\n' 'curl is required to verify the Muse endpoint.' >&2
    exit 1
}
[[ -f "${config_path}" ]] || {
    printf '%s\n' "OpenCode Muse config not found: ${config_path}" >&2
    exit 1
}

base_url="http://${local_bind}:${local_port}/v1"
endpoint_ready() {
    curl -fsS --max-time 2 \
        -H "Authorization: Bearer ${api_key}" \
        "${base_url}/models" >/dev/null 2>&1
}

if ! endpoint_ready; then
    printf 'Opening SSH tunnel to %s for Muse/OpenCode...\n' "${remote_host}"
    ssh -N \
        -o ExitOnForwardFailure=yes \
        -L "${local_bind}:${local_port}:${remote_bind}:${remote_port}" \
        "${remote_host}" &
    tunnel_pid="$!"

    for ((elapsed = 0; elapsed < wait_seconds; elapsed += 1)); do
        if endpoint_ready; then
            break
        fi
        sleep 1
    done
fi

if ! endpoint_ready; then
    printf '%s\n' "Muse endpoint did not become ready at ${base_url}." >&2
    exit 1
fi

export OPENCODE_CONFIG="${config_path}"
export OPENCODE_MUSE_API_KEY="${api_key}"
printf '%s\n' "Starting OpenCode with Muse Glimmer 30B through ${base_url}."
"${real_opencode}" "$@"
