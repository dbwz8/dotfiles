# main.sh - can be sourced in .bash_profile/.bashrc or .zshrc

if [ -z "${DOTFILES:-}" ]; then
    if [ -n "${BASH_SOURCE[0]:-}" ]; then
        _dotfiles_source="${BASH_SOURCE[0]}"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        _dotfiles_source="${(%):-%N}"
    else
        _dotfiles_source="$0"
    fi
    export DOTFILES="$(cd -P "$(dirname "$_dotfiles_source")/../.." && pwd)"
    unset _dotfiles_source
fi

[ -n "$BASH_VERSION" ] && source "$DOTFILES/configs/shell/00_prefer_zsh.sh"  # no-op in zsh
[ -n "$ZSH_VERSION" ] && source "$DOTFILES/configs/shell/05_zsh_completions.sh"
source "$DOTFILES/configs/shell/10_functions.sh"
source "$DOTFILES/configs/shell/15_exports.sh"
source "$DOTFILES/configs/shell/20_aliases.sh"
source "$DOTFILES/configs/shell/30_misc.sh"
source "$DOTFILES/configs/shell/40_keychain.sh"
source "$DOTFILES/configs/shell/50_python.sh"
source "$DOTFILES/configs/shell/60_slurm.sh"
source "$DOTFILES/configs/shell/65_VcXsrv.sh"
[ -n "$ZSH_VERSION" ] && source "$DOTFILES/configs/shell/70_zsh_plugins.sh"
