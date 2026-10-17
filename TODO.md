# TODO


## Step 76 — Split `cdd-maintain` into a routing core and four mode files

points: 3
touches: skills/cdd-maintain/SKILL.md, skills/cdd-maintain/references/*.md, scripts/validate_skills.py
deps: 74, 75

### Goal

`skills/cdd-maintain/SKILL.md` holds routing, mode selection, approval contract, safe-write scope, INDEX freshness, and output at or below 10 KB; each mode is one self-contained reference read after selection; the approval loop is stated once; the Mode C self-grade gate is replaced by a concrete checklist.

### Constraints

- No rule is deleted; the implementer keeps the same bullet-to-home mapping as Step 75.
- Each mode's read list exists once, in its mode file.
- The one-approval-at-a-time loop and the separation of documentation, stale-TODO, runtime-cleanup, and source-cleanup approvals live only in `## Approval contract`; mode files name the approval surface and nothing more.
- Low-freedom text stays verbatim: Mode C validation commands for both layouts, archive filename patterns, the fixed order `A -> B -> C -> D`.
- Mode C preflight gate: "all preflight items present and the mode's validation commands pass" replaces the 0-12 self-grade.
- Canonical options block and one-question loop from Step 74.

### Tasks

- [x] `skills/cdd-maintain/SKILL.md`: rewrite into `## Shared routing read`, `## Mode selection`, `## Approval contract`, `## Safe write behavior`, `## INDEX freshness`, `## Output`, `## Mode files`; the last section lists the four files with "after selection, read the file for each selected mode in execution order".
- [x] `skills/cdd-maintain/references/mode-a-doc-drift.md`: `## Contents`, read list, canonical support docs, drift review and classification, codebase-comparison checks, subsystem clusters, ad-hoc support docs, TODO archive rules, stale adjacent TODO handling, journal archive rules, ad-hoc archive rules, local runtime cleanup review, and one closing list of the mode's four approval surfaces.
- [x] `skills/cdd-maintain/references/mode-b-source-cleanup.md`: candidate scan list, classification, per-candidate record, concern batches.
- [x] `skills/cdd-maintain/references/mode-c-index.md`: split detection, write scope, generation discipline, split-file emission, preflight checklist, validation for both layouts.
- [x] `skills/cdd-maintain/references/mode-d-refactor.md`: preconditions, candidate sources, review, options, report.
- [x] `scripts/validate_skills.py`: set `REQUIRED_SECTIONS["cdd-maintain"]` to the seven core headings; add `REQUIRED_REFERENCE_SECTIONS["cdd-maintain"]` with mode-a `("## Contents", "## Read list", "## Codebase-comparison checks", "## TODO archive rules", "## Journal archive rules", "## Ad-hoc support doc archive rules", "## Local runtime cleanup review")`, mode-b `("## Cleanup candidates",)`, mode-c `("## Split detection", "## Write scope", "## Preflight", "## Validation")`, mode-d `("## Candidate sources",)`.

### Implementation notes

- `## Shared routing read` is three lines: read `AGENTS.md`; read only what routes the mode; mode read lists live in the mode files.
- `## Safe write behavior` keeps one line per mode naming its write scope; Mode C's detailed never-modify list stays in `mode-c-index.md` under `## Write scope`.
- `## Output` keeps the per-mode block lists unchanged.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_installers.sh`

### UAT

- Core at or below 10 KB; four mode files present; the Mode A read list greps to one location.
- An index-mode run reads only `mode-c-index.md`; a do-all run reads the four files in `A -> B -> C -> D` order.
- The validation command blocks and archive filename patterns are byte-identical to today's.
- The validator fails when `## Preflight` is removed from the Mode C file.

## Step 77 — Restructure `cdd-init-project` around one approval ladder, one contract table, and two flows

points: 3
touches: skills/cdd-init-project/SKILL.md, scripts/validate_skills.py
deps: 74

### Goal

`skills/cdd-init-project/SKILL.md` stays a single file, states the two-level approval ladder once, carries the per-file contract rules as one table, runs one init flow with conditional steps plus one adoption flow, keeps state detection whole, and drops the orphan `### A) EMPTY_DIR` heading. Quality is the target; size is not.

### Constraints

- `scripts/test_init_project_artifacts.sh` stays untouched and green: heading `## Open decisions queue`; phrases `visible \`Open decisions\` section`, `A repo-backed recommendation is not closure`, `\`asking now\``, `\`queued\``, `Do not emit a finished init or adoption plan while a plan-shaping \`Open decisions\` item remains unresolved`; fixture file kept.
- Approval ladder stated once: level one approves the apply plan; level two is a separate confirmation for clone, download, remote creation, `git init`, `git push`, and moving or restoring user documents, listing exact commands, paths, and network need; never inferred from interest in CDD; stop at the boundary when only level one is granted.
- The README footer block stays verbatim.
- State detection precedence, ignore list, and signal lists stay verbatim.
- Canonical blocks from Step 74: options block, one-question loop, intent checkpoint and open decisions with init's field names and `derived-from-docs`.

### Tasks

- [x] `skills/cdd-init-project/SKILL.md`: rewrite into `## Canonical contract`, `## Approval ladder`, `## Canonical bootstrap source`, `## Contract-surface table`, `## Intent and assumption checkpoint`, `## Open decisions queue`, `## Interactive planning contract`, `## State detection`, `## Init flow`, `## Adoption flow`.
- [x] `## Contract-surface table`: columns `file | source | preserve | allowed edits`, rows `AGENTS.md`, `TODO.md`, `docs/JOURNAL.md`, `docs/journal/*`, `docs/prompts/PROMPT-INDEX.md`, `.agents/skills/*/SKILL.md`, `.gitignore`, `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`; the README row carries the footer rule for fresh versus adoption repos; the footer block follows the table.
- [x] `## Init flow`: name and backing; docs-seeded only: inventory, source-input question via open decisions, staging after level-two confirmation and restore under `docs/source-material/`; materialize per bootstrap source unless the repo is fresh boilerplate; intent gate; standard edit set as a pointer to the table; apply options; closeout; the fresh-boilerplate stop rule when Step 00 is complete.
- [x] `## Adoption flow`: Phase 1 audit, Phase 2 proposal built from the table plus doc reorganization and Step 01+ planning, Phase 3 apply with the level-two confirmation.
- [x] `scripts/validate_skills.py`: set `REQUIRED_SECTIONS["cdd-init-project"]` to the ten headings in document order.

### Implementation notes

- Bootstrap materialization mechanics (GitHub-backed and local-only) stay under `## Canonical bootstrap source` and are referenced, not repeated, by both flows.
- "Do not precreate split-journal files" and "keep `docs/JOURNAL.md` as the stable entrypoint, rewritten as a short index after split activation" live only in the `docs/JOURNAL.md` and `docs/journal/*` table rows.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_init_project_artifacts.sh`

### UAT

- Ten H2 headings; the separate-confirmation rule greps to `## Approval ladder` only; the per-file rules grep to the table only.
- A dry run of each detected state follows one flow without consulting another section for the file rules.
- Both checks pass; the validator fails when `## Approval ladder` is removed.

## Step 78 — Thin `cdd-master-chef` SKILL.md to an entrypoint and add a contents block to CONTRACT.md

points: 3
touches: skills/cdd-master-chef/SKILL.md, skills/cdd-master-chef/CONTRACT.md

### Goal

`skills/cdd-master-chef/SKILL.md` is a 10 KB entrypoint holding the adapter note, read-first instructions, routing, the kickoff approval bundle, report events, and a section map into `CONTRACT.md`; every rule `CONTRACT.md` already states is removed from SKILL.md; `CONTRACT.md` gains a `## Contents` block and changes in no other way.

### Constraints

- Pins stay: the names of all six core skills, `effective Builder transport`, a `CONTRACT.md §7` pointer, `.cdd-runtime/worktrees/<run-id>/`; no legacy worktree path; no 5, 10, 20, or 30-minute sentences near cadence, boot, suspect, silence, replace, or probe words; no probe-count replacement phrases.
- `CONTRACT.md` numbered `## N)` headings and all section bodies stay byte-identical; the contents block goes between the intro paragraphs and `## 0) Purpose`.
- Frontmatter unchanged. The Hermes sentence is removed.
- References stay one level deep: SKILL.md links `CONTRACT.md`, `RUNBOOK.md`, `RUNTIME-CAPABILITIES.md`, `CODEX-ADAPTER.md`, `CLAUDE-ADAPTER.md` directly.

### Tasks

- [x] `skills/cdd-master-chef/SKILL.md`: rewrite into the H1, a three-line adapter note, `## Read first` (read `CONTRACT.md` fully before kickoff, `RUNBOOK.md` for operations, `RUNTIME-CAPABILITIES.md` and the active runtime's adapter, `CONTRACT.md §7` for decision prompts and Builder lifecycle), `## Routing` (today's item 8 bullets, including the `points:` oversized sentence once), `## Kickoff approval` (today's item 10 list and its `A.`-`C.` options, plus the managed worktree path), `## Report events` (the event list and a pointer to `CONTRACT.md §9` for mission reports and closeout bundles), `## Section map` (table `topic | CONTRACT.md section` for actors, repo state, runtime state, session settings and transport, routing, worktree lifecycle, kickoff and Builder lifecycle, validation and QA, reporting and recovery, compaction, adapter obligations, wave-parallel).
- [x] Delete from SKILL.md: the Shared policy flow bullets, operating-contract items 2-7, 9, 11-17, 19-25, the `BLOCKER_CLEARED` and mission-report paragraphs, and the three closeout bundles, all of which `CONTRACT.md` states.
- [x] `skills/cdd-master-chef/CONTRACT.md`: insert `## Contents` listing `§0` through `§12` with one line each.

### Implementation notes

- `_extract_contract_section` matches only `## N)` headings, so `## Contents` does not disturb section extraction.
- Keep the one-sentence rule "when SKILL.md and CONTRACT.md disagree, CONTRACT.md wins" in the adapter note; after this step it should never trigger.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`

### UAT

- SKILL.md at or below 10 KB; the 8-word shingle overlap with `CONTRACT.md` drops below 10 percent of SKILL.md.
- A kickoff dry run finds every needed rule either in SKILL.md or one hop away through the section map.
- `CONTRACT.md` diff is the contents block only.
- Both checks pass.
