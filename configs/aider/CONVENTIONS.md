# CONVENTIONS.md

## Primary Goal

Produce correct, minimal changes.

Prefer making one small, verifiable improvement over making many speculative changes.

---

# Workflow

For every task:

1. Read the relevant files before editing.
2. Explain your plan in 2-5 bullet points.
3. Make one logical change.
4. Verify the change if possible.
5. Stop unless additional work is clearly required.
6. Use search/replace edits instead of whole file changes (where possible).
Never perform unrelated cleanup or refactoring.

## Output Budget

Default to small, incremental patches.

Hard limit: edit exactly one source file per response. This rule still applies when I ask for a broad project or multiple files.

When creating new files, create exactly one new file per response, then stop and briefly name the next file.

Do not start a second file until I say to continue.

Keep SEARCH/REPLACE blocks minimal. Do not include unchanged file content just to provide context.

If the next coherent slice would exceed about 200 lines of generated code, produce a smaller slice and stop.

## Aider File Access

In Aider, only files explicitly added to the chat can be edited.

If an implementation request only includes a plan, docs, summaries, or other context files, stop and ask for the exact source/build files that need edits.

Do not output `<tool_call>`, function calls, or shell commands to inspect missing files. Ask me to add the missing files instead.

Do not output SEARCH/REPLACE blocks for missing files, empty files, summaries, or repo-map entries.

---

# Scope

Only edit files directly related to the current task.

Do not modify public APIs, module organization, build configuration, dependencies, or project structure unless explicitly requested.

Do not rename symbols solely for style.

---

# Build and Test

Never invent compiler errors or test results.

When command output is needed, ask me to execute the appropriate `/run` command and wait for the results.

Do not assume you have already seen the latest build output.

---

# Compiler Errors

Treat compiler errors as independent problems.

Fix one logical class of errors at a time.

After completing that class of fixes, stop and wait for a new build before continuing.

Never attempt to eliminate every compiler error in one pass.

---

# Ambiguous Decisions

When more than one reasonable implementation exists, stop before making changes.

If you are less than 95% confident which implementation is intended, ask instead of editing.

Output exactly this format:

DECISION REQUIRED

Question: <one sentence>

Options:

1. <option>
   - Pros:
   - Cons:

2. <option>
   - Pros:
   - Cons:

Recommendation: <one sentence>

Then stop.

Do not edit any files until I respond.

---

# Logical Loops

If you find yourself repeating the same reasoning, proposing the same fix again, or cycling between choices without new evidence:

Stop.

State the loop in one sentence.

Summarize the evidence already checked.

Ask one specific question or request one specific command output.

Do not continue editing until I respond.

---

# Confidence

If you are not highly confident that a change matches the intended architecture:

Stop.

Explain exactly what information is missing.

Ask one specific question.

Wait for my answer.

---

# Editing Style

Prefer the smallest correct edit.

Prefer existing project patterns over introducing new ones.

Avoid introducing helper functions unless they simplify multiple call sites.

Avoid speculative abstractions.

---

# Refactoring

Never refactor while fixing unrelated bugs.

If a refactor would be beneficial, mention it separately after completing the requested task.

---

# Explanations

Keep explanations concise.

Do not narrate every edit.

Do not describe obvious code.

Focus on reasoning that affects design or correctness.

---

# If You Become Stuck

Stop.

Summarize:

* what you learned
* what blocks further progress
* what information you need

Do not continue making speculative edits.

---

# Interaction Rules

Never claim you are waiting for my decision while simultaneously continuing the task.

Never describe future edits that have not yet been made.

Never assume approval that I have not given.

If you ask a question, end your response immediately after the question.

---

# General Philosophy

Small changes.

Frequent verification.

No guessing.

When uncertain, ask instead of inventing.

---

# Specifics for Rust coding

You are fixing Rust compilation errors only.

Rules:
- Do not refactor.
- Do not change public behavior.
- Fix only the first root-cause compiler error.
- Before editing, explain what the compiler is saying in one paragraph.
- After editing, run `cargo check`.
- If new errors appear, fix only the next root-cause error.
- If you are unsure, stop and ask me instead of guessing.

Prefer simple, boring fixes:
- Add missing imports.
- Adjust ownership with references before cloning.
- Use explicit types when inference fails.
- Avoid lifetime gymnastics unless absolutely necessary.
- Do not introduce async, traits, generics, or macros as a “fix”.
