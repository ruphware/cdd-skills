# TODO

## Step 01 — Make GitHub boilerplate source explicit and approval-gated

### Goal

Make `cdd-init-project` treat `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source when boilerplate material is needed, while keeping copy/download from that source behind explicit user approval.

### Constraints

- Preserve separate explicit approval for clone, download, remote creation, `git init`, and `git push`.
- Do not describe a local `cdd-boilerplate` checkout as the preferred default path.
- Preserve local-path fallback wording for local-only or network-restricted cases.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` so bootstrap-source language names `https://github.com/ruphware/cdd-boilerplate` as the canonical source in Empty-directory and Docs-seeded flows.
- [x] Rewrite bootstrap-path instructions so the skill asks for explicit approval before copying, cloning, or otherwise materializing boilerplate from that GitHub source, instead of implying that the source can be used immediately.
- [x] Keep local checkout usage as an explicit fallback or user-selected alternative rather than the preferred default.
- [x] Extend `scripts/validate_skills.py` to assert the init skill includes the direct GitHub source rule and the explicit approval rule for copying/downloading from it.

### Implementation notes

- Touch only the canonical skill source and validator unless a failing check proves another surface is required.
- Keep the existing high-impact action guardrails intact.
- The wording should make the security boundary obvious: canonical source is GitHub, execution still waits for user approval.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated init skill and confirm the default bootstrap source is `https://github.com/ruphware/cdd-boilerplate`.
- Confirm the skill still requires explicit approval before copying/downloading boilerplate from that source.
- Confirm local checkout wording remains available only as fallback or explicit choice.

## Step 02 — Require the CDD README header block with adoption confirmation

### Goal

Make `cdd-init-project` require the exact CDD README header block in initialized repos, and require explicit user confirmation before adding that block to an existing project `README.md` during CDD adoption.

### Constraints

- Preserve `README.md` as the runbook entrypoint.
- For fresh/bootstrap repos, require the exact block under the title and short project description.
- For existing-repo adoption, do not add the block unless the user explicitly confirms that README edit.
- Avoid duplicate insertion when the block or its badges already exist.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` so README-drafting steps for fresh/bootstrap flows require this exact block under the title and project description:
  `[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)`
  `[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)`
  `> This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.`
  `> Start with `$cdd-boot`. Use `$cdd-plan` + `$cdd-implement-todo` for feature work, `$cdd-maintain` for upkeep and drift control, and `$cdd-refactor` for structured refactors.`
- [x] Update existing-repo adoption guidance so the skill must ask for confirmation before adding that full block to an existing `README.md`.
- [x] Extend `scripts/validate_skills.py` to assert both the exact block requirement and the existing-README confirmation rule.

### Implementation notes

- The confirmation rule is for the full block, not just badges.
- Fresh/bootstrap flows and existing-repo adoption may need different wording in the skill; keep that distinction explicit.
- Keep the snippet placement rule precise: under title and short description, before the rest of the runbook.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated init skill and confirm the exact block is present for fresh/bootstrap README generation.
- Confirm the placement rule says the block goes under the title and project description.
- Confirm existing-repo adoption now asks before modifying `README.md` with that full block.

## Step 03 — Bound contract-doc drift in `cdd-init-project`

### Goal

Make `cdd-init-project` distinguish methodology-stable CDD contract docs from repo-specific docs so init and adoption preserve boilerplate workflow language while still allowing bounded repo fit.

### Constraints

- `AGENTS.md` may only receive small repo-specific adjustments that lock in language, framework, or structure; do not rewrite or remove boilerplate methodology sections, rule numbering, or output contract.
- `TODO.md` must preserve the boilerplate header, Step 00, and Step template; repo-specific planning starts in Step 01+.
- `docs/JOURNAL.md` must preserve the boilerplate rules, entry format, and archive mechanics; repo-specific content is limited to journal entries and summaries.
- `docs/prompts/PROMPT-INDEX.md` must stay a boilerplate-stable regeneration prompt rather than a repo-specific rewrite.
- `README.md`, `docs/specs/prd.md`, and `docs/specs/blueprint.md` remain repo-specific outputs.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` to add an explicit contract-surface taxonomy that separates methodology-stable files from repo-specific files.
- [x] Define per-file drift rules for `AGENTS.md`, `TODO.md`, `docs/JOURNAL.md`, and `docs/prompts/PROMPT-INDEX.md`, including where repo-specific content is allowed and where it is not.
- [x] Update the empty-dir, docs-seeded, fresh-boilerplate, and existing-repo adoption flows so stable docs are materialized from `cdd-boilerplate` under those drift rules instead of being freely rewritten.
- [x] Replace existing-repo wording that calls for a custom “Step 00-style” adoption step with wording that preserves boilerplate `TODO.md` Step 00 and appends repo-specific Step 01+ work only where needed.

### Implementation notes

- Keep the canonical bootstrap-source and approval-gate rules unchanged.
- Be explicit about allowed repo-specific writes: `AGENTS.md` repo details, `docs/JOURNAL.md` entries, `TODO.md` Step 01+, and the normal repo-specific `README.md` / PRD / Blueprint outputs.
- Prefer rules that block methodology drift by default instead of relying on examples alone.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- [ ] Read the updated init skill and confirm it classifies methodology-stable vs repo-specific contract surfaces.
- [ ] Confirm `AGENTS.md` methodology stays boilerplate-stable while limited repo-detail tailoring is still allowed.
- [ ] Confirm `TODO.md`, `docs/JOURNAL.md`, and `docs/prompts/PROMPT-INDEX.md` are no longer described as repo-specific rewrites.

## Step 04 — Validate contract-doc drift rules

### Goal

Add local validation that fails when `cdd-init-project` reopens methodology drift in CDD contract docs.

### Constraints

- The validator must verify the contract-surface taxonomy and drift boundaries without relying on network access.
- Validation must fail if the skill allows a custom `TODO.md` Step 00 or repo-specific rewrite of `docs/JOURNAL.md` or `docs/prompts/PROMPT-INDEX.md`.
- Validation must allow bounded `AGENTS.md` repo-fit edits without allowing methodology edits.
- Keep the checks focused on the canonical skill source unless a failing test proves another surface needs coverage.

### Tasks

- [x] Extend `scripts/validate_skills.py` to assert that the init skill declares the methodology-stable contract surfaces and the repo-specific surfaces.
- [x] Add assertions that the init skill preserves boilerplate `TODO.md` Step 00 and the step template instead of replacing them with a repo-specific adoption template.
- [x] Add assertions that the init skill preserves boilerplate `docs/JOURNAL.md` structure and `docs/prompts/PROMPT-INDEX.md` prompt guidance rather than synthesizing replacements.
- [x] Add assertions that the init skill allows only bounded `AGENTS.md` repo-detail adjustments while keeping methodology sections stable.
- [x] Add any narrow negative checks needed to catch the current drift language if it reappears.

### Implementation notes

- Prefer positive assertions for the desired rules plus narrow negative assertions for known bad patterns.
- If the validator becomes hard to read, extract a helper instead of expanding fragile regex blocks.
- Touch `scripts/test-skill-audit.sh` only if a validation gap cannot be covered cleanly in `scripts/validate_skills.py`.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- [ ] Run the validator and confirm it would fail if the skill text reintroduced repo-specific rewrites for `TODO.md`, `docs/JOURNAL.md`, or `docs/prompts/PROMPT-INDEX.md`.
- [ ] Confirm the validator still permits repo-specific `README.md` / PRD / Blueprint generation and limited `AGENTS.md` repo-detail edits.

## Step 05 — Collapse repetitive implementation confirmations in `cdd-audit-and-implement`

### Goal

Make `cdd-audit-and-implement` keep its explicit approval model without asking the user to reconfirm implementation immediately after they already chose the first step to implement.

### Constraints

- Preserve the skill's plan-approval gate before any TODO edits are applied.
- Preserve an explicit implementation-start decision after the TODO plan is applied.
- In the normal path, the step-selection prompt must also serve as the implementation-start approval for the selected step.
- Keep a clear non-implementation exit path so the user can stop after plan application.
- Align the behavior with `cdd-implement-todo`, which already treats an explicitly chosen step as authoritative.

### Tasks

- [x] Update `skills/cdd-audit-and-implement/SKILL.md` so Flow B collapses step selection and implementation approval into one guided options message.
- [x] Replace the separate `Approve starting implementation now?` follow-up with wording that makes the selected option itself the implementation approval, while still offering a stop-after-plan option.
- [x] Keep the recommendation in dependency order and make the stop path explicit rather than implied.
- [x] Extend `scripts/validate_skills.py` to assert the non-redundant Flow B wording and to reject the old repetitive-confirmation prompt if it reappears.

### Implementation notes

- Keep the skill's top-level “two approvals” contract, but make the second approval happen inside the step-selection decision instead of in a separate follow-up message.
- Prefer wording such as “Which newly created step should I implement now?” with options that map directly to “implement this step now” or “stop after planning”.
- Touch `skills/cdd-audit-and-implement/SKILL.md` and `scripts/validate_skills.py` only unless a failing check proves another surface is required.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- [ ] Read the updated audit skill and confirm the first-step selection prompt doubles as the implementation-start approval.
- [ ] Confirm the skill still offers a clear stop-after-plan path without forcing implementation.
- [ ] Confirm the old standalone `Approve starting implementation now?` wording is gone.
