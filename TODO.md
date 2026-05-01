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

## Step 06 — Encode the Master Chef pass/remediation loop

### Goal

Make `cdd-master-chef` explicitly run the normal development loop as Builder completion -> Master Chef QA -> remediation when needed -> commit -> push -> session-native `STEP_PASS` advertising -> automatic continuation to the next runnable TODO step.

### Constraints

- Keep the Builder limited to one delegated TODO action per run.
- Treat the current Master Chef session as the comms channel.
- Do not add external route metadata or notification config to shared docs or runtime state.
- Master Chef may either push bad QA findings back to a fresh Builder run or fix the issue directly, but must re-run QA before passing the step.

### Tasks

- [x] Update `openclaw/SKILL.md` to state the full pass/remediation/autocontinue loop.
- [x] Update `openclaw/MASTER-CHEF-RUNBOOK.md` with the bad-QA remediation path and required evidence before `STEP_PASS`.
- [x] Update `openclaw/README.md` with the concise user-facing loop behavior.
- [x] Update `openclaw/MASTER-CHEF-TEST-HARNESS.md` with a QA-reject/remediation case.
- [x] Extend `scripts/validate_skills.py` to assert the pass/remediation/session-advertising/autocontinue contract.

### Implementation notes

- Preserve existing one-step Builder wording and fresh Builder continuation rules.
- Use `STEP_PASS` only after QA/UAT, commit, and push succeed.
- If Master Chef fixes a bad result directly, the fix remains inside the same step and must be included in QA evidence.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm the Master Chef docs say bad QA is remediated before a step can pass.
- Confirm passed steps are advertised in the current Master Chef session.
- Confirm the loop automatically re-inspects TODO and continues to the next runnable step.

## Step 07 — Encode blocked-step strategy and smaller-step restart

### Goal

Make `cdd-master-chef` stop the autonomous loop on a blocked step, revise the situation, decompose the blocked work into smaller TODO steps, clean stale runtime/build state when needed, and restart only from the next smaller actionable step.

### Constraints

- Do not burn cycles after a hard blocker or repeated failed Builder replacements.
- Preserve `STEP_BLOCKED` and `DEADLOCK_STOPPED` reporting in the current Master Chef session.
- Decomposition must update TODO planning before another autonomous implementation attempt starts.
- Cleanup must be scoped to stale runtime/build artifacts and must not revert unrelated user work.

### Tasks

- [x] Update `openclaw/SKILL.md` with the blocked-step revise/decompose/restart contract.
- [x] Update `openclaw/MASTER-CHEF-RUNBOOK.md` with a concrete blocked-step recovery procedure.
- [x] Update `openclaw/README.md` with the concise user-facing blocker behavior.
- [x] Update `openclaw/MASTER-CHEF-TEST-HARNESS.md` with blocked-step decomposition and restart expectations.
- [x] Extend `scripts/validate_skills.py` to assert the blocked-step strategy, TODO decomposition, cleanup, and smaller-step restart contract.

### Implementation notes

- Prefer plan repair in Master Chef before spawning any replacement Builder after a real blocker.
- If the step is too large or ambiguous, split it into smaller TODO steps instead of retrying the same broad step.
- Runtime cleanup should keep `.cdd-runtime/master-chef/` coherent and leave unrelated working-tree changes intact.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm a blocked step stops the autonomous loop instead of retrying indefinitely.
- Confirm Master Chef must revise/decompose the work into smaller TODO steps before restarting.
- Confirm cleanup language protects unrelated user work.

## Step 08 — Encode Master Chef context compaction checkpoints

### Goal

Make `cdd-master-chef` handle long autonomous runs by using durable Master Chef context checkpoints, so Builder can stay fresh per step while Master Chef can compact and resume without losing run intent, active state, blockers, or next action.

### Constraints

- Preserve fresh one-step Builder runs as the normal Builder context strategy.
- Keep Master Chef as the only control plane; do not introduce a second supervising loop.
- Do not rely on live transcript history as the only source of run memory.
- Compaction must happen only after writing durable state and only at safe workflow boundaries.
- Keep checkpoint content free of secrets, raw transcript dumps, and external route config.

### Tasks

- [x] Update `openclaw/SKILL.md` with the Master Chef context checkpoint and compaction boundary contract.
- [x] Update `openclaw/MASTER-CHEF-RUNBOOK.md` to add `.cdd-runtime/master-chef/context-summary.md`, its required fields, safe compaction triggers, unsafe compaction windows, and resume procedure.
- [x] Update `openclaw/README.md` with concise operator-facing context-limit behavior.
- [x] Update `openclaw/MASTER-CHEF-TEST-HARNESS.md` with a compaction/resume test case.
- [x] Extend `scripts/validate_skills.py` to assert the context checkpoint, safe-boundary compaction, and resume contract.

### Implementation notes

- Recommended checkpoint fields: run id, repo, branch/upstream, active TODO file/step, phase, last pass SHA, current Builder session key/status, pending QA/UAT/checks, blocker state, recent decisions, current diff summary, and next action.
- Safe compaction points: after kickoff state is written, after Builder handoff, after `STEP_PASS`, after `STEP_BLOCKED` / `DEADLOCK_STOPPED`, after Master-Chef-direct planning/refactor work, and before a known large QA or planning phase.
- Unsafe compaction points: before runtime state is written, during unrecorded QA decisions, between QA pass and commit/push unless a checkpoint is written first, or while blocker strategy is only in transcript.
- Resume should treat runtime files and repo state as canonical, then re-inspect the active TODO and git status before continuing.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm Builder context strategy remains fresh one-step sessions.
- Confirm Master Chef has a durable checkpoint file and explicit compaction triggers.
- Confirm resume after compaction starts from runtime files, TODO, and git state rather than transcript memory.

## Step 09 — Move the CDD README contract block into a bottom Footnote section

### Goal

Make `cdd-init-project` require the full CDD README block in a bottom `## Footnote` section instead of under the title and short description.

### Constraints

- Preserve `README.md` as the runbook entrypoint.
- The required block is the existing four-line CDD block: two badges plus the two quoted guidance lines.
- For fresh/bootstrap repos, the block must live in a bottom `## Footnote` section rather than at the top of the README.
- For existing-repo adoption, do not add or move the block unless the user explicitly confirms that README edit.
- Avoid duplicate insertion when the full block or its badges already exist.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` so the required README rule changes from a top-of-file header block to a bottom `## Footnote` section that contains the full four-line CDD block.
- [x] Update all README-drafting instructions in `cdd-init-project` flows so generated or adopted READMEs keep the runbook content primary and place the CDD block in the bottom Footnote section.
- [x] Keep the existing-repo adoption confirmation rule, but rewrite it so the confirmation applies to adding or moving the full CDD block into the Footnote section.
- [x] Extend `scripts/validate_skills.py` to assert the Footnote placement rule and reject the old under-title placement rule if it reappears.

### Implementation notes

- This step supersedes the older top-of-README contract recorded in Step 02; preserve that older step as TODO history rather than editing it away.
- Keep the exact four-line block content unless a failing validator proves another change is required.
- The placement rule should be explicit: bottom `## Footnote` section, not merely “somewhere in README”.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated init skill and confirm fresh/bootstrap README generation places the full CDD block in a bottom `## Footnote` section.
- Confirm existing-repo adoption still requires explicit approval before adding or moving that full block.
- Confirm the validator would fail if the skill switched back to top-of-README placement.

## Step 10 — Tighten `cdd-maintain` support-doc drift rules around current truth and doc roles

### Goal

Make `cdd-maintain` audit `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and connected `*-definition.md` files against a stricter no-drift contract: support docs must reflect current state or approved future state, with clear separation between product-facing and technical surfaces.

### Constraints

- `README.md` remains the runbook entrypoint and may include current features, use cases, and future plans.
- `README.md` must not include historical project narration or CDD/TODO step progression.
- `README.md` may be compacted when it is long and substantially duplicates content already maintained elsewhere, but that compaction stays user-approved.
- `docs/specs/prd.md` is the product-manager view and may include vision, use cases, JTBD, and feature lists.
- `docs/specs/blueprint.md` and connected `*-definition.md` files hold technical architecture, data structures, technical reasoning, and implementation detail.
- `cdd-maintain` must audit for drift against current codebase reality or clearly intended future-state docs, not against repo history.

### Tasks

- [x] Update `skills/cdd-maintain/SKILL.md` so support-doc drift review explicitly forbids history and CDD/TODO step progression in `README.md` while allowing current or future plans and concise runbook guidance.
- [x] Expand the support-doc scope in `cdd-maintain` to include connected `*-definition.md` files as technical documentation surfaces reviewed alongside `docs/specs/blueprint.md`.
- [x] Add explicit role rules to `cdd-maintain` for `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and `*-definition.md` files so product-facing versus technical content boundaries are enforced during drift review.
- [x] Extend `scripts/validate_skills.py` to assert the new `cdd-maintain` drift-language contract and the `*-definition.md` review scope.
- [x] Add a repo follow-on requirement that this repository's own `README.md` should be refreshed to match the new doc-role contract once the skill and validator changes land.

### Implementation notes

- Keep approval-gated doc edits intact; `cdd-maintain` should propose refreshes, not silently rewrite docs.
- "Current or future" should be expressed as current repo truth or clearly intended forward-looking documentation, not vague aspirational history.
- Treat `blueprint.md` as the anchor technical spec and `*-definition.md` files as connected detail surfaces rather than parallel PRDs.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated maintain skill and confirm `README.md` is audited as a current or future runbook surface with no history and no CDD/TODO step progression.
- Confirm `prd.md` is described as the PM/product view.
- Confirm `blueprint.md` plus connected `*-definition.md` files are described as technical architecture/detail surfaces.
- Confirm the validator would fail if `cdd-maintain` stopped reviewing connected `*-definition.md` files or allowed historical README drift language.

## Step 11 — Make planning skills decompose coarse steps first and track confirmed requirements

### Goal

Make `cdd-plan` and `cdd-audit-and-implement` handle qualifying planning requests by first breaking the work into coarse dependency-ordered steps, then refining one coarse step at a time into implementation-ready TODO steps, while visibly carrying confirmed user requirements into the resulting plan.

### Constraints

- Apply this planning mode only when the request is multi-surface, ambiguous, or likely to produce more than one TODO step.
- Preserve the existing approval-gated planning flow and one-question-at-a-time clarification contract.
- Final TODO steps must remain decision-complete and dependency ordered.
- Plans may be long and include many steps when the confirmed request warrants that scope; do not over-compress the plan just to stay minimal.
- Only requirements that make sense for the repo and that the user has confirmed should be carried forward as required plan coverage.
- `cdd-audit-and-implement` must keep its audit normalization rules and root-cause grouping behavior intact.

### Tasks

- [x] Update `skills/cdd-plan/SKILL.md` so qualifying planning runs must first produce a coarse-step decomposition, then refine one coarse step at a time into runnable TODO steps rather than jumping straight to a full mixed-surface detailed plan.
- [x] Update `skills/cdd-plan/SKILL.md` to require a visible confirmed-requirements coverage section or mapping that records which user requirements were confirmed, which were excluded by user decision or repo fit, and where each confirmed requirement is represented in the plan.
- [x] Update `skills/cdd-plan/SKILL.md` so the planner may produce long or many-step plans when confirmed scope requires it, while still keeping the steps dependency ordered and implementation ready.
- [x] Update `skills/cdd-audit-and-implement/SKILL.md` with the same qualifying coarse-step-first planning contract, adapted to audit normalization so coarse root-cause work packages are refined one by one into TODO steps.
- [x] Update `skills/cdd-audit-and-implement/SKILL.md` to require the same visible confirmed-requirements coverage behavior before the final TODO plan is proposed for approval.
- [x] Extend `scripts/validate_skills.py` to assert the new qualifying-request trigger, the coarse-step-first planning rule, the one-by-one refinement rule, the confirmed-requirements coverage rule, and the allowance for longer multi-step plans when warranted.

### Implementation notes

- Use the same qualifying-request trigger in both skills: multi-surface, ambiguous, or likely to produce more than one TODO step.
- The coarse-step pass should happen before detailed TODO drafting, not after.
- The confirmed-requirements coverage section can be lightweight, but it must be visible in planning output and must prevent confirmed requirements from being silently dropped.
- Keep KISS as a guardrail against invented structure, but do not let “minimal steps” language block legitimately broad plans.
- Touch `skills/cdd-plan/SKILL.md`, `skills/cdd-audit-and-implement/SKILL.md`, and `scripts/validate_skills.py` only unless a failing check proves another surface is needed.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated `cdd-plan` skill and confirm that qualifying requests begin with coarse dependency-ordered steps before detailed TODO drafting.
- Confirm the updated `cdd-plan` skill refines one coarse step at a time and visibly tracks confirmed user requirements.
- Read the updated `cdd-audit-and-implement` skill and confirm it follows the same pattern after audit normalization.
- Confirm the validator would fail if either skill skipped the coarse-step pass for qualifying requests or silently dropped confirmed requirements from the plan.
