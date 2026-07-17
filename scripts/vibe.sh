#!/usr/bin/env bash
set -euo pipefail

resolve_script_path() {
  local source="${BASH_SOURCE[0]}"
  local dir

  while [[ -L "$source" ]]; do
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="${dir}/${source}"
  done

  dir="$(cd -P "$(dirname "$source")" && pwd)"
  printf '%s/%s\n' "$dir" "$(basename "$source")"
}

script_path="$(resolve_script_path)"
script_dir="$(cd -P "$(dirname "$script_path")" && pwd)"
server_mode="${VIBE_SERVER_MODE:-ssh}"
remote_host="${VIBE_REMOTE_HOST:-weckerAA}"
local_bind="${VIBE_REMOTE_LOCAL_BIND:-127.0.0.1}"
local_port="${VIBE_REMOTE_LOCAL_PORT:-18024}"
remote_bind="${VIBE_REMOTE_BIND_HOST:-127.0.0.1}"
remote_port="${VIBE_REMOTE_PORT:-8023}"
local_direct_port="${VIBE_LOCAL_PORT:-$remote_port}"
proxy_enabled="${VIBE_OPENAI_PROXY:-1}"
proxy_bind="${VIBE_PROXY_BIND:-127.0.0.1}"
proxy_port="${VIBE_PROXY_PORT:-18025}"
proxy_script="${VIBE_PROXY_SCRIPT:-${script_dir}/vibe-openai-proxy.js}"
proxy_log="${VIBE_PROXY_LOG:-$HOME/.vibe/logs/openai-proxy.log}"
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

node_bin() {
  if [[ -n "${NODE_BIN:-}" && -x "$NODE_BIN" ]]; then
    printf '%s\n' "$NODE_BIN"
    return 0
  fi

  for candidate in \
    "$HOME"/.nvm/versions/node/*/bin/node \
    "$HOME/.local/bin/node" \
    "/opt/homebrew/bin/node" \
    "/usr/local/bin/node" \
    "/usr/bin/node"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  node_cmd="$(command -v node 2>/dev/null || true)"
  if [[ -n "$node_cmd" && -x "$node_cmd" ]]; then
    printf '%s\n' "$node_cmd"
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
    upstream_base_url="http://127.0.0.1:${local_direct_port}/v1"
    ;;
  ssh)
    upstream_base_url="http://${local_bind}:${local_port}/v1"
    ;;
  *)
    printf 'Unknown Vibe server mode: %s\n' "$server_mode" >&2
    exit 1
    ;;
esac

endpoint_ok() {
  local url="$1"
  curl -fsS --max-time 2 "${url}/models" >/dev/null 2>&1
}

proxy_health() {
  curl -fsS --max-time 2 "http://${proxy_bind}:${proxy_port}/__health" 2>/dev/null || true
}

proxy_ok() {
  local health
  health="$(proxy_health)"
  [[ "$health" == *"\"upstream_base\":\"${upstream_base_url}\""* ]]
}

ensure_proxy() {
  if [[ "$proxy_enabled" != "1" ]]; then
    return 0
  fi

  if proxy_ok; then
    return 0
  fi

  if [[ -n "$(proxy_health)" ]]; then
    printf 'Vibe OpenAI proxy is already running on %s:%s with a different upstream.\n' "$proxy_bind" "$proxy_port" >&2
    printf 'Set VIBE_PROXY_PORT to another port or stop the existing proxy.\n' >&2
    exit 1
  fi

  node_cmd="$(node_bin)" || {
    printf '%s\n' 'node is required to launch the Vibe OpenAI proxy.' >&2
    exit 1
  }

  mkdir -p "$(dirname "$proxy_log")"
  printf 'Starting Vibe OpenAI proxy on %s:%s...\n' "$proxy_bind" "$proxy_port"
  nohup "$node_cmd" "$proxy_script" \
    --bind "$proxy_bind" \
    --port "$proxy_port" \
    --upstream-base "$upstream_base_url" \
    >>"$proxy_log" 2>&1 &

  elapsed=0
  while [[ "$elapsed" -lt "$wait_seconds" ]]; do
    if proxy_ok; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  printf 'Vibe OpenAI proxy did not become ready at http://%s:%s.\n' "$proxy_bind" "$proxy_port" >&2
  printf 'Proxy log: %s\n' "$proxy_log" >&2
  exit 1
}

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' 'curl is required to check the Devstral endpoint.' >&2
  exit 1
fi
if [[ "$server_mode" = "ssh" ]] && ! command -v ssh >/dev/null 2>&1; then
  printf 'ssh is required to open the Vibe tunnel to %s.\n' "$remote_host" >&2
  exit 1
fi

if [[ "$server_mode" = "ssh" ]] && ! endpoint_ok "$upstream_base_url"; then
  printf 'Opening SSH tunnel to %s for Mistral Vibe...\n' "$remote_host"
  ssh -f -N \
    -o ExitOnForwardFailure=yes \
    -L "${local_bind}:${local_port}:${remote_bind}:${remote_port}" \
    "$remote_host"

  elapsed=0
  while [[ "$elapsed" -lt "$wait_seconds" ]]; do
    if endpoint_ok "$upstream_base_url"; then
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
fi

if ! endpoint_ok "$upstream_base_url"; then
  printf 'Devstral endpoint did not become ready at %s.\n' "$upstream_base_url" >&2
  exit 1
fi

provider_base_url="$upstream_base_url"
if [[ "$proxy_enabled" = "1" ]]; then
  ensure_proxy
  provider_base_url="http://${proxy_bind}:${proxy_port}/v1"
fi

export VIBE_LOCAL_API_KEY="$api_key"
export VIBE_ACTIVE_MODEL="devstral-local"
export VIBE_PROVIDERS="[{\"name\":\"devstral-local\",\"api_base\":\"${provider_base_url}\",\"api_key_env_var\":\"VIBE_LOCAL_API_KEY\",\"api_style\":\"openai\",\"backend\":\"generic\"}]"

exec "$real_vibe" "$@"
