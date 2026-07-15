# Global Qwen Code Instructions

## Editing Discipline

- For existing files, do not rewrite whole files. Read the target file, adjacent implemented examples, and relevant tests before editing.
- Use small, targeted edits by default for existing source files.
- Prefer small `edit` patches for existing files. Use `write_file` only when replacing a whole file is explicitly safer, and verify the result immediately afterward.
- Do not use base64, generated scripts, or shell heredocs to bypass editing limits for source changes.
- If a change is too large, split it into small verified patches.
- After a failure, inspect the exact error and make the minimum necessary correction instead of rewriting the implementation.
- For implementation work, proceed in narrow steps: add helpers, implement one behavior, run the focused test, then continue.

## Debugging Discipline

- State the invariant before changing code. Do not weaken or revert a correct invariant just to satisfy a downstream test.
- Reduce failures to the smallest repro before broad edits. Prefer one focused failing assertion over repeated broad package runs.
- Trace the boundary where state changes. For derived or cached state, check where it is created, invalidated, rebuilt, cloned, and consumed.
- Use one hypothesis at a time. Before editing, write the current hypothesis in one sentence and make the smallest change that proves or disproves it.
- After two failed fix attempts, stop and summarize the invariant, failing behavior, attempts, evidence, and next ambiguity instead of continuing to edit.
- Do not loop on unchanged test commands. Re-run the same failing test only after a meaningful code or test change.
- Prefer boundary fixes over symptom fixes. If a caller passes stale or inconsistent state, fix the handoff, rebuild, or validation point rather than making downstream code silently tolerate invalid assumptions.
- If a correct invariant breaks a downstream test, assume stale derived state or a bad boundary contract before changing the invariant.
- Finish debugging reports with the root cause, changed files or functions, targeted tests run, and remaining risk.
