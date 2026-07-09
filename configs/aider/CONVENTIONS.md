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

Never perform unrelated cleanup or refactoring.

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

