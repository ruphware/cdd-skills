---
name: cdd-boot
description: "Boot a repo from AGENTS.md plus sliced reads of README, TODO, and journal routing, deepen only where the intent needs it, then route to the `cdd-*` continuation that adds leverage or back to vanilla AGENTS-driven work, with a checkout recommendation (interactive, read-only)."
---

# CDD Boot (interactive, read-only)

One-time context boot: read the root entrypoints in slices, route to the continuation that adds leverage, otherwise hand back to vanilla `AGENTS.md`-driven work.

## Contract
- `AGENTS.md` at repo root is required; read it first as the source of truth for role and response format. Missing: stop, say the repo is not CDD-ready for vanilla boot, recommend `cdd-init-project`.
- Boot is read-only: no repo edits, external mutations (post, update, label, assign), worktree creation or switching, implementation, or approval requests. The option the user selects authorizes those as the continuation's first step.

## Reading
- Default set, in order: `AGENTS.md`; `README.md` title, first section, heading outline; `TODO.md` step index plus the first open or user-named step; top of `docs/JOURNAL.md`. A missing file falls through to the fallbacks below.
- Slice rule: first ~4 KB of any file, plus a heading outline (grep the headings, do not read the body) for the router files `README.md`, `TODO*.md`, `docs/JOURNAL.md`, `docs/INDEX.md`. Slice further only when the first slice leaves the boot need unanswered; read a whole file only when the user names it or the intent requires it. Never ingest full history.
- Deepen into one surface per need:

| Surface | Open only when |
|---|---|
| `docs/specs/prd.md`, `docs/specs/blueprint.md` | requirements or architecture are in question |
| `docs/INDEX.md`, then the one `docs/index/**` body it routes to | diagrams, inventory, ownership, or file-level discovery are requested |
| one `TODO-<area>.md` | a lane, area, issue, PR, or step is named, or `TODO.md` routes the intent there |
| one `docs/journal/JOURNAL-<area>.md` via `docs/JOURNAL.md`, `docs/journal/JOURNAL.md` for cross-cutting notes, or `docs/journal/SUMMARY.md` for older context | history, prior attempts, decisions, or regressions are requested, or the chosen lane needs recent implementation context |
| code entrypoints, configs, tests | the intent names a task, bug, or subsystem |

- One lane: never scan lane files to discover work. Two plausible lanes or bodies: ask one clarifying question. Open a second only when evidence forces it.
- Fallbacks, first existing wins. Project context: `README*.md`, `docs/specs/prd.md`, `TODO.md`, then a concise root or `docs/` markdown named `index`, `overview`, `spec`, `blueprint`, or `design`. Development context: top of `TODO.md`, `CHANGELOG*.md`, `docs/CHANGELOG*.md`, `docs/notes*.md`. Several candidates for one slot: prefer canonical CDD files, then root runbook docs, then the shortest current-state doc.

### External sources
- Resolve user-named issues, tickets, PRs, RFCs, docs, or tracker references read-only, via connectors, CLIs, local remotes, pasted URLs, or identifiers.
- Read the complete thread before routing: body, all comments, review comments, directly referenced artifacts; do not crawl unrelated links. The latest authoritative comment is current intent; flag superseded body requirements.
- Ask one clarifying question when the reference or source of truth is ambiguous enough to change the routing. When a surface cannot be fetched, mark the boot partial, name the unread surfaces, and route from local context.

## Routing
- Classify a named intent. Research, analysis, investigation, proposal review, and audit are read-only evidence intents unless the user asks for write-producing follow-up.

| Intent | Continuation |
|---|---|
| a runnable TODO step, named by the user or narrowly resolved from `TODO.md` plus one lane | `$cdd-implement <step>`, precedence over every other route |
| a question about the codebase, behavior, requirements, or project state (`inquiry`) | answer in the boot report; no continuation required |
| a new change request or feature idea | `$cdd-plan <intent>` |
| review or verification of implemented work or a proposed enhancement | `$cdd-audit <intent>` |
| doc drift, repo upkeep, or index refresh | `$cdd-maintain <intent>` |
| multi-step autonomous execution over prepared TODO steps | `$cdd-master-chef` |
| a bounded operational, runbook, release, or other concrete repo task | vanilla AGENTS-driven mode on `<intent>` |

- No intent: infer the continuation from the default set under the same lane discipline.
- Recommend a `cdd-*` skill only when its contract adds real control, decomposition, audit shape, upkeep flow, or autonomous execution; otherwise vanilla. `$cdd-implement` direct mode is optional for one bounded non-TODO task, never mandatory.
- Carry the intent into the recommended option text so the user can continue directly.

### Checkout
- In a Git repo, detect main vs linked worktree, then recommend: linked worktree, stay there; read-only evidence intent, the current or main checkout; write-producing intent from main while linked worktrees or repo-local managed worktree paths already exist, move into `.cdd-runtime/worktrees/<branch-or-tag>/` named after the recommended branch or approved workstream tag; otherwise main is acceptable unless the user wants parallel or isolated development.

## Output
- Report fields: `Role`, `Project`, `Development`, `Worktree`, `Intent` (classified intent and recommended continuation), `Answer` for inquiries (lead with a short factual answer, then detail, a table or ASCII diagram where it clarifies structure, explicit gaps; other fields one line each), `Sources used` (files and external artifacts actually read, partial reads named), `Missing expected files` (canonical docs only), `Next action`.
- Options block: repo-local `NEXT` when `AGENTS.md` defines one, otherwise `**Options**`: question, reply hint, choices; nothing follows the final choice. 2-4 lettered choices (`A.`-`D.`, nested `A1.`, also in native option UIs), recommended first; say the user may reply with the selector alone. From a main worktree, offer both `worktree+branch first, then <continuation>` and `main checkout, <continuation>`, placed by suitability, main first for read-only intents. Inquiries omit `Next action` unless a continuation genuinely helps.

### Examples
- `$cdd-boot` — plain boot from the default set.
- `$cdd-boot I want to fix the flaky CI test` — intent boot: warms the relevant surfaces and recommends the continuation.
- `$cdd-boot how do releases get versioned here, and which script owns that?` — inquiry: the answer is the result.
- `$cdd-boot stay on main, cut release 0.7.4 from docs/runbooks/release.md` — operational task: vanilla route in the main checkout.
