#!/usr/bin/env bash
set -euo pipefail

script_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
server_mode="${VIBE_SERVER_MODE:-ssh}"
remote_host="${VIBE_REMOTE_HOST:-weckerAA}"
local_bind="${VIBE_REMOTE_LOCAL_BIND:-127.0.0.1}"
local_port="${VIBE_REMOTE_LOCAL_PORT:-18024}"
remote_bind="${VIBE_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${VIBE_REMOTE_PORT:-8023}"
local_direct_port="${VIBE_LOCAL_PORT:-$remote_port}"
api_key="${VIBE_LOCAL_API_KEY:-local-vllm}"
wait_seconds="${VIBE_REMOTE_TUNNEL_WAIT_SECONDS:-30}"

vibe_bin() {
  if [[ -n "${VIBE_BIN:-}" && -x "$VIBE_BIN" ]]; then
    printf '%s\n' "$VIBE_BIN"
    return 0
  fi

  for candidate in \
    "$HOME/.local/share/uv/tools/mistral-vibe/bin/vibe" \
    "/opt/homebrew/bin/vibe" \
    "/usr/local/bin/vibe"; do
    if [[ -x "$candidate" && ! "$candidate" -ef "$script_path" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  vibe_cmd="$(command -v vibe 2>/dev/null || true)"
  if [[ -n "$vibe_cmd" && -x "$vibe_cmd" && ! "$vibe_cmd" -ef "$script_path" ]]; then
    printf '%s\n' "$vibe_cmd"
    return 0
  fi

  return 1
}

real_vibe="$(vibe_bin)" || {
  printf '%s\n' "Mistral Vibe CLI is not installed. Run sync-uv-tools or rerun ~/dotfiles/install." >&2
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
      remote_host="${VIBE_REMOTE_HOST_REMOTE:-weckerAA-remote}"
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
  -h|--help|-V|--version|--setup|--check-upgrade)
    exec "$real_vibe" "$@"
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
    printf 'Unknown Vibe server mode: %s\n' "$server_mode" >&2
    exit 1
    ;;
esac

endpoint_ok() {
  curl -fsS --max-time 2 "${base_url}/models" >/dev/null 2>&1
}

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' 'curl is required to check the Devstral endpoint.' >&2
  exit 1
fi
if [[ "$server_mode" = "ssh" ]] && ! command -v ssh >/dev/null 2>&1; then
  printf 'ssh is required to open the Vibe tunnel to %s.\n' "$remote_host" >&2
  exit 1
fi

if [[ "$server_mode" = "ssh" ]] && ! endpoint_ok; then
  printf 'Opening SSH tunnel to %s for Mistral Vibe...\n' "$remote_host"
  ssh -f -N \
    -o ExitOnForwardFailure=yes \
    -L "${local_bind}:${local_port}:${remote_bind}:${remote_port}" \
    "$remote_host"

  elapsed=0
  while [[ "$elapsed" -lt "$wait_seconds" ]]; do
    if endpoint_ok; then
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
fi

if ! endpoint_ok; then
  printf 'Devstral endpoint did not become ready at %s.\n' "$base_url" >&2
  exit 1
fi

export VIBE_LOCAL_API_KEY="$api_key"
export VIBE_ACTIVE_MODEL="devstral-local"
export VIBE_PROVIDERS="[{\"name\":\"devstral-local\",\"api_base\":\"${base_url}\",\"api_key_env_var\":\"VIBE_LOCAL_API_KEY\",\"api_style\":\"openai\",\"backend\":\"generic\"}]"

exec "$real_vibe" "$@"
