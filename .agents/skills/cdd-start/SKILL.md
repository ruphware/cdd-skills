---
name: cdd-start
description: "Start a new project workflow: PRD -> Blueprint -> TODO (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Start (explicit-only)


## No deadlines
- Never introduce deadlines, schedules, or time-bound phrasing.
- If you need a disambiguating tag for a filename, ask the user for a short tag (don’t default to dates).


## Session bootstrap (required)
Initialize context in this order:
1) Read `AGENTS.md`.
2) Read `README.md`.
3) Read `docs/INDEX.md` (if missing: recommend running `$cdd-index` when repo context matters).
4) Read `docs/specs/blueprint.md`.
5) Read `docs/specs/prd.md`.
6) Read the **top** of `docs/JOURNAL.md` for process rules (do not scan the entire file unless needed).


## Repo detection & template state (required, before Stage 1)
Goal: detect whether we are in a fresh cdd-boilerplate-derived repo and whether the contract docs are still placeholders.

### 1) Detect CDD contract presence
Check the existence of:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/prompts/PROMPT-INDEX.md`

If critical files are missing, STOP and ask the user whether to initialize the CDD contract in this repo or exit.

### 2) Detect “template placeholders” (empty vs initialized)
Run placeholder scans (prefer `rg` if available; otherwise `grep`).

Primary (high-signal) markers:
- `YYYY-MM-DD`
- `<PROJECT NAME>`

Secondary (boilerplate-typical) markers (use as supporting signal; they can be false positives in rare cases):
- `G1 — ...`, `FR1 — ...`, `AC1 — ...`, `NG1 — ...`, `NFR1 — ...`, `Persona A — ...`
- `Components: ...`, `Data flow: ...`, `Boundaries: ...`

Concrete checks (examples):

- PRD + Blueprint placeholders (primary):
  - Prefer ripgrep:
    - `rg -n "YYYY-MM-DD|<PROJECT NAME>" docs/specs/prd.md docs/specs/blueprint.md`
  - Fallback grep:
    - `grep -REIn "YYYY-MM-DD|<PROJECT NAME>" docs/specs/prd.md docs/specs/blueprint.md`

- PRD + Blueprint placeholders (secondary/supporting):
  - Prefer ripgrep:
    - `rg -n "\b(G1|FR1|AC1|NG1|NFR1)\b\s+—\s+\.\.\.|Persona A\s+—\s+\.\.\.|(Components|Data flow|Boundaries):\s+\.\.\." docs/specs/prd.md docs/specs/blueprint.md`
  - Fallback grep (less precise):
    - `grep -REIn "(G1|FR1|AC1|NG1|NFR1) — \\.\\.\\.|Persona A — \\.\\.\\.|(Components|Data flow|Boundaries): \\.\\.\\." docs/specs/prd.md docs/specs/blueprint.md`

- Step >= 01 present (any TODO file):
  - Prefer ripgrep:
    - `rg -n "^## Step (0?[1-9]|[1-9][0-9]+)\b" TODO*.md`
  - Fallback grep (portable ERE; no \b):
    - `grep -REn "^## Step (0?[1-9]|[1-9][0-9]+)([^0-9]|$)" TODO*.md`

Classify `repo_state`:
- **TEMPLATE_EMPTY**: placeholder markers exist in PRD/Blueprint AND TODO has no Step >= 01.
- **TEMPLATE_PARTIAL**: placeholder markers exist in PRD or Blueprint OR only one of them is filled.
- **PROJECT_INITIALIZED**: no placeholder markers in PRD/Blueprint AND TODO has Step >= 01 with real content.
- **NOT_A_CDD_REPO**: missing critical CDD contract files.

### 3) Behavior by repo_state
- If **PROJECT_INITIALIZED**:
  - STOP and recommend using `$cdd-plan` (or `$cdd-implement` for an existing step).
  - Ask whether the user still wants to run `$cdd-start` (which may overwrite specs).

- If **TEMPLATE_EMPTY** or **TEMPLATE_PARTIAL**:
  - Proceed with Stage 1 PRD drafting.
  - Treat boilerplate PRD/Blueprint as scaffolding, not authoritative content.

- If **NOT_A_CDD_REPO**:
  - Ask whether to initialize the CDD contract files in this repo.

### 4) Context ingestion (before asking PRD questions)
Ask the user:
- “Do you have context already written in files (notes, pitch, requirements)? If yes, provide the paths; I will read them first.”

If the user provides paths:
- Read them and treat them as primary inputs for the PRD draft.
- Do not modify any files until approval.


## Approval gate (mandatory)
Planning skills must **not** modify repo files on the first pass.

Workflow:
1) Ask one blocking question at a time (only questions that materially change the plan).
2) Produce a draft plan / proposed edits.
3) Ask: **“Approve and apply these changes?”**
4) Only after explicit approval: write to files.


## Multi-TODO rules
- If multiple TODO files exist (`TODO.md`, `TODO-*.md`), ask which file to update (default: `TODO.md`).
- If creating a new plan file (audit/refactor), ask the user for a short tag and name it:
  - `TODO-audit-<tag>.md`
  - `TODO-refactoring-<tag>.md`
- If a new TODO file is created, link it from `TODO.md` (Active Work Index) if present; otherwise propose adding that section.


## Stage 1 — PRD (draft then apply)
Draft pass:
- Ask one blocking question at a time.
- Produce a PRD draft (full text or patch).
- Ask for approval.

Apply pass (after approval):
- Write `docs/specs/prd.md`.

## Stage 2 — Blueprint (draft then apply)
Draft pass:
- Read the approved PRD.
- Propose 1 recommended architecture/stack + 1–2 alternatives (brief tradeoffs).
- Produce a blueprint draft.
- Ask for approval.

Apply pass (after approval):
- Write `docs/specs/blueprint.md`.

## Stage 3 — TODO plan (draft then apply)
Draft pass:
- Convert PRD (+ blueprint) into 5–15 small, sequential steps.
- Step 01 should be the smallest end-to-end slice.
- Every step must include: Goal / Deliverable / Changes / Automated checks (exact commands) / UAT.
- Ask for approval.

Apply pass (after approval):
- Write the approved plan into the selected TODO file.

## After completion
- Ask whether the user wants to implement the next step now using `$cdd-implement`.
