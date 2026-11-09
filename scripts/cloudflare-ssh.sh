#!/usr/bin/env bash
# Keep service credentials outside dotfiles and out of process arguments.
set -euo pipefail
mode=connect
case ${1:-} in
    --configure) mode=configure; shift ;;
    --check) mode=check; shift ;;
esac
hostname=${1:-}
if [[ $# != 1 || ! $hostname =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]; then
    printf 'Usage: %s [--configure|--check] hostname\n' "$0" >&2
    exit 2
fi
credential_dir="$HOME/.cloudflared/service-tokens"
credential_file="$credential_dir/$hostname.credentials"
if [[ $mode == configure ]]; then
    read -r -p 'Cloudflare Client ID: ' client_id
    read -r -s -p 'Cloudflare Client Secret (hidden): ' client_secret
    printf '\n' >&2
    if [[ ! $client_id =~ ^[a-zA-Z0-9]+\.access$ ||
          ! $client_secret =~ ^[a-zA-Z0-9_]+$ ]]; then
        printf 'Invalid Client ID or Client Secret format; nothing was saved.\n' >&2
        exit 1
    fi
    umask 077
    mkdir -p -- "$credential_dir"
    chmod 700 "$credential_dir"
    temporary_file=$(mktemp "$credential_dir/.credentials.XXXXXX")
    trap 'rm -f -- "$temporary_file"' EXIT
    printf '%s\n%s\n' "$client_id" "$client_secret" > "$temporary_file"
    mv -f -- "$temporary_file" "$credential_file"
    trap - EXIT
    printf 'Saved private service credentials for %s.\n' "$hostname"
    exit 0
fi
if [[ ! -f $credential_file || ! -O $credential_file ||
      $(stat -c '%a' "$credential_file") != 600 ]]; then
    printf 'Missing or insecure service credentials for %s. Run:\n' "$hostname" >&2
    printf '  bash %q --configure %q\n' "${BASH_SOURCE[0]}" "$hostname" >&2
    exit 1
fi
{
    IFS= read -r client_id
    IFS= read -r client_secret
} < "$credential_file"
if [[ ! $client_id =~ ^[a-zA-Z0-9]+\.access$ ||
      ! $client_secret =~ ^[a-zA-Z0-9_]+$ ]]; then
    printf 'Invalid service credentials for %s.\n' "$hostname" >&2
    exit 1
fi
[[ $mode != check ]] || exit 0
export TUNNEL_SERVICE_TOKEN_ID="$client_id"
export TUNNEL_SERVICE_TOKEN_SECRET="$client_secret"
exec cloudflared access ssh --hostname "$hostname"
