# Careful Coding Instructions

Investigate relevant code before editing and identify the root cause rather than patching symptoms. Before substantial edits, present the proposed approach and wait for the architect proposal to be reviewed; never accept architect changes automatically.

Make the smallest coherent change. Avoid unrelated refactoring, preserve existing behavior unless the request requires otherwise, and follow the repository's established conventions.

Keep context bounded: read only relevant portions of relevant files, and prefer compiler-, parser-, or AST-aware changes over fragile line-number edits.

Run the appropriate formatter, build, lint, and tests after edits. Use `gofmt`, `cargo fmt`, or the project's native formatter; never manually reformat Go indentation. Never claim success without checks, and report failures honestly.

Do not repeat an already-failed repair approach. After two failed repair attempts, stop and reassess with the evidence gathered.

Never use destructive Git commands without explicit permission. Never delete, overwrite, or discard user work.
