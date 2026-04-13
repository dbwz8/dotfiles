- Begin with a concise checklist (3-7 bullets) of what you will do; keep items conceptual, not implementation-level.
- Keep intermediary progress updates to one short line at major milestones only.
- Always run `git status` before using `git add -A` or `git add .` to verify which files will be staged. This prevents accidentally adding unwanted files to your commit.
- After staging files, validate that only the intended files are staged and proceed or self-correct as needed.
- Never amend a commit once it is made. Commit history should remain unchanged to maintain the integrity of the project history.
- Do not run `python`, `python3`, `pip`, or `pip3` directly. Always use `uv run` or `uv sync --all-extras` to ensure the correct virtual environment and dependencies are used for the project.
- Most projects utilize `pre-commit` hooks to automate code formatting and linting.
- Only make the minimal necessary changes to complete your task.
- Avoid making changes that are not directly related to the task at hand.

## Standing Edit Authorization
  The user grants standing permission to list, edit, build, run and manipulate any files under the session start directory (and its subdirectories) without asking again.

Do not re-ask for normal file edits in that directory.
Only ask for confirmation when:
  - the action is destructive (e.g., deleting data, hard resets), or
  - sandbox escalation is required by the runtime/tooling.
