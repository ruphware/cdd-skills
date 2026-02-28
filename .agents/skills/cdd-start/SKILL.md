---
name: cdd-start
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-start`.
  
  Purpose:
  - Start a new project workflow: PRD → Blueprint → TODO.
  - Approval-gated at each stage; no file edits until approved.
  
  Default file scope (after approval):
  - `docs/specs/prd.md`
  - `docs/specs/blueprint.md`
  - `TODO.md` (or a user-selected TODO file)
---

# CDD Start (explicit-only)


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


## Stage 1 — PRD (draft then apply)
Draft pass:
- Ask one blocking question at a time.
- Produce a PRD draft (full text or patch).
- Ask for approval.

Apply pass (after approval):
- Write `docs/specs/prd.md`.

## Stage 2 — Blueprint (draft then apply)
Draft pass:
- Read the approved PRD.
- Propose 1 recommended architecture/stack + 1–2 alternatives (brief tradeoffs).
- Produce a blueprint draft.
- Ask for approval.

Apply pass (after approval):
- Write `docs/specs/blueprint.md`.

## Stage 3 — TODO plan (draft then apply)
Draft pass:
- Convert PRD (+ blueprint) into 5–15 small, sequential steps.
- Step 01 should be the smallest end-to-end slice.
- Every step must include: Goal / Deliverable / Changes / Automated checks (exact commands) / UAT.
- Ask for approval.

Apply pass (after approval):
- Write the approved plan into the selected TODO file.

## After completion
- Ask whether the user wants to implement the next step now using `$cdd-implement`.
