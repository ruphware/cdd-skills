---
name: cdd-refactor
description: "Turn refactor candidates in docs/INDEX.md into a TODO refactor plan (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Refactor (explicit-only)

Turn refactor candidates in `docs/INDEX.md` into a small, checkable TODO plan.

## Candidate sources
- `docs/INDEX.md` file inventory rows tagged `refactor-candidate` (when present)
- Any explicit refactor notes already in `docs/INDEX.md` or `TODO*.md`

## Flow (approval-gated)
1) Read `AGENTS.md`, `README.md`, `docs/INDEX.md`, the active `TODO*.md`, and relevant specs.
2) Extract candidate items and draft a small step plan using the repo’s existing Step template.
3) Ask the user for a short tag and propose creating `TODO-refactor-<tag>.md` (or updating an existing TODO file if preferred).
4) Ask: **Approve and apply these changes?**
5) Apply the approved plan and (if applicable) link it from `TODO.md` if the repo maintains an index section.
