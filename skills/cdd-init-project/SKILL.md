---
name: cdd-init-project
description: "Init or adopt the CDD contract in the current folder (empty dir, docs-seeded folder, fresh boilerplate repo, or existing repo migration) (interactive, approval-gated; level-two confirmation for bootstrap copy/download, clone/remote/init/push, and document moves)."
---

# CDD Init Project (interactive, approval-gated)

This skill is designed for:
- a brand-new project directory
- a folder with raw source/reference documents but no substantive code yet
- a repo freshly created from `cdd-boilerplate`
- an existing repo that wants to adopt the CDD workflow

## Canonical contract
These repo files are the authoritative workflow and format; reference them instead of duplicating them:
- `AGENTS.md`
- `README.md`
- `TODO.md` and any split `TODO-<area>.md` files
- `docs/JOURNAL.md`
- `docs/journal/JOURNAL.md`, `docs/journal/JOURNAL-<area>.md`, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when split-journal mode is active
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md` (if present)
- repo-local `.agents/skills/*/SKILL.md` files when present as project workflow surfaces

## Approval ladder
- Level one approves the apply plan. Stay read-only until the user approves a concrete apply plan. Default final apply choices: `A. apply now`, `B. revise first`, `C. stop read-only`; when a concrete follow-up is clear, option A may say `apply now and continue with ...`.
- Level two is a separate explicit confirmation, after level one, before any networked or repo-admin action, including:
  - copying, downloading, or cloning bootstrap material
  - creating a GitHub repo or remote
  - `git init`, connecting a remote, or `git push`
  - moving or restoring user documents (template path conflicts or doc reorganization)
- The level-two request lists the exact commands or operations, the affected paths, and whether network access is required.
- Never infer level two from level one or from general interest in adopting CDD.
- When only level one is granted, stop at the level-two boundary and report the blocked next step.

## Canonical bootstrap source
- Canonical source: `https://github.com/ruphware/cdd-boilerplate`, whenever boilerplate material is needed.
- Local fallback: when the user explicitly prefers a local checkout or network access is unavailable, ask for a local path to an existing `cdd-boilerplate` checkout and use it as the bootstrap source.
- Materializing from either source is level two. Mechanics for the chosen backing:
  - GitHub-backed:
    - create the remote from `ruphware/cdd-boilerplate` using the confirmed repo name
    - materialize the approved boilerplate files into the current folder without cloning to a sibling directory and without changing directories
    - never keep the template repo's git history as part of the new project history
    - if the current folder already has local git history, preserve it and commit the imported boilerplate files into that history; otherwise initialize locally if needed and create a fresh project-owned history after the boilerplate files are in place
    - connect/push the resulting project history so the remote matches the project history rather than the template history
  - Local-only:
    - materialize the approved boilerplate into the current folder without changing directories
    - initialize git locally if needed, or preserve existing local history if `.git/` already exists

## Contract-surface table
Source `boilerplate`: materialize per `## Canonical bootstrap source` and keep its CDD workflow language; never freehand-rewrite. Source `target repo`: fill from the actual target repo; never copy verbatim.

| file | source | preserve | allowed edits |
|---|---|---|---|
| `AGENTS.md` | boilerplate | CDD methodology, rule numbering, method structure, output contract | if needed, bounded repo-fit edits for project facts only (language, framework, repo layout, runbook entrypoints, a short repo note); never rewrite the methodology |
| `TODO.md` | boilerplate | header, Step 00, Step template | if needed, append repo-specific Step 01+ in root `TODO.md` or split `TODO-<area>.md` files; never replace Step 00 with a repo-specific adoption format |
| `docs/JOURNAL.md` | boilerplate | rules, entry format, compact header guidance, transition-to-split mechanics; its role as the stable journal entrypoint/index | repo-specific content only in entries and summaries; unsplit, it stays the live journal; after split activation (active implementation work branches into `TODO-<area>.md`), rewrite it as a short current-state index, compact and high-signal |
| `docs/journal/*` | boilerplate, only in split-journal mode | `docs/journal/JOURNAL.md` for cross-cutting notes, `docs/journal/JOURNAL-<area>.md` for matching active `TODO-<area>.md` workstreams, `docs/journal/SUMMARY.md` for condensed archive history, `docs/journal/archive/` for raw archived batches; split-journal mode once it starts | create or preserve only when split-journal mode is active; never precreate split-journal files before active `TODO-<area>.md` work exists |
| `docs/prompts/PROMPT-INDEX.md` | boilerplate | role, quality bar, output structure; repo-local INDEX workflow and checks when present | otherwise aligned with the boilerplate scaffold; repo-local INDEX workflow and checks may specialize it |
| `.agents/skills/*/SKILL.md` | boilerplate or target repo, when present | repo-local project skills, as project-level workflow surfaces tied to the repo's documented process, through bootstrap and adoption | never require them when absent; never pull user-home skills into the repo |
| `.gitignore` | target repo | existing repo-specific ignore rules | if needed, ensure repo-local `.cdd-runtime/` is ignored, in fresh/bootstrap and adoption outputs |
| `README.md` | target repo | its role as the runbook entrypoint | write from the actual product, architecture, and runbook reality, matching PRD and Blueprint; CDD footer per the rule below |
| `docs/specs/prd.md` | target repo | none | fill from the actual product reality; never carry boilerplate placeholders forward |
| `docs/specs/blueprint.md` | target repo | none | fill from the actual architecture reality; never carry boilerplate placeholders forward |

README footer rule: fresh/bootstrap repos require the block below near the bottom, so the runbook stays primary and the CDD contract stays present but low-visibility. In adoption, get the user's explicit yes before proposing or applying it, then add or move the full block near the bottom of the current `README.md`. Never duplicate it when the block or its badges already exist.

README footer block (exact):

```md
___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)

<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `$cdd-boot`. Use `$cdd-audit` for implementation or codebase audits, `$cdd-plan` + `$cdd-implement` for feature work, and `$cdd-maintain` for doc drift, codebase cleanup, index refresh, refactor architecture audit, and upkeep.</sup>
```

## Intent and assumption checkpoint

- Before detailed implementation questions, drafting `docs/specs/prd.md`, `docs/specs/blueprint.md`, repo-specific `README.md` content, or Step 01+ TODO items, or setup-shape selection, build a project intent frame from the user request, the canonical bootstrap source, the workspace audit, and any discovered source documents.
- Frame fields: `Project purpose`, `Target user or audience`, `Deliverable`, `Hardest constraint`, `Success signal`, `Non-goals`, `Material assumptions`, `Recommended starting shape`, `Unstable points`.
- If intent is unclear, including when workspace evidence suggests another reading of the user's first wording, ask one intent-level clarification first, not implementation-detail questions (file paths, framework choice, repo name, GitHub-vs-local).
- Challenge a material assumption that could change the product purpose, target user, architecture or tech stack, scope or non-goals, deployment or distribution target, Step 01+ sequencing, integrations or external dependencies, validation or UAT shape, or risk/privacy/security/permission behavior.
- With intent stable, classify each remaining material assumption as `confirmed`, `derived-from-docs`, `recommended default`, `risky`, or `excluded`; only `risky` blocks planning by itself. A `recommended default` goes straight into the plan only if a different choice would not create a live `Open decisions` item; otherwise keep the choice visible with the default recommended.
- Expand scope only once the expansion is confirmed to serve the intent, however obvious the path.
- The proposed init or adoption plan shows a compact `Intent and assumptions` section: the frame fields, assumptions by status, and any blocking intent question.
- Apply order: resolve intent → fill PRD → fill Blueprint → align README and TODO Step 01+. Do not let boilerplate placeholders or template wording stand in for an unresolved intent frame.

## Open decisions queue

- After the intent frame and workspace review stabilize the request, surface unresolved plan-shaping choices in a visible `Open decisions` section before emitting a finished init or adoption plan.
- Queue only choices where a different answer would materially change project purpose, target user, architecture or stack direction, source inputs, repo or bootstrap posture, doc/write location, Step 01+ stop point, or validation/UAT shape; exclude reversible implementation details, minor wording, or file-placement questions implied by repo conventions.
- A repo-backed recommendation is not closure: `derived-from-docs` and `recommended default` justify the recommended option but never close a live decision alone.
- Close a decision only by explicit user instruction, a hard workspace or contract constraint, or a remaining difference that is a true minor default leaving plan shape unchanged.
- Record per decision, collapsing duplicates into the smallest root decision: short label, affected boundary, why it matters, recommended option, status:
  - `asking now` = the single highest-leverage open decision for this message
  - `queued` = still unresolved, visible to the user, but not asked yet
- Visibility is broader than questioning: show every remaining decision, mark one `asking now`, leave the rest `queued`.
- Do not emit a finished init or adoption plan while a plan-shaping `Open decisions` item remains unresolved unless the user explicitly resolves or accepts it, or the clarification budget is exhausted and the plan keeps it visible instead of pretending the plan is decision-complete.
- If none remain, say so briefly and continue.

## Interactive planning contract

- Use the runtime's native read-only or plan mode when available; otherwise stay read-only until level one (`## Approval ladder`).
- Review the workspace before and during planning: the relevant docs, code, manifests, configs, runbook files, and current TODO surfaces, so the init or adoption plan reflects the real repo state.
- Ask only to resolve assumptions, goals, or implementation paths that materially affect the plan; never ask preference questions that do not.
- Ask at most one substantive question per message. After each answer, re-rank what remains and ask the next highest-leverage question; never list several open questions as a checklist.
- After each user answer or new repo finding, update state classification, source inputs, sequencing, assumptions, and validation requirements before continuing.
- Keep messages easy to scan: concise, no fluff, lightweight Markdown emphasis such as `**bold**` and `*italics*` when helpful; do not depend on color.
- Offer 2-4 short, action-oriented, repo-grounded choices; open-ended only when a free-form value is required.
- End every decision message with repo-local `NEXT` when `AGENTS.md` defines one, otherwise `**Options**`: question, any reply hint, then choices; nothing follows the final choice.
- Label every choice with a lettered selector, also in native option UIs (`A.`, `B.`, …; nested `A1.`, `A2.`); put the recommended choice first and mark it; say the user may reply with the selector alone. The selected option is the approval; never append a separate approval question.

## State detection
Before any flow, classify the workspace into exactly one state.

Use this precedence order; stop on the first matching state:

0) Ignore non-substantive paths when classifying:
   - `.git/`, `.github/`, `.gitignore`, `.gitattributes`, `.editorconfig`
   - `.cdd-runtime/`
   - editor/OS noise such as `.DS_Store`, `.idea/`, `.vscode/`
   - `LICENSE`, empty directories, and CI-only files

1) `FRESH_BOILERPLATE_REPO` if the full CDD contract exists and the repo is still in Step 00 initialization mode.

Minimum signal files:
- `AGENTS.md`
- `TODO.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/JOURNAL.md`
- `docs/prompts/PROMPT-INDEX.md`

Compatibility note:
- A repo-local `.agents/skills/` folder may also be present in fresh boilerplate state; treat it as compatible boilerplate workflow surface, not as evidence of existing-repo adoption.

2) `EXISTING_REPO_ADOPT_CDD` if any substantive code/build/dependency signal exists, even if raw documents are also present.

Common code/build signals:
- source trees such as `src/`, `app/`, `lib/`, `cmd/`, `server/`, `client/`, `tests/`, `__tests__/`
- language source files such as `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.go`, `.rs`, `.java`, `.kt`, `.rb`, `.php`, `.swift`, `.c`, `.cc`, `.cpp`
- dependency/build manifests such as `package.json`, `pyproject.toml`, `requirements*.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `Gemfile`, `composer.json`, `Makefile`, `Dockerfile`

Important boundary rule:
- partial CDD contract files without the full boilerplate layout count as `EXISTING_REPO_ADOPT_CDD`, not a fresh init

3) `DOCS_SEEDED_INIT` if no code/build signal exists but likely source/reference documents do exist.

Common source-document signals:
- root docs such as `README.md`, `notes*.md`, `requirements*.md`, `brief*.md`, `proposal*.md`, `spec*.md`
- document folders such as `docs/`, `design/`, `adr/`, `research/`, `notes/`
- document files such as `.md`, `.txt`, `.rst`, `.pdf`, `.docx`, `.odt`, `.pptx`, `.key`, `.xlsx`, `.csv`, `.drawio`, `.mmd`

4) `EMPTY_DIR` otherwise.

After classification:
- tell the user which state was detected and the main evidence for that classification
- if any nearby state was ruled out for an important reason, say so briefly
- continue with the matching flow: `## Init flow` for `EMPTY_DIR`, `DOCS_SEEDED_INIT`, and `FRESH_BOILERPLATE_REPO`; `## Adoption flow` for `EXISTING_REPO_ADOPT_CDD`

## Init flow
Goal: bootstrap `cdd-boilerplate` into the current folder as the local repo root (already done in `FRESH_BOILERPLATE_REPO`), preserve any discovered source material, and build Step 00 from it inside this repo.

Stop rule: in `FRESH_BOILERPLATE_REPO`, if Step 00 is already complete and the repo is actively developed, STOP and recommend `$cdd-plan` instead.

1) Skip for `EMPTY_DIR`: before asking any questions, inventory the current folder for candidate source/reference documents and show the detected list grouped by likely importance (for example: core requirements, supporting notes, appendices). If exclusions or missing external documents could materially change the Step 00 input set, queue them in `Open decisions` and ask only the highest-leverage source-input question first.
2) Skip for `FRESH_BOILERPLATE_REPO`: propose the current directory basename as the default repo name and have the user confirm or edit it before any bootstrap step; ask whether they want a GitHub-backed repo (default: private) or a local-only repo for now.
3) `DOCS_SEEDED_INIT` only: before materializing, and after level two, stage discovered source documents that would conflict with template paths; restore them afterward under `docs/source-material/`, preserving relative paths as much as possible, and use `docs/source-material/` as the default input set for Step 00.
4) Skip for `FRESH_BOILERPLATE_REPO`: materialize per `## Canonical bootstrap source` for the chosen backing.
5) Continue directly with Step 00 in this repo, with the discovered documents as the default source material; do not stop and do not ask the user to rerun the skill in another directory. Read the `## Canonical contract` files and use `TODO.md` **Step 00** as the checklist (do not re-define it).
6) Before drafting edits, resolve intent per `## Intent and assumption checkpoint`, then surface remaining plan-shaping choices per `## Open decisions queue`. Present 2-3 setup shapes only for a real plan-shaping decision about source inputs, repo backing or bootstrap source, write location, or Step 01+ sequencing; recommend one based on the workspace review.
7) Draft proposed edits grouped by file, applying each `## Contract-surface table` row.
8) Present the final apply options for the proposed edits (level one).
9) After applying: list the exact Step 00 `Automated checks` commands to run, provide a Step 00 UAT checklist, and suggest the next step to implement via `$cdd-implement`.

## Adoption flow
Goal: add the CDD contract files and reorganize docs so the repo becomes CDD-operable.

### Phase 1 — Audit (no writes)
1) Read `README.md` and find the current runbook (setup/dev/test/build).
2) Inventory existing docs (e.g., `docs/`, `design/`, `adr/`, root markdown files) and repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present.
3) Review the current implementation surfaces that shape adoption planning: manifests, entrypoints, test/lint/typecheck config, and any existing planning system (issues, backlog files, TODO docs).
4) Ask only blocking questions (for example, docs that must keep their path due to external links).

### Phase 2 — Proposal
1) Resolve intent per `## Intent and assumption checkpoint`, deriving the frame primarily from the current repo state and the user's adoption goals rather than from a blank brief, then surface remaining plan-shaping choices per `## Open decisions queue`. Present 2-3 migration shapes only for a real decision about scope, doc reorganization, or TODO placement; recommend one based on the workspace review.
2) Draft a patch proposal grouped by file, applying each `## Contract-surface table` row; source the `boilerplate` rows per `## Canonical bootstrap source`.
3) Reorganize docs around the `README.md` runbook entrypoint: move or normalize non-runbook docs under `docs/` (or `docs/archive/` if historical), preserving content and adding links.
4) Plan repo-specific Step 01+ work in `TODO.md`, including a step to generate or refresh `docs/INDEX.md` via the repo-local INDEX workflow (or `$cdd-maintain` in `index` mode).

### Phase 3 — Apply
1) Present the final apply options for the migration plan (level one).
2) Get level two for every level-two operation in the approved plan before executing it.
3) Apply only the approved changes.
4) Provide exact Automated checks + UAT for the adoption step(s), and recommend `$cdd-maintain` in `index` mode as the next action.
