---
name: cdd-audit-and-implement
description: "Convert audit bullets into TODO steps, then implement the first step (two approvals, explicit-only)."
disable-model-invocation: true
---

# CDD Audit + Implement (explicit-only)

Turn an audit list into small TODO steps, apply them, then immediately implement the first chosen step.

## Flow (two approvals)

### A) Plan
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, and the relevant specs.
2) Ask for the audit items (inline bullets or a file path + section).
3) Before drafting TODO steps, identify only the blocking or plan-shaping clarifications.
4) Ask clarifying questions one at a time and keep them guided:
   - offer 2-4 concrete options grounded in the repo context
   - mark one option as the recommended default and explain it briefly
   - avoid open-ended questions unless a free-form value is required
5) If any assumption would remain after the answers, list the assumptions explicitly and ask the user to confirm or correct them before continuing.
6) Group items into 1–N TODO steps using the repo’s existing Step template. Keep the plan KISS and CDD-style: minimal steps, minimal diffs, no invented structure.
7) Decide where to write using guided options:
   - default: update an existing TODO file
   - alternative: create `TODO-audit-<tag>.md`
   - ask for a short tag only if the user chose the new-file option
8) Ask: **Approve and apply the TODO plan?**
9) Apply the approved plan.

### B) Implement
10) Ask which of the newly created steps to implement first using guided options; recommend the first runnable new step by default.
11) Ask: **Approve starting implementation now?**
12) Implement that step using the same workflow as `$cdd-implement-todo`.
