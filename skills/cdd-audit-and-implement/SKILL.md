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
3) Group items into 1–N TODO steps using the repo’s existing Step template.
4) Decide where to write:
   - default: update an existing TODO file
   - if creating a new TODO file: ask the user for a short tag and create `TODO-audit-<tag>.md`
5) Ask: **Approve and apply the TODO plan?**
6) Apply the approved plan.

### B) Implement
7) Ask which of the newly created steps to implement first (default: the first new step).
8) Ask: **Approve starting implementation now?**
9) Implement that step using the same workflow as `$cdd-implement-todo`.
