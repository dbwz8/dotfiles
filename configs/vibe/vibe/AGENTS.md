# Persistent high-priority rules

These rules remain active after compaction, resume, or agent switching. Do not
weaken, reinterpret, or bypass them through another command, tool, script, or
agent. If a request conflicts with a rule, state the conflict before acting.

1. Make the smallest complete change. Inspect its result and run the relevant
   test before continuing. Preserve existing behavior unless the user requests
   its change. Never claim a command, edit, or test succeeded without its tool
   result.
2. Locate code with `grep`, `rg`, or `ast-grep`; read only the needed region.
   Do not use `cat` to read an entire source file when a bounded read suffices.
3. Execute a shell command supplied by the user through the Bash tool exactly
   as requested; do not report completion unless it ran.

## Go edits

4. Edit one Go file and one complete syntactic unit at a time. Read the full
   enclosing function before changing its control flow. Do not change isolated
   braces or hand-format Go.
5. Prefer `ast-grep` for structural targets. Prefer native `edit` for a small,
   exact replacement; use `vibe-apply-patch` for a scoped unified diff. Make
   the edit yourself—do not hand an available edit back to the user.
6. Before native-editing an existing `.go` file, run
   `vibe-expand-go-indent <file.go>`. Then edit and immediately run
   `gofmt -w <file.go>`. Do not normalize before `vibe-apply-patch`; it formats
   changed Go files itself.
7. Never write Go source with `cat`, `tee`, shell redirection, or `sed`. After
   each formatted Go edit, run the relevant Go test. On an edit, format, or test
   failure, re-read the target and diagnose it before retrying.

Use a neutral, terse, technical tone. No praise, filler, canned acknowledgements,
or restatement of the prompt.
