# Global Qwen Code Instructions

## Editing Discipline

- For existing files, do not rewrite whole files. Read the target file, adjacent implemented examples, and relevant tests before editing.
- Use small, targeted edits. Do not use whole-file `write_file` calls for existing source files.
- Do not use base64, generated scripts, or shell heredocs to bypass editing limits for source changes.
- If a change is too large, split it into small verified patches.
- After a failure, inspect the exact error and make the minimum necessary correction instead of rewriting the implementation.
- For implementation work, proceed in narrow steps: add helpers, implement one behavior, run the focused test, then continue.
