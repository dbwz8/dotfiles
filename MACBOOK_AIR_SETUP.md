# MacBook Air Development Setup

This is the first-boot checklist for setting up an M2 MacBook Air for this dotfiles environment, Codex, VS Code, GitHub, and browser-based work. Follow it in order on the new laptop.

## 1. First macOS Setup

1. Turn on the MacBook Air, connect to Wi-Fi, and complete the Apple setup screens.
2. Sign in with your Apple ID if you want iCloud, Find My, and App Store purchases on this machine.
3. Open **System Settings** and run any available macOS updates:
   - **System Settings** -> **General** -> **Software Update**
   - Install updates and restart if prompted.
4. Open **Terminal**:
   - Press `Cmd+Space`
   - Type `Terminal`
   - Press `Return`

Keep Terminal open for most of the remaining steps.

## 2. Install Apple Command Line Tools

Git and compiler tools come from Apple's Command Line Tools package. In Terminal, run:

```bash
xcode-select --install
```

Click **Install** in the popup and wait for it to finish. If Terminal says the tools are already installed, continue.

Verify Git works:

```bash
git --version
```

## 3. Clone Your Dotfiles

Use HTTPS for the first clone so the setup does not depend on SSH or 1Password yet:

```bash
mkdir -p ~/git
git clone https://github.com/dbwz8/dotfiles.git ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive --remote --jobs 8
```

If GitHub asks for authentication, open `https://github.com/login` in Safari or Chrome, sign in, and retry the command.

## 4. Run the Dotfiles Installer

From Terminal:

```bash
cd ~/dotfiles
DOTFILES_MACOS_COMPUTER_NAME="wecker-macbook-air" ./install
```

What this does:

- Installs Homebrew if it is missing.
- Installs core developer tools and apps from `configs/macos/Brewfile`, including 1Password, Google Chrome, iTerm2, Karabiner Elements, Keyboard Maestro, VS Code, Git, Neovim, `uv`, and Rust setup.
- Installs Rosetta for Intel-only Mac apps when needed.
- Applies basic macOS defaults for keyboard repeat, Finder, Dock, and screenshots.
- Links your dotfiles with Dotbot.
- Installs Codex CLI through `scripts/install-codex.sh`.
- Syncs dotbins and `uv` tools.

If the installer stops because Command Line Tools or Homebrew asked for setup, finish that prompt and run the same `./install` command again.

## 5. Restart the Terminal Session

After `./install` completes, close Terminal. Open **iTerm2** from Applications or Spotlight:

1. Press `Cmd+Space`.
2. Type `iTerm2`.
3. Press `Return`.

The shell should now load your dotfiles. Check the basics:

```bash
echo "$SHELL"
git --version
brew --version
uv --version
codex --version
```

If `codex` is not found, run:

```bash
~/dotfiles/scripts/install-codex.sh
```

Then close and reopen iTerm2.

## 6. Set Up 1Password and GitHub SSH

1. Open **1Password**.
2. Sign in to your 1Password account.
3. Enable the 1Password SSH agent:
   - Open 1Password settings.
   - Go to **Developer**.
   - Turn on **Use the SSH agent**.
4. Make sure your GitHub SSH key is present in 1Password.

Verify GitHub SSH:

```bash
ssh -T git@github.com
```

The first time, type `yes` when asked to trust GitHub's host key. A successful result usually says GitHub authenticated you but does not provide shell access.

Switch your dotfiles checkout to SSH once SSH works:

```bash
cd ~/dotfiles
git remote set-url origin git@github.com:dbwz8/dotfiles.git
git remote -v
```

## 7. Set Up Git Identity

Check the linked Git config:

```bash
git config --global user.name
git config --global user.email
```

If either value is wrong, edit:

```bash
nvim ~/dotfiles/configs/git/gitconfig-personal
```

Then verify again:

```bash
git config --global user.name
git config --global user.email
```

## 8. Sign In to Codex

Codex is installed by the dotfiles installer. Sign in from iTerm2:

```bash
codex login
```

Choose **Sign in with ChatGPT** unless you specifically want API-key billing. Codex will open a browser window. Complete the login flow there, then return to iTerm2.

Verify Codex:

```bash
codex doctor
codex --ask-for-approval never "Summarize the active instructions for this repository."
```

Codex reads global guidance from `AGENTS.md` in your Codex home and project guidance from `AGENTS.md` files in the repository. This dotfiles repo links the base Codex config under `~/.codex`. On `wecker-macbook-air`, the shell sets `CODEX_HOME=~/.codex-local` and filters corporate MCP servers out of the active config.

Check the active Codex home:

```bash
echo "${CODEX_HOME:-$HOME/.codex}"
```

Useful Codex commands:

```bash
codex
codex --cd ~/dotfiles
codex app ~/dotfiles
codex update
```

## 9. Set Up VS Code

Open VS Code:

```bash
open -a "Visual Studio Code"
```

Your dotfiles link these VS Code files automatically:

- `~/Library/Application Support/Code/User/settings.json`
- `~/Library/Application Support/Code/User/keybindings.json`

Install the shell command:

1. In VS Code, press `Cmd+Shift+P`.
2. Type `Shell Command`.
3. Choose **Shell Command: Install 'code' command in PATH**.

Verify from iTerm2:

```bash
code --version
code ~/dotfiles
```

Install the Codex IDE extension:

1. Open VS Code.
2. Open Extensions with `Cmd+Shift+X`.
3. Search for `Codex`.
4. Install the official OpenAI Codex extension.
5. Sign in when prompted.

The Codex IDE extension shares configuration with the Codex CLI. Use the Codex sidebar for editor-aware coding tasks, and use iTerm2 plus `codex` for terminal-first work.

## 10. Set Up Chrome and Browser Work

Google Chrome is installed by the Brewfile. Open it:

```bash
open -a "Google Chrome"
```

Sign in to your browser profile if you want bookmarks, extensions, and history synced.

Install the usual browser extensions manually:

- 1Password browser extension
- Any work SSO or password-manager extensions you need
- GitHub-related extensions you rely on

For Codex browser control, use Chrome:

1. Open Codex with `codex app ~/dotfiles`.
2. In Codex, open **Plugins**.
3. Add the **Chrome** plugin.
4. Follow the setup flow to install the Codex Chrome extension.
5. Open Chrome and confirm the Codex extension shows **Connected**.

Use the Codex Chrome extension only when Codex needs your signed-in browser state. For local development previews and public pages, use Codex's in-app browser first.

## 11. macOS Permission Prompts

macOS will ask for permissions as you start using tools. Approve these when prompted:

- **Karabiner Elements**: Input Monitoring and Accessibility.
- **Keyboard Maestro**: Accessibility.
- **iTerm2**: Full Disk Access if you want terminal tools to access protected folders.
- **VS Code**: file, folder, terminal, and Git permissions as needed.
- **Chrome**: extension permissions for 1Password and Codex.

If something does not work, check:

**System Settings** -> **Privacy & Security**

## 12. Final Verification

Run this from iTerm2:

```bash
cd ~/dotfiles
git status --short --branch
brew bundle check --file configs/macos/Brewfile
dotbins status
uv tool list
codex doctor
code ~/dotfiles
```

Expected state:

- `git status` shows the branch and no unexpected local edits.
- `brew bundle check` says dependencies are satisfied or tells you what to install.
- `dotbins status` shows tools for `macos/arm64`.
- `codex doctor` does not report missing installation or authentication.
- VS Code opens the dotfiles repo.

## Troubleshooting

### `git clone` fails

Use the HTTPS URL first:

```bash
git clone https://github.com/dbwz8/dotfiles.git ~/dotfiles
```

Set up SSH after 1Password is installed and signed in.

### `brew` is not found

Run the installer again:

```bash
cd ~/dotfiles
./install
```

Then close and reopen iTerm2.

### `codex` is not found

Run:

```bash
~/dotfiles/scripts/install-codex.sh
```

Then close and reopen iTerm2.

### Codex login opens the wrong browser

Copy the login URL from Terminal and paste it into Chrome. If browser login still fails, run:

```bash
codex login --device-auth
```

### VS Code settings are missing

Re-run Dotbot through the main installer:

```bash
cd ~/dotfiles
./install
```

Then restart VS Code.

### Homebrew says an app already exists

Usually this is safe. Continue setup, then run:

```bash
brew bundle check --file ~/dotfiles/configs/macos/Brewfile
```

Install anything missing with:

```bash
brew bundle --file ~/dotfiles/configs/macos/Brewfile
```
