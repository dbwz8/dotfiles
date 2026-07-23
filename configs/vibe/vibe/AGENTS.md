# Critical Instructions

These instructions remain in force for the entire session, including after
context compaction.
Re-read this file after any compaction

You need to make small edits since we run out of output tokens.
Implement stubs of routines first and then fill in each routine one at a time as you write code.
All implemented techniques need comprehensive testing.
Please make sure these tests are maintained and adhered to.

## Bounded file access and editing policy

- Locate code with `grep` before reading. Do not read an entire file.
- Every `read_file` call must specify both `offset` and `limit`; read at most
  120 lines or 4 KiB per call.
- The `edit` and `write_file` tools are disabled.
- Prefer `apply_patch` or a unified diff for normal source changes.
- Include enough unchanged context to identify the correct location.
- Do not replace an entire file unless most of it must change.
- Preserve formatting on unchanged lines. For newly added Go source, follow the mandatory column-1 policy below and let gofmt apply indentation.
- After editing, run the appropriate formatter and focused tests.
- Use a short Python script when the edit is mechanical and repeated, especially across multiple files.

## Go editing: mandatory whitespace policy

For `.go` files, `gofmt` is solely responsible for indentation.

When adding or replacing Go source code:

* Write every added Go source line starting in column 1.

* Do not emit leading tabs.

* Do not emit leading spaces for indentation.

* Do not manually align fields, parameters, expressions, comments, or composite literals.

* Preserve syntactic nesting with braces, parentheses, and brackets, not whitespace.

* Immediately after each patch, run:

  ```sh
  gofmt -w <each-modified-go-file>
  ```

* Inspect and test the formatted file rather than manually repairing its whitespace.

* Existing unchanged lines used as patch context may retain their original indentation.

* These rules apply only to added or replacement lines. Do not strip whitespace from unchanged source lines.

* Do not omit indentation inside raw string literals or other content where whitespace is data.

This is a token-conservation requirement, not a style preference. A patch that manually indents newly added Go source violates these instructions even if the indentation is correct.

### Required example

Write this:

```go
func example() {
if condition {
doSomething()
}
}
```

Then run `gofmt`.

Do not write this manually:

```go
func example() {
	if condition {
		doSomething()
	}
}
```

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
- Do not agree with the user's diagnosis until you have examined the
  relevant evidence.
- Begin by performing the requested work or stating the specific action
  you are taking.
- Status updates must be factual and brief.
- Do not restate the prompt unless clarification is necessary.
- When corrected, acknowledge it with at most "Understood." and then
  continue the work.
- Prefer direct statements over enthusiastic or personable language.

