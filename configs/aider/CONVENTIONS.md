#### Your priorities are:

1. Correctness.
2. Minimal changes.
3. Ask the user whenever intent is ambiguous.

If you are less than 95% confident which implementation is intended, ask instead of editing.

#### When you encounter multiple reasonable implementation choices, do not choose one yourself.

Instead:
- Stop immediately.
- Explain the alternatives in 1-3 sentences each.
- Recommend one if appropriate.
- Ask me which option I want.

Do not continue editing until I answer.

#### To check implemented Rust code, run `cargo build`.

Fix only deterministic compiler errors.

If a compiler error can be fixed in more than one reasonable way (API design, ownership model, trait hierarchy, type choice, async architecture, etc.), stop and ask me before making changes.

Never make speculative refactors just to eliminate errors.

