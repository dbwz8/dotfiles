#!/usr/bin/env bash
# Start the local GLM coding endpoint, either manually or under a user service.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=local-ai-common.sh
source "${script_dir}/local-ai-common.sh"

if [[ "${LOCAL_AI_FOREGROUND:-0}" != "1" ]] \
    && command -v systemctl >/dev/null 2>&1 \
    && systemctl --user is-enabled --quiet local-ai-glm.service; then
    if systemctl --user is-active --quiet local-ai-glm.service; then
        printf 'Local AI systemd service is already running.\n'
        exit 0
    fi
    printf 'Starting local AI through local-ai-glm.service.\n'
    systemctl --user start local-ai-glm.service
    timeout_seconds="${LOCAL_AI_START_TIMEOUT_SECONDS}"
    for (( elapsed = 0; elapsed < timeout_seconds; elapsed += 2 )); do
        if curl --fail --silent --max-time 2 "${local_ai_base_url}/models" >/dev/null 2>&1; then
            printf 'Local AI systemd service is ready at %s.\n' "${local_ai_base_url}"
            exit 0
        fi
        if ! systemctl --user is-active --quiet local-ai-glm.service; then
            printf 'Local AI systemd service failed during startup. Inspect its journal.\n' >&2
            exit 1
        fi
        sleep 2
    done
    printf 'Local AI systemd service did not become ready within %s seconds.\n' "${timeout_seconds}" >&2
    exit 1
fi

if [[ ! -x "${local_ai_server_bin}" ]]; then
    printf 'llama-server is not installed. Run %s first.\n' "${script_dir}/local-ai-setup.sh" >&2
    exit 1
fi
if [[ ! -f "${local_ai_model_path}" ]]; then
    printf 'Configured model is missing. Run %s first.\n' "${script_dir}/local-ai-setup.sh" >&2
    exit 1
fi
if [[ -f "${local_ai_pid_file}" ]] && local_ai_pid_is_server "$(<"${local_ai_pid_file}")"; then
    printf 'Local AI server is already running (pid %s).\n' "$(<"${local_ai_pid_file}")"
    exit 0
fi

mkdir -p "${LOCAL_AI_STATE_DIR}" "${local_ai_log_dir}"
rm -f "${local_ai_pid_file}"
server_args=(
    --model "${local_ai_model_path}"
    --alias "${LOCAL_AI_MODEL_NAME}"
    --host "${LOCAL_AI_HOST}"
    --port "${LOCAL_AI_PORT}"
    --ctx-size "${LOCAL_AI_CTX_SIZE}"
    --n-gpu-layers "${LOCAL_AI_GPU_LAYERS}"
    --cache-type-k "${LOCAL_AI_CACHE_TYPE_K}"
    --cache-type-v "${LOCAL_AI_CACHE_TYPE_V}"
    --parallel "${LOCAL_AI_PARALLEL}"
    --flash-attn on
    --reasoning-preserve
    --jinja
)

if [[ "${LOCAL_AI_FOREGROUND:-0}" == "1" ]]; then
    printf '%s\n' "$$" >"${local_ai_pid_file}"
    exec "${local_ai_server_bin}" "${server_args[@]}"
fi

nohup "${local_ai_server_bin}" "${server_args[@]}" >>"${local_ai_log_file}" 2>&1 &
server_pid=$!
printf '%s\n' "${server_pid}" >"${local_ai_pid_file}"

timeout_seconds="${LOCAL_AI_START_TIMEOUT_SECONDS}"
for (( elapsed = 0; elapsed < timeout_seconds; elapsed += 2 )); do
    if ! local_ai_pid_is_server "${server_pid}"; then
        printf 'Local AI server exited during startup. Inspect %s\n' "${local_ai_log_file}" >&2
        rm -f "${local_ai_pid_file}"
        exit 1
    fi
    if curl --fail --silent --max-time 2 "${local_ai_base_url}/models" >/dev/null 2>&1; then
        printf 'Local AI server is ready at %s (pid %s).\n' "${local_ai_base_url}" "${server_pid}"
        exit 0
    fi
    sleep 2
done

printf 'Local AI server did not become ready within %s seconds. Inspect %s\n' "${timeout_seconds}" "${local_ai_log_file}" >&2
exit 1
