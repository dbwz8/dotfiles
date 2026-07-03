# Repository Guidelines

## Scope
- These instructions apply to the entire repository.
- This is a cross-platform dotfiles repo for macOS, Linux, WSL, and Windows. It uses Dotbot for symlink installation, dotbins for managed CLI binaries, and git submodules for external projects.
- Keep changes minimal and task-focused. Do not refactor unrelated shell, editor, or installer behavior while making a targeted change.

## Git Safety
- Never force-push, rebase, amend commits, rewrite history, or merge into `main`.
- If files or commits change unexpectedly, assume the user changed them. Do not revert user work unless explicitly asked.
- Always run `git status` before `git add -A` or `git add .`.
- After staging, verify the staged set before committing.
- Treat `submodules/` as external code. Do not edit submodule contents unless the task explicitly requires updating vendored upstream content or submodule pins.

## Tooling
- Prefer `rg` and `rg --files` for searching.
- For ad hoc Python or Python-package commands, use `uv run` or `uv tool run`; do not run `python`, `python3`, `pip`, or `pip3` directly. Existing installer scripts may invoke Python internally for Dotbot compatibility.
- Use Bash-compatible shell syntax for shared Unix scripts unless a file is explicitly zsh-only. Preserve PowerShell idioms in `.ps1` files.
- Keep files ASCII unless an existing file already uses non-ASCII content for a clear reason.

## Common Commands
- Initialize submodules: `git submodule update --init --recursive --remote --jobs 8`
- Install Unix-like systems: `./install`
- Skip system package installation during a Unix install: `DOTFILES_INSTALL_SYSTEM_PACKAGES=0 ./install`
- Install Windows: `powershell -ExecutionPolicy Bypass -File ./install.ps1`
- Try the environment in Docker: `docker build -t dotfiles-env .` then `docker run -it --rm dotfiles-env`
- Sync local submodules and tools: `./scripts/sync-local-dotfiles.sh`

## Validation
- Run `git diff --check` before finishing edits.
- Run `pre-commit run --all-files` when `pre-commit` is available; `.pre-commit-config.yaml` is currently a placeholder, so this mainly verifies the repo-level hook entry point.
- For installer or symlink changes, prefer the narrowest safe validation first, such as inspecting the relevant Dotbot YAML and running the installer only when the task requires it.
- For README updates, preserve the existing markdown-code-runner generated-block markers. Regenerate generated sections only when the task specifically touches those sections and the required tooling is available.

## Project Map
- `install` is the Unix entry point and delegates package setup, Dotbot, Codex setup, Sudoku setup, dotbins sync, and tmux session links.
- `install.ps1` is the Windows entry point.
- `install.conf.yaml` and `install.windows.conf.yaml` define Dotbot links.
- `configs/shell/` contains shared shell initialization loaded by both zsh and bash.
- `configs/nvim/` wraps the `submodules/kickstart.nvim` configuration.
- `configs/codex/`, `configs/gemini/`, and `configs/claude/` hold local AI tool configuration.
- `scripts/` contains helper installers, sync utilities, and user-facing command wrappers.
