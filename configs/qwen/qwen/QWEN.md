# Global Qwen Code Instructions

## Editing Discipline

- For existing files, do not rewrite whole files. Read the target file, adjacent implemented examples, and relevant tests before editing.
- Use small, targeted edits by default for existing source files.
- Prefer small `edit` patches for existing files. Use `write_file` only when replacing a whole file is explicitly safer, and verify the result immediately afterward.
- Do not use base64, generated scripts, or shell heredocs to bypass editing limits for source changes.
- If a change is too large, split it into small verified patches.
- After a failure, inspect the exact error and make the minimum necessary correction instead of rewriting the implementation.
- For implementation work, proceed in narrow steps: add helpers, implement one behavior, run the focused test, then continue.

## Plan Execution Discipline

- When a repository has a `PLAN.md`, treat it as the project contract. Read the relevant section before editing.
- Work on one plan item or clearly bounded sub-item at a time.
- Before changing code, identify the target plan item, the expected exit criteria, and the focused test or command that will prove the change.
- If a plan item is too broad to complete safely, split the plan into smaller reviewable steps before implementation.
- Do not mark a plan item complete until its exit criteria are satisfied and the relevant validation commands pass.
- If a validation phase exposes a product bug, reduce it to one focused failing test before broad implementation changes.
- Keep diagnostic/reporting tests separate from required pass/fail tests. Do not make a broad diagnostic pass by weakening exact checks.

## Stub Discovery Discipline

- If a validation task discovers that the target behavior is a stub, placeholder, TODO, panic, or explicitly unimplemented path, stop the validation task and report that as the result.
- Do not silently turn a validation task into a feature implementation task. Ask for direction or update the plan first.
- Before implementing a formerly stubbed feature, identify the source of truth, expected behavior, smallest useful slice, and focused tests.
- Do not mark surrounding validation work complete because a stub was partially filled in. The implementation needs its own reviewable plan item and validation.
- If the plan claims a behavior is implemented but the code is a stub, report the plan/code mismatch instead of trying to reconcile it with broad edits.
- Treat broad fixture failures against a stub as inventory evidence, not as a signal to implement the whole missing subsystem immediately.

## Debugging Discipline

- State the invariant before changing code. Do not weaken or revert a correct invariant just to satisfy a downstream test.
- Reduce failures to the smallest repro before broad edits. Prefer one focused failing assertion over repeated broad package runs.
- Trace the boundary where state changes. For derived or cached state, check where it is created, invalidated, rebuilt, cloned, and consumed.
- Use one hypothesis at a time. Before editing, write the current hypothesis in one sentence and make the smallest change that proves or disproves it.
- After two failed fix attempts, stop and summarize the invariant, failing behavior, attempts, evidence, and next ambiguity instead of continuing to edit.
- Do not loop on unchanged test commands. Re-run the same failing test only after a meaningful code or test change.
- Do not keep creating ad hoc scratch programs for the same investigation. After one scratch probe, either convert the repro into a focused test or summarize why the evidence is inconclusive and stop.
- Prefer boundary fixes over symptom fixes. If a caller passes stale or inconsistent state, fix the handoff, rebuild, or validation point rather than making downstream code silently tolerate invalid assumptions.
- If a correct invariant breaks a downstream test, assume stale derived state or a bad boundary contract before changing the invariant.
- Finish debugging reports with the root cause, changed files or functions, targeted tests run, and remaining risk.
