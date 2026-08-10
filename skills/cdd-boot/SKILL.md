---
name: cdd-boot
description: "Boot a repo into vanilla AGENTS-driven mode from root entrypoints first, deepen only into intent-relevant follow-ons, route to a specialized `cdd-*` continuation only when it adds real leverage, and otherwise hand back with the right checkout recommendation (interactive, read-only)."
---

# CDD Boot (interactive, read-only)

Use this skill for a one-time vanilla CDD context boot, whether or not the next step later uses another `cdd-*` skill.

Boot the current repo into vanilla `AGENTS.md`-driven work by reading role, project, and development context, then either recommending the specialized `cdd-*` continuation that best shapes the next step or handing back to vanilla AGENTS-driven work when no specialized contract helps. Decide only whether to stay in place or continue via a branch-backed worktree; do not change repo files during boot.

## Required contract
- `AGENTS.md` at repo root
- If `AGENTS.md` is missing, stop, tell the user the repo is not CDD-ready for vanilla boot, and recommend `cdd-init-project`.

## Preferred inputs
Role:
- `AGENTS.md`

Root boot entrypoints:
- `README.md`
- `TODO.md`
- `docs/specs/blueprint.md`
- `docs/specs/prd.md` when present
- top of `docs/JOURNAL.md` as the stable journal entrypoint
- `docs/INDEX.md` when present

Scaled follow-on surfaces:
- one matching `TODO-<area>.md` when one named lane or intent clearly needs it
- one matching `docs/journal/JOURNAL-<area>.md` or `docs/journal/SUMMARY.md` when one named lane or explicit history request clearly needs it
- the relevant `docs/index/**` body when the user explicitly asks for diagrams, inventory, ownership, or file-level discovery and `docs/INDEX.md` routes there

External intent surfaces:
- user-named external issues, tickets, PRs, RFCs, docs, or tracker references

## Default boot set
- Treat default boot as the small-repo path: read `AGENTS.md` plus the root boot entrypoints only.
- In scaled or big repos, those same root files still boot first. Treat them as routers into deeper material, not as a reason to read every split file.
- Do not expand into split TODO, journal, or INDEX bodies unless the user asks for it or one named intent clearly requires one specific lane or body.
- Do not scan lane files just to discover work. Use `TODO.md` plus the named intent; otherwise recommend the best broad `cdd-*` continuation.

## Deepening triggers
- Follow one `TODO-<area>.md` only when the user names a lane, area, issue, PR, or step, or when `TODO.md` clearly routes the named intent into that lane.
- Follow one journal lane only when the user asks for history, prior attempts, decisions, regressions, or when the chosen lane needs recent implementation context beyond the root journal entrypoint.
- Follow one INDEX body only when the user explicitly asks for diagrams, inventory, ownership, or file-level discovery that the root `docs/INDEX.md` does not already answer.
- If more than one lane or body is plausible, ask one clarifying question instead of opening several.
- Once the target lane or body is clear, read only that lane or body unless the evidence forces a second one.

## Graceful fallback rules
- Read `AGENTS.md` first and treat it as the source of truth for role and response format.
- Continue gracefully when root boot entrypoints or scaled follow-on surfaces are missing.
- Detect split layouts from the entrypoints — `docs/INDEX.md` for INDEX, `docs/JOURNAL.md` for journals. When either points to split bodies, treat them as latent follow-ons and open only the one the current question needs.
- For missing project context, use the first existing curated fallback in this order:
  - `README*.md`
  - `docs/specs/prd.md`
  - `TODO.md`
  - matching `TODO-<area>.md` only when a deepening trigger identifies one area
  - concise root or `docs/` markdown files with names matching `index`, `overview`, `spec`, `blueprint`, or `design`
- For missing development context, use the first existing curated fallback in this order:
  - top of `TODO.md`
  - matching `TODO-<area>.md` only when a deepening trigger identifies one area
  - top of `CHANGELOG*.md`
  - top of `docs/CHANGELOG*.md`
  - top of `docs/notes*.md`
- If deeper development context is needed and no matching area journal is clear, prefer `docs/journal/JOURNAL.md` for cross-cutting notes and `docs/journal/SUMMARY.md` for older condensed context before falling back to non-journal docs.
- Use only the top of `docs/JOURNAL.md`, matching split-journal files, or development fallback files; do not ingest full history unless the user explicitly asks.
- If multiple plausible fallback docs exist in the same tier, prefer canonical CDD files, then root runbook docs, then the shortest current-state doc that answers the need.
- Ask a question only when the repo layout is genuinely ambiguous and the ambiguity would materially change the boot summary.

## External source handling
- Resolve user-named external references with available read-only surfaces: connectors, CLIs, local remotes, pasted URLs, and identifiers.
- When an external artifact is in scope, read the complete thread before routing: title/body/description, all comments, review comments when present, and material directly referenced artifacts. Do not recursively crawl unrelated links.
- Treat the latest authoritative comment or decision as current intent; flag superseded body requirements.
- Ask one clarifying question when the reference or source of truth is ambiguous enough to change the boot summary or continuation.
- If the artifact, comments, or material references cannot be fetched after a reasonable read-only attempt, mark the boot partial, name the unread surfaces, and route from available local context.
- Never post, update, label, assign, or otherwise mutate external systems during boot.

## Boot intent routing
- When the boot invocation names a task or goal, classify the intent and extend boot reading to the intent-relevant surfaces — external threads, `TODO.md`, the narrowly matching `TODO-<area>.md` or `docs/journal/JOURNAL-<area>.md` files when a deepening trigger identifies them, relevant docs, and code entrypoints — without ingesting full history.
- Treat research, analysis, investigation, proposal review, and audit as read-only evidence intents unless the user explicitly asks for write-producing follow-up.
- Route the intent to its continuation:
  - a matching runnable TODO step already named by the user or narrowly resolved from `TODO.md` plus one matching lane → `$cdd-implement <step>` (takes precedence over all other routes)
  - a direct question about the codebase, functionality, requirements, or project state that the booted context can answer (`inquiry`) → answer it in the boot report itself per `## Output`; no continuation required
  - a new change request or feature idea → `cdd-plan`
  - review or verification of implemented work or a proposed enhancement → `cdd-audit`
  - doc drift, repo upkeep, or index refresh → `cdd-maintain`
  - multi-step autonomous execution over prepared TODO steps → `cdd-master-chef`
  - a concrete operational, runbook, release, or other bounded repo task that does not need a planning, audit, upkeep, or autonomous-execution contract → continue in vanilla AGENTS-driven mode
  - missing `AGENTS.md` → `cdd-init-project` (per `## Required contract`)
- With no intent, infer the continuation from the root boot entrypoints; `## Default boot set` lane discipline still applies.
- Carry the intent into the recommended option text so the user can continue directly (for example `$cdd-plan <intent>` or `continue in vanilla AGENTS-driven mode on <intent>`).

## Continuation fit
- Recommend another `cdd-*` skill only when its contract materially improves control, decomposition, audit shape, upkeep flow, or autonomous execution for the next step.
- Prefer vanilla AGENTS-driven continuation for bounded operational work, runbook procedures, release steps, or direct exploration when a specialized skill would add ceremony more than leverage.
- Treat `$cdd-implement` direct mode as optional post-boot scaffolding for one bounded non-TODO task when that handoff is useful; do not make it mandatory just because the work is write-producing.

## Follow-up contract
- Treat repo-local `AGENTS.md` response-format guidance as authoritative for follow-up presentation; when it defines a repo-local `NEXT` section or selector-style follow-up contract, use that `NEXT` section with visible selector-labeled choices.
- Prefix every follow-up option label with a visible selector in the label itself so plan-mode UIs still show a selectable key. Default to letters `A.` through `D.`; use numbers only when the surrounding context is already numeric and that would be clearer.
- Offer 2-4 concrete next-step choices in both paths, ordered by suitability with the recommended option first; when practical tell the user they can reply with just the selector. When no repo-local `NEXT` contract exists, use a final `**Options**` section.
- For `inquiry` intents the answer itself is the result: omit `Next action` unless a concrete continuation genuinely helps.
- When booting from the main worktree of a Git repo, include both `create or move into a worktree+branch first` and `continue in the main checkout` as distinct choices, each naming the continuation it chains to (for example `create worktree ... then $cdd-plan <intent>` or `continue in the main checkout in vanilla AGENTS-driven mode on <intent>`). Place them by suitability, not fixed slots.
- For read-only evidence intents, order `continue in the main checkout` ahead of worktree creation unless the user explicitly asks for isolation.
- Keep boot follow-up as routing only; do not ask for approval and do not execute implementation from boot itself. The next action may chain to another `cdd-*` skill or to vanilla AGENTS-driven work.
- If a clear next runnable TODO step exists, recommend continuing via `$cdd-implement <step>` rather than offering direct implementation.

## Worktree check
- If the repo is Git-backed, inspect whether the current checkout is the main worktree or a linked worktree before finishing the boot report.
- If the current checkout is already a linked worktree, recommend staying in that worktree for development.
- For read-only evidence intents, prefer staying in the current or main checkout; do not recommend worktree migration solely because linked worktrees or repo-local managed worktree paths already exist.
- For feature implementation or write-producing planning from the main worktree, if linked worktrees or repo-local managed worktree paths already exist, recommend moving feature development into a worktree rather than the main folder.
- When the boot report recommends creating or moving into a worktree first, recommend a repo-local path under `.cdd-runtime/worktrees/<branch-or-tag>/`, where `<branch-or-tag>` defaults to the recommended branch name or approved workstream tag.
- Otherwise, say that staying in the main folder is acceptable unless the user wants parallel or isolated development.
- Do not create, switch, remove, or clean worktrees during boot; a selected follow-up choice authorizes creation as the continuation's first action after the boot report.

## Output
Return a concise boot report that includes:
- `Role` — confirm the `AGENTS.md` role was assumed
- `Project` — summarize the project using canonical files or fallbacks
- `Development` — summarize current implementation context from the journal top or fallbacks
- `Worktree` — summarize whether development should stay in the main folder or move into a worktree
- `Intent` — when the boot invocation named a task, state the classified intent, the intent-relevant surfaces warmed up, any partial external read gaps, and the recommended continuation
- `Answer` — for `inquiry` intents, lead the report with it: a short factual answer first, then supporting detail — a table or ASCII diagram where it clarifies structure, explicit gaps or unknowns when found. Keep the other report fields to one line each when they do not serve the answer, and omit `Next action` unless a concrete continuation genuinely helps.
- `Sources used` — list the files and external artifacts actually read; mark partial external threads when comments or material references were unavailable
- `Missing expected files` — list only the missing canonical docs
- `Next action` — up to four suitability-ordered selector choices, recommended first, including both checkout choices per `## Follow-up contract`, through the repo-local `NEXT` section when `AGENTS.md` defines one, otherwise a final `**Options**` section. When worktree migration is recommended, one choice creates or moves into `.cdd-runtime/worktrees/<branch-or-tag>/` and chains a clear runnable TODO step with `$cdd-implement <step>`; when no specialized continuation fits, recommend vanilla AGENTS-driven continuation in the appropriate checkout rather than force-fitting another `cdd-*` skill.

## Example prompt
`$cdd-boot Ingest AGENTS.md and assume the role. Read the repo's root entrypoints first, and only follow one scaled lane, journal, or INDEX body if I name a lane or ask for history, diagrams, or inventory.`

With an intent:
`$cdd-boot I want to fix the flaky CI test — warm up the relevant context and recommend the continuation.`

With an inquiry (the answer is the result):
`$cdd-boot how do releases get versioned in this repo, and which script owns that?`

With a direct operational task:
`$cdd-boot stay on main, cut new release 0.7.4 from docs/runbooks/release.md`
