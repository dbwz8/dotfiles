#!/usr/bin/env bash
# Show local model process, endpoint, log, and GPU state.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=local-ai-common.sh
source "${script_dir}/local-ai-common.sh"

case "${1:-}" in
    logs)
        if [[ "${2:-}" == "--follow" ]]; then
            exec tail -n 200 -f "${local_ai_log_file}"
        fi
        tail -n 200 "${local_ai_log_file}"
        exit 0
        ;;
    --quiet|"")
        ;;
    *)
        printf 'usage: %s [--quiet|logs [--follow]]\n' "$0" >&2
        exit 2
        ;;
esac

server_running=0
if [[ -f "${local_ai_pid_file}" ]] && local_ai_pid_is_server "$(<"${local_ai_pid_file}")"; then
    server_running=1
fi
if [[ "${1:-}" == "--quiet" ]]; then
    (( server_running ))
    exit
fi

if (( server_running )); then
    printf 'process: running (pid %s)\n' "$(<"${local_ai_pid_file}")"
else
    printf 'process: stopped\n'
fi
printf 'endpoint: %s\n' "${local_ai_base_url}"
printf 'model: %s\n' "${LOCAL_AI_MODEL_NAME}"
printf 'log: %s\n' "${local_ai_log_file}"
if curl --fail --silent --max-time 2 "${local_ai_base_url}/models" >/dev/null 2>&1; then
    printf 'api: reachable\n'
else
    printf 'api: unavailable\n'
fi
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits 2>/dev/null |
        awk -F, '{ gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4); printf "gpu: %s, %s/%s MiB, %s%% util\n", $1, $2, $3, $4 }'
fi
