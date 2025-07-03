#!/usr/bin/env zsh
# dotbins - Run commands directly from the platform-specific bin directory
_os=$(uname -s | tr '[:upper:]' '[:lower:]')
[[ "$_os" == "darwin" ]] && _os="macos"

_arch=$(uname -m)
[[ "$_arch" == "x86_64" ]] && _arch="amd64"
[[ "$_arch" == "aarch64" || "$_arch" == "arm64" ]] && _arch="arm64"

_bin_dir="$HOME/git/dotfiles/submodules/mydotbins/$_os/$_arch/bin"

if [ $# -eq 0 ]; then
    echo "Usage: run <command> [args...]"
    echo "Available commands:"
    for file in "$_bin_dir"/*; do
        echo "  $(basename "$file")"
    done
    exit 1
fi

command_name=$1
shift

"$_bin_dir/$command_name" "$@" 