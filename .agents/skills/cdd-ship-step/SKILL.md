---
name: cdd-ship-step
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-ship-step`.

  Primary use:
  - Implement a concrete change (feature/bugfix/refactor) and produce a working patch.
  - Create or update a TODO.md step with:
    - Automated checks (exact commands)
    - UAT checklist
  - Follow the repo’s operating contract in AGENTS.md.

  Don’t use when:
  - The user wants only Q&A, brainstorming, or review without code changes.
  - The task is only to refresh docs/INDEX.md (use `$cdd-refresh-index`).

  Success criteria:
  - Minimal patch implementing the deliverable.
  - TODO step has Goal/Deliverable/Changes/Automated checks/UAT.
  - Validation commands listed (and run when possible).
  - Final report includes files changed + commands + next action.
---

# CDD Ship Step Skill (explicit-only)

## 0) Repo contract (required)
1) Read and follow `/AGENTS.md` (repo-level contract).
2) Read: `/TODO.md`, `/docs/INDEX.md`, `/docs/JOURNAL.md`, and any relevant `/docs/specs/*`.

If `docs/INDEX.md` is missing/stale and the task depends on architecture context:
- Prefer running `$cdd-refresh-index` explicitly before continuing.

## 1) Plan before edits (required)
Provide:
- **File Plan** table: `filename | purpose | ≈LOC`
- **Logging Plan:** 3–7 grep-friendly logs at key branches/state changes/I/O
- **Risks:** list likely failure points (interfaces, migration, data shape, env assumptions)

## 2) Implementation constraints (required)
- Keep changes minimal; avoid unrelated refactors.
- Do not remove existing logs/tests unless explicitly requested.
- Prefer composition over cleverness.
- Add logs where state changes or branching occurs.

## 3) TODO step discipline (required)
If the work is not represented in TODO.md:
- Add a new `## Step NN — ...` section using the template in:
  `.agents/skills/cdd-ship-step/assets/todo-step.template.md`

Every step MUST include:
- Goal
- Deliverable
- Changes
- Automated checks (exact commands)
- UAT checklist

## 4) Validate (required)
Run repo checks if they exist (lint/typecheck/tests/build).
If checks don’t exist, propose exact commands and capture missing checks as a follow-up TODO step.

## 5) Documentation updates (required when applicable)
Update:
- `docs/JOURNAL.md` when changes are non-trivial (decisions, trade-offs, gotchas).
- `docs/INDEX.md` (or run `$cdd-refresh-index`) when architecture/inventory materially changes.

## 6) Final report format (required)
Return:
- GOAL (1 sentence)
- CONSTRAINTS (bullets)
- METHOD (2–4 lines)
- ASSUMPTIONS
- EXECUTION (files changed + key decisions)
- VALIDATION (exact commands)
- NEXT (commit message + next step)
