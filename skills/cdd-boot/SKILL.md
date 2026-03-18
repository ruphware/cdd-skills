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
- top of `docs/JOURNAL.md`

## Graceful fallback rules
- Read `AGENTS.md` first and treat it as the source of truth for role and response format.
- Continue gracefully when `README.md`, `docs/INDEX.md`, `docs/specs/blueprint.md`, or `docs/JOURNAL.md` are missing.
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
- Use only the top of `docs/JOURNAL.md` or development fallback files; do not ingest full history unless the user explicitly asks.
- If multiple plausible fallback docs exist in the same tier, prefer canonical CDD files, then root runbook docs, then the shortest current-state doc that answers the need.
- Do not write or modify repo files.
- Do not ask for approval.
- Ask a question only when the repo layout is genuinely ambiguous and the ambiguity would materially change the boot summary.

## Output
Return a concise boot report that includes:
- `Role` — confirm the `AGENTS.md` role was assumed
- `Project` — summarize the project using canonical files or fallbacks
- `Development` — summarize current implementation context from the journal top or fallbacks
- `Sources used` — list the files actually read
- `Missing expected files` — list only the missing canonical docs
- `Next action` — recommend the best follow-up

On success, recommend continuing in vanilla AGENTS-driven mode.

## Example prompt
`$cdd-boot Ingest AGENTS.md and assume the role. Read README.md docs/INDEX.md docs/specs/blueprint.md to understand the project. See top of docs/JOURNAL.md for implementation details.`
