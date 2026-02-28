---
name: cdd-ship-step
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-ship-step`.

  Primary use:
  - Implement one concrete TODO step (feature/bugfix/refactor) and produce a working patch.
  - Ensure the step has exact Automated checks + a UAT checklist.
  - Follow the repo’s operating contract in AGENTS.md.

  Success criteria:
  - Minimal patch implementing the deliverable.
  - TODO step has: Goal / Deliverable / Changes / Automated checks / UAT.
  - Validation commands listed (and run when possible).
  - Final report includes: files changed + commands + next action + request for UAT sign-off.
---

# CDD: Ship a TODO step (explicit-only)

## Non-negotiables
- Follow the target repo’s `/AGENTS.md`.
- Keep diffs minimal and scoped to the chosen step.
- Never introduce deadlines or deadline-like phrasing.

## 0) Session bootstrap (required)
Initialize context in this order:
1) Read `/AGENTS.md`.
2) Read `/README.md`.
3) Find TODO files (`TODO.md`, `TODO-*.md`).
4) Read `/docs/INDEX.md` (if missing: recommend running `$cdd-refresh-index` before proceeding when architecture context matters).
5) Read `/docs/specs/blueprint.md`.
6) Read `/docs/JOURNAL.md` **top section only** for process rules.

## 1) Choose the TODO file + step (required)
- If multiple TODO files exist, ask which file contains the step (default: `TODO.md`).
- Ask the user to confirm the exact step heading being shipped (e.g. `Step 03 — ...`).

If the step is ambiguous or missing acceptance detail:
- Ask one blocking question, OR
- Propose a short **Confirm** bullet list (acceptance rules / constraints) and ask for approval to add it to the step.

## 2) Plan before edits (required)
Provide:
- File plan: `filename | purpose | ≈LOC`
- Logging plan: 3–7 grep-friendly logs at key branches/state changes/I/O
- Risks: top likely failure modes (interfaces, migrations, data shapes, env assumptions)

## 3) Implementation constraints (required)
- Keep changes minimal; avoid drive-by refactors.
- Do not remove existing logs/tests unless explicitly requested.
- Prefer boring, readable code over cleverness.

## 4) TODO discipline (required)
- Ensure the chosen step contains (at minimum):
  - Goal
  - Deliverable
  - Changes
  - Automated checks (exact commands)
  - UAT (manual checklist)

If the work is not represented anywhere:
- Add a new `## Step NN — ...` using:
  - `.agents/skills/cdd-ship-step/assets/todo-step.template.md`

Optional (recommended): validate TODO structure via:
- `python .agents/skills/cdd-ship-step/scripts/validate_todo.py TODO.md`

## 5) Validate (required)
- Run repo checks if they exist (lint/typecheck/tests/build).
- If checks don’t exist yet, propose exact commands and capture missing checks as a follow-up TODO step.

## 6) Docs updates (required when applicable)
- Update `docs/JOURNAL.md` when changes include real decisions/tradeoffs/gotchas.
- Refresh `docs/INDEX.md` when architecture/inventory materially changes (prefer `$cdd-refresh-index`).

## 7) Final report format (required)
Return:
- GOAL (1 sentence)
- SCOPE (what you touched / didn’t touch)
- ASSUMPTIONS
- CHANGES (bullets + files)
- VALIDATION (exact commands + results)
- UAT (checklist; ask for human sign-off)
- NEXT (suggest commit message + next step)
