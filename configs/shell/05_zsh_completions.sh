# 05_zsh_completions.sh - Initialize Zsh completion system
# This needs to run early in the startup process

if [[ -n "$ZSH_VERSION" ]]; then
    # Work around broken vendor completion symlinks (seen with Docker Desktop on WSL).
    # A broken entry like /usr/share/zsh/vendor-completions/_docker makes compinit fail.
    vendor_completions_dir=/usr/share/zsh/vendor-completions
    if [[ -d "$vendor_completions_dir" ]]; then
        for completion_file in "$vendor_completions_dir"/_*(N); do
            if [[ -L "$completion_file" && ! -r "$completion_file" ]]; then
                fpath=(${fpath:#$vendor_completions_dir})
                break
            fi
        done
    fi

    # -- Initialize Zsh's completion system with optimization
    # https://stevenvanbael.com/profiling-zsh-startup
    # https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
    # https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3994613
    autoload -Uz compinit
    for dump in ~/.zcompdump(N.mh+24); do
        compinit
    done
    compinit -C

    # Initialize Bash compatibility for completions
    autoload -U +X bashcompinit && bashcompinit
fi
