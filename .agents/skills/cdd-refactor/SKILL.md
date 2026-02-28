---
name: cdd-refactor
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-refactor`.
  
  Purpose:
  - Read `docs/INDEX.md` and extract refactoring targets.
  - Propose 2–3 approaches per target with tradeoffs; recommend one.
  - Approval-gated; write a refactor TODO file only after approval.
---

# CDD Refactor (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Session bootstrap (required)
1) Read `/AGENTS.md`.
2) Read `/README.md`.
3) Read `/docs/INDEX.md` (required).
4) Read `/docs/specs/blueprint.md`.
5) Read `/docs/specs/prd.md`.
6) Read the **top** of `/docs/JOURNAL.md` for process rules.

## Approval gate (mandatory)
Planning skills must **not** modify repo files on the first pass.

Workflow:
1) Ask one blocking question at a time (only questions that materially change the plan).
2) Produce a draft plan / proposed edits.
3) Ask: **“Approve and apply these changes?”**
4) Only after explicit approval: write to files.


## Tagging / filenames
- Ask the user for a short tag for the refactor TODO filename (e.g., `refactor-001`).
- Do not default to dates.

## Draft pass requirements
- Extract targets from `## Refactoring targets` in `docs/INDEX.md`.
- For each target:
  - Propose 2–3 architectural approaches (e.g., pipeline, layers, micro-kernel) with brief tradeoffs.
  - Recommend one approach.
- Propose a step plan written as `## Step NN — ...` sections including Automated checks + UAT.

## Apply pass (after approval)
- Create `TODO-refactoring-<tag>.md`.
- Add a link to it from `TODO.md` (Active Work Index) if present; otherwise propose adding that section.
