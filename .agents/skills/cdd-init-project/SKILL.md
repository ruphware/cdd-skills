---
name: cdd-init-project
description: "Init or adopt the CDD contract (empty dir, docs-seeded folder, fresh boilerplate repo, or existing repo migration) (approval-gated, explicit-only)."
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
- `TODO.md` (and/or `TODO-*.md`)
- `docs/JOURNAL.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md` (if present)

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

### A) EMPTY_DIR
No substantive files are present after applying the ignore rules above.

## Flow A — Empty directory (no writes)
Goal: get the user into a real `cdd-boilerplate`-derived repo (preferred) and re-run this skill there.

1) If `.git/` exists, tell the user this is already a git repo and ask whether they want:
   - a GitHub-connected repo, or
   - a local-only repo for now
2) Provide template-creation instructions (GitHub template), then STOP:

GitHub CLI (template → clone):
```bash
gh repo create <owner>/<new-repo> --template ruphware/cdd-boilerplate --private
git clone git@github.com:<owner>/<new-repo>.git
cd <new-repo>
```

GitHub UI:
- Use “Use this template” on `ruphware/cdd-boilerplate`, then clone locally.

If the user insists on keeping the current empty folder:
- Explain that you can only proceed after the boilerplate contract files exist in this directory.
- Ask the user for a local path to a `cdd-boilerplate` checkout (or permission to clone it), then propose a copy plan and ask approval before writing.

## Flow B — Docs-seeded init (approval-gated)
Goal: bootstrap the CDD contract into the current folder, preserve the raw documents, and use them as default Step 00 inputs.

1) Inventory the current folder for candidate source/reference documents before asking any questions.
2) Show the detected document list grouped by likely importance (for example: core requirements, supporting notes, appendices) and ask only about:
   - documents to exclude
   - important external documents not present in the workspace
3) Propose bootstrapping the CDD contract into the current folder while preserving the raw documents in place.
4) Ask: **Approve bootstrapping the CDD contract here?**
5) After approval, apply the CDD contract and continue with Step 00 using the detected documents as the default source material.
6) Draft proposed edits (grouped by file) to:
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint
   - extend `TODO.md` with Step 01+ if needed (use the Step template already in `TODO.md`)
7) Ask: **Approve and apply these changes?**
8) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

## Flow C — Fresh boilerplate repo (approval-gated)
1) Read the canonical contract files above.
2) Use `TODO.md` **Step 00** as the checklist (do not re-define it).
3) Inventory the current workspace for candidate source/reference documents before asking questions.
4) Show the detected document list and ask only about:
   - documents to exclude
   - important external documents not present in the workspace
5) Draft proposed edits (grouped by file) to:
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint
   - extend `TODO.md` with Step 01+ if needed (use the Step template already in `TODO.md`)
6) Ask: **Approve and apply these changes?**
7) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

If Step 00 is already complete and the repo is actively developed:
- STOP and recommend using `$cdd-plan` instead.

## Flow D — Existing repo adopting CDD (approval-gated)
Goal: add the CDD contract files and reorganize docs so the repo becomes CDD-operable.

### Phase 1 — Audit (no writes)
1) Read `README.md` and find the current runbook (setup/dev/test/build).
2) Inventory existing docs (e.g., `docs/`, `design/`, `adr/`, root markdown files).
3) Identify any existing planning system (issues, backlog files, TODO docs).
4) Ask only blocking questions (e.g., docs that must keep their path due to external links).

### Phase 2 — Draft migration plan (proposal)
Draft a patch proposal grouped by file, including:
1) Add the CDD contract files (prefer matching `cdd-boilerplate` structure):
   - `AGENTS.md`, `TODO.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, `docs/JOURNAL.md`, `docs/prompts/PROMPT-INDEX.md`
2) Reorganize docs:
   - keep `README.md` as the runbook entrypoint
   - move/normalize non-runbook docs under `docs/` (or `docs/archive/` if historical), preserving content and adding links
3) Add an adoption plan to `TODO.md`:
   - a Step 00-style “CDD adoption” step
   - a step to generate/refresh `docs/INDEX.md` via `docs/prompts/PROMPT-INDEX.md` (or `$cdd-index`)

### Phase 3 — Apply
1) Ask: **Approve and apply this migration plan?**
2) Apply the approved changes.
3) Provide exact Automated checks + UAT for the adoption step(s), and recommend `$cdd-index` as the next action.
