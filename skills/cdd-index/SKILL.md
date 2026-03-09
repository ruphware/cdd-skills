---
name: cdd-index
description: "Regenerate docs/INDEX.md using docs/prompts/PROMPT-INDEX.md with a preflight plan, direct execution, validation, and post-action review (explicit-only)."
disable-model-invocation: true
---

# CDD Index (explicit-only)

Regenerate `docs/INDEX.md` in one run.

## Flow
1) Read the target repo `AGENTS.md`, `README.md`, and `docs/prompts/PROMPT-INDEX.md`.
2) Treat `docs/prompts/PROMPT-INDEX.md` as the source of truth for `docs/INDEX.md` content and `AGENTS.md` as the source of truth for response format.
3) Emit a concise preflight plan before writing:
   - intended `docs/INDEX.md` changes
   - source files and repo signals you will use
   - exact validation commands you will run
4) Update `docs/INDEX.md` immediately according to `docs/prompts/PROMPT-INDEX.md`.
   - Do not ask for approval for this write.
   - Ask only if a required input is missing or the target path is genuinely ambiguous.
5) Run validation:
   - use checks required by `docs/prompts/PROMPT-INDEX.md` when specified
   - otherwise run minimal repo-safe validation for the regenerated index
6) Return a post-action review using the target repo's `AGENTS.md` output contract.
   - Explicitly state what changed, what was validated, and any assumptions or limits.
