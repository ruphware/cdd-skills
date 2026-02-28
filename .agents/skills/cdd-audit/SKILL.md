---
name: cdd-audit
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-audit`.
  
  Purpose:
  - Convert an audit list (bugs/UX issues/observations) into an actionable TODO plan.
  - Approval-gated; write only after explicit approval.
---

# CDD Audit (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Session bootstrap (required)
Initialize context in this order:
1) Read `/AGENTS.md`.
2) Read `/README.md`.
3) Read `/docs/INDEX.md` (if missing: recommend running `$cdd-index` when repo context matters).
4) Read `/docs/specs/blueprint.md`.
5) Read `/docs/specs/prd.md`.
6) Read the **top** of `/docs/JOURNAL.md` for process rules (do not scan the entire file unless needed).


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


## Draft pass requirements
- Ask one blocking question at a time.
- Group audit items into 1–N steps.
- Each step must include Automated checks (exact commands) + UAT.

## Apply pass (after approval)
- Write the plan into the selected TODO file.
- If you created `TODO-audit-<tag>.md`, link it from `TODO.md` (Active Work Index) if present.
- After writing, ask whether to implement the first step now using `$cdd-implement`.
