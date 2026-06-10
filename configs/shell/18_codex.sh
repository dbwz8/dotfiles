# Codex should not load corporate MCPs on personal machines.

_codex_configure_home() {
    _codex_host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || sed -n '1p' /etc/hostname 2>/dev/null)"

    case "$_codex_host" in
        weckerAA|weckerAA.*|weckeraa|weckeraa.*|weckerlap|weckerlap.*) ;;
        *)
            unset _codex_host
            return
            ;;
    esac

    _codex_source_home="${CODEX_SOURCE_HOME:-$HOME/.codex}"
    _codex_target_home="${CODEX_HOME:-$HOME/.codex-local}"

    if [ "$_codex_source_home" = "$_codex_target_home" ] || [ ! -r "$_codex_source_home/config.toml" ]; then
        unset _codex_host _codex_source_home _codex_target_home
        return
    fi

    export CODEX_HOME="$_codex_target_home"

    mkdir -p "$CODEX_HOME" || {
        unset _codex_host _codex_source_home _codex_target_home
        return
    }

    for _codex_entry in AGENTS.md auth.json history.jsonl skills plugins marketplaces apps sessions logs; do
        if [ -e "$_codex_source_home/$_codex_entry" ]; then
            if [ -L "$CODEX_HOME/$_codex_entry" ]; then
                ln -sfn "$_codex_source_home/$_codex_entry" "$CODEX_HOME/$_codex_entry" 2>/dev/null || true
            elif [ ! -e "$CODEX_HOME/$_codex_entry" ]; then
                ln -s "$_codex_source_home/$_codex_entry" "$CODEX_HOME/$_codex_entry" 2>/dev/null || true
            fi
        fi
    done

    _codex_tmp="$CODEX_HOME/config.toml.$$"
    awk '
        /^\[mcp_servers\.slack-reader(\.|\])/ { skip = 1; next }
        /^\[mcp_servers\.ionq-mcp-gateway(\.|\])/ { skip = 1; next }
        /^\[/ { skip = 0 }
        !skip { print }
    ' "$_codex_source_home/config.toml" > "$_codex_tmp" \
        && mv "$_codex_tmp" "$CODEX_HOME/config.toml"
    rm -f "$_codex_tmp" 2>/dev/null || true

    unset _codex_host _codex_source_home _codex_target_home _codex_entry _codex_tmp
}

_codex_configure_home
unset -f _codex_configure_home
