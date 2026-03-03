---
name: cdd-init-project
description: "Init or adopt the CDD contract (empty dir, fresh boilerplate repo, or existing repo migration) (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Init Project (explicit-only)

This skill is designed for:
- a brand-new project directory
- a repo freshly created from `cdd-boilerplate`
- an existing repo that wants to adopt the CDD workflow

## Canonical contract (do not duplicate)
Use these repo files as the authoritative workflow and format:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md` (if present)

## State detection (required)
Classify the workspace into exactly one state and tell the user which one you detected:

### A) EMPTY_DIR
No files present (ignore `.git/` if it exists).

### B) FRESH_BOILERPLATE_REPO
The CDD contract files exist (typical `cdd-boilerplate` layout), and the repo still needs Step 00 work.

Minimum signal files:
- `AGENTS.md`
- `TODO.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/JOURNAL.md`
- `docs/prompts/PROMPT-INDEX.md`

### C) EXISTING_REPO_ADOPT_CDD
Anything else (non-empty repo that is not the boilerplate layout).

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

## Flow B — Fresh boilerplate repo (approval-gated)
1) Read the canonical contract files above.
2) Use `TODO.md` **Step 00** as the checklist (do not re-define it).
3) Ask the user for any existing notes/requirements paths and read them before asking questions.
4) Draft proposed edits (grouped by file) to:
   - fill `docs/specs/prd.md`
   - fill `docs/specs/blueprint.md`
   - update `README.md` to match the PRD/Blueprint
   - extend `TODO.md` with Step 01+ if needed (use the Step template already in `TODO.md`)
5) Ask: **Approve and apply these changes?**
6) After applying:
   - list the exact Step 00 `Automated checks` commands to run
   - provide a Step 00 UAT checklist
   - suggest the next step to implement via `$cdd-implement-todo`

If Step 00 is already complete and the repo is actively developed:
- STOP and recommend using `$cdd-plan` instead.

## Flow C — Existing repo adopting CDD (approval-gated)
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
