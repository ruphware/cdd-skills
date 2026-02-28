---
name: cdd-prd-to-todo
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-prd-to-todo`.

  Purpose:
  - Convert `docs/specs/prd.md` (+ `docs/specs/blueprint.md`) into an executable step plan.
  - Produce 5–15 small steps; every step has checks + UAT.
  - Stop for explicit approval before writing.

  Default file scope:
  - `TODO.md` (or a user-selected TODO file).
---

# CDD: PRD → TODO (explicit-only)

## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for filenames, ask the user for a short tag (don’t default to dates).

## Session bootstrap (required)
Initialize context in this order:
1) Read `/AGENTS.md`.
2) Read `/README.md`.
3) Read `/docs/INDEX.md` (if missing: recommend `$cdd-refresh-index`).
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
- If multiple TODO files exist, ask which file to update (default: `TODO.md`).

## Planning rules
- Steps must be small and sequential.
- Step 01 should be the smallest end-to-end slice.
- Every step must include: Goal / Deliverable / Changes / Automated checks (exact commands) / UAT.

## Output requirements (draft pass)
Provide:
- Proposed TODO steps (full text)
- A short rationale for the step boundaries

## Apply pass (after approval)
- Write the approved steps into the selected TODO file.
- If you created a new TODO file, ensure `TODO.md` links to it from an “Active Work Index” (create the section if needed and approved).
