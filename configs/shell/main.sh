# main.sh - can be sourced in .bash_profile/.bashrc or .zshrc

[ -n "$BASH_VERSION" ] && source ~/git/dotfiles/configs/shell/00_prefer_zsh.sh  # no-op in zsh
[ -n "$ZSH_VERSION" ] && source ~/git/dotfiles/configs/shell/05_zsh_completions.sh
source ~/git/dotfiles/configs/shell/10_functions.sh
source ~/git/dotfiles/configs/shell/15_exports.sh
source ~/git/dotfiles/configs/shell/20_aliases.sh
source ~/git/dotfiles/configs/shell/30_misc.sh
source ~/git/dotfiles/configs/shell/40_keychain.sh
source ~/git/dotfiles/configs/shell/50_python.sh
source ~/git/dotfiles/configs/shell/60_slurm.sh
[ -n "$ZSH_VERSION" ] && source ~/git/dotfiles/configs/shell/70_zsh_plugins.sh
