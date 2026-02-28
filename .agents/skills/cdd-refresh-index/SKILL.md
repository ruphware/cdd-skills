---
name: cdd-refresh-index
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-refresh-index`.

  Use when:
  - `docs/INDEX.md` is missing/stale, or the repo has materially changed.
  - You need an updated architecture snapshot + file inventory.

  Success criteria:
  - Update `docs/INDEX.md` with GitHub-safe Mermaid and a file/LOC inventory.
  - Change ONLY `docs/INDEX.md` unless `docs/prompts/PROMPT-INDEX.md` explicitly requires more.
---

# CDD: Refresh docs/INDEX.md (explicit-only)

## Non-negotiables
- Never introduce deadlines or deadline-like phrasing.
- Update **only** `docs/INDEX.md` (unless `docs/prompts/PROMPT-INDEX.md` explicitly requires other edits).

## Canonical instructions
- Execute `/docs/prompts/PROMPT-INDEX.md` as the source of truth.

## Required INDEX sections
Ensure `docs/INDEX.md` contains (at minimum):
- A high-level architecture overview
- A file/directory inventory (aligned to the repo tree)
- GitHub-safe Mermaid diagrams (when diagrams are included)

### Refactoring targets (required section)
Include a section titled exactly:

`## Refactoring targets`

Format (stable + grep-friendly):
- `- [ ] <target> — <symptom> — <why it matters> — <suggested direction>`

If none are identified, explicitly write:
- `- (none identified)`
