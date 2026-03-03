---
name: cdd-plan
description: "Plan work by updating the CDD contract + TODO steps (approval-gated, explicit-only)."
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

## Flow (approval-gated)
1) Read the contract files above (and any linked sub-specs).
2) Ask for the change request and only the blocking clarifications.
3) Draft proposed edits (grouped by file):
   - PRD/Blueprint deltas only if required
   - TODO step updates using the repo’s existing Step template
4) Ask: **Approve and apply these changes?**
5) After applying, suggest implementing the next step via `$cdd-implement-todo`.
