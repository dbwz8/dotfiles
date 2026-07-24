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

## Editing Go source

- Never edit Go files using line-number-based `sed` commands.
- Scope each Go edit pass to one file and one complete syntactic unit: a
  function, method, declaration, import block, or cohesive adjacent block.
  Do not make one patch span unrelated functions or manually rebalance a large
  nesting hierarchy.
- Before every Go edit, run `ast-grep` to identify the exact target node.
  Use an `ast-grep` rewrite only when it selects one intended node.
- Otherwise, apply a standard unified diff through `vibe-apply-patch`. It
  accepts one file and at most 120 changed lines, so split larger work into
  separate edit passes. Never invoke an unqualified `apply_patch` command.
- Only when neither structural rewrite nor the scoped patch can express the
  change, invoke the fallback exactly as `uv run python <script>`; never use
  `python` or `python3` directly. The script must:
    - searches for an exact, unique anchor;
    - refuses to edit unless exactly one match is found;
    - replaces a complete syntactic unit such as a function, method, statement,
    declaration, or import block.
- Do not use shell redirection, `cat`, `echo`, or direct Python to write Go
  source.
- Do not insert or delete isolated braces.
- Read the complete enclosing function before changing its control flow.
- Before editing a file, preserve its current contents in a temporary file.
- Do not spend time hand-formatting or reindenting Go during an edit. Preserve
  the surrounding indentation as-is and let `gofmt` format the completed file.
- After all intended edits to one Go file are complete, run this before editing
  another Go file:

      gofmt -w <changed-file>

- If `gofmt` fails:
  - do not edit another file;
  - inspect the first reported syntax error;
  - either correct the current edit or restore the saved file.
- Once formatting succeeds, run:

      go test ./...

- Do not stack additional changes on top of a file that does not parse.
- If a formatted file needs another edit, re-read the complete enclosing
  syntactic unit and start a new small edit pass.

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
