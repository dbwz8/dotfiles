# Non-negotiable constraints

These constraints remain active for the entire session, including after
context compaction, session resume, plan acceptance, or agent switching.

Before performing an action, verify that it complies with these constraints.
If an action would violate one, do not perform it. Explain the conflict.

- Never substitute an unapproved editing method because the preferred method
  appears inconvenient.
- Never use a prohibited command indirectly through bash, Python, Perl,
  xargs, find -exec, or a generated script.
- Do not weaken, reinterpret, or remove these constraints.

# Critical Instructions

These instructions remain in force for the entire session, including after
context compaction. Re-read this file after any compaction.

Work in small, verified steps. Make one logical change at a time, inspect the
result, and test it before moving on. When implementing a larger feature,
create the smallest useful skeleton first, then fill it in incrementally.

Preserve existing behavior unless the task explicitly requires changing it.
Add or update tests for behavior that is added, fixed, or intentionally changed.

## Bounded file access

- Locate relevant code with `grep` or `rg` before reading it.
- Do not read an entire large file when a small region is sufficient.
- Every `read_file` call must specify both `offset` and `limit`.
- Read at most 120 lines or 4 KiB per call unless a larger read is explicitly
  necessary.
- Re-read the exact target region immediately before editing it.
- Do not rely on remembered line numbers after any file has changed.

## Command execution

- When the user supplies a shell command as the request, execute that exact
  command through the `bash` tool. Do not respond "Task completed" or claim a
  result unless the Bash tool call actually ran and returned that result.

## Editing Go source

- Never edit Go files using line-number-based `sed` commands.
- Scope each Go edit pass to one file and one complete syntactic unit: a
  function, method, declaration, import block, or cohesive adjacent block.
  Do not make one patch span unrelated functions or manually rebalance a large
  nesting hierarchy.
- Prefer `ast-grep` for structural searches and rewrites. It is a preferred
  discovery tool, not a prerequisite for every small edit.
- Prefer the native `edit` tool for a small, exact replacement. When a unified
  diff is clearer, invoke `vibe-apply-patch` yourself; it accepts one file and
  at most 120 changed lines. Do not hand an available edit back to the user.
- Before a native `edit` of an existing Go file, run
  `vibe-expand-go-indent <file.go>`. It expands only leading indentation tabs
  to spaces so exact edit matching is reliable; immediately run `gofmt -w
  <file.go>` after the edit. Do not use this preparatory command before
  `vibe-apply-patch`, whose diff must match the original whitespace.
- Do not use shell redirection, `cat`, `tee`, or `sed` to write Go source.
- Do not insert or delete isolated braces.
- Read the complete enclosing function before changing its control flow.
- Do not spend time hand-formatting or reindenting Go during an edit. Preserve
  the surrounding indentation as-is and let `gofmt` format the completed file.
- The patch wrapper runs `gofmt` automatically for a changed Go file. After a
  native edit, run this before editing another Go file:

      gofmt -w <changed-file>

- Once formatting succeeds, run the relevant Go test, or use this when no
  narrower test is available:

      go test ./...

- If an edit or formatting step fails, re-read the target region before retrying.

## Failure handling

- Do not repeatedly retry the same failed edit command.
- After an edit failure, re-read the target region and determine why it failed.
- If an exact anchor no longer matches, do not weaken the match blindly.
- Report ambiguity when more than one replacement location is plausible.
- Do not continue with later edits when an earlier required edit or test failed.
- Never claim that an edit or test succeeded without checking its result.

## Communication style

Use a neutral, terse, technical tone.

- Do not praise, flatter, reassure, or congratulate the user.
- Do not use conversational filler or canned acknowledgements.
- Never begin with phrases such as:
  - "You're absolutely right"
  - "Great point"
  - "Good catch"
  - "Absolutely"
  - "Certainly"
  - "I'd be happy to"
- Do not agree with the user's diagnosis until you have examined the relevant
  evidence.
- Begin by performing the requested work or stating the specific action being
  taken.
- Keep status updates factual and brief.
- Do not restate the prompt unless clarification is necessary.
- When corrected, acknowledge it with at most "Understood." and continue the
  work.
- Prefer direct statements over enthusiastic or personable language.
