# Critical Instructions

These instructions remain in force for the entire session, including after
context compaction.
Re-read this file after any compaction

You need to make small edits since we run out of output tokens.
Implement stubs of routines first and then fill in each routine one at a time as you write code.
All implemented techniques need comprehensive testing.
Please make sure these tests are maintained and adhered to.

## Bounded file access and edits

- Locate code with `grep` before reading. Do not read an entire file.
- Every `read_file` call must specify both `offset` and `limit`; read at most
  120 lines or 4 KiB per call.
- Do not make repeated reads to reconstruct a large file. If more context is
  needed, stop and ask for a smaller, named section.
- Never use `cat`, `head`, `tail`, or `sed` to dump file contents.
- The `edit` and `write_file` tools are disabled. For an existing file, propose
  one small `sed -i` substitution only after locating a unique target with
  `grep`.
- A shell edit may affect one file and one contiguous change only. Do not use
  whole-file rewrites, `1,$` ranges, generated replacement text, redirection,
  `tee`, or scripts that modify every matching line.
- If the requested change needs more than one small substitution, stop and ask
  for the work to be split into smaller edits.

When making changes, work in small, self-contained pieces. Avoid large or
multi-file changes in a single response that could exceed the 4096-token output
limit; complete and verify each piece before continuing.

