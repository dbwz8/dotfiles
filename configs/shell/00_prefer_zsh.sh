# prefer_zsh.sh - meant to be sourced in .bash_profile/.bashrc

# Change terminal sessions to zsh, preserving Bash commands such as bash -ilc.
if [[ $- == *i* && -z "$ZSH_VERSION" && -z "${BASH_EXECUTION_STRING:-}" && -t 0 && -t 1 ]]; then
    export SHELL=`which zsh`
    if [[ ! -z "${SHELL// }" ]]; then
        unset FPATH # https://github.com/TACC/Lmod/commit/b75b04b7c1a976cf20d633f2d1ca9b0cc6a9db87
        # Only if zsh is installed and we're not already in zsh
        exec "$SHELL" -il
    fi
fi
