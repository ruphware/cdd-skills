---
name: cdd-init-project
description: "Initialize a cdd-boilerplate repo: complete TODO Step 00 and propose Step 01+ (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Init Project (explicit-only)

This skill is designed for repos created from `cdd-boilerplate`.

## Canonical contract (do not duplicate)
Use these repo files as the authoritative workflow and format:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md` (if present)

## Flow (approval-gated)
1) Read the canonical contract files above.
2) Use `TODO.md` **Step 00** as the checklist.
3) Ask the user for any existing notes/requirements paths and read them before asking questions.
4) Draft proposed edits (grouped by file) to:
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint
   - extend `TODO.md` with Step 01+ if needed (use the Step template already in `TODO.md`)
5) Ask: **Approve and apply these changes?**
6) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`
