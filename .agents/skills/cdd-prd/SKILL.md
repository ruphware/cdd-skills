---
name: cdd-prd
description: "Create/update docs/specs/prd.md via Q&A (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD PRD (explicit-only)


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


## Scope safety
- Default to editing **only** `docs/specs/prd.md`.
- If the PRD file is missing, create it from `assets/prd.template.md` (OpenClaw: `{baseDir}/assets/prd.template.md`).

## Q&A style
- Ask one blocking question at a time.
- If the user provides a file to read, read it first and extract what you can before asking questions.

## Output requirements (draft pass)
Provide:
- A PRD draft (full text) OR a minimal patch.
- A short “what changed / what’s still open” summary.

## Apply pass (after approval)
- Write the approved PRD to `docs/specs/prd.md`.
