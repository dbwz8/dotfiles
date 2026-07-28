#!/usr/bin/env bash
# Stop only the llama-server process started by local-ai-server-start.sh.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=local-ai-common.sh
source "${script_dir}/local-ai-common.sh"

if [[ "${LOCAL_AI_SERVICE_STOP:-0}" != "1" ]] \
    && command -v systemctl >/dev/null 2>&1 \
    && systemctl --user is-active --quiet local-ai-glm.service; then
    printf 'Stopping local AI through local-ai-glm.service.\n'
    systemctl --user stop local-ai-glm.service
    exit 0
fi

if [[ ! -f "${local_ai_pid_file}" ]]; then
    printf 'Local AI server is not running (no PID file).\n'
    exit 0
fi

server_pid="$(<"${local_ai_pid_file}")"
if ! local_ai_pid_is_server "${server_pid}"; then
    printf 'Removing stale local AI PID file: %s\n' "${local_ai_pid_file}"
    rm -f "${local_ai_pid_file}"
    exit 0
fi

kill -TERM "${server_pid}"
for (( attempt = 0; attempt < 15; attempt++ )); do
    if ! kill -0 "${server_pid}" 2>/dev/null; then
        rm -f "${local_ai_pid_file}"
        printf 'Local AI server stopped.\n'
        exit 0
    fi
    sleep 1
done

printf 'Local AI server is still stopping (pid %s). Check %s\n' "${server_pid}" "${local_ai_log_file}" >&2
exit 1
