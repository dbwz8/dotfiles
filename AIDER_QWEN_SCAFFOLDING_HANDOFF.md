# Aider/Qwen Scaffolding Handoff

Date: 2026-07-10
Repo: `/home/dbwz8/git/dotfiles`
Related service repo: `/home/dbwz8/git/tinyAA/projects/chatDBW`

## Current Problem

Aider on the laptop is using the local wrapper to talk to the remote Qwen3 Coder Next service on `weckerAA`, but for new-project scaffolding it keeps generating a huge multi-file patch in one assistant response. It runs until the output token window is exhausted, then Aider applies nothing because the response is incomplete/unparseable.

The user tried explicitly asking for only a subset, including "only do the first 4 files", and the model still attempted all files at once.

Observed failure shape:

- The model emits many `<<<<<<< SEARCH` / `=======` / `>>>>>>> REPLACE` blocks.
- It includes full contents for many new files.
- It hits the output token cap.
- No files are written to disk.

## Important Constraint

Aider does not write partially streamed edits as it goes. It applies edits only after a complete response can be parsed. So if the backend hits `max_tokens` midway through a patch, the practical result is zero written files.

## Current Model/Service

The current backend on `weckerAA` is Qwen3 Coder Next via llama.cpp:

- service: `agents-qwen-coder-next-llama.service`
- raw endpoint on server: `http://127.0.0.1:8023/v1`
- laptop tunnel endpoint: `http://127.0.0.1:18023/v1`
- model id used by Aider: `openai/qwen3-coder-next`
- served alias: `qwen3-coder-next`
- llama.cpp reported context: `n_ctx=131072`
- GGUF path on server: `/mnt/d/data/caches/qwen3-coder-next/Qwen3-Coder-Next-UD-Q2_K_XL.gguf`

A direct backend smoke test accepted `max_tokens=16384`, so the backend is not limited to 8K output. The issue is behavior/instruction adherence and Aider patch atomicity.

## Dotfiles Changes Already Tried

These are in `/home/dbwz8/git/dotfiles` unless reverted later.

### Aider metadata/settings

`configs/aider/aider.model.metadata.json` was adjusted for the 131K backend window. Current intended shape:

```json
{
  "openai/qwen3-coder-next": {
    "max_tokens": 131072,
    "max_input_tokens": 114688,
    "max_output_tokens": 16384,
    "input_cost_per_token": 0,
    "output_cost_per_token": 0,
    "litellm_provider": "openai",
    "mode": "chat"
  }
}
```

`configs/aider/aider.model.settings.yml` currently uses `diff` format, `lazy: true`, and a strong prompt prefix telling the model to edit one file only.

### Aider config

`configs/aider/aider.conf.yml` explicitly sets:

```yaml
model: openai/qwen3-coder-next
openai-api-base: http://127.0.0.1:18023/v1
openai-api-key: local-vllm
edit-format: diff
read:
    - ~/.aider/CONVENTIONS.md
```

Other current values in that file may include `stream: true`, `subtree-only: true`, `auto-commits: true`, and `dirty-commits: true`.

### User conventions

`configs/aider/CONVENTIONS.md` contains an "Output Budget" section with the same one-file hard limit.

### Auto-add behavior

The Aider wrappers previously generated a temporary `--load` file containing `/add` commands for every tracked source file. This was suspected of giving the model too much editable scope.

Changed wrappers so auto-add is now opt-in only:

- `scripts/aider.sh`: `write_auto_add_file` now returns unless `AIDER_AUTO_ADD=1`
- `scripts/aider.ps1`: `New-AiderAutoAddFile` now returns unless `$env:AIDER_AUTO_ADD -eq "1"`

This did not fix the behavior according to the user: Aider still tries to generate all needed files at once.

## Validation Already Done

On `weckerAA`:

- `jq empty configs/aider/aider.model.metadata.json` passed.
- YAML parse via vendored PyYAML passed for Aider config files.
- `bash -n scripts/aider.sh` passed.
- `git diff --check` passed.
- PowerShell wrapper syntax was not checked because `pwsh` is not installed on `weckerAA`.

## Likely Next Things To Check On Laptop

1. Confirm Aider is actually reading the expected files.

   Run Aider with verbose/debug output if available and verify it sees:

   - `~/.aider.conf.yml`
   - `~/.aider.model.metadata.json`
   - `~/.aider.model.settings.yml`
   - `~/.aider/CONVENTIONS.md`

   Also verify those are symlinks into the dotfiles checkout on the laptop.

2. Confirm the wrapper being run is the dotfiles wrapper.

   Check:

   ```bash
   type aider
   which aider
   ls -l ~/.local/bin/aider
   ```

3. Check whether the wrapper is still passing a generated `--load` file.

   It should not unless `AIDER_AUTO_ADD=1` is present in the environment.

   Check:

   ```bash
   env | rg '^AIDER_'
   ```

4. Start Aider with exactly one file argument and no repo-wide context.

   Example:

   ```bash
   AIDER_AUTO_ADD=0 aider roaster/Cargo.toml
   ```

   Prompt:

   ```text
   Create only roaster/Cargo.toml. Do not create, mention, or patch any other file. Stop after Cargo.toml.
   ```

   If it still emits other files, the model/settings are not being honored or the model is not reliable enough with Aider diff format.

5. Try forcing model settings/config explicitly on the command line.

   Depending on installed Aider options, test something like:

   ```bash
   aider \
     --config ~/git/dotfiles/configs/aider/aider.conf.yml \
     --model-settings-file ~/git/dotfiles/configs/aider/aider.model.settings.yml \
     --model-metadata-file ~/git/dotfiles/configs/aider/aider.model.metadata.json \
     roaster/Cargo.toml
   ```

   If this changes behavior, the wrapper/install path is the issue.

6. Consider using Aider architect mode or ask/architect planning first, then explicit one-file edit turns.

   The model may treat a plan file as permission to implement all plan files. A better workflow may be:

   - Keep `PLAN.md` in read-only context.
   - Add exactly one target file.
   - Ask for only that file.
   - Continue file-by-file.

7. Consider switching edit format if Qwen is poor at Aider search/replace discipline.

   Current format is `diff`. If it keeps producing unbounded multi-file SEARCH/REPLACE, test whether `udiff` or another Aider-supported format behaves better with this backend.

8. If all Aider controls fail, the practical workaround may be a small custom wrapper around Aider or direct OpenAI calls that enforces file count post-generation:

   - Ask model for exactly one file as plain content.
   - Write that file locally only if output validates as one file.
   - Repeat from PLAN.md.

   This loses Aider's normal patch machinery but gives deterministic write-as-you-go scaffolding.

## Current Hypothesis

The most likely causes are one of:

- Laptop Aider is not loading `aider.model.settings.yml`, so the hard one-file system prefix is never sent.
- The wrapper still starts Aider with too much editable context or a stale generated load file.
- Qwen3 Coder Next is ignoring the one-file instruction inside Aider's edit prompt, especially when it sees a PLAN.md that describes many files.
- Aider's repo map or chat context is enough to make the model scaffold everything, even with one explicit file argument.

The highest-signal next step is to inspect the actual laptop command line/config Aider is using and the exact `PLAN.md`/prompt that triggers the failure.
