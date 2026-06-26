#!/usr/bin/env bash
set -euo pipefail

warn() {
    printf '%s\n' "$*" >&2
}

resolve_sudoku_source() {
    if [ "${1:-}" != "" ]; then
        printf '%s\n' "$1"
        return 0
    fi

    if [ -n "${SUDOKU_SOURCE:-}" ]; then
        printf '%s\n' "$SUDOKU_SOURCE"
        return 0
    fi

    if [ -n "${SUDOKO_SOURCE:-}" ]; then
        printf '%s\n' "$SUDOKO_SOURCE"
        return 0
    fi

    if [ -f "$HOME/git/languages/rust/Sudoku/Cargo.toml" ]; then
        printf '%s\n' "$HOME/git/languages/rust/Sudoku"
        return 0
    fi

    if [ -f "$HOME/git/languages/rust/Sudoko/Cargo.toml" ]; then
        printf '%s\n' "$HOME/git/languages/rust/Sudoko"
        return 0
    fi

    printf '%s\n' "$HOME/git/languages/rust/Sudoku"
}

resolve_cargo() {
    if command -v cargo >/dev/null 2>&1; then
        command -v cargo
        return 0
    fi

    if [ -x "$HOME/.cargo/bin/cargo" ]; then
        printf '%s\n' "$HOME/.cargo/bin/cargo"
        return 0
    fi

    return 1
}

cargo_package_name() {
    local manifest="$1"
    awk '
        /^\[[^]]+\]/ {
            in_package = ($0 == "[package]")
            next
        }
        in_package && /^[[:space:]]*name[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*name[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }
    ' "$manifest"
}

display_name_for_package() {
    case "$1" in
        sudoku) printf '%s\n' "Sudoku" ;;
        sudoko) printf '%s\n' "Sudoko" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

install_linux_desktop_entry() {
    local package_name="$1"
    local binary_path="$2"

    case "${SUDOKU_INSTALL_DESKTOP:-1}" in
        0|false|FALSE|no|NO)
            return 0
            ;;
    esac

    if [ "$(uname -s)" != "Linux" ]; then
        return 0
    fi

    if [ ! -x "$binary_path" ]; then
        warn "Skipping Sudoku desktop entry because the installed binary was not found at '$binary_path'."
        return 0
    fi

    local display_name desktop_dir desktop_file escaped_binary
    display_name="$(display_name_for_package "$package_name")"
    desktop_dir="$HOME/.local/share/applications"
    desktop_file="$desktop_dir/$package_name.desktop"
    escaped_binary="${binary_path//\"/\\\"}"

    mkdir -p "$desktop_dir"
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=$display_name
GenericName=Sudoku Puzzle
Comment=Play Sudoku puzzles
Exec="$escaped_binary" --gui
Terminal=false
Categories=Game;LogicGame;
StartupNotify=true
StartupWMClass=$display_name
EOF
    chmod 0644 "$desktop_file"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$desktop_dir" >/dev/null 2>&1 || true
    fi
}

if [ "$(uname -s)" != "Linux" ]; then
    exit 0
fi

if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
fi

source_path="$(resolve_sudoku_source "${1:-}")"
if [ ! -d "$source_path" ]; then
    warn "Skipping Sudoku install because the source checkout was not found at '$source_path'. Set SUDOKU_SOURCE to override."
    exit 0
fi

cargo_toml="$source_path/Cargo.toml"
if [ ! -f "$cargo_toml" ]; then
    warn "Sudoku source path exists but does not contain Cargo.toml: $source_path"
    exit 1
fi

if ! cargo_bin="$(resolve_cargo)"; then
    warn "Skipping Sudoku install because cargo was not found. Install Rust and rerun ./install."
    exit 0
fi

package_name="$(cargo_package_name "$cargo_toml")"
if [ -z "$package_name" ]; then
    package_name="sudoko"
fi

printf '%s\n' "Installing Sudoku from $source_path..."
if ! "$cargo_bin" install --path "$source_path" --locked --force; then
    warn "Skipping Sudoku update because cargo install failed. Fix the Rust build and rerun scripts/install-sudoku.sh."
    exit 0
fi

cargo_install_root="${CARGO_INSTALL_ROOT:-${CARGO_HOME:-$HOME/.cargo}}"
installed_binary="$cargo_install_root/bin/$package_name"

install_linux_desktop_entry "$package_name" "$installed_binary"

if [ -x "$installed_binary" ]; then
    printf '%s\n' "Sudoku installed at $installed_binary"
else
    warn "Sudoku install completed, but the expected binary was not found at '$installed_binary'."
fi
