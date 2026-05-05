---
name: cdd-boot
description: "Boot a repo into vanilla AGENTS-driven mode by ingesting AGENTS.md plus project and development docs, gracefully when non-core files differ or are missing (explicit-only)."
disable-model-invocation: true
---

# CDD Boot (explicit-only)

Use this skill when the user wants a one-time vanilla CDD context boot and does not intend to use another `cdd-*` skill for the task.

Boot the current repo into vanilla `AGENTS.md`-driven work by reading role, project, and development context without changing repo files.

## Required contract
- `AGENTS.md` at repo root
- If `AGENTS.md` is missing, stop and tell the user the repo is not CDD-ready for vanilla boot.
- Recommend `cdd-init-project` when the repo is missing `AGENTS.md`.

## Preferred inputs
Role:
- `AGENTS.md`

Project:
- `README.md`
- `docs/INDEX.md`
- `docs/specs/blueprint.md`

Development:
- top of `docs/JOURNAL.md` as the stable journal entrypoint
- matching `docs/journal/JOURNAL-<area>.md` files and `docs/journal/SUMMARY.md` when `docs/JOURNAL.md` indicates split-journal mode

## Graceful fallback rules
- Read `AGENTS.md` first and treat it as the source of truth for role and response format.
- Continue gracefully when `README.md`, `docs/INDEX.md`, `docs/specs/blueprint.md`, or `docs/JOURNAL.md` are missing.
- Use `docs/JOURNAL.md` to detect journal layout first. If it indicates split-journal mode, continue with the matching `docs/journal/JOURNAL-<area>.md` files and `docs/journal/SUMMARY.md` as needed.
- For missing project context, use the first existing curated fallback in this order:
  - `README*.md`
  - `docs/specs/prd.md`
  - `TODO*.md`
  - concise root or `docs/` markdown files with names matching `index`, `overview`, `spec`, `blueprint`, or `design`
- For missing development context, use the first existing curated fallback in this order:
  - top of `TODO*.md`
  - top of `CHANGELOG*.md`
  - top of `docs/CHANGELOG*.md`
  - top of `docs/notes*.md`
- If split-journal mode is active but no matching area journal is clear, prefer `docs/journal/JOURNAL.md` for cross-cutting notes and `docs/journal/SUMMARY.md` for older condensed context before falling back to non-journal docs.
- Use only the top of `docs/JOURNAL.md`, matching split-journal files, or development fallback files; do not ingest full history unless the user explicitly asks.
- If multiple plausible fallback docs exist in the same tier, prefer canonical CDD files, then root runbook docs, then the shortest current-state doc that answers the need.
- Do not write or modify repo files.
- Do not ask for approval.
- Ask a question only when the repo layout is genuinely ambiguous and the ambiguity would materially change the boot summary.

## Follow-up contract
- Treat repo-local `AGENTS.md` response-format guidance as authoritative for follow-up presentation, including any repo-local `NEXT` section or selector-style follow-up contract.
- When `AGENTS.md` defines a repo-local `NEXT` section or selector-style follow-up contract, use that `NEXT` section with visible selector-labeled choices.
- Prefix every follow-up option label with a visible selector in the label itself so plan-mode UIs still show a selectable key. Default to letters: `A.`, `B.`, `C.`. Use numbers only when the surrounding context is already numeric and that would be clearer.
- When no repo-local `NEXT` contract exists, use a final `**Options**` section with 2-4 concrete next-step choices, put the recommended option first, and when practical tell the user they can reply with just the selector.
- Keep boot follow-up read-only navigation only; do not ask for approval and do not offer to start implementation directly from boot.
- If a clear next runnable TODO step exists, recommend continuing via `$cdd-implement-todo <step>` rather than offering direct implementation.

## Worktree check
- If the repo is Git-backed, inspect whether the current checkout is the main worktree or a linked worktree before finishing the boot report.
- If the current checkout is already a linked worktree, recommend staying in that worktree for development.
- If the current checkout is the main worktree and linked worktrees or repo-local managed worktree paths already exist, recommend moving feature development into a worktree rather than the main folder.
- When the boot report recommends creating or moving into a worktree first, recommend a repo-local path under `.cdd-runtime/worktrees/<branch-or-tag>/`, where `<branch-or-tag>` defaults to the recommended branch name or approved workstream tag.
- Worktree follow-up choices must explicitly distinguish `create or move into a worktree first` from `continue in the current worktree`.
- Otherwise, say that staying in the main folder is acceptable unless the user wants parallel or isolated development.
- Do not create, switch, remove, or clean worktrees during boot.

## Output
Return a concise boot report that includes:
- `Role` — confirm the `AGENTS.md` role was assumed
- `Project` — summarize the project using canonical files or fallbacks
- `Development` — summarize current implementation context from the journal top or fallbacks
- `Worktree` — summarize whether development should stay in the main folder or move into a worktree
- `Sources used` — list the files actually read
- `Missing expected files` — list only the missing canonical docs
- `Next action` — recommend the best follow-up using selector-labeled choices through the repo-local `NEXT` section when `AGENTS.md` defines one, otherwise through a final `**Options**` section
- When worktree migration is recommended, `Next action` must include a selector choice that creates or moves into `.cdd-runtime/worktrees/<branch-or-tag>/` and, if a clear next runnable TODO step exists, chains that path with `$cdd-implement-todo <step>`.
- When staying in the current checkout is acceptable and a clear next runnable TODO step exists, recommend `$cdd-implement-todo <step>` rather than offering to start implementation directly.

On success, recommend continuing in vanilla AGENTS-driven mode.

## Example prompt
`$cdd-boot Ingest AGENTS.md and assume the role. Read README.md docs/INDEX.md docs/specs/blueprint.md to understand the project. Use docs/JOURNAL.md as the journal entrypoint and continue with matching split-journal files when it points to them.`
