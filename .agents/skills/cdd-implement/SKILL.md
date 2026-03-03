---
name: cdd-implement
description: "Implement one TODO step with validation + UAT (explicit-only)."
disable-model-invocation: true
---

# CDD Implement (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Non-negotiables
- Follow the target repo’s `AGENTS.md`.
- Keep diffs minimal and scoped to the chosen step.

## Session bootstrap (required)
1) Read `AGENTS.md`.
2) Read `README.md`.
3) Find TODO files (`TODO.md`, `TODO-*.md`).
4) Read `docs/INDEX.md` (if missing: recommend `$cdd-index` when architecture context matters).
5) Read `docs/specs/blueprint.md`.
6) Read `docs/specs/prd.md`.
7) Read `docs/JOURNAL.md` **top section only** for process rules.

## Choose the TODO file + step (required)
- If multiple TODO files exist, ask which file contains the step (default: `TODO.md`).
- Ask the user to confirm the exact step heading being shipped (e.g. `Step 03 — ...`).

If the step is ambiguous or missing acceptance detail:
- Ask one blocking question, OR
- Propose a short **Confirm** bullet list (acceptance rules / constraints) and ask for approval to add it.

## Plan before edits (required)
Provide:
- File plan: `filename | purpose | ≈LOC`
- Logging plan: 3–7 grep-friendly logs at key branches/state changes/I/O
- Risks: top likely failure modes

## TODO discipline (required)
- Ensure the chosen step contains:
  - Goal
  - Deliverable
  - Changes
  - Automated checks (exact commands)
  - UAT (manual checklist)

If the work is not represented anywhere:
- Add a new `## Step NN — ...` using:
  - `assets/todo-step.template.md` (OpenClaw: `{baseDir}/assets/todo-step.template.md`)

Optional (recommended): validate TODO structure via:
- `scripts/validate_todo.py` (OpenClaw: `{baseDir}/scripts/validate_todo.py`; see file for usage)

## Validate (required)
- Run repo checks if they exist (lint/typecheck/tests/build).
- If checks don’t exist yet, propose exact commands and capture missing checks as follow-up TODO work.

## Journal merge sanity (required if you edit docs/JOURNAL.md)
- Append entries to the end of `docs/JOURNAL.md` under a stable `## Entries` header (create it if missing).
- Never reorder existing entries.
- Include an entry marker line: `Entry: <tag-or-uuid>`.

## Docs updates (when applicable)
- Update `docs/JOURNAL.md` when changes include real decisions/tradeoffs/gotchas.
- Refresh `docs/INDEX.md` when architecture/inventory materially changes (prefer `$cdd-index`).

## Final report format (required)
Return:
- GOAL (1 sentence)
- SCOPE (what you touched / didn’t touch)
- ASSUMPTIONS
- CHANGES (bullets + files)
- VALIDATION (exact commands + results)
- UAT (checklist; ask for human sign-off)
- NEXT (suggest commit message + next step)
