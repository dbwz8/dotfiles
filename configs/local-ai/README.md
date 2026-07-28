# Local AI Coding Workflow

This is the cautious replacement for the Vibe/Devstral coding workflow. It runs
GLM-4.7-Flash locally through llama.cpp and starts Aider in architect mode with
manual architect acceptance. It runs automatically as a user service and does
not remove existing models or services.

## Install

Run `~/git/dotfiles/scripts/local-ai-setup.sh`. It clones llama.cpp into
`~/.local/opt/llama.cpp`, builds a CUDA `llama-server`, and downloads the
configured `MXFP4` GGUF to `~/.local/share/local-ai-coding/models`. The default
download is about 15.9 GiB. Re-running the script rebuilds safely and resumes a
partial model download.

Configuration is in `~/.config/local-ai-coding.env` after Dotbot installation,
or in `configs/local-ai/local-ai.env` when the scripts are run from this clone.
It contains no secrets. Set `LOCAL_AI_UPDATE_LLAMA=1` only when deliberately
updating the llama.cpp checkout.

## Start and verify

```bash
~/git/dotfiles/scripts/local-ai-server-start.sh
~/git/dotfiles/scripts/local-ai-server-health.sh
~/git/dotfiles/scripts/local-ai-server-status.sh
```

The endpoint binds only to `127.0.0.1:8000` and exposes `/v1/models` and
`/v1/chat/completions` as model `glm-4.7-flash-local`. View logs with
`local-ai-server-status.sh logs --follow`; stop it with `local-ai-server-stop.sh`.

## Automatic startup

`local-ai-glm.service` is a user systemd service. After `./install` has linked
the unit, `local-ai-setup.sh` enables and starts it automatically. To restore
or enable it manually, run:

```bash
systemctl --user enable --now local-ai-glm.service
loginctl enable-linger "$(id -un)"
```

The second command keeps the service running after boot even before the first
interactive login. Inspect it with `systemctl --user status local-ai-glm.service`
or `journalctl --user -u local-ai-glm.service -f`.

The normal `local-ai-server-start.sh` and `local-ai-server-stop.sh` commands
delegate to this service when it is enabled, so they remain the convenient
manual lifecycle commands.

## Client machines

`aider` first uses a healthy local endpoint. If none is available, it
automatically opens an SSH tunnel to `weckerAA`, forwarding the server's
`127.0.0.1:8000` endpoint to the client's `127.0.0.1:18000`. Set
`AIDER_REMOTE_HOST` to use another server, `AIDER_SERVER_MODE=local` to forbid
the fallback, or `AIDER_SERVER_MODE=remote` to always use it.

## Careful Aider workflow

From a focused directory in a Git repository, run `aider`. The wrapper checks
the local endpoint, enables architect mode, disables auto-acceptance, and adds
no source files by itself. Add only relevant files in Aider. It refuses a
repository root with more than 500 tracked files unless passed
`--allow-repo-root`.

It suggests and enables per-repository validation. Override it without changing
global configuration:

```bash
aider --test-cmd 'cargo fmt --check && cargo test'
```

Go uses `gofmt -w` through Aider's changed-file lint hook followed by
`go test ./...`; Go formatting remains authoritative. Rust defaults to
`cargo fmt --check && cargo test`. Python uses existing Ruff configuration when
present, otherwise `uv run pytest`.

The one shared instruction file is `~/.aider/CONVENTIONS.md`, managed from
`configs/aider/CONVENTIONS.md`. It is loaded by the local Aider profile so
there are no per-project copies to conflict.

## Troubleshooting and tuning

Use `local-ai-server-status.sh` and its log mode first. If startup fails, make
sure no other model server is consuming GPU memory and that port 8000 is free.
The default 32K context is deliberate; reduce `LOCAL_AI_CTX_SIZE` to 24576 if
VRAM is tight. Do not raise it before confirming stable health checks. Change
`LOCAL_AI_MODEL_REPO`, `LOCAL_AI_MODEL_FILE`, and `LOCAL_AI_MODEL_NAME` together
when replacing the model, then rerun setup and health checks.

## Removal

First run `systemctl --user disable --now local-ai-glm.service`. Then remove
only the dedicated paths if no longer wanted: `~/.local/opt/llama.cpp`,
`~/.local/share/local-ai-coding`, and `~/.local/state/local-ai-coding`. Remove
the Dotbot-managed unit link only if the dotfiles no longer manage this
workflow. Existing Devstral, Vibe, models, containers, and Python environments
are unaffected.
