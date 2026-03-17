---
name: cdd-audit-and-implement
description: "Convert audit bullets into implementation-ready TODO steps, then implement the first dependency-ordered step (two approvals, explicit-only)."
disable-model-invocation: true
---

# CDD Audit + Implement (explicit-only)

Turn an audit list into small TODO steps, apply them, then immediately implement the first chosen step.

## Audit normalization rules
Do not convert raw audit bullets directly into TODO tasks.

- Normalize each audit item into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- Collapse duplicate symptoms into the smallest root-cause work package that can be implemented and validated cleanly.
- Preserve dependency order: prerequisite contract or plumbing changes should appear before downstream UI, storage, export, or cleanup work.
- Generated execution steps must satisfy the same implementation-ready standard as `cdd-plan`: `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, and `UAT` for non-trivial work, or equivalent sections if the repo already uses a richer local template.

## Flow (two approvals)

### A) Plan
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, and the relevant specs.
2) Ask for the audit items (inline bullets or a file path + section).
3) Before drafting TODO steps, identify only the blocking or plan-shaping clarifications that would materially change scope, grouping, file placement, sequencing, or approval boundaries.
4) Ask clarifying questions one at a time and keep them guided:
   - offer 2-4 concrete options grounded in the repo context
   - mark one option as the recommended default and explain it briefly
   - skip low-impact preferences and avoid open-ended questions unless a free-form value is required
5) If any material assumption would remain after the answers, list only those material assumptions and ask the user to confirm or correct them before continuing.
6) If only minor defaults remain, disclose them briefly in the plan and proceed without blocking.
7) Normalize the audit items:
   - identify the user-visible symptom, likely root cause, affected boundary, and proof needed for each item
   - tag each item as `spec_delta`, `implementation_delta`, `verification_delta`, or `defer`
   - merge duplicates and split mixed-surface findings before drafting steps
8) Group the normalized items into 1–N implementation-ready TODO steps using the repo’s existing Step template. Keep the plan KISS and CDD-style: minimal steps, minimal diffs, no invented structure.
9) Decide where to write using guided options:
   - default: update an existing TODO file
   - alternative: create `TODO-audit-<tag>.md`
   - ask for a short tag only if the user chose the new-file option
10) Ask: **Approve and apply the TODO plan?**
11) Apply the approved plan.

### B) Implement
12) Ask which of the newly created steps to implement first using guided options; recommend the first runnable new step by default, prioritizing dependency order and prerequisite work.
13) Ask: **Approve starting implementation now?**
14) Implement that step using the same workflow as `$cdd-implement-todo`.
