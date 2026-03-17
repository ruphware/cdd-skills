---
name: cdd-plan
description: "Plan work by updating the CDD contract + implementation-ready TODO steps (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Plan (explicit-only)

Treat the target repo’s CDD contract files as the source of truth:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/INDEX.md` (if present)

## Runnable TODO step contract
For any new or rewritten execution step, produce an implementation-ready step rather than a placeholder summary.

- Preserve the repo's existing Step template when possible, but add missing sections when the current template would leave the step underspecified.
- Preferred section set for non-trivial work:
  - `Goal`
  - `Constraints`
  - `Tasks`
  - `Implementation notes`
  - `Automated checks`
  - `UAT`
- A runnable step is decision-complete: the implementer can execute it without reopening PRD/Blueprint to discover missing product, architecture, sequencing, or validation decisions.
- Each `Tasks` bullet must name:
  - the target boundary or subsystem
  - the exact change to make
  - the output artifact, contract, or behavior that must result
  - any must-preserve invariant or evidence requirement when relevant
- Use `Implementation notes` for file/symbol hints, interface or schema changes, ordering constraints, migration notes, snapshot/audit requirements, and other coding-critical detail that would otherwise be lost in a short task list.
- Do not leave essential implementation detail only in the surrounding chat. Put it in the TODO step.
- Split work into separate steps when it crosses distinct hard gates, migration boundaries, rollback surfaces, or independently testable subsystems.

## Flow (approval-gated)
1) Read the contract files above (and any linked sub-specs).
2) Ask for the change request and only the blocking clarifications.
3) Draft proposed edits (grouped by file):
   - PRD/Blueprint deltas only if required
   - TODO step updates using the repo’s existing Step template
   - translate spec deltas into implementation deltas instead of restating product intent
   - for each new or revised execution step, include exact boundaries, interface or contract changes, sequencing notes, and validation evidence
   - add `Implementation notes` when the step would otherwise force the implementer to make decisions
   - split oversized mixed-surface work into dependency-ordered steps
4) Ask: **Approve and apply these changes?**
5) After applying, suggest implementing the next step via `$cdd-implement-todo`.
