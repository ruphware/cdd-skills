---
name: cdd-index
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-index`.
  
  Purpose:
  - Regenerate `docs/INDEX.md` using `docs/prompts/PROMPT-INDEX.md`.
  
  Success criteria:
  - Update `docs/INDEX.md` with GitHub-safe Mermaid and a file/LOC inventory.
  - Change ONLY `docs/INDEX.md` unless `docs/prompts/PROMPT-INDEX.md` explicitly requires more.
---

# CDD Index (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Canonical instructions
- Execute `/docs/prompts/PROMPT-INDEX.md` as the source of truth.

## Rules
- Update ONLY `docs/INDEX.md` unless PROMPT-INDEX requires otherwise.
- Use shell commands to compute LOC + inventories.
- Keep Mermaid compatible with GitHub Markdown.

## Required INDEX sections
Ensure `docs/INDEX.md` contains (at minimum):
- A high-level architecture overview
- A file/directory inventory (aligned to the repo tree)
- GitHub-safe Mermaid diagrams (when diagrams are included)

### Refactoring targets (required section)
Include a section titled exactly:
- `## Refactoring targets`

Format (stable + grep-friendly):
- `- [ ] <target> — <symptom> — <why it matters> — <suggested direction>`

If none are identified, explicitly write:
- `- (none identified)`
