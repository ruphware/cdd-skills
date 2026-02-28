---
name: cdd-blueprint
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-blueprint`.
  
  Purpose:
  - Select the simplest viable architecture consistent with PRD constraints.
  - Create/update `docs/specs/blueprint.md`.
  - Approval-gated; write only after explicit approval.
  
  Default file scope:
  - `docs/specs/blueprint.md` (and optional sub-specs only if approved).
---

# CDD Blueprint (explicit-only)


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


## Scope safety
- Default to editing **only** `docs/specs/blueprint.md`.
- Create modular sub-specs only when necessary and only after approval.

## Tech/architecture choice rules
- Prefer the simplest viable option.
- Present 1 recommended option + 1–2 alternatives with short tradeoffs.

## Output requirements (draft pass)
Provide:
- Recommended option + tradeoffs
- Blueprint draft (full text) or patch

## Apply pass (after approval)
- Write the approved changes to `docs/specs/blueprint.md`.
- If modular sub-specs were approved, create them under a user-approved folder and link them from a “Definition Index”.
