# keychain.sh - meant to be sourced in .bash_profile/.zshrc

# Check if keychain is installed and the key exists
if command -v keychain &> /dev/null && [[ -f ~/.ssh/id_ed25519 ]]; then
    # On macOS, use 1Password (if available) to provide passphrase for SSH keys
    if [[ `uname` == 'Darwin' ]] && command -v op &> /dev/null; then
        # Set SSH_ASKPASS to use the 1Password helper script for passphrase prompts
        export SSH_ASKPASS="$HOME/.ssh/askpass-1password.sh"
        # Ensure ssh-add uses SSH_ASKPASS even in non-graphical/terminal sessions.
        export SSH_ASKPASS_REQUIRE="prefer"
    fi

    # Execute keychain:
    # --eval: Output shell commands (export SSH_AUTH_SOCK=...; export SSH_AGENT_PID=...)
    # --quiet: Suppress informational messages.
    # id_ed25519: The specific key to load into the agent (will use SSH_ASKPASS).
    if [ -t 0 ] && [ -z "${WSL_DISTRO_NAME:-}" ]; then
        # Interactive terminal outside WSL - allow prompting
        eval $(keychain --eval --quiet id_ed25519) || true
    else
        # Non-interactive sessions and WSL - don't prompt
        eval $(keychain --eval --quiet --noask id_ed25519)
    fi

    # Clean up the temporary ASKPASS variables; they are only needed when adding keys.
    unset SSH_ASKPASS
    unset SSH_ASKPASS_REQUIRE

    # Or use 1Password SSH agent (https://developer.1password.com/docs/ssh/get-started/)
    # export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
fi