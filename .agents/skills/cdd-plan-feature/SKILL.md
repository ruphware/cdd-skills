---
name: cdd-plan-feature
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-plan-feature`.

  Purpose:
  - Turn a feature request into an actionable plan.
  - Update PRD/Blueprint if required.
  - Append/insert TODO steps with checks + UAT.
  - Stop for explicit approval before writing.

  Default file scope:
  - `TODO.md` (or selected TODO file)
  - `docs/specs/prd.md` (if requirements/AC change)
  - `docs/specs/blueprint.md` (if interfaces/architecture change)
  - `docs/JOURNAL.md` (only if a real decision is made)
---

# CDD: Plan a feature (explicit-only)

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
- If multiple TODO files exist, ask which one to update.
- Default to `TODO.md` unless the user chooses otherwise.

## Planning checklist (draft pass)
- Restate the feature request in one sentence.
- Ask one blocking question at a time.
- Decide whether PRD and/or Blueprint changes are required.
- Propose:
  - PRD deltas (FR/AC) if needed
  - Blueprint deltas (interfaces/contracts) if needed
  - TODO steps (with checkbox tasks) implementing the change

## Output requirements (draft pass)
- Proposed edits grouped by file
- Proposed TODO steps with exact Automated checks + UAT

## Apply pass (after approval)
- Apply the approved edits.
- After writing, ask whether the user wants to implement the next step now using `$cdd-ship-step`.
