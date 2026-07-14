#!/usr/bin/env bash
set -euo pipefail

is_disabled() {
    case "${1:-}" in
        0|false|FALSE|no|NO)
            return 0
            ;;
    esac
    return 1
}

if is_disabled "${DOTFILES_INSTALL_GO:-1}"; then
    exit 0
fi

GO_VERSION_URL="${DOTFILES_GO_VERSION_URL:-https://go.dev/VERSION?m=text}"
GO_DOWNLOAD_BASE="${DOTFILES_GO_DOWNLOAD_BASE:-https://go.dev/dl}"
GO_INSTALL_ROOT="${DOTFILES_GO_INSTALL_ROOT:-/usr/local/go}"
GO_TOOLS="${DOTFILES_GO_TOOLS:-golang.org/x/tools/gopls@latest golang.org/x/tools/cmd/goimports@latest}"
GO_LEGACY_INSTALL_ROOT="$HOME/.local/go"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf '%s\n' "$1 is required to install Go." >&2
        exit 1
    fi
}

normalize_go_version() {
    case "$1" in
        go*) printf '%s\n' "$1" ;;
        *) printf 'go%s\n' "$1" ;;
    esac
}

latest_go_version() {
    local version

    if [ -n "${DOTFILES_GO_VERSION:-}" ]; then
        normalize_go_version "$DOTFILES_GO_VERSION"
        return 0
    fi

    require_command curl
    version="$(curl -fsSL "$GO_VERSION_URL" | sed -n '1{s/[[:space:]].*$//;p;q;}')"
    if [ -z "$version" ] || [ "$version" = "${version#go}" ]; then
        printf '%s\n' "Could not resolve the latest Go version from $GO_VERSION_URL." >&2
        exit 1
    fi

    printf '%s\n' "$version"
}

host_goos() {
    case "$(uname -s)" in
        Darwin) printf '%s\n' darwin ;;
        Linux) printf '%s\n' linux ;;
        *)
            printf '%s\n' "Unsupported Go OS: $(uname -s)" >&2
            exit 1
            ;;
    esac
}

host_goarch() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s\n' amd64 ;;
        arm64|aarch64) printf '%s\n' arm64 ;;
        *)
            printf '%s\n' "Unsupported Go architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

installed_go_version() {
    local go_bin
    go_bin="$1"

    if [ ! -x "$go_bin" ]; then
        return 0
    fi

    "$go_bin" version 2>/dev/null | sed -n 's/^go version \(go[0-9][^[:space:]]*\).*/\1/p'
}

version_part() {
    local version part major minor patch
    version="${1#go}"
    version="${version%%-*}"
    version="${version%%+*}"
    part="$2"

    IFS=. read -r major minor patch _ <<EOF
$version
EOF

    case "$part" in
        major) printf '%s\n' "${major:-0}" ;;
        minor) printf '%s\n' "${minor:-0}" ;;
        patch)
            patch="${patch:-0}"
            patch="${patch%%[^0-9]*}"
            printf '%s\n' "${patch:-0}"
            ;;
    esac
}

compare_go_versions() {
    local a b a_major a_minor a_patch b_major b_minor b_patch
    a="$1"
    b="$2"

    a_major="$(version_part "$a" major)"
    a_minor="$(version_part "$a" minor)"
    a_patch="$(version_part "$a" patch)"
    b_major="$(version_part "$b" major)"
    b_minor="$(version_part "$b" minor)"
    b_patch="$(version_part "$b" patch)"

    if [ "$a_major" -lt "$b_major" ]; then printf '%s\n' -1; return 0; fi
    if [ "$a_major" -gt "$b_major" ]; then printf '%s\n' 1; return 0; fi
    if [ "$a_minor" -lt "$b_minor" ]; then printf '%s\n' -1; return 0; fi
    if [ "$a_minor" -gt "$b_minor" ]; then printf '%s\n' 1; return 0; fi
    if [ "$a_patch" -lt "$b_patch" ]; then printf '%s\n' -1; return 0; fi
    if [ "$a_patch" -gt "$b_patch" ]; then printf '%s\n' 1; return 0; fi
    printf '%s\n' 0
}

fetch_archive_sha256() {
    local archive_name
    archive_name="$1"

    require_command awk
    require_command tr

    curl -fsSL "$GO_DOWNLOAD_BASE/?mode=json&include=all" \
        | tr '{},' '\n' \
        | awk -v target="$archive_name" '
            {
                compact = $0
                gsub(/[[:space:]]/, "", compact)
            }
            compact == "\"filename\":\"" target "\"" {
                found = 1
                next
            }
            found && compact ~ /^"sha256":/ {
                sub(/^"sha256":"/, "", compact)
                sub(/"$/, "", compact)
                print compact
                found = 0
            }
        '
}

verify_archive() {
    local archive_path expected
    archive_path="$1"
    expected="$2"

    if [ -z "$expected" ]; then
        printf '%s\n' "Could not find a SHA-256 checksum for $(basename "$archive_path")." >&2
        exit 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s  %s\n' "$expected" "$archive_path" | sha256sum -c - >/dev/null
        return 0
    fi

    if command -v shasum >/dev/null 2>&1; then
        printf '%s  %s\n' "$expected" "$archive_path" | shasum -a 256 -c - >/dev/null
        return 0
    fi

    printf '%s\n' "sha256sum or shasum is required to verify the Go archive." >&2
    exit 1
}

safe_install_root() {
    case "$GO_INSTALL_ROOT" in
        ""|"/"|"$HOME"|"$HOME/")
            printf '%s\n' "Refusing to install Go into unsafe path: $GO_INSTALL_ROOT" >&2
            exit 1
            ;;
    esac
}

run_or_sudo() {
    if "$@" 2>/dev/null; then
        return 0
    fi

    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
        return $?
    fi

    "$@"
}

install_archive() {
    local archive_path extract_root parent
    archive_path="$1"
    extract_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-go.XXXXXX")"

    tar -C "$extract_root" -xzf "$archive_path"
    if [ ! -x "$extract_root/go/bin/go" ]; then
        printf '%s\n' "Downloaded Go archive did not contain go/bin/go." >&2
        rm -rf "$extract_root"
        exit 1
    fi

    parent="$(dirname "$GO_INSTALL_ROOT")"
    run_or_sudo mkdir -p "$parent"
    if [ -e "$GO_INSTALL_ROOT" ] || [ -L "$GO_INSTALL_ROOT" ]; then
        run_or_sudo rm -rf "$GO_INSTALL_ROOT"
    fi
    run_or_sudo mv "$extract_root/go" "$GO_INSTALL_ROOT"
    rm -rf "$extract_root"
}

remove_legacy_go_install() {
    if [ -n "${DOTFILES_GO_INSTALL_ROOT:-}" ]; then
        return 0
    fi

    if [ "$GO_INSTALL_ROOT" = "$GO_LEGACY_INSTALL_ROOT" ]; then
        return 0
    fi

    if [ -d "$GO_LEGACY_INSTALL_ROOT" ] && [ -x "$GO_LEGACY_INSTALL_ROOT/bin/go" ]; then
        printf '%s\n' "Removing legacy dotfiles Go install at $GO_LEGACY_INSTALL_ROOT..."
        rm -rf "$GO_LEGACY_INSTALL_ROOT"
    fi
}

install_go_tools() {
    local go_bin tool

    if is_disabled "${DOTFILES_INSTALL_GO_TOOLS:-1}"; then
        return 0
    fi

    if [ -z "$GO_TOOLS" ]; then
        return 0
    fi

    go_bin="$GO_INSTALL_ROOT/bin/go"
    if [ ! -x "$go_bin" ]; then
        go_bin="$(command -v go || true)"
    fi

    if [ -z "$go_bin" ] || [ ! -x "$go_bin" ]; then
        printf '%s\n' "Go is not available; skipping Go tool installation." >&2
        return 1
    fi

    export GOPATH="${GOPATH:-$HOME/go}"
    export GOBIN="${GOBIN:-$GOPATH/bin}"
    export GOMODCACHE="${GOMODCACHE:-$GOPATH/pkg/mod}"
    export GOCACHE="${GOCACHE:-$HOME/.cache/go-build}"
    mkdir -p "$GOBIN" "$GOMODCACHE" "$GOCACHE"
    if [ -d "$GO_INSTALL_ROOT" ]; then
        export GOROOT="$GO_INSTALL_ROOT"
        export PATH="$GO_INSTALL_ROOT/bin:$GOBIN${PATH:+":$PATH"}"
    else
        export PATH="$GOBIN${PATH:+":$PATH"}"
    fi

    for tool in $GO_TOOLS; do
        printf '%s\n' "Installing Go tool $tool..."
        "$go_bin" install "$tool"
    done
}

main() {
    local latest_version current_version version_cmp goos goarch archive_name archive_path checksum

    require_command tar
    require_command mktemp
    safe_install_root

    latest_version="$(latest_go_version)"
    current_version="$(installed_go_version "$GO_INSTALL_ROOT/bin/go" || true)"

    if [ -n "$current_version" ]; then
        version_cmp="$(compare_go_versions "$current_version" "$latest_version")"
        if [ "$version_cmp" -ge 0 ]; then
            printf '%s\n' "Go $current_version is already installed at $GO_INSTALL_ROOT."
            remove_legacy_go_install
            install_go_tools
            return 0
        fi
    fi

    goos="$(host_goos)"
    goarch="$(host_goarch)"
    archive_name="$latest_version.$goos-$goarch.tar.gz"
    archive_path="${TMPDIR:-/tmp}/$archive_name"

    printf '%s\n' "Installing Go $latest_version for $goos/$goarch..."
    curl -fL --retry 3 -o "$archive_path" "$GO_DOWNLOAD_BASE/$archive_name"
    checksum="$(fetch_archive_sha256 "$archive_name")"
    verify_archive "$archive_path" "$checksum"
    install_archive "$archive_path"
    remove_legacy_go_install

    "$GO_INSTALL_ROOT/bin/go" version
    install_go_tools
}

main "$@"
