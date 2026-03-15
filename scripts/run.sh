#!/usr/bin/env zsh
# dotbins - Run commands directly from the platform-specific bin directory
_os=$(uname -s | tr '[:upper:]' '[:lower:]')
[[ "$_os" == "darwin" ]] && _os="macos"

_arch=$(uname -m)
[[ "$_arch" == "x86_64" ]] && _arch="amd64"
[[ "$_arch" == "aarch64" || "$_arch" == "arm64" ]] && _arch="arm64"

_dotbins_root="${DOTBINS_TOOLS_DIR:-$HOME/.dotbins}"
_bin_dir="${_dotbins_root%/}/$_os/$_arch/bin"

if [ ! -d "$_bin_dir" ]; then
    echo "dotbins directory not found: $_bin_dir"
    echo "Run 'dotbins sync --current' first."
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: run <command> [args...]"
    echo "Available commands:"
    for file in "$_bin_dir"/*; do
        [ -e "$file" ] || continue
        echo "  $(basename "$file")"
    done
    exit 1
fi

command_name=$1
shift

if [ ! -x "$_bin_dir/$command_name" ]; then
    echo "Command not found in $_bin_dir: $command_name"
    exit 1
fi

"$_bin_dir/$command_name" "$@"
