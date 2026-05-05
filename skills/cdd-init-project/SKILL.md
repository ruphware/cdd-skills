---
name: cdd-init-project
description: "Init or adopt the CDD contract in the current folder (empty dir, docs-seeded folder, fresh boilerplate repo, or existing repo migration) (approval-gated, explicit-only; separate confirmation required for bootstrap copy/download and clone/remote/init/push actions)."
disable-model-invocation: true
---

# CDD Init Project (explicit-only)

This skill is designed for:
- a brand-new project directory
- a folder with raw source/reference documents but no substantive code yet
- a repo freshly created from `cdd-boilerplate`
- an existing repo that wants to adopt the CDD workflow

## Canonical contract (do not duplicate)
Use these repo files as the authoritative workflow and format:
- `AGENTS.md`
- `README.md`
- `TODO.md` and any split `TODO-<area>.md` files
- `docs/JOURNAL.md`
- `docs/journal/JOURNAL.md`, `docs/journal/JOURNAL-<area>.md`, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when split-journal mode is active
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md` (if present)
- repo-local `.agents/skills/*/SKILL.md` files when present as project workflow surfaces

For methodology-stable contract surfaces, materialize from `cdd-boilerplate` and preserve the CDD workflow language under the drift rules below instead of freehand rewriting.

## High-impact action guardrails
- Stay read-only until the user approves a concrete apply plan.
- Require a separate explicit confirmation before any networked or repo-admin action, including:
  - cloning or downloading bootstrap material
  - creating a GitHub repo or remote
  - `git init`, connecting a remote, or `git push`
  - moving or restoring user documents to resolve template path conflicts
- When asking for that confirmation, list the exact commands or operations, the affected paths, and whether network access is required.
- Never infer approval for clone/remote/init/push operations from general interest in adopting CDD.
- If the user approves document edits but not repo-admin or networked actions, stop at that boundary and report the blocked next step.

## Canonical bootstrap source
- Treat `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source when boilerplate material is needed.
- Even when that canonical source is identified, do not copy, download, clone, or otherwise materialize boilerplate from it until the user gives separate explicit confirmation.
- If the user explicitly prefers a local checkout or network access is unavailable, ask for a local path to an existing `cdd-boilerplate` checkout as the fallback bootstrap source.

## Required README CDD footnote footer
- For fresh/bootstrap repos, require this exact `README.md` footer block near the bottom of the file so the runbook stays primary and the CDD contract remains present but low-visibility:

```md
___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)

<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `$cdd-boot`. Use `$cdd-implementation-audit` for implementation or codebase audits, `$cdd-plan` + `$cdd-implement-todo` for feature work, and `$cdd-maintain` for doc drift, index refresh, codebase cleanup, refactor planning, and upkeep.</sup>
```

- For existing-repo adoption, ask the user for explicit confirmation before proposing or applying that README.md edit; only then consider adding or moving that full CDD footnote footer near the bottom of the current `README.md`.
- Avoid duplicating the block if it or its badges already exist.

## Contract-surface taxonomy and drift rules
- Treat these files as methodology-stable contract surfaces that should be materialized from `cdd-boilerplate` and kept aligned with its CDD workflow language:
  - `AGENTS.md`
  - `TODO.md`
  - `docs/JOURNAL.md`
  - `docs/prompts/PROMPT-INDEX.md`
- Treat these optional scaled workflow surfaces as boilerplate-aligned only when the repo shape activates them:
  - `docs/journal/JOURNAL.md`
  - `docs/journal/JOURNAL-<area>.md`
  - `docs/journal/SUMMARY.md`
  - `docs/journal/archive/`
- Treat these optional repo-local workflow surfaces as project-level contract files to preserve when present:
  - `.agents/skills/*/SKILL.md`
- Treat these files as repo-specific contract surfaces that must be filled from the actual target repo rather than copied verbatim:
  - `README.md`
  - `docs/specs/prd.md`
  - `docs/specs/blueprint.md`
- `AGENTS.md`: start from the boilerplate `AGENTS.md` and preserve the CDD methodology, rule numbering, method structure, and output contract. Limited repo-fit edits are allowed only for project facts such as language, framework, repo layout, runbook entrypoints, or a short repo note; do not rewrite the methodology.
- `TODO.md`: start from the boilerplate `TODO.md` and preserve its header, Step 00, and Step template. Add repo-specific work only as Step 01+ in root `TODO.md` or split `TODO-<area>.md` files; do not replace Step 00 with a repo-specific adoption format.
- `docs/JOURNAL.md`: start from the boilerplate journal and preserve its rules, entry format, compact header guidance, and transition-to-split mechanics. In unsplit repos it remains the live journal; once active implementation work branches into `TODO-<area>.md`, keep `docs/JOURNAL.md` as the stable journal entrypoint/index, rewrite it as a short current-state index after split activation, and keep it compact and high-signal. Repo-specific content belongs in entries and summaries only.
- `docs/journal/*`: create or preserve these only when split-journal mode is active. Keep `docs/journal/JOURNAL.md` for cross-cutting notes, `docs/journal/JOURNAL-<area>.md` for matching active `TODO-<area>.md` workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches. Do not precreate split-journal files before active `TODO-<area>.md` work exists, and keep split-journal mode once it starts.
- `docs/prompts/PROMPT-INDEX.md`: start from the boilerplate prompt and preserve its role, analysis and generation workflow, quality bar, and template structure. Do not replace it with a repo-specific docs-index prompt.
- `.agents/skills/*/SKILL.md`: preserve repo-local project skills when present. Treat them as project-level workflow surfaces tied to the repo's documented process. Preserve them during bootstrap or adoption; do not require them when absent and do not pull user-home skills into the repo.
- `README.md`, `docs/specs/prd.md`, and `docs/specs/blueprint.md` are repo-specific outputs and should be written from the target repo's actual product, architecture, and runbook reality.

## Interactive planning contract
Planning in this skill is interactive, review-driven, and continuously refined.

- Start in planning mode when the runtime supports a native read-only or plan mode. If it does not, emulate that behavior by staying read-only until the user approves applying the plan.
- Review the workspace before and during planning. Audit the relevant docs, code, manifests, configs, runbook files, and current TODO surfaces so the init or adoption plan reflects the real repo state.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths. Do not ask preference questions that do not materially affect the plan.
- Ask at most one substantive clarification or decision question per message.
- Keep refining the execution plan as new evidence appears. After each user answer or new repo finding, update state classification, source inputs, sequencing, assumptions, and validation requirements before continuing.
- Keep messages easy to scan: concise, no fluff, and use lightweight Markdown emphasis such as `**bold**` and `*italics*` when helpful. Do not depend on color.
- For every clarification or decision message, put the choices at the bottom under a final `**Options**` section:
  - offer 2-4 concrete options grounded in the repo context
  - put the recommended option first and mark it clearly
  - prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key
  - default to letters: `A.`, `B.`, `C.`
  - use numbers only when the surrounding context is already numeric and that would be clearer
  - keep each option short and action-oriented
  - avoid open-ended options unless a free-form value is truly required
  - when practical, tell the user they can reply with just the selector

## State detection (required)
Classify the workspace into exactly one state and tell the user which one you detected:

Use this precedence order; stop on the first matching state:

0) Ignore non-substantive paths when classifying:
   - `.git/`, `.github/`, `.gitignore`, `.gitattributes`, `.editorconfig`
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
- continue with the matching flow using the interactive planning contract above

### A) EMPTY_DIR
No substantive files are present after applying the ignore rules above.

## Flow A — Empty directory (approval-gated)
Goal: bootstrap `cdd-boilerplate` into the current folder, using this directory as the local repo root.

1) Derive the current directory basename and propose it as the default repo name.
2) Ask the user to confirm or edit that repo name before any bootstrap step, using the interaction contract above.
3) Ask whether they want, using the interaction contract above:
   - a GitHub-backed repo (default: private), or
   - a local-only repo for now
4) If GitHub-backed and separately approved for networked/repo-admin actions:
   - use `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source
   - ask for separate explicit approval before copying, downloading, cloning, or otherwise materializing boilerplate from that source
   - create the remote from `ruphware/cdd-boilerplate` using the confirmed repo name
   - materialize the approved boilerplate files into the current folder without cloning to a sibling directory and without changing directories
   - never keep the template repo's git history as part of the new project history
   - if the current folder already has local git history, preserve it and commit the imported boilerplate files into that history
   - otherwise, initialize locally if needed and create a fresh project-owned history after the boilerplate files are in place
   - connect/push the resulting project history so the remote matches the project history rather than the template history
5) If local-only:
   - default the bootstrap source to `https://github.com/ruphware/cdd-boilerplate`
   - ask for separate explicit approval before copying, downloading, cloning, or otherwise materializing boilerplate from that source
   - if the user explicitly prefers a local checkout or network access is unavailable, ask for a local path to an existing `cdd-boilerplate` checkout as the fallback bootstrap source
   - materialize the approved boilerplate into the current folder without changing directories
   - initialize git locally if needed, or preserve existing local history if `.git/` already exists
6) Continue directly with Step 00 in this repo; do not stop and do not ask the user to rerun the skill in another directory.
7) Before drafting edits, present 2-3 setup shapes only when there is a real plan-shaping decision about source inputs, repo backing, or where bootstrap material should come from.
   - Recommend one option based on the workspace review.
   - Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
8) Draft proposed edits (grouped by file) to:
   - if needed, add only bounded repo-detail edits to `AGENTS.md` under the drift rules above
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint and include the required CDD footnote footer near the bottom of the file
   - extend `TODO.md` with Step 01+ if needed, preserving the boilerplate header, Step 00, and Step template already in `TODO.md`
   - keep `docs/JOURNAL.md` as the stable journal entrypoint/index, preserve split-journal topology only when active, keep post-split `docs/JOURNAL.md` as a short current-state index, keep `docs/prompts/PROMPT-INDEX.md` aligned with its boilerplate methodology scaffold, and preserve repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present
9) Ask: **Approve and apply these changes?**
10) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

## Flow B — Docs-seeded init (approval-gated)
Goal: bootstrap `cdd-boilerplate` into the current folder, preserve the discovered source material, and build Step 00 from it inside this repo.

1) Inventory the current folder for candidate source/reference documents before asking any questions.
2) Show the detected document list grouped by likely importance (for example: core requirements, supporting notes, appendices) and ask only about, using the interaction contract above:
   - documents to exclude
   - important external documents not present in the workspace
3) Derive the current directory basename and propose it as the default repo name.
4) Ask the user to confirm or edit that repo name before any bootstrap step, using the interaction contract above.
5) Ask whether they want, using the interaction contract above:
   - a GitHub-backed repo (default: private), or
   - a local-only repo for now
6) Before materializing the boilerplate, and only after explicit apply approval, stage discovered source documents that would conflict with template paths.
   - restore them afterward under `docs/source-material/`, preserving relative paths as much as possible
   - use `docs/source-material/` as the default input set for Step 00
7) If GitHub-backed and separately approved for networked/repo-admin actions:
   - use `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source
   - ask for separate explicit approval before copying, downloading, cloning, or otherwise materializing boilerplate from that source
   - create the remote from `ruphware/cdd-boilerplate` using the confirmed repo name
   - materialize the approved boilerplate files into the current folder without cloning to a sibling directory and without changing directories
   - never keep the template repo's git history as part of the new project history
   - if the current folder already has local git history, preserve it and commit the imported boilerplate files into that history
   - otherwise, initialize locally if needed and create a fresh project-owned history after the boilerplate files are in place
   - connect/push the resulting project history so the remote matches the project history rather than the template history
8) If local-only:
   - default the bootstrap source to `https://github.com/ruphware/cdd-boilerplate`
   - ask for separate explicit approval before copying, downloading, cloning, or otherwise materializing boilerplate from that source
   - if the user explicitly prefers a local checkout or network access is unavailable, ask for a local path to an existing `cdd-boilerplate` checkout as the fallback bootstrap source
   - materialize the approved boilerplate into the current folder without changing directories
   - initialize git locally if needed, or preserve existing local history if `.git/` already exists
9) Continue directly with Step 00 in this repo using the discovered documents as the default source material.
10) Before drafting edits, present 2-3 setup shapes only when there is a real plan-shaping decision about source inputs, bootstrap mode, or write location.
    - Recommend one option based on the workspace review.
    - Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
11) Draft proposed edits (grouped by file) to:
   - if needed, add only bounded repo-detail edits to `AGENTS.md` under the drift rules above
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint and include the required CDD footnote footer near the bottom of the file
   - extend `TODO.md` with Step 01+ if needed, preserving the boilerplate header, Step 00, and Step template already in `TODO.md`
   - keep `docs/JOURNAL.md` as the stable journal entrypoint/index, preserve split-journal topology only when active, keep post-split `docs/JOURNAL.md` as a short current-state index, keep `docs/prompts/PROMPT-INDEX.md` aligned with its boilerplate methodology scaffold, and preserve repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present
12) Ask: **Approve and apply these changes?**
13) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

## Flow C — Fresh boilerplate repo (approval-gated)
1) Read the canonical contract files above.
2) Use `TODO.md` **Step 00** as the checklist (do not re-define it).
3) Inventory the current workspace for candidate source/reference documents before asking questions.
4) Show the detected document list and ask only about, using the interaction contract above:
   - documents to exclude
   - important external documents not present in the workspace
5) Before drafting edits, present 2-3 setup shapes only when there is a real plan-shaping decision about source inputs or Step 01+ sequencing.
   - Recommend one option based on the workspace review.
   - Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
6) Draft proposed edits (grouped by file) to:
   - if needed, add only bounded repo-detail edits to `AGENTS.md` under the drift rules above
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint and include the required CDD footnote footer near the bottom of the file
   - extend `TODO.md` with Step 01+ if needed, preserving the boilerplate header, Step 00, and Step template already in `TODO.md`
   - keep `docs/JOURNAL.md` as the stable journal entrypoint/index, preserve split-journal topology only when active, keep post-split `docs/JOURNAL.md` as a short current-state index, keep `docs/prompts/PROMPT-INDEX.md` aligned with its boilerplate methodology scaffold, and preserve repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present
7) Ask: **Approve and apply these changes?**
8) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

If Step 00 is already complete and the repo is actively developed:
- STOP and recommend using `$cdd-plan` instead.

## Flow D — Existing repo adopting CDD (approval-gated)
Goal: add the CDD contract files and reorganize docs so the repo becomes CDD-operable.

### Phase 1 — Audit (no writes)
1) Read `README.md` and find the current runbook (setup/dev/test/build).
2) Inventory existing docs (e.g., `docs/`, `design/`, `adr/`, root markdown files) and repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present.
3) Review the current implementation surfaces that shape adoption planning: manifests, entrypoints, test/lint/typecheck config, and any existing planning system (issues, backlog files, TODO docs).
4) Ask only blocking questions one at a time using the interaction contract above (for example, docs that must keep their path due to external links).

### Phase 2 — Draft migration plan (proposal)
Before drafting the patch proposal, present 2-3 migration shapes when there is a real decision about scope, doc reorganization, or TODO placement.
- Recommend one option based on the workspace review.
- Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
- Use `https://github.com/ruphware/cdd-boilerplate` as the source of truth for the CDD contract when migrating an existing repo.
- If migration requires copying, downloading, cloning, or otherwise materializing contract files from that source, ask for separate explicit confirmation before doing so.
- If the user explicitly prefers a local checkout or network access is unavailable, you may use a local `cdd-boilerplate` checkout as the migration fallback source.

Draft a patch proposal grouped by file, including:
1) Add the CDD contract files using the taxonomy above:
   - `AGENTS.md`: start from the boilerplate contract and allow only bounded repo-fit edits that do not change the CDD methodology
   - `TODO.md`, `docs/JOURNAL.md`, and `docs/prompts/PROMPT-INDEX.md`: materialize from `https://github.com/ruphware/cdd-boilerplate` and preserve their methodology scaffolds, with `docs/JOURNAL.md` kept as the stable journal entrypoint/index, rewritten as a short current-state index after split activation, and split-journal `docs/journal/*` topology preserved only when active
   - `.agents/skills/*/SKILL.md`: when present in the source or target repo, preserve them as repo-local workflow surfaces tied to the repo's documented process; do not require them when absent and do not import user-home skills
   - `docs/specs/prd.md` and `docs/specs/blueprint.md`: fill from the actual repo rather than copying boilerplate placeholders forward
2) Reorganize docs:
   - keep `README.md` as the runbook entrypoint
   - if the current `README.md` does not already contain the required CDD footnote footer, ask for explicit confirmation before proposing or applying that full-block README.md edit during existing-repo adoption
   - move/normalize non-runbook docs under `docs/` (or `docs/archive/` if historical), preserving content and adding links
3) Add repo-specific planning to `TODO.md`:
   - preserve the boilerplate header, Step 00, and Step template
   - append repo-specific Step 01+ work, including a step to generate or refresh `docs/INDEX.md` via `docs/prompts/PROMPT-INDEX.md` (or `$cdd-maintain` in `index` mode)

### Phase 3 — Apply
1) Ask: **Approve and apply this migration plan?**
2) If the approved plan includes clone, remote creation, git initialization, push, or path-moving operations, ask a second confirmation listing those exact operations before executing them.
3) Apply only the approved changes.
4) Provide exact Automated checks + UAT for the adoption step(s), and recommend `$cdd-maintain` in `index` mode as the next action.
