---
name: cdd-refresh-index
description: |
  EXPLICIT-ONLY SKILL.
  Use this skill only when explicitly invoked via `$cdd-refresh-index`.

  Use when:
  - docs/INDEX.md is missing/stale or repo has materially changed.
  - You need an updated architecture snapshot + file inventory.

  Don’t use when:
  - The primary goal is code changes (use `$cdd-ship-step`).

  Success criteria:
  - Update docs/INDEX.md with GitHub-safe Mermaid and LOC inventory.
  - Change ONLY docs/INDEX.md unless PROMPT-INDEX explicitly requires more.
---

# CDD Refresh Index Skill (explicit-only)

## Canonical instructions
- Execute `/docs/prompts/PROMPT-INDEX.md` as the source of truth.

## Rules
- Update ONLY `docs/INDEX.md` unless PROMPT-INDEX requires otherwise.
- Use shell commands to compute LOC + inventories.
- Keep Mermaid compatible with GitHub Markdown.
