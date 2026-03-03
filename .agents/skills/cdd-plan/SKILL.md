---
name: cdd-plan
description: "Plan new work and propose doc/TODO edits (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Plan (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Session bootstrap (required)
Initialize context in this order:
1) Read `AGENTS.md`.
2) Read `README.md`.
3) Read `docs/INDEX.md` (if missing: recommend running `$cdd-index` when repo context matters).
4) Read `docs/specs/blueprint.md`.
5) Read `docs/specs/prd.md`.
6) Read the **top** of `docs/JOURNAL.md` for process rules (do not scan the entire file unless needed).


## Approval gate (mandatory)
Planning skills must **not** modify repo files on the first pass.

Workflow:
1) Ask one blocking question at a time (only questions that materially change the plan).
2) Produce a draft plan / proposed edits.
3) Ask: **“Approve and apply these changes?”**
4) Only after explicit approval: write to files.


## Multi-TODO rules
- If multiple TODO files exist (`TODO.md`, `TODO-*.md`), ask which file to update (default: `TODO.md`).
- If creating a new plan file (audit/refactor), ask the user for a short tag and name it:
  - `TODO-audit-<tag>.md`
  - `TODO-refactoring-<tag>.md`
- If a new TODO file is created, link it from `TODO.md` (Active Work Index) if present; otherwise propose adding that section.


## Draft pass checklist
- Restate the work request in one sentence.
- Ask one blocking question at a time.
- Decide whether PRD and/or Blueprint must change.
- Propose:
  - PRD deltas (FR/AC) if needed
  - Blueprint deltas (interfaces/contracts) if needed
  - TODO steps (with checkbox tasks) implementing the change

## Output requirements (draft pass)
- Proposed edits grouped by file
- Proposed TODO steps with exact Automated checks + UAT

## Apply pass (after approval)
- Apply the approved edits.
- After writing, ask whether to implement the next step now using `$cdd-implement`.
