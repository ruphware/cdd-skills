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

## Step 12 — Preserve reviewed planning artifacts in `TODO.md` and surface disposition before approval

### Goal

Make `cdd-plan` and `cdd-audit-and-implement` expand user-supplied contract/content artifacts during the coarse planning phase, preserve exact implementation-driving detail in `TODO.md`, and show a visible pre-approval `Reviewed contract artifacts` section that explains how each reviewed artifact was handled.

### Constraints

- Apply this rule inside the existing coarse-step/root-cause planning phase; do not invent a separate brainstorming section.
- Keep exact implementation-driving detail in `TODO.md` rather than leaving it only in surrounding chat or pushing it prematurely into PRD/Blueprint text.
- If a reviewed artifact affects both product behavior and implementation detail, keep the exact implementation-driving detail in `TODO.md` and add explicit `TODO.md` follow-up for the relevant spec/doc update unless the planner is intentionally drafting a durable spec delta now.
- This repository change is internal to the skill prompts, so the planning step itself does not require PRD or Blueprint edits.
- The new review output must appear before the approval question and must work in both `cdd-plan` and `cdd-audit-and-implement`.

### Tasks

- [x] Update `skills/cdd-plan/SKILL.md` so the coarse planning phase explicitly reviews user-provided contract details, content details, and other implementation-driving artifacts, expands them into the plan, and preserves exact implementation detail in `TODO.md`.
- [x] Update `skills/cdd-plan/SKILL.md` to require a visible `Reviewed contract artifacts` section before approval that identifies the user-provided artifacts, marks each as `copied as-is`, `corrected`, `expanded`, `removed`, or `left intentionally unspecified`, gives a short reason for each material change, and records where each artifact was written.
- [x] Update `skills/cdd-plan/SKILL.md` so mixed product/implementation artifacts produce exact implementation detail in `TODO.md` plus explicit `TODO.md` follow-up for later spec/doc updates unless a durable spec delta is intentionally being drafted now.
- [x] Update `skills/cdd-audit-and-implement/SKILL.md` with the same artifact-review, TODO-placement, mixed-surface follow-up, and pre-approval `Reviewed contract artifacts` rules, adapted to its audit-normalization flow.
- [x] Extend `scripts/validate_skills.py` to assert the new artifact-review rules, the `TODO.md` placement rule for exact implementation-driving detail, the mixed-surface spec/doc follow-up rule, and the required `Reviewed contract artifacts` section contents for both planning skills.

### Implementation notes

- Reuse the existing coarse-step/root-cause planning phase rather than introducing a new named planning section.
- Keep `Confirmed requirements coverage` and `Reviewed contract artifacts` distinct: one tracks confirmed user requirements, the other tracks how reviewed user-provided artifacts were handled.
- Prefer validator assertions that check the exact placement/handling rules and reject regressions where implementation-driving detail is left only in chat or silently shifted into durable specs.
- Touch `skills/cdd-plan/SKILL.md`, `skills/cdd-audit-and-implement/SKILL.md`, and `scripts/validate_skills.py` only unless a failing check proves another surface is required.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated `cdd-plan` skill and confirm that user-provided contract/content artifacts are reviewed during the coarse planning phase and that exact implementation-driving detail is preserved in `TODO.md`.
- Confirm the updated `cdd-plan` skill requires a visible `Reviewed contract artifacts` section before approval with artifact identity, disposition, reason for each material change, and write location.
- Read the updated `cdd-audit-and-implement` skill and confirm it applies the same rules after audit normalization.
- Confirm the validator would fail if either planning skill dropped the `Reviewed contract artifacts` section, stopped preserving exact implementation-driving detail in `TODO.md`, or omitted explicit `TODO.md` follow-up for mixed product/implementation artifacts that are not being drafted as durable spec deltas now.

## Step 13 — Teach `cdd-maintain` split-journal topology and repo-local skills

### Goal

Make `cdd-maintain` maintain both single-journal and split-journal CDD repos, and account for repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present.

### Constraints

- Preserve the existing approval-gated maintenance model for documentation updates and stale TODO deletion.
- Treat `docs/JOURNAL.md` as the stable journal entrypoint, not always the only hot journal.
- When split-journal mode is active, route maintenance through `docs/journal/JOURNAL.md`, matching `docs/journal/JOURNAL-<area>.md` files, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` as applicable.
- Treat `.agents/skills/*/SKILL.md` as optional repo-local workflow/governance surfaces only; do not expand this step to user-home skill directories.
- Keep validation local and deterministic.

### Tasks

- [x] Update `skills/cdd-maintain/SKILL.md` so its sources of truth and journal archive rules distinguish single-journal mode from split-journal mode, with `docs/JOURNAL.md` treated as the stable entrypoint and split-journal maintenance routed through `docs/journal/` when active.
- [x] Update `skills/cdd-maintain/SKILL.md` so split-journal review covers `docs/journal/JOURNAL.md` for cross-cutting notes, matching `docs/journal/JOURNAL-<area>.md` files for active `TODO-<area>.md` workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches when present.
- [x] Update `skills/cdd-maintain/SKILL.md` so maintenance reviews repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces, checks them against the current repo structure and documentation topology, and reports drift without silently rewriting them.
- [x] Update `skills/cdd-maintain/SKILL.md` so `TODO-next.md` stays backlog-only, does not require `JOURNAL-next.md`, and split-journal files are not precreated before split mode is active.
- [x] Extend `scripts/validate_skills.py` to assert the new split-journal and repo-local-skill rules for `cdd-maintain`, and refresh `skills/cdd-maintain/agents/openai.yaml` only if its default prompt would otherwise misdescribe the updated coverage.

### Implementation notes

- Touch `skills/cdd-maintain/SKILL.md` and `scripts/validate_skills.py` by default; touch `skills/cdd-maintain/agents/openai.yaml` only if the invocation hint materially drifts.
- Reuse the boilerplate split-journal vocabulary already introduced in `../cdd-boilerplate`: once any active `TODO-<area>.md` exists, split-journal mode is active and should remain active.
- Local skill coverage is repo-local only: `.agents/skills/*/SKILL.md`.
- Keep local-skill and support-doc edits approval-gated; `cdd-maintain` may propose updates but must not silently rewrite those files.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated maintain skill and confirm it distinguishes single-journal vs split-journal maintenance, with `docs/JOURNAL.md` treated as the stable entrypoint.
- Confirm split mode review covers `docs/journal/JOURNAL.md`, matching `docs/journal/JOURNAL-<area>.md`, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when present.
- Confirm repo-local `.agents/skills/*/SKILL.md` files are reviewed when present and are reported as drift surfaces rather than silently rewritten.
- Confirm `TODO-next.md` is treated as backlog only and does not require `JOURNAL-next.md`.
- Confirm the validator would fail if `cdd-maintain` reverted to single-journal-only wording or stopped accounting for repo-local skills.

## Step 14 — Align `cdd-boot` and `cdd-implement-todo` with split-journal routing

### Goal

Make the runtime skills read from and write to the correct journal surfaces once a repo has switched from single-journal mode to split-journal mode.

### Constraints

- `cdd-boot` stays read-only.
- `cdd-boot` must treat `docs/JOURNAL.md` as the stable journal entrypoint, not always the live journal.
- If split mode is indicated, `cdd-boot` should continue with matching `docs/journal/JOURNAL-<area>.md` and `docs/journal/SUMMARY.md` as needed.
- `cdd-implement-todo` must follow `AGENTS.md` journaling rules for the matching hot journal file, avoid duplicate entries, and treat `TODO-next.md` as backlog that does not require `JOURNAL-next.md`.
- Keep validator and `skills/cdd-boot/agents/openai.yaml` wording aligned.

### Tasks

- [x] Update `skills/cdd-boot/SKILL.md` so development-context ingestion starts from `docs/JOURNAL.md` as the stable entrypoint and follows split-journal pointers when present.
- [x] Update `skills/cdd-boot/SKILL.md` fallbacks and example prompt so they no longer describe root `docs/JOURNAL.md` as the always-live implementation journal.
- [x] Update `skills/cdd-boot/agents/openai.yaml` only where needed so its prompt metadata matches the new split-journal boot behavior.
- [x] Update `skills/cdd-implement-todo/SKILL.md` so non-trivial journaling writes go to the matching journal file under `AGENTS.md`, using `docs/journal/JOURNAL-<area>.md` for active `TODO-<area>.md` work, `docs/journal/JOURNAL.md` only for cross-cutting notes, and no duplicated entries.
- [x] Extend `scripts/validate_skills.py` to assert the new `cdd-boot` split-journal read path, the revised `cdd-implement-todo` journaling rule, and the refreshed `cdd-boot` prompt text.

### Implementation notes

- `cdd-boot` must still degrade gracefully when split-journal files are absent because small repos may still use root `docs/JOURNAL.md` as the live journal.
- Keep the change local to `skills/cdd-boot/*`, `skills/cdd-implement-todo/SKILL.md`, and `scripts/validate_skills.py` unless a failing check proves another surface is required.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm `cdd-boot` now reads root `docs/JOURNAL.md` as the journal entrypoint and follows split-journal files when indicated.
- Confirm `cdd-implement-todo` now routes non-trivial journal updates to the matching hot journal file rather than always `docs/JOURNAL.md`.
- Confirm the validator fails if either skill reverts to single-journal-only behavior.

## Step 15 — Teach `cdd-init-project` split-journal topology and repo-local skills

### Goal

Make `cdd-init-project` preserve and adopt the newer boilerplate contract for stable journal entrypoints, split-journal scaling, and repo-local project skills when present.

### Constraints

- Preserve existing approval gates for bootstrap copy, download, clone, repo-admin actions, and adoption edits.
- Keep `docs/JOURNAL.md` methodology-stable, but model it as the stable journal entrypoint once split mode is active.
- Support optional `docs/journal/JOURNAL.md`, `docs/journal/JOURNAL-<area>.md`, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` only when split mode is active.
- Treat `.agents/skills/*/SKILL.md` as repo-local project workflow surfaces only.
- Do not precreate split-journal files before active `TODO-<area>.md` work exists, and do not require `JOURNAL-next.md`.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` canonical contract and drift taxonomy so root `docs/JOURNAL.md` is the stable journal entrypoint and `docs/journal/*` is the optional scaled topology for split mode.
- [x] Update `skills/cdd-init-project/SKILL.md` fresh/bootstrap and existing-repo flows so they preserve the split-journal contract without precreating split-journal files.
- [x] Update `skills/cdd-init-project/SKILL.md` so repo-local `.agents/skills/*/SKILL.md` files are accounted for when present: preserve them during bootstrap or adoption, treat them as project-level workflow surfaces during repo review, and keep the scope repo-local rather than user-home.
- [x] Extend `scripts/validate_skills.py` to assert the new split-journal and repo-local-skill rules for `cdd-init-project`.

### Implementation notes

- Reuse the vocabulary already introduced in `../cdd-boilerplate` rather than inventing another split-journal model.
- Keep fresh-boilerplate detection compatible with repos that include a local governance skill, but do not require `.agents/skills/` in every adoption case.
- Touch `skills/cdd-init-project/SKILL.md` and `scripts/validate_skills.py` unless a failing check proves another surface must move with them.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm `cdd-init-project` now models root `docs/JOURNAL.md` as the stable entrypoint and describes split-journal files only for active split mode.
- Confirm it now accounts for repo-local `.agents/skills/*/SKILL.md` files when present.
- Confirm it does not require `JOURNAL-next.md` and does not precreate split-journal files in unsplit repos.
- Confirm the validator fails if `cdd-init-project` drops either the split-journal or repo-local-skill rule.

## Step 16 — Split `cdd-master-chef` into a shared orchestration contract with runtime adapters

### Goal

Make `cdd-master-chef` stop being OpenClaw-only by separating the shared Master Chef orchestration contract from runtime-specific adapter rules for OpenClaw, Codex, and Claude Code.

### Constraints

- Preserve the existing OpenClaw autonomous loop semantics: kickoff, one-step Builder runs, QA remediation, blocker handling, compaction, commit/push, and in-session lifecycle reporting.
- Do not describe any runtime as supporting subagent, approval, MCP, or worktree behavior that its current docs or current local CLI surface do not support.
- Keep shared orchestration rules distinct from runtime adapter rules so test coverage can fail on either layer independently.
- `README.md` must stop presenting Master Chef as an OpenClaw-only upgrade once the new contract lands.

### Tasks

- [x] Create a shared Master Chef source-of-truth surface that defines the runtime-agnostic contract: kickoff, routing, Builder lifecycle, QA/UAT gates, blocker handling, commit/push policy, lifecycle events, and durable runtime state.
- [x] Refactor the existing `openclaw/*` package so OpenClaw-specific files become an adapter layer over the shared contract instead of the only Master Chef contract.
- [x] Add a runtime capability matrix for OpenClaw, Codex, and Claude that records, at minimum, subagent model, nested-delegation limits, approval model, MCP/tool inheritance, child working-directory support, worktree-hand-off behavior, and startup-only versus in-session capabilities.
- [x] Update the repo `README.md` so Master Chef is described as a shared workflow with runtime adapters, while keeping any still-experimental status explicit.
- [x] Replace OpenClaw-only contract assertions with shared-contract and adapter-specific coverage that fails if the repo drifts back to OpenClaw-only wording.

### Implementation notes

- Prefer a new shared directory such as `master-chef/` or equivalent adapter-neutral surface rather than continuing to treat `openclaw/` as the canonical source.
- Keep the current OpenClaw files readable during the migration, but no longer canonical.
- Encode capability differences as first-class contract data, not as incidental prose hidden in one runtime README.
- Claude `2.1.126` now exposes `--agent`, `--agents`, `agents`, and `--worktree`; write those facts into the Claude adapter instead of relying on older assumptions.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- [x] Confirm the repo now has a shared Master Chef contract plus runtime adapters.
- [x] Confirm OpenClaw docs no longer act as the only source of truth.
- [x] Confirm `README.md` now describes Master Chef as multi-runtime rather than OpenClaw-only.
- [x] Confirm the validator fails if shared rules collapse back into OpenClaw-only wording.

## Step 17 — Add a clean-checkout-first managed worktree and branch lifecycle

### Goal

Make Master Chef provision work on a new branch in a new git worktree under a clean-checkout-first safety policy, with explicit runtime fallback rules when autonomous continuation from that worktree is not possible.

### Constraints

- Before kickoff, the source checkout must be clean; if it is dirty, Master Chef must stop and ask the human to stash, commit, or discard changes first.
- v1 must not promise dirty-state transfer into the managed worktree.
- The managed worktree must start from the current branch `HEAD` and create a fresh per-run branch rather than mutating the source checkout branch in place.
- The contract must respect Git’s one-branch-per-worktree rule and must not tell users to check out the same branch in multiple worktrees.
- Cleanup must not remove user branches, commits, or worktrees without explicit approval.

### Tasks

- [x] Define the managed worktree lifecycle: preflight cleanliness check, worktree path selection, branch naming, worktree creation, runtime-state initialization, active-worktree recording, and cleanup/archival behavior.
- [x] Define where Master Chef stores worktree metadata and the active worktree path in runtime state, including any additions needed in `run.json`, `run.lock.json`, and `context-summary.md`.
- [x] Define the runtime decision rule for “continue inside the worktree” versus “provision worktree and stop with exact relaunch instructions” when the adapter cannot safely keep Builder and Master Chef operating from the new worktree.
- [x] Update the shared runbook and runtime adapters so commit, push, QA, and TODO inspection are performed against the managed worktree once it becomes active.
- [x] Add executable test coverage for the clean-checkout-first rule, new-branch/new-worktree rule, and fallback behavior.

### Implementation notes

- Prefer a repo-local managed location such as `.cdd-runtime/master-chef/worktrees/<run-id>/` for adapters that control their own worktree path, unless an adapter is intentionally documented as using a runtime-managed external location instead.
- Record the source checkout path separately from the active worktree path so resume logic can reason about both.
- Claude’s current `--worktree` flag suggests a startup-time worktree path is viable there; do not treat that as proof of safe in-session worktree switching.
- If a runtime cannot safely re-root the active control loop into the new worktree, the contract should stop after provisioning and emit exact restart or handoff instructions instead of improvising shell-level path switching.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Confirm Master Chef refuses kickoff from a dirty source checkout.
- Confirm the contract now requires a fresh branch in a fresh worktree for the run.
- Confirm runtime state records the active worktree path.
- Confirm the docs state when Master Chef continues in the worktree versus when it stops and asks for a relaunch/handoff.

## Step 18 — Add Codex and Claude adapter contracts for Builder delegation

### Goal

Make `cdd-master-chef` support Codex and Claude Code subagent delegation using each runtime’s real subagent model, approval behavior, and context-management limits.

### Constraints

- Codex adapter rules must align with explicit subagent workflows and Codex agent configuration rather than assuming automatic delegation.
- Claude adapter rules must state that subagents cannot spawn subagents.
- Claude background subagent flows must not rely on MCP tools or interactive approval recovery.
- The shared Builder contract still requires one approved delegated action per Builder run, but the adapter may choose foreground-only delegation when background execution is unsafe.
- Do not require per-run model overrides in a way the target runtime cannot actually materialize during a normal skill invocation; any downgrade or startup-only mapping must be explicit.

### Tasks

- [x] Add a Codex adapter contract that defines how Master Chef uses Codex subagents for Builder, exploration, QA support, and read-heavy sidecar work, including when built-in agent roles are sufficient and when project-scoped `.codex/agents/*.toml` surfaces are required.
- [x] Add a Claude adapter contract that defines how Master Chef uses Claude subagents, including foreground-vs-background policy, non-nesting limits, permission-mode expectations, configured-agent surfaces, and when Builder work must remain foreground to keep approvals and tool access coherent.
- [x] For both adapters, define how the approved `Run config` maps onto real runtime capabilities: exact support, inherited-model fallback, startup-only application, or adapter-specific constrained behavior.
- [x] Add runtime-specific runbook and test-harness coverage for Codex and Claude, including explicit blocked paths for unsupported delegation patterns.
- [x] Update shared docs so OpenClaw remains one adapter among three rather than the implied default control plane.

### Implementation notes

- Codex supports explicit subagent workflows and project-scoped `.codex/agents/*.toml`.
- Claude `2.1.126` exposes `--agent`, `--agents`, `agents`, `--worktree`, `--tmux`, `--effort`, and `--permission-mode auto`; use those current facts in the adapter contract.
- Treat “Builder may continue automatically” as adapter-specific, not universal.
- If per-run Builder model selection cannot be made reliable in Codex or Claude v1, codify the limitation and keep the run config field visible as desired state rather than silently ignoring it.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- [x] Confirm the Codex adapter uses explicit subagent semantics and does not claim automatic spawning.
- [x] Confirm the Claude adapter states the non-nesting rule and background MCP limitation.
- [x] Confirm both adapters explain how `Run config` fields are honored or downgraded.
- [x] Confirm the validator fails if either adapter reintroduces unsupported runtime claims.

## Step 19 — Collapse Master Chef packaging into `install.sh` and retire `install-openclaw.sh`

### Goal

Make the normal installer own Master Chef packaging across runtimes so the repo no longer depends on a separate `install-openclaw.sh` path for Master Chef delivery.

### Constraints

- Preserve the current core `cdd-*` install behavior for Codex, Claude, and Gemini users.
- Keep runtime-specific adapter artifacts installable to the correct target roots without forcing a second installer.
- The packaging model must still allow any generated adapter-specific Builder variants that remain necessary after the shared-contract split.
- Do not leave README or smoke tests referring to `install-openclaw.sh` as the primary path once the unified installer lands.

### Tasks

- [x] Extend `scripts/install.sh` so it can install the shared Master Chef package and any runtime-specific adapter assets into the appropriate target roots, including `~/.agents/skills`, `~/.claude/skills`, and any retained OpenClaw target.
- [x] Remove `scripts/install-openclaw.sh` after `install.sh` reaches feature parity, or reduce it to a temporary shim that exits with migration guidance if immediate removal would be too disruptive.
- [x] Update `scripts/test_installers.sh` so installer smoke tests verify the unified Master Chef packaging path and no longer require a separate OpenClaw installer test matrix.
- [x] Rename or generalize any OpenClaw-only generator/build script that remains necessary so its purpose matches the new multi-runtime packaging model.
- [x] Update `README.md` install, update, and uninstall instructions so Master Chef is documented through the unified installer path.

### Implementation notes

- Touch `scripts/install.sh`, `scripts/test_installers.sh`, `README.md`, and any surviving adapter-generation script by default.
- If OpenClaw still needs a distinct target root, that should be expressed as an installer target or mode, not a completely separate installer entrypoint.
- Keep the final user story simple: one installer path, multiple targets.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_installers.sh`

### UAT

- [x] Confirm Codex/Claude install docs now include Master Chef.
- [x] Confirm installer smoke tests cover the new Master Chef packaging.
- [x] Confirm validator coverage extends beyond OpenClaw.
- [x] Confirm the repo no longer implies that Master Chef can only be installed through `install-openclaw.sh`.

## Step 20 — Replace weak literal-text validation with structural and executable contract tests

### Goal

Replace the current phrase-by-phrase `scripts/validate_skills.py` approach with stronger structural checks and executable smoke tests so Master Chef behavior is validated by artifacts, packaging, and runtime-facing fixtures rather than fragile wording matches.

### Constraints

- Do not delete useful coverage before an equal or stronger replacement exists.
- Keep any remaining Python validation focused on structural invariants such as frontmatter, required files, generated artifact shape, and schema-like checks.
- Behavioral contract coverage should move toward executable tests, fixture validation, installer smoke tests, and generated-surface assertions rather than raw substring matches.
- The new coverage must validate the shared contract, runtime adapters, installer outputs, and managed-worktree metadata expectations.

### Tasks

- [x] Audit `scripts/validate_skills.py` and classify each current assertion as structural, generated-artifact, or fragile prose match.
- [x] Remove or shrink the fragile prose-match layer after equivalent stronger coverage exists in shell tests, fixture-based tests, or narrower schema checks.
- [x] Add executable coverage for Master Chef packaging and contract artifacts, using `scripts/test_installers.sh`, `scripts/test-skill-audit.sh`, and any new focused smoke-test script needed for shared Master Chef surfaces.
- [x] Ensure the remaining validation checks generated adapter artifacts, required frontmatter, installer outputs, runtime-state field presence, and any deterministic capability-matrix surface instead of exact explanatory sentences.
- [x] Update `TODO.md` validation commands for the new test split if `python3 scripts/validate_skills.py` is no longer the primary contract gate.

### Implementation notes

- Prefer “prove the artifact exists and has the required machine-readable fields” over “prove this sentence exists verbatim.”
- A smaller `validate_skills.py` is acceptable if stronger shell or fixture tests replace the removed coverage.
- Keep local deterministic execution as a requirement; avoid network-dependent behavioral tests.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`
- `bash scripts/test-skill-audit.sh --skip-remote`

### UAT

- [x] Confirm fragile literal text assertions are no longer the primary contract gate.
- [x] Confirm remaining Python validation is structural rather than prose-driven.
- [x] Confirm executable tests cover installer outputs and shared Master Chef artifacts.
- [x] Confirm the documented validation flow still runs locally without network access.

## Step 21 — Normalize CDD skill taxonomy and Master Chef references

### Goal

Organize the visible CDD skill map as `[CDD-0]` through `[CDD-8]`, with `[CDD-8] Master Chef` documented as the separate autonomous development process.

### Constraints

- Do not rename skill directories, skill `name:` frontmatter, invocation commands, install roots, or generated Builder skill names.
- Preserve the core single-agent CDD workflow as `[CDD-0]` through `[CDD-7]`.
- Preserve Master Chef as separate from the core `skills/` pack: shared contract in `master-chef/`, current runnable adapter in `openclaw/`.
- Keep behavior unchanged; this step is taxonomy, docs, display metadata, and validator coverage only.

### Tasks

- [x] Update `README.md` so the primary skill map lists `[CDD-0] Boot` through `[CDD-8] Master Chef`, removes redundant Basic Commands / Golden path drift, and states when to use the core loop versus Master Chef.
- [x] Update `skills/*/agents/openai.yaml` display names to `[CDD-0]` through `[CDD-7]` and keep short descriptions aligned with the public skill map.
- [x] Update `master-chef/README.md` so it identifies Master Chef as `[CDD-8] Master Chef` and clarifies that it is a separate shared contract for autonomous development.
- [x] Update `openclaw/SKILL.md`, `openclaw/README.md`, `openclaw/MASTER-CHEF-RUNBOOK.md`, and `openclaw/MASTER-CHEF-TEST-HARNESS.md` so OpenClaw docs use the same `[CDD-8] Master Chef` label and show the internal `[CDD-0]` through `[CDD-7]` routing map where skill routing is explained.
- [x] Update `scripts/install.sh` so the generated documentation-only `cdd-master-chef` package introduces itself as `[CDD-8] Master Chef`.
- [x] Extend `scripts/validate_skills.py` to assert the numbered taxonomy in README, core skill display metadata, Master Chef docs, and OpenClaw routing/test harness coverage.

### Implementation notes

Use this exact public map:
`[CDD-0] Boot`, `[CDD-1] Init Project`, `[CDD-2] Plan`, `[CDD-3] Implement TODO`, `[CDD-4] Audit + Implement`, `[CDD-5] Refactor`, `[CDD-6] Index`, `[CDD-7] Maintain`, `[CDD-8] Master Chef`.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`

### UAT

- [x] Confirm `README.md` shows the full `[CDD-0]` through `[CDD-8]` map.
- [x] Confirm Master Chef is visibly separate and described as starting autonomous development.
- [x] Confirm OpenClaw routing docs and test harness use the same labels without changing behavior.

## Step 22 — Canonicalize `cdd-master-chef/` as the committed source package

### Goal

Make top-level `cdd-master-chef/` the only committed first-class Master Chef skill package visible to repo-root skill installers.

### Constraints

- Do not rename the `cdd-master-chef` skill or command.
- Avoid duplicate canonical shared-contract trees.
- Preserve shared docs for Codex, Claude Code, and OpenClaw adapters.
- Demote top-level `openclaw/` from package-scanned root surface so repo-root skill discovery no longer treats it as a peer installable skill.

### Tasks

- [x] Create a committed top-level `cdd-master-chef/` package surface with `SKILL.md`, `README.md`, shared contract docs, and current concrete adapter docs/artifacts now split across `master-chef/` and `openclaw/`.
- [x] Move or rewrite source-of-truth references so shared contract docs point to `cdd-master-chef/` as canonical and top-level `master-chef/` / `openclaw/` no longer act as parallel canonical package roots.
- [x] Re-home OpenClaw adapter files under the canonical package or another non-root-scanned adapter subtree and remove any top-level `SKILL.md` surface that would cause repo-root skill discovery to treat the old `openclaw/` path as a separate installable skill.
- [x] Update local scripts/tests that read from `MASTER_CHEF_SRC_ROOT` or `OPENCLAW_SRC_ROOT` to follow the new canonical package layout.

### Implementation notes

- Prefer one canonical committed package tree under `cdd-master-chef/`.
- If compatibility stubs remain in `master-chef/` or `openclaw/`, they must be explicitly non-canonical and non-package-scanned.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`

### UAT

- [ ] Confirm the repo has one committed first-class `cdd-master-chef/` package root.
- [ ] Confirm top-level `openclaw/` no longer behaves like a separate skill package root.

## Step 23 — Make repo-root installs and `install.sh` ship the first-class `cdd-master-chef`

### Goal

Make repo-root `npx skills add https://github.com/ruphware/cdd-skills/` and `scripts/install.sh` install all skills, including first-class `cdd-master-chef`, from the canonical package layout.

### Constraints

- Preserve existing core `[CDD-0]` through `[CDD-7]` installs.
- Keep OpenClaw-specific Builder generation only where the runtime actually needs it.
- Generic/Codex/Claude targets must not receive a docs-only surrogate if the canonical package can ship directly.

### Tasks

- [x] Update `scripts/install.sh` so generic/Codex/Claude installs package the committed canonical `cdd-master-chef/` skill rather than synthesizing a docs-only surrogate from `master-chef/`.
- [x] Update OpenClaw install assembly so `--runtime openclaw` installs the canonical `cdd-master-chef` skill plus any required OpenClaw-specific overlays/generated Builder skills from the new adapter subtree.
- [x] Update installer smoke tests and local install-audit scripts to assert the canonical package is installed for generic, Claude, and OpenClaw targets and that installed contents match the new root package layout.
- [x] Update `README.md` quick-install instructions so the root repo URL is the primary `npx skills add` entrypoint and no longer warns users away from it.

### Implementation notes

- Remove or minimize generated-package-only behavior in `emit_generic_master_chef_package`; prefer copying committed package source.
- Keep local proof deterministic; remote root-URL verification may remain UAT after push.

### Automated checks

- `bash scripts/test_installers.sh`
- `bash scripts/test-skill-audit.sh --skip-remote`
- `python3 scripts/validate_skills.py`

### UAT

- [ ] Confirm root install instructions point to `https://github.com/ruphware/cdd-skills/`.
- [ ] Confirm local smoke tests install the core skills plus `cdd-master-chef` from repo-root semantics.
- [ ] After push, confirm root `npx skills add` installs the expected skill set.

## Step 24 — Promote first-class multi-runtime Master Chef docs and status

### Goal

Make docs describe `cdd-master-chef` as a first-class in-development skill for Codex, Claude Code, OpenClaw, and other compatible adapter-based runtimes, without treating OpenClaw as the only target or calling the skill experimental.

### Constraints

- Only claim concrete runtime behavior already covered by current shared contract/adapters.
- Hermes and similar autonomous systems may be described only as potential adapter targets in this pass.
- README must distinguish current concrete adapters from future adapter targets.

### Tasks

- [x] Update root `README.md` and canonical `cdd-master-chef/README.md` / `SKILL.md` to describe Master Chef as first-class, in development, and multi-runtime rather than experimental, OpenClaw-only, or docs-only.
- [x] Replace wording that presents OpenClaw as the only runnable or packaged target with wording that presents OpenClaw as one current adapter and Codex/Claude as current subagent-backed targets.
- [x] Update the runtime capability matrix and adapter overviews so Codex/Claude/OpenClaw status lines match the shipped package and installer story.
- [x] Add explicit wording that other subagent-capable coding tools and autonomous systems can be supported through additional adapters, without claiming a shipped Hermes adapter.

### Implementation notes

- Touch `README.md`, canonical `cdd-master-chef/README.md`, `cdd-master-chef/SKILL.md`, `RUNTIME-CAPABILITIES.md`, and any adapter overviews that still say “only packaged target” or “experimental”.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`

### UAT

- [ ] Confirm README no longer says Master Chef is experimental.
- [ ] Confirm docs no longer treat OpenClaw as the only target.
- [ ] Confirm Codex, Claude, and OpenClaw are described as current concrete adapters.
- [ ] Confirm Hermes is not falsely claimed as a shipped adapter.

## Step 25 — Audit first-class runtime functionality and regression coverage

### Goal

Prove the first-class `cdd-master-chef` contract, packaging, and adapter claims hold across concrete runtime targets and fail when drift reintroduces docs-only or OpenClaw-only assumptions.

### Constraints

- Keep checks local and deterministic by default.
- Audit only concrete shipped targets in this pass: Codex, Claude Code, and OpenClaw.
- Do not depend on live external services as the primary gate.

### Tasks

- [ ] Extend `scripts/validate_skills.py` and/or focused smoke tests to assert canonical package-root presence, absence of conflicting top-level package surfaces, installer use of canonical package source, and non-experimental multi-runtime README claims.
- [ ] Expand `scripts/test_master_chef_artifacts.sh` and `scripts/test-skill-audit.sh` to verify canonical package contents, Codex/Claude adapter docs in the installed package, and OpenClaw adapter/install overlays from the new layout.
- [ ] Add narrow negative checks that fail if README drifts back to root-URL avoidance, docs-only generic Master Chef packaging, or OpenClaw-as-only-target wording.
- [ ] Update TODO validation commands or supporting test docs to reflect the new first-class package story.

### Implementation notes

- Prefer structural package-surface assertions over exact prose checks, except for critical user-facing claims like root install URL and status wording.
- If compatibility shims remain, tests must prove they are non-canonical.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`
- `bash scripts/test-skill-audit.sh --skip-remote`

### UAT

- [ ] Confirm drift tests fail when OpenClaw-only or docs-only wording returns.
- [ ] Confirm local audit shows installed `cdd-master-chef` contains shared contract plus current adapters.
- [ ] Confirm root install story and installer story match.
