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

- [x] Read the updated init skill and confirm it classifies methodology-stable vs repo-specific contract surfaces.
- [x] Confirm `AGENTS.md` methodology stays boilerplate-stable while limited repo-detail tailoring is still allowed.
- [x] Confirm `TODO.md`, `docs/JOURNAL.md`, and `docs/prompts/PROMPT-INDEX.md` are no longer described as repo-specific rewrites.

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

- [x] Run the validator and confirm it would fail if the skill text reintroduced repo-specific rewrites for `TODO.md`, `docs/JOURNAL.md`, or `docs/prompts/PROMPT-INDEX.md`.
- [x] Confirm the validator still permits repo-specific `README.md` / PRD / Blueprint generation and limited `AGENTS.md` repo-detail edits.

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

- [x] Read the updated audit skill and confirm the first-step selection prompt doubles as the implementation-start approval.
- [x] Confirm the skill still offers a clear stop-after-plan path without forcing implementation.
- [x] Confirm the old standalone `Approve starting implementation now?` wording is gone.

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

Make `cdd-master-chef` pause delegated implementation on a blocked step, revise the situation, decompose the blocked work into smaller TODO steps, clean stale runtime/build state when needed, and restart only from the next smaller actionable step.

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

- [x] Confirm the repo has one committed first-class `cdd-master-chef/` package root.
- [x] Confirm top-level `openclaw/` no longer behaves like a separate skill package root.

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

- [x] Confirm root install instructions point to `https://github.com/ruphware/cdd-skills/`.
- [x] Confirm local smoke tests install the core skills plus `cdd-master-chef` from repo-root semantics.
- [x] After push, confirm root `npx skills add` installs the expected skill set.

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

- [x] Confirm README no longer says Master Chef is experimental.
- [x] Confirm docs no longer treat OpenClaw as the only target.
- [x] Confirm Codex, Claude, and OpenClaw are described as current concrete adapters.
- [x] Confirm Hermes is not falsely claimed as a shipped adapter.

## Step 25 — Audit first-class runtime functionality and regression coverage

### Goal

Prove the first-class `cdd-master-chef` contract, packaging, and adapter claims hold across concrete runtime targets and fail when drift reintroduces docs-only or OpenClaw-only assumptions.

### Constraints

- Keep checks local and deterministic by default.
- Audit only concrete shipped targets in this pass: Codex, Claude Code, and OpenClaw.
- Do not depend on live external services as the primary gate.

### Tasks

- [x] Extend `scripts/validate_skills.py` and/or focused smoke tests to assert canonical package-root presence, absence of conflicting top-level package surfaces, installer use of canonical package source, and non-experimental multi-runtime README claims.
- [x] Expand `scripts/test_master_chef_artifacts.sh` and `scripts/test-skill-audit.sh` to verify canonical package contents, Codex/Claude adapter docs in the installed package, and OpenClaw adapter/install overlays from the new layout.
- [x] Add narrow negative checks that fail if README drifts back to root-URL avoidance, docs-only generic Master Chef packaging, or OpenClaw-as-only-target wording.
- [x] Update TODO validation commands or supporting test docs to reflect the new first-class package story.

### Implementation notes

- Prefer structural package-surface assertions over exact prose checks, except for critical user-facing claims like root install URL and status wording.
- If compatibility shims remain, tests must prove they are non-canonical.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`
- `bash scripts/test-skill-audit.sh --skip-remote`

### UAT

- [x] Confirm drift tests fail when OpenClaw-only or docs-only wording returns.
- [x] Confirm local audit shows installed `cdd-master-chef` contains shared contract plus current adapters.
- [x] Confirm root install story and installer story match.

## Step 26 — Retire `cdd-audit-and-implement` and fold audit planning into `cdd-plan`

### Goal

Make `cdd-plan` the single planning entrypoint for both change requests and audit findings, retire the standalone `cdd-audit-and-implement` skill, and keep `[CDD-5]` through `[CDD-8]` numbering stable by treating `[CDD-4]` as retired.

### Constraints

- Preserve `cdd-plan -> cdd-implement-todo` as the only normal planning-to-implementation handoff.
- Preserve audit normalization behavior: root-cause grouping, duplicate collapse, dependency order, and optional `TODO-audit-<tag>.md` placement.
- Remove the retired skill from shipped skill packs, installer expectations, and Master Chef routing docs.
- Do not renumber `[CDD-5]` through `[CDD-8]`.

### Tasks

- [x] Update `skills/cdd-plan/SKILL.md` and `skills/cdd-plan/agents/openai.yaml` so `cdd-plan` explicitly accepts audit findings, normalizes them into implementation-ready TODO steps, and still stops after suggesting `$cdd-implement-todo`.
- [x] Remove `skills/cdd-audit-and-implement/` from the canonical skill pack.
- [x] Update `README.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, and the OpenClaw adapter docs so audit findings route through `cdd-plan` and `[CDD-4]` is treated as retired rather than as a live excluded skill.
- [x] Extend `scripts/validate_skills.py` and `scripts/test_installers.sh` so local validation fails if the retired skill returns or installers ship it again.

### Implementation notes

- Keep the public story compact: no fake `[CDD-4]` command entry, just a short retirement note plus audit-via-plan routing.
- Let installer/remove behavior fall out of the canonical `skills/` source set unless a focused smoke test needs an explicit negative assertion.
- Historical references inside older completed TODO steps are expected and should not be rewritten.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`

### UAT

- [x] Confirm `cdd-plan` now covers both change requests and audit findings without directly implementing.
- [x] Confirm `skills/cdd-audit-and-implement/` is gone from the repo and no longer ships through installer smoke tests.
- [x] Confirm root README and Master Chef/OpenClaw docs treat `[CDD-4]` as retired and route audit findings through `cdd-plan`.

## Step 27 — Add `[CDD-4] Implementation Audit` as a first-class audit entrypoint

### Goal

Add a new audit-only core skill at `[CDD-4]` that audits a selected implementation scope, triages major findings with the user, and routes approved follow-up into `cdd-plan`.

### Constraints

- Keep `cdd-plan` able to normalize externally supplied audit findings.
- Keep `[CDD-4]` read-only and audit-only; it must not implement fixes directly.
- Cover spec compliance, code quality, test quality, accidental complexity, and documentation in one coherent audit contract.
- Restore `[CDD-4]` in the shipped skill pack, README taxonomy, validators, and installer smoke tests.

### Tasks

- [x] Add `skills/cdd-implementation-audit/` with a canonical skill body and OpenAI metadata.
- [x] Update `README.md` so `[CDD-4] Implementation Audit` is a live skill again and the normal audit flow becomes `[CDD-4]` then `[CDD-2] Plan`.
- [x] Extend `scripts/validate_skills.py` so the new skill has a display-name mapping, generated OpenClaw validation coverage, and topic validation in legacy-prose mode.
- [x] Update `scripts/test_installers.sh` and the OpenClaw package docs so the new skill is part of the shipped core pack and internal Builder map.

### Implementation notes

- Keep the heavy audit rubric in the new skill rather than re-bloating `cdd-plan`.
- Treat missing docs/specs/tests as findings when the chosen audit scope depends on them.
- In Master Chef/OpenClaw docs, treat `[CDD-4]` as an installed direct audit helper whose approved findings still flow into `cdd-plan` before delegated implementation.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_installers.sh`

### UAT

- [x] Confirm `[CDD-4] Implementation Audit` appears in the live root README skill map.
- [x] Confirm the new skill accepts implementation-scope audit inputs and ends by recommending `cdd-plan`.
- [x] Confirm installer smoke tests now ship `cdd-implementation-audit` across builder, Claude, and OpenClaw targets.

## Step 28 — Collapse `cdd-index` and `cdd-refactor` into `cdd-maintain`

### Goal

Make `cdd-maintain` the single upkeep skill for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, and local runtime cleanup review.

### Constraints

- Hard-remove standalone `cdd-index` and `cdd-refactor`.
- Renumber `cdd-maintain` to `[CDD-5]` and `cdd-master-chef` to `[CDD-6]`.
- Keep `[CDD-4] cdd-implementation-audit` as the scoped audit skill.
- Allow `codebase cleanup` to remove approved dead code or legacy artifacts directly, but keep `refactor` read-only and architecture-audit-only.

### Tasks

- [x] Update `skills/cdd-maintain/*` so the skill starts with `A. doc drift`, `B. codebase cleanup`, `C. index`, `D. refactor` when intent is unclear, supports multi-select and `do all`, and keeps the correct write scope for each mode.
- [x] Remove `skills/cdd-index/` and `skills/cdd-refactor/` from the canonical skill pack.
- [x] Update `README.md`, `skills/cdd-init-project/SKILL.md`, and `cdd-master-chef/*` so the public taxonomy, recommendations, and routing use `[CDD-5] Maintain` and `[CDD-6] Master Chef`.
- [x] Update `scripts/validate_skills.py`, `scripts/test_installers.sh`, and `scripts/test_master_chef_artifacts.sh` so validation fails if the retired standalone skills return or numbering drifts back.

### Implementation notes

- Keep `index` mode narrow: it may write only `docs/INDEX.md`.
- Keep `codebase cleanup` approval-gated and evidence-driven; remove only approved dead code, dead folders, duplicate retired paths, and legacy leftovers.
- Treat `Maintain` as the Master Chef direct maintenance helper when cleanup, index refresh, or refactor architecture audit is the real task.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_installers.sh`
- `bash scripts/test_master_chef_artifacts.sh`

### UAT

- [x] Confirm `cdd-maintain` asks the new A/B/C/D mode question when invoked without a clear task.
- [x] Confirm `cdd-index` and `cdd-refactor` are no longer shipped as standalone skills.
- [x] Confirm `[CDD-5] Maintain` covers doc drift, codebase cleanup, index refresh, and refactor architecture audit.
- [x] Confirm `[CDD-6] Master Chef` docs and tests no longer reference standalone `cdd-index` or `cdd-refactor`.

## Step 29 — Unify repo-local worktree root under `.cdd-runtime/worktrees/`

### Goal

Make `.cdd-runtime/worktrees/` the single repo-wide root for managed worktrees while keeping Master Chef runtime files and metadata under `.cdd-runtime/master-chef/`.

### Constraints

- Preserve clean-checkout-first kickoff, fresh per-run branches, Git's one-branch-per-worktree rule, and approval-gated cleanup.
- `active_worktree_path` must move to `.cdd-runtime/worktrees/<run-id>/`, but runtime files must still live under the active worktree's `.cdd-runtime/master-chef/`.
- Root `.gitignore` must ignore `.cdd-runtime/`, and init/adoption flows must preserve or add that rule safely.

### Tasks

- [x] Update the shared Master Chef contract and runbook surfaces in `cdd-master-chef/` so every managed worktree path changes from `.cdd-runtime/master-chef/worktrees/<run-id>/` to `.cdd-runtime/worktrees/<run-id>/`, while runtime-state field meanings and runtime-file locations stay under `.cdd-runtime/master-chef/`.
- [x] Update adapter-facing docs and harnesses that currently hardcode the old path, including the OpenClaw runbook and README, so relaunch instructions, examples, and JSON examples all use the new worktree root.
- [x] Update the executable and structural validation surfaces, including `scripts/test_master_chef_worktree.sh`, `scripts/test_master_chef_artifacts.sh`, and `scripts/validate_skills.py`, so validation fails if the old nested worktree root returns.
- [x] Update this repo's root `.gitignore` to ignore `.cdd-runtime/`, and update `skills/cdd-init-project/SKILL.md` so fresh/bootstrap and adoption flows treat `.cdd-runtime/` as a required local ignore surface for target repos.

### Implementation notes

- Keep the semantic split explicit: worktrees under `.cdd-runtime/worktrees/`, durable Master Chef metadata under `.cdd-runtime/master-chef/`.
- Remove the old `.cdd-runtime/master-chef/worktrees/` wording from docs, tests, and examples rather than supporting both paths.
- Do not widen this step into `cdd-boot` behavior; that stays in Step 30.

### Automated checks

- `python3 scripts/validate_skills.py`
- `bash scripts/test_master_chef_artifacts.sh`
- `bash scripts/test_master_chef_worktree.sh`

### UAT

- Confirm shared and adapter docs now point managed worktrees at `.cdd-runtime/worktrees/<run-id>/`.
- Confirm runtime metadata and runtime files still live under `.cdd-runtime/master-chef/`.
- Confirm root `.gitignore` includes `.cdd-runtime/`.
- Confirm worktree smoke coverage still rejects same-branch reuse and dirty-source preflight failures.

## Step 30 — Make `cdd-boot` use selector next actions and `$cdd-implement-todo` handoff

### Goal

Make `cdd-boot` emit selector-labeled next actions, recommend repo-local worktree paths under `.cdd-runtime/worktrees/`, and route clear runnable TODO follow-up through `$cdd-implement-todo` instead of direct implementation offers.

### Constraints

- `cdd-boot` remains read-only and must not create worktrees, switch directories, or start implementation.
- Repo-local `AGENTS.md` response-format guidance remains authoritative for `NEXT` or selector-style follow-up.
- Worktree recommendations must use the Step 29 path contract.

### Tasks

- [x] Update `skills/cdd-boot/SKILL.md` so any follow-up surface uses selector-labeled choices aligned to repo-local `AGENTS.md`; when no repo-local `NEXT` contract exists, fall back to a final `**Options**` section with 2-4 concrete choices and the recommended option first.
- [x] Update `skills/cdd-boot/SKILL.md` so worktree-migration recommendations use `.cdd-runtime/worktrees/<branch-or-tag>/` and explicitly distinguish "create or move into a worktree first" from "continue in the current worktree."
- [x] Update `skills/cdd-boot/SKILL.md` so when a clear next runnable TODO step exists, the recommended follow-up names `$cdd-implement-todo <step>` rather than offering to start the step directly; if the user first needs a worktree, the recommended option should chain that path with continuing via `$cdd-implement-todo`.
- [x] Update `skills/cdd-boot/agents/openai.yaml` and `scripts/validate_skills.py` so the boot metadata and regression coverage enforce the selector contract, the new worktree root, and the `$cdd-implement-todo` handoff rule.

### Implementation notes

- Keep selector choices as navigation or clarification only; do not turn boot into an approval-gated apply skill.
- Use the target branch or approved workstream tag as the default manual-worktree leaf name so boot recommendations are path-stable and predictable.
- Preserve the existing graceful-fallback and split-journal boot behavior.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Confirm boot reports now show selector-labeled next actions instead of plain bullets in repos whose `AGENTS.md` expects optioned follow-up.
- Confirm boot worktree recommendations now point at `.cdd-runtime/worktrees/<branch-or-tag>/`.
- Confirm a clear runnable TODO step now produces a `$cdd-implement-todo <step>` recommendation rather than "I can start it directly."
- Confirm validation fails if `cdd-boot` drifts back to the old worktree root or unlabeled/direct-implementation follow-up wording.

## Step 31 — Narrow `cdd-maintain` B to source cleanup and fold upkeep into A

### Goal

Make `cdd-maintain` treat `A` as doc drift plus repo upkeep, and treat `B` as a tracked source-code cleanup pass focused on dead code, dead branches, stale wiring, duplicate retired paths, and related removals.

### Constraints

- Keep the existing four-mode selector shape; do not add a separate upkeep mode.
- `A` must own support-doc drift, TODO archive review, stale adjacent TODO review, journal archive review, and repo-local runtime cleanup review.
- `B` must default to tracked source, tests, configs, manifests, and entrypoints; it may read `README.md`, `TODO*.md`, journal, repo-local skills, or `.cdd-runtime/` only when one of those surfaces is needed as proof for a specific cleanup candidate.
- Keep cleanup removals approval-gated and evidence-driven.
- Keep `C` as `docs/INDEX.md`-only and keep `D` read-only and audit-only.

### Tasks

- [x] Update `skills/cdd-maintain/SKILL.md` so the mode selector and mode headings make `A` the doc-drift-plus-upkeep lane and make `B` the source-cleanup lane, with user-facing wording that reduces the current ambiguity.
- [x] Rewrite `skills/cdd-maintain/SKILL.md` so TODO archive rules, stale adjacent `TODO*.md` handling, journal archive rules, and repo-local `.cdd-runtime/` cleanup review move under `A` instead of behaving like repo-wide default work for every maintain pass.
- [x] Rewrite `skills/cdd-maintain/SKILL.md` so `B` starts from repo-native dead-code or unused-code tooling when present, otherwise scans tracked source/tests/configs/manifests/entrypoints for dead modules, unreachable branches, duplicate retired paths, stale feature wiring, obsolete generated leftovers, and strong unused exports.
- [x] Update `skills/cdd-maintain/SKILL.md` so pure `B` reports are mode-scoped: they should report cleanup findings, proof, approval need, and validation only, rather than always emitting TODO/journal/runtime/support-doc status blocks.
- [x] Update `skills/cdd-maintain/agents/openai.yaml` and `README.md` so the public prompt and workflow wording match the new `A` and `B` boundaries.
- [x] Extend `scripts/validate_skills.py` so validation fails if `B` drifts back to broad upkeep review, if `A` stops owning upkeep surfaces, or if pure `B` output again requires runtime/archive/doc-status sections by default.

### Implementation notes

- Prefer clearer visible labels such as `A. doc drift + upkeep` and `B. source cleanup` without widening the skill taxonomy.
- Keep the mode-specific read scope near the top of the skill so the runtime does not front-load docs or `.cdd-runtime/` inspection before the selected mode requires it.
- Allow `B` to cite `README.md`, `TODO*.md`, or journal evidence only to prove whether a tracked-code candidate is truly dead or intentionally retained.
- Keep runtime cleanup approval separate inside `A` when stale `.cdd-runtime/` artifacts are found.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- [x] Invoke `cdd-maintain`, reply `B`, and confirm the investigation starts from tracked code/tests/configs/entrypoints rather than TODO, journal, or runtime surfaces.
- [x] Confirm a pure `B` report no longer includes TODO/journal/archive/runtime status sections unless one of those surfaces is needed as proof for a specific cleanup candidate.
- [x] Confirm `B` can still surface dead branches, unwired modules, duplicate retired paths, or obsolete generated leftovers with explicit proof and approval-gated removals.
- [x] Invoke `cdd-maintain`, reply `A`, and confirm doc drift plus TODO/journal/archive/runtime upkeep all live under that mode, including separate approval surfaces where required.

## Step 32 — Make Master Chef session model and thinking implicit, with Builder inherit-by-default

### Goal

Make `cdd-master-chef` derive `master_model` and `master_thinking` directly from the active session, make Builder inherit those settings by default, and remove the current four-field `Run config` complexity around master-session settings.

### Constraints

- The active session is the only source of truth for Master Chef model and thinking; do not ask the user to supply, approve, or default `master_model` or `master_thinking`.
- Builder must still support an explicit divergence path when an adapter can materially honor one, but the default Builder behavior must be to inherit the current session model and thinking.
- Keep kickoff approval selector-driven and focused on next action, effective Builder settings, run step budget, and whether to spawn Builder now.
- Preserve durable runtime transparency by recording effective `master_model`, `master_thinking`, `builder_model`, and `builder_thinking` in runtime state even though the user-facing config surface is simplified.
- Remove the old `exact support` / `inherited-model fallback` / `startup-only application` / `constrained behavior` taxonomy rather than renaming it.

### Tasks

- [x] Update `cdd-master-chef/SKILL.md`, `CONTRACT.md`, `RUNBOOK.md`, and `README.md` so the shared contract no longer requires a four-field `Run config`; instead, Master Chef reads the current session model and current session thinking directly, surfaces them as read-only kickoff facts, and treats Builder settings as inherited by default unless an explicit Builder override is provided.
- [x] Rewrite the shared kickoff contract so it no longer offers `A. use this Run config`, `B. edit this Run config`, or `C. stop before kickoff`, and no longer asks for `master_model` or `master_thinking`; the kickoff summary should show current session model, current session thinking, effective Builder settings, proposed next action, run step budget, and whether to spawn Builder now.
- [x] Update shared runtime-state semantics so `master_model`, `master_thinking`, `builder_model`, and `builder_thinking` remain in `run.json` as effective resolved run facts, with `master_*` mirrored from the active session and `builder_*` resolved from either explicit override or inherit-by-default behavior; add new fields only if the existing four fields cannot express whether Builder inherited or overrode.
- [x] Update `cdd-master-chef/CODEX-ADAPTER.md`, `CODEX-RUNBOOK.md`, `CLAUDE-ADAPTER.md`, and `CLAUDE-RUNBOOK.md` so Codex and Claude always treat active-session model and thinking as Master Chef truth, describe Builder as inheriting those settings by default, describe explicit Builder override paths only when the runtime can actually honor them, and remove the old four-way mapping taxonomy from both adapter and runbook text.
- [x] Update `cdd-master-chef/openclaw/README.md`, `MASTER-CHEF-RUNBOOK.md`, and `MASTER-CHEF-TEST-HARNESS.md` so OpenClaw no longer uses inline or local-default four-field `Run config` resolution; instead it reads current session model and thinking directly, mirrors them into runtime state, and accepts only an optional explicit Builder override when the user wants Builder to diverge from the active session.
- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `CLAUDE-TEST-HARNESS.md`, `RUNTIME-CAPABILITIES.md`, and `scripts/validate_skills.py` so validation and harness coverage enforce session-derived Master Chef settings, inherit-by-default Builder behavior, removal of the old Run-config approval flow, and removal of the old adapter classification taxonomy.

### Implementation notes

- Prefer a user-facing term like `Builder override` or `Builder settings` only when Builder is intentionally diverging from the active session; otherwise kickoff should simply report the detected current session model and current session thinking.
- Remove `~/.openclaw/config/master-chef/default-run-config.yaml` from the shared and OpenClaw contract rather than narrowing it, because keeping it would preserve the precedence logic this step is meant to eliminate.
- Keep kickoff terse: current session model, current session thinking, effective Builder settings, proposed next action, run step budget, spawn-now decision.
- If a runtime cannot cleanly materialize a requested Builder override, Master Chef must say so and fall back to inherited Builder settings instead of carrying forward taxonomy prose or pretending the override landed.
- Touch the shared package docs, all three current adapters, their harnesses, and the validator in one pass so the simplification is contract-complete.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- [x] Start `cdd-master-chef` in a Codex or Claude session with no inline config and confirm kickoff reports current session model and thinking automatically instead of asking for `master_model` or `master_thinking`.
- [x] Confirm kickoff no longer presents `use/edit Run config` options and no longer mentions `~/.openclaw/config/master-chef/default-run-config.yaml`.
- [x] Confirm default Builder behavior is reported as inheriting the current session settings when no explicit Builder override is supplied.
- [x] Confirm an explicit Builder override, when described, is framed as a deviation from the inherited default rather than through the old four-way mapping taxonomy.
- [x] Confirm `run.json` records the effective `master_*` and `builder_*` settings for the run.

## Step 33 — Make blocked-step decomposition clear the blocker and resume the same Master Chef run

### Goal

Make Master Chef treat a successful oversized or underspecified-step split as blocker repair that clears the blocker and continues the active run from the first new runnable step instead of stopping at that boundary.

### Constraints

- Preserve `STEP_BLOCKED` and `DEADLOCK_STOPPED` for unresolved blockers.
- Preserve fresh single-step Builder runs and no Builder session resurrection.
- Do not require a new human kickoff or reset the approved `run_step_budget` when the split succeeds without new human input.
- Do not increment `steps_completed_this_run` for planning-only split or repair work.
- Keep worktree, branch, QA/UAT, commit, and push semantics unchanged.

### Tasks

- [x] Update `cdd-master-chef/CONTRACT.md` and `cdd-master-chef/SKILL.md` so blocked-step recovery distinguishes unresolved blockers from successful repair; when Master Chef decomposes a blocked oversized or underspecified step into smaller decision-complete TODO steps and has a safe next step, it must emit `BLOCKER_CLEARED`, preserve the active run and remaining `run_step_budget`, re-inspect TODO state, and spawn a fresh Builder for the first new runnable step instead of stopping at the split boundary.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` and `cdd-master-chef/openclaw/README.md` so the operational path records the `STEP_BLOCKED` stop, the main-session repair and decomposition work, the `BLOCKER_CLEARED` transition, and same-run continuation from the next smaller actionable step with no second kickoff.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md` so blocked-step tests require both the initial blocker report and the post-repair automatic continuation path, including proof that Master Chef does not stop cleanly at the first decomposed step when continuation is still authorized.
- [x] Update shared reporting and runtime guidance that mentions `BLOCKER_CLEARED` so it records the original blocked step id, replacement step ids, preserved remaining budget, and the chosen next delegated action.

### Implementation notes

- Differentiate two boundaries explicitly: unresolved blocker means stopped run; resolved-by-split means the same run may continue after a durable checkpoint.
- A successful split is Master-Chef-direct repair, not a passed TODO step; do not emit `STEP_PASS` or consume step budget for it.
- If `run_step_budget` is numeric, preserve the remaining budget after subtracting only already passed implementation steps.
- Touch only the shared contract plus the canonical OpenClaw operational surfaces in this step; adapter propagation and validator expansion belong in the follow-on step.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Simulate a blocked oversized step, decompose it into `R05A+`, and confirm Master Chef reports `STEP_BLOCKED`, repairs TODO, emits `BLOCKER_CLEARED`, and automatically starts a fresh Builder for `R05A` without a new kickoff.
- Confirm the run stays stopped only when a hard technical or physical limitation still prevents safe autonomous continuation.
- Confirm `steps_completed_this_run` and numeric budget accounting do not change merely because the step was split.

## Step 34 — Propagate mission-owned autonomy to adapters and validation

### Goal

Make the shared Master Chef docs, adapter docs, harnesses, and validators enforce mission-owned autonomy so Codex, Claude, and OpenClaw no longer allow `split then stop`, routine blocker handoff to the human, or vague terminal reporting as compliant behavior.

### Constraints

- Keep adapter-specific capability claims truthful.
- Preserve selector-driven kickoff and one-step Builder delegation.
- Prefer structural or scenario-level validation over brittle transcript wording when possible.
- Keep true unresolved-blocker stop behavior available after the propagation lands.
- Terminal states should end with a final mission report covering completed work and decisions made.

### Tasks

- [x] Update `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/RUNBOOK.md`, `cdd-master-chef/README.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, and `cdd-master-chef/CLAUDE-RUNBOOK.md` so once kickoff is approved Master Chef clearly owns the mission under the approved run step budget, keeps continuation and blocker-resolution decisions in-session, restarts Builders as needed, and ends terminal states with a final mission report covering completed work and decisions made.
- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md` so blocked-step recovery proves autonomous in-session repair and continuation when safe, and terminal states require a final mission report.
- [x] Extend `scripts/validate_skills.py` to assert coverage for `BLOCKER_CLEARED`, preserved remaining `run_step_budget`, no budget increment for split or repair work, rejection of `stop cleanly at the first decomposed step` as valid successful-repair behavior, and final mission-report requirements.

### Implementation notes

- No runtime implementation files exist in this repo; this step is contract, adapter, harness, and validator propagation only.
- Keep adapter text focused on orchestration semantics, not unsupported runtime internals.
- Use the existing `BLOCKER_CLEARED` event label instead of inventing another recovery event.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the shared and adapter docs and confirm they no longer leave `successful split but stopped at R05A`, routine blocker handoff to the human, or vague terminal reporting as acceptable.
- Confirm the validator or harness would fail if stop-after-split drift or missing mission-report drift reappears.
- Confirm unresolved blockers still permit a hard-stop run only when a technical or physical limit prevents safe autonomous continuation.

## Step 35 — Encode Builder-run viability as the shared split decision for Master Chef

### Goal

Make Master Chef decide whether to delegate, repair, or split a TODO step based on one shared rule: whether one fresh Builder can plausibly complete the step safely in one run with acceptable failure risk.

### Constraints

- Do not treat the number of checklist tasks by itself as a reason to split.
- Preserve Step 33 and Step 34 behavior: successful repair still emits `BLOCKER_CLEARED` and continues the same run when safe.
- Keep the split policy qualitative and evidence-based; do not invent token, file-count, or elapsed-time thresholds that this repo cannot verify.
- Preserve single-step Builder runs and do not let Builder invent missing product, architecture, sequencing, or proof decisions.
- Keep preflight review and blocked-step review on the same core rubric.

### Tasks

- [x] Update `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so Master Chef uses one explicit Builder-run-viability rubric for `delegate unchanged`, `repair in place`, `split the remainder into child steps`, or `hard-stop`.
- [x] Define the delegation-ready test explicitly: a step is safe for one Builder run only when Master Chef can reasonably expect one fresh Builder to finish it end-to-end without reopening planning, without relying on large context recovery between attempts, and without an unusually high risk of stalling in repeated edit-validate-debug loops.
- [x] Define non-signals explicitly: many checklist tasks, many touched files, or broad-looking wording are not by themselves reasons to split.
- [x] Define supporting risk signals explicitly: expected need for several sequential debug or validation cycles, heavy cross-cutting coordination that is likely to force replanning mid-run, expensive hard-gate proof likely to create long recovery loops, or a remainder that would naturally separate into clearer executable chunks if the first attempt stalls.
- [x] Define the preflight decision path explicitly: if a minimal TODO repair makes the step viable for one Builder run without changing its true scope, Master Chef should repair in place; otherwise it should split before Builder handoff only when Master Chef already has strong evidence that one-run completion is too risky.
- [x] Define the blocked-step decision path explicitly: when a Builder attempt does not pass, Master Chef must review the returned evidence, current diff, failed checks, and remaining work using the same viability rubric before deciding whether the next Builder should continue the same step, receive an in-place repair, or resume on a new child step.

### Implementation notes

- Center the policy on execution risk, not superficial size.
- Reuse the repo's existing `decision-complete` standard as the minimum quality bar for any step Builder is asked to run, but keep split logic focused on one-run viability rather than checkbox count.
- Treat structural breadth as supporting evidence only when it materially increases one-run failure risk.
- Keep the wording explicit that Master Chef may continue the same step after partial progress when the remaining work is still one bounded Builder-sized action.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Simulate a step with many concrete tasks that still forms one coherent implementation pass and confirm Master Chef does not split it for task count alone.
- Simulate a step whose first-pass proof is likely to require several long debug or validation cycles and confirm Master Chef may split it before Builder handoff when one-run failure risk is already clear.
- Simulate a non-passing Builder attempt with meaningful progress and confirm Master Chef reviews the remaining work through the same viability rubric before choosing the next action.
- Confirm the reported reason for delegation, repair, or split is framed in terms of one-run viability and failure risk rather than generic size language.

## Step 36 — Encode the post-attempt continuation review and split-remainder contract

### Goal

Make Master Chef review every non-passing Builder result, decide whether the same step can continue safely, and when necessary split only the remaining work into lower-risk child steps with preserved proof and invariants.

### Constraints

- Preserve adapter-specific capability claims and keep runtime descriptions truthful.
- Do not force a split after every failed or partial Builder attempt; continuing the same step must remain valid when the remainder is still Builder-sized.
- Cleaning is optional and scoped: do it only when stale runtime or build artifacts materially increase retry risk or obscure the true remaining work.
- Child steps must preserve the parent step's intent, proof obligations, and must-preserve invariants.

### Tasks

- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, and `cdd-master-chef/CLAUDE-RUNBOOK.md` so every non-passing Builder attempt triggers an explicit Master Chef review with four possible outcomes: `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, or `hard_stop`.
- [x] Define the continuation review explicitly: Master Chef must inspect what was actually completed, what failed, whether the remaining work is still one bounded implementation action, whether a fresh Builder would spend most of its effort on recovery rather than completion, and whether the unfinished remainder now has cleaner sub-step boundaries than the original parent step.
- [x] Define `continue_same_step` explicitly: use it when progress is coherent, the step boundary still holds, and a fresh Builder can plausibly finish the remainder without reopening planning.
- [x] Define `repair_in_place` explicitly: use it when the step boundary still holds but the TODO step needs a tighter contract, sequencing note, or proof note before the next Builder run.
- [x] Define `split_remainder_into_child_steps` explicitly: use it when observed progress shows the unfinished portion is too risky to keep as one Builder run and can now be expressed as clearer executable child steps with explicit dependency order.
- [x] Define the split artifact contract explicitly: when Master Chef splits after partial progress, it must record what part of the parent step is already done, what exact remainder is being separated, why the first child is the next runnable step, what checks and UAT carry forward, and what invariants or compatibility duties remain attached to each child.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `scripts/validate_skills.py` so docs and validation fail if Master Chef either splits too eagerly without risk evidence or keeps retrying a same-step continuation after the remaining work has clearly become a lower-risk child-step sequence.

### Implementation notes

- The important distinction is not `failed once` versus `failed twice`; it is whether the remaining work is still one viable Builder-sized execution.
- `Builder can continue` means a fresh single-step Builder can resume the same parent step intentionally, not that an old Builder session is resurrected.
- Prefer terminology that reflects review outcomes directly: `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, and `hard_stop`.
- Keep `BLOCKER_CLEARED` aligned with the existing reporting contract rather than inventing a separate split event.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Simulate a partial but coherent Builder result and confirm Master Chef continues the same step with a fresh Builder instead of splitting automatically.
- Simulate repeated partial progress where most new Builder effort would be spent on context recovery and confirm Master Chef stops the parent step, optionally cleans stale artifacts, splits the remainder, and resumes on the first runnable child.
- Confirm the child-step split records completed portion, remaining portion, next-child justification, carried-forward checks, and preserved invariants.
- Confirm the validator or harness would fail if docs said `split because large` without tying that decision to Builder-run viability and observed retry risk.

## Step 37 — Make session-setting observability non-blocking for Master Chef startup

### Goal

Make missing session model or thinking visibility a non-blocking reporting gap so Master Chef proceeds with the active session as-is, records any unknown settings honestly, and never dies or stops kickoff just because `master_model` or `master_thinking` cannot be read exactly.

### Constraints

- Keep the existing `master_model`, `master_thinking`, `builder_model`, `builder_thinking`, and `builder_settings_source` runtime fields.
- Do not ask the human to supply, confirm, or type replacement `master_*` values.
- Treat the active session as the source of truth even when its exact model or thinking cannot be introspected.
- Preserve Builder inherit-by-default behavior and explicit `Builder override` behavior when the adapter can honor it cleanly.
- Preserve mission-owned autonomy: missing setting visibility must not hand ordinary continuation decisions back to the human or block kickoff by itself.
- Keep adapter claims truthful: if a runtime cannot expose exact values, say so explicitly instead of guessing.

### Tasks

- [x] Update `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so current session model and thinking are best-effort read-only Master Chef facts rather than mandatory startup prerequisites; when either value is not observable, Master Chef must record that field as `unknown`, proceed with the active session as-is, and keep kickoff moving.
- [x] Define the runtime-state rule explicitly: keep `master_model`, `master_thinking`, `builder_model`, `builder_thinking`, and `builder_settings_source`, and allow any unresolved setting field to be stored as `unknown` rather than stopping the run or inventing replacement values.
- [x] Define partial-known behavior explicitly: if one session field is observable and the other is not, preserve the known value and record only the missing value as `unknown`; if Builder inherits from an unknown parent field, the inherited Builder field is also `unknown` unless an explicit Builder override supplies a concrete replacement for that field.
- [x] Update `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, and `cdd-master-chef/RUNTIME-CAPABILITIES.md` so all adapters describe the same rule: observe session settings when available, report exact unknowns honestly when not, continue autonomously, and never treat this case as a normal kickoff stop.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `scripts/validate_skills.py` so verification requires `unknown-and-proceed` behavior, rejects `stop before kickoff` for missing session-setting visibility alone, and confirms Master Chef still reports the limitation honestly in kickoff and final mission reporting.
- [x] Require kickoff and final mission reporting to disclose any unresolved session-setting fields explicitly, including that Master Chef continued with the active session as-is and which effective Builder settings were concrete versus `unknown`.

### Implementation notes

- Do not infer `master_*` settings from repo docs, memory, previous `run.json`, or earlier runs.
- Keep `builder_settings_source` as `inherited` or `override`; it describes where Builder settings came from, not whether every inherited field was observable.
- Preferred kickoff wording is compact and honest, for example:
  - `current session model: unknown`
  - `current session thinking: unknown`
  - `effective Builder settings: inherited from active session`
  - `note: runtime does not expose exact session settings here; Master Chef will proceed with the active session as-is`
- If a Builder override is requested and only part of it can be honored, preserve concrete honored fields, report rejected fields explicitly, and keep unresolved inherited fields as `unknown` instead of blocking startup.
- Do not change blocker, split, Builder-restart, or run-budget semantics in this step beyond what is needed to remove the startup stop.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Start `cdd-master-chef` in a runtime path where exact session model and/or thinking are not exposed and confirm kickoff continues instead of stopping.
- Confirm kickoff does not ask the human to type replacement `master_model` or `master_thinking`.
- Confirm `run.json` records unresolved session-setting fields as `unknown` while preserving any concrete known values and any concrete Builder override values.
- Confirm adapter docs and harnesses no longer accept `stop before kickoff` for this case alone.
- Confirm the final mission report discloses any session-setting unknowns while still reporting completed work and decisions made.

## Step 38 — Make Master Chef provision a branch-backed, environment-ready active worktree before autonomous implementation

### Goal

Make Master Chef treat fresh-run branch setup and active-worktree environment bootstrap as part of the normal startup contract so autonomous implementation, tests, and QA run in a prepared managed worktree rather than a merely relocated checkout.

### Constraints

- Preserve the existing clean-checkout-first rule, fresh per-run worktree branch rule, and Git's one-branch-per-worktree constraint.
- Keep the descriptive source feature branch as the default recommendation on fresh runs from long-lived branches, but still allow the user to decline it explicitly.
- Do not hardcode repo-specific package-manager or language-tool commands into the shared contract; require repo-native environment setup discovery instead.
- Keep the managed worktree as the active repo root for Builder, tests, QA, commit, and push once the worktree becomes active.
- Hard-stop only when the worktree environment cannot be prepared autonomously because of a real technical or physical limitation.
- Preserve adapter-truthfulness: runtimes may differ on whether they continue in-session or require relaunch, but both paths must produce the same prepared active worktree contract.

### Tasks

- [x] Update `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so a fresh run from a long-lived branch defaults to recommending a descriptive source feature branch unless the user declines, still creates a separate fresh per-run worktree branch, and treats both branch setup and managed worktree creation as part of startup rather than optional side guidance.
- [x] Define the active-worktree environment bootstrap phase explicitly: after the managed worktree becomes the active repo root, Master Chef must inspect repo-native manifests, runbook commands, and validation entrypoints, prepare the worktree-local test and validation environment there, and only then treat Builder, hard-gate validation, and QA as ready to rely on that worktree.
- [x] Define the bootstrap evidence contract explicitly: runtime state and durable reporting must record the active worktree path, source branch, worktree branch, whether the default feature-branch recommendation was accepted or declined, what environment/bootstrap commands or checks were run in the active worktree, and whether the worktree is `env_ready`, partially ready, or blocked.
- [x] Update `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, and `cdd-master-chef/RUNTIME-CAPABILITIES.md` so every adapter describes the same startup flow: inspect source repo, recommend or create the source feature branch when appropriate, create the fresh per-run worktree branch, move execution to the active worktree through in-session continuation or relaunch, bootstrap the worktree environment there, and only then proceed into autonomous implementation.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `scripts/validate_skills.py` so verification requires branch-backed worktree setup plus explicit active-worktree environment bootstrap before tests or QA, and fails if docs reduce the worktree requirement to path creation alone.
- [x] Require kickoff and final mission reporting to disclose the active source branch, active worktree branch, active worktree path, whether the default branch recommendation was taken, and whether the worktree environment was prepared successfully before Builder or QA depended on it.

### Implementation notes

- Keep the existing semantic split: optional descriptive source feature branch for the source checkout, mandatory fresh per-run branch for the managed worktree.
- The shared contract should describe environment bootstrap qualitatively: discover and run the repo-native install, dependency, build, test, or validation preparation commands needed for this repo in the active worktree. Adapter docs may add runtime-specific execution details, but must not invent repo-specific commands at the shared layer.
- `env_ready` is a workflow fact, not a claim that every optional local tool is installed. It should mean the worktree is prepared enough for the approved Builder action and the repo's declared hard-gate validation path.
- If environment preparation reveals missing credentials, unavailable external services, or other hard technical or physical limits, report that explicitly as the stop reason rather than falling back to running validation from the source checkout.
- Keep Builder readiness separate from environment readiness: the worktree may be active before it is fully `env_ready`, and Builder should not be treated as ready to execute proof-heavy work until the worktree bootstrap phase is complete.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Start `cdd-master-chef` from a long-lived branch and confirm kickoff defaults to recommending a descriptive source feature branch, while still allowing that recommendation to be declined explicitly.
- Confirm the managed worktree is created on a fresh per-run branch regardless of whether the source feature-branch recommendation was accepted.
- Confirm the active worktree environment is bootstrapped there before Builder or hard-gate validation rely on it, and that the setup is described in durable run evidence.
- Confirm docs and harnesses fail if the flow creates a worktree and branch but skips explicit worktree-local environment preparation before tests or QA.
- Confirm a hard-stop report names the exact technical or physical limitation when the active worktree environment cannot be prepared autonomously.

## Step 39 — Make Master Chef treat step splitting as a costed last resort

### Goal

Make Master Chef prefer keeping a step intact, repairing it in place, or continuing the same parent step with a fresh Builder, and only split when concrete evidence shows that splitting the remainder will reduce total delivery cost despite the extra Builder boot, hard-gate reruns, and mission delay it introduces.

### Constraints

- Preserve single-step Builder runs, fresh Builder replacement, and same-run `BLOCKER_CLEARED` continuation.
- Do not treat raw task count, file count, broad wording, or speculative “this may take a while” intuition as split reasons.
- Treat every split as expensive because it introduces new delegated boundaries, new proof loops, and usually new test or QA runs.
- Keep pre-delegation split available only when the parent step is not safely delegable as one coherent Builder action or is missing critical decision-complete detail that cannot be repaired in place.
- Keep post-attempt split available only when observed evidence shows the parent step boundary is now actively costing more than preserving it.
- Do not hand ordinary split decisions back to the human; Master Chef still owns them in-session.

### Tasks

- [x] Update `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so the shared split policy explicitly prefers this order: `delegate unchanged`, `repair in place`, `continue_same_step`, then `split_remainder_into_child_steps` only as the last normal option before `hard_stop`.
- [x] Define split cost explicitly in the shared contract: a split adds Builder restart overhead, extra hard-gate and QA cycles, extra mission time, and extra proof boundaries, so Master Chef must treat splitting as more expensive than preserving the current step unless evidence shows the split will reduce total retry cost.
- [x] Tighten pre-delegation split rules explicitly: Master Chef should not split a top-level step before first Builder handoff merely because it looks large, spans many tasks, or is likely to need several validation cycles; it should split before delegation only when the parent step is not decision-complete for one coherent Builder action and cannot be made so with a minimal in-place repair.
- [x] Tighten post-attempt split rules explicitly: after a non-passing Builder attempt, Master Chef should prefer `continue_same_step` when progress is real and the remaining work still forms one bounded proof boundary, and should prefer `repair_in_place` when the step only needs tighter sequencing or proof notes; split the remainder only when concrete evidence shows continued same-step retries would cost more total proof churn than introducing child steps.
- [x] Define required split evidence explicitly: repeated low-forward-progress retries on the same parent boundary, recovery effort dominating completion effort, a remainder that now has materially cleaner proof boundaries than the parent step, or proof that continuing unchanged would trigger more total hard-gate reruns than splitting the remainder.
- [x] Update `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, and `cdd-master-chef/CLAUDE-RUNBOOK.md` so startup and continuation text no longer normalize “split oversized one first”; instead they should describe split as rare, cost-aware, and evidence-driven.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `scripts/validate_skills.py` so verification fails if docs allow speculative preflight splitting, first-failure auto-splitting, or split rationale that ignores added test and QA cost.

### Implementation notes

- A long or proof-heavy step is not the same thing as a splittable step. If the work still forms one coherent proof boundary, Master Chef should usually keep it intact.
- Repeated validation cycles are not automatic split evidence. They matter only when they show that preserving the parent step is producing more total churn than a remainder split would.
- `Oversized` should stop being shorthand for `split now`. It should mean `review carefully for one-run viability and split cost`.
- Same-step continuation preserves existing context, existing parent proof, and usually avoids inventing extra hard-gate checkpoints. The contract should model that as the preferred path when still plausible.
- When a split does happen, Master Chef should report why the split cost was justified, not just why the parent looked hard.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Simulate a broad but coherent step with expensive full validation and confirm Master Chef prefers `delegate unchanged`, `repair in place`, or `continue_same_step` rather than splitting preflight.
- Simulate one non-passing Builder attempt with meaningful progress and confirm Master Chef does not split automatically after the first miss.
- Simulate repeated low-forward-progress retries where the remainder now has cleaner proof boundaries and confirm Master Chef splits only then.
- Confirm adapter docs and harnesses fail if split is justified only by generic size language or generic expectation of `many test runs`.
- Confirm split reporting names why the split cost was justified compared with continuing the parent step.

## Step 40 — Compact the Master Chef contract and realign CI proof surfaces

### Goal

Make the Master Chef startup, worktree, and split policy shorter, more canonical, and less drift-prone, then align the artifact script, harnesses, and validator to that compact contract so CI proves the refined behavior instead of obsolete split-first and stop-before-kickoff wording.

### Constraints

- Preserve the current Step 37-39 semantics: unresolved session-setting fields remain `unknown` and non-blocking, active worktrees must be branch-backed and `env_ready` before Builder or `hard_gate` depend on them, and split stays a costed last resort.
- Keep the shared contract normative, the shared runbook procedural, the READMEs user-facing, and adapter docs focused on runtime-specific deltas rather than restating the full shared contract.
- Fix the failing `scripts/test_master_chef_artifacts.sh` checks without reintroducing the old split-first or visible-before-kickoff policy.
- Prefer behavior-oriented proof in CI over brittle literal prose matches, while still keeping a small set of canonical phrases stable where they materially help maintainers.
- Keep adapter capability claims truthful and do not overstate live reasoning visibility, session-setting introspection, or worktree continuation capabilities.

### Tasks

- [x] Update [README.md](/Users/ruph/Workspace/cdd-skills/README.md), `cdd-master-chef/README.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/SKILL.md` so the shared package exposes one compact canonical policy flow:
  - startup observes session settings when available and records unresolved fields as `unknown` while continuing with the active session as-is
  - fresh runs from long-lived branches default to a descriptive source feature-branch recommendation, then still create a fresh per-run worktree branch and bootstrap the active worktree to `env_ready` before Builder or `hard_gate`
  - oversized-looking steps are reviewed first, preserved when still viable, repaired in place when possible, and split only when split cost is justified
- [x] Update `cdd-master-chef/RUNTIME-CAPABILITIES.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, `cdd-master-chef/openclaw/README.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` so adapter docs reference the shared policy compactly and only restate runtime-specific deltas:
  - how that runtime reports unknown session fields
  - how it continues or relaunches into the managed worktree
  - what direct Builder readiness and monitoring evidence it can actually provide
- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md` so prompts and expected outcomes verify the refined behavior instead of the old literals:
  - reject `stop before kickoff` for missing session-setting visibility alone
  - reject `split before Builder handoff` as the default oversized-step behavior
  - require branch-backed `env_ready` worktree bootstrap before Builder or `hard_gate`
  - require split decisions to be justified by preserved-versus-split cost, not generic size language
- [x] Update [scripts/test_master_chef_artifacts.sh](/Users/ruph/Workspace/cdd-skills/scripts/test_master_chef_artifacts.sh) so artifact assertions match the refined contract and no longer require obsolete phrases such as:
  - `visible enough to mirror into runtime state before kickoff`
  - `split it first`
  - `oversized top-level step is split in Master Chef before Builder handoff`
  - `oversized for one Builder run.*split.*smaller decision-complete TODO steps` as an unconditional preflight rule
- [x] Update [scripts/validate_skills.py](/Users/ruph/Workspace/cdd-skills/scripts/validate_skills.py) so its regex and substring checks use the same compact canonical topics as the artifact script, and fail when docs drift back to split-first or stop-before-kickoff semantics.
- [x] Ensure the root install story and package docs remain concise and user-facing while still truthfully covering kickoff approval, default/max step budget guidance, managed worktree bootstrap expectations, and final mission reporting.

### Implementation notes

- Keep `cdd-master-chef/CONTRACT.md` as the normative wording source for the three key policies:
  - unknown session settings do not block kickoff
  - managed worktree readiness requires branch setup plus worktree-local bootstrap
  - split is rare and justified only when preserving the parent step costs more
- Keep `cdd-master-chef/RUNBOOK.md` procedural and shorter than the current restated contract blocks; it should explain sequence and runtime-state handling, not re-argue policy.
- Keep root and package READMEs brief and operator-facing. They should describe the flow cleanly without carrying the whole contract text.
- Adapter docs should state only runtime-specific behavior that differs in surface shape, not duplicate all shared policy prose.
- In proof surfaces, prefer compact topic bundles keyed to concepts such as `unknown`, `active session as-is`, `do not split by default`, `split cost`, `env_ready`, and `final mission report` instead of older sentence-shaped literals.
- If a small canonical phrase is worth preserving for grepability, use the same phrase family across shared docs and proof surfaces intentionally rather than letting each file drift independently.
- Do not roll back any Step 37-39 behavior to satisfy old CI wording.

### Automated checks

- `bash scripts/test_master_chef_artifacts.sh`
- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Run `bash scripts/test_master_chef_artifacts.sh` and confirm it passes without expecting split-first or visible-before-kickoff semantics.
- Read [README.md](/Users/ruph/Workspace/cdd-skills/README.md), `cdd-master-chef/CONTRACT.md`, and `cdd-master-chef/RUNBOOK.md` and confirm the startup/worktree/split flow is shorter, more canonical, and no longer duplicated unnecessarily.
- Read one adapter path such as `cdd-master-chef/openclaw/README.md` plus its runbook and confirm they now focus on OpenClaw-specific behavior rather than restating the full shared contract.
- Confirm the harnesses and validator would fail if docs regress to:
  - `stop before kickoff` for unknown session settings
  - `split oversized step first` as the default rule
  - worktree path creation without explicit `env_ready` bootstrap before Builder or `hard_gate`
- Confirm the root install story still truthfully describes kickoff approval, step budget guidance, and Master Chef mission ownership without reintroducing obsolete split wording.

## Step 41 — Replace the legacy fresh-Builder lifecycle with a persistent Builder contract

### Goal

Make Master Chef keep one long-lived Builder alive across normal delegated step transitions in the same autonomous run, removing the legacy fresh-per-step Builder rule while preserving explicit replacement on real Builder failure or unusable drift.

### Constraints

- Preserve Master Chef as the single controlling loop and keep Builder replacement available for hard failure, explicit runtime closure, deadlock, or unusable drift.
- Preserve durable run state, Builder evidence, QA/UAT, commit/push, and final mission reporting.
- Do not introduce a shared numeric context-pressure threshold unless the runtime can actually surface it truthfully.
- Shared policy must distinguish normal step transition from failure recovery.
- Preserve adapter-truthfulness: the shared contract may require a compaction attempt when supported, but must not pretend every runtime exposes the same compaction command or context meter.

### Tasks

- [x] Update `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so the normal Builder lifecycle changes from `fresh single-step Builder run per delegated action` to `persistent Builder per active run`, with explicit language that the same Builder normally continues across multiple delegated steps.
- [x] Replace the legacy rule that Master Chef always spawns a fresh Builder after every `STEP_PASS`, same-step continuation, or repaired-step continuation with a new shared rule: Master Chef first attempts to reuse the active Builder for the next delegated step in the same run, and replaces Builder only on defined recovery conditions such as hard failure, explicit runtime closure, deadlock, unusable drift, or inability to continue safely in the active worktree.
- [x] Define beginning-of-step compaction explicitly in the shared contract: before handing a new delegated step to the persistent Builder, Master Chef must attempt a Builder compaction operation when the active runtime exposes a supported compaction command or API; if the runtime does not expose one, Master Chef must continue with the same Builder and rely on native auto-compaction or the runtime's own context management instead of inventing a fake compaction path.
- [x] Define shared replacement conditions explicitly: Builder replacement is no longer the normal step-transition path and is valid only after explicit failure evidence, explicit runtime closure, deadlock, unusable drift, or an adapter-defined inability to continue coherently after compaction or status checks.
- [x] Define runtime-state additions or changes needed for persistent Builder continuity, including the active Builder identity across steps, latest step-boundary compaction attempt/result, and Builder replacement lineage when replacement does occur.

### Implementation notes

- The shared contract should stop using phrases like `single-step Builder runs only`, `fresh Builder for the next delegated action`, and `do not compact or resume Builders as the normal path`.
- The new shared policy should remain qualitative on context pressure; it should require `attempt compaction when the runtime supports it` rather than a fabricated universal occupancy threshold.
- Preserve the difference between `same Builder continues to the next step` and `Master Chef compacts its own long-lived context`; both may happen, but they are separate control-loop behaviors.
- Do not weaken the QA, blocker, deadlock, or final mission reporting contract while changing Builder lifespan.
- If Builder replacement occurs, durable reporting should still show why the persistent Builder contract was suspended for that branch of execution.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the shared contract and confirm a passed step no longer implies automatic Builder replacement.
- Confirm a normal next-step handoff attempts same-Builder continuation first.
- Confirm Builder replacement is now described as recovery behavior, not the default lifecycle.
- Confirm beginning-of-step compaction is required only when the runtime actually supports it.

## Step 42 — Propagate persistent Builder and compaction capability rules across adapters and runtime matrix

### Goal

Make Codex, Claude, OpenClaw, and the runtime capability matrix describe persistent Builder continuation, manual compaction support, auto-compaction fallback, and context-visibility limits truthfully and consistently.

### Constraints

- Preserve runtime-specific truth: do not claim a compaction command, context-left meter, or parent-visible subagent token budget where the runtime docs do not actually provide one.
- Keep the shared contract canonical and use adapter docs only for runtime-specific deltas.
- Preserve the managed-worktree, Builder readiness, and monitoring rules already in place unless they need to change directly for persistent Builder continuation.

### Tasks

- [x] Update `cdd-master-chef/RUNTIME-CAPABILITIES.md` so the matrix and notes explicitly cover:
  - whether persistent Builder continuation across delegated steps is supported
  - whether manual compaction is supported
  - whether only auto-compaction is available
  - whether the controller can observe real context-budget or context-left evidence
- [x] Update `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md` so the Codex path describes persistent Builder reuse truthfully, defines whether a manual compaction path is actually available in supported Codex surfaces, and states whether visible context-left or token-budget evidence is reliable enough to drive Master Chef decisions.
- [x] Update `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md` so the Claude path describes persistent Builder reuse, manual `/compact` support when appropriate, auto-compaction fallback, and the limits of parent-visible subagent context information.
- [x] Update `cdd-master-chef/openclaw/README.md` and `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` so the packaged runtime path describes whether persistent Builder continuation is supported there, whether Builder compaction is manually available, and what fallback behavior applies if only auto-compaction or no explicit compaction surface exists.
- [x] Ensure all adapter docs distinguish:
  - step-start compaction attempt
  - normal same-Builder continuation
  - replacement-only-on-failure conditions
  - context-awareness or context-meter limits visible to Master Chef

### Implementation notes

- Claude currently has the strongest official documentation for long-lived sessions plus auto/manual compaction; Codex may need more careful, narrower wording.
- If a runtime supports compaction but not a parent-visible fullness meter, document that clearly and keep the shared contract qualitative.
- If an adapter cannot safely support persistent Builder continuation after worktree transition or compaction, that limitation must be stated explicitly rather than hidden behind shared prose.
- The runtime matrix is the right place to state `manual compaction`, `auto-compaction`, and `context-budget visibility` as separate capabilities.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read each adapter path and confirm it no longer claims fresh-per-step Builder replacement as the normal path.
- Confirm Claude, Codex, and OpenClaw docs each state whether manual compaction, auto-compaction, and context-budget visibility are actually available.

## Step 43 — Realign harnesses, artifact checks, and validator rules to the persistent Builder contract

### Goal

Make the harnesses, artifact script, and structural validator enforce persistent Builder continuation plus step-boundary compaction semantics instead of the legacy fresh-Builder lifecycle.

### Constraints

- Preserve proof strength while removing obsolete fresh-Builder assertions.
- Prefer concept-level checks over brittle sentence-shaped literals when possible.
- Keep CI aligned with the new shared contract and adapter-specific truth.
- Do not require proof surfaces to assert unsupported runtime capabilities such as exact subagent context percentages when the adapter cannot actually expose them.

### Tasks

- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md` so they test persistent Builder continuation across steps, beginning-of-step compaction attempts when supported, and replacement only under defined failure or drift conditions.
- [x] Update `scripts/test_master_chef_artifacts.sh` so artifact checks no longer require phrases or topics that imply `fresh single-step Builder runs only`, `next delegated step gets a fresh Builder`, or `Builder compaction is not a normal path`, and instead verify the new persistent-Builder lifecycle plus adapter-specific compaction capability language.
- [x] Update `scripts/validate_skills.py` so structural checks fail if docs regress to legacy fresh-per-step Builder semantics, fail if they invent unsupported universal context metrics, and pass only when they encode persistent Builder continuation, step-boundary compaction attempts when supported, and replacement-only-on-failure behavior.
- [x] Add validator and harness coverage that distinguishes:
  - normal next-step continuation on the same Builder
  - beginning-of-step compaction when supported
  - auto-compaction fallback when manual compaction is unavailable
  - replacement after explicit failure, deadlock, unusable drift, or runtime closure

### Implementation notes

- Remove or rewrite all assertions built on the old phrases:
  - `Use single-step Builder runs only`
  - `fresh Builder for the next delegated action`
  - `do not compact or resume Builders as the normal path`
- Keep proof surfaces focused on behavior and capability boundaries rather than forcing one exact phrasing.
- Preserve existing coverage for Builder readiness, worktree continuation, blocker repair, and mission reporting unless it directly conflicts with the new Builder lifecycle.
- If a runtime lacks a controller-visible context metric, tests should verify truthful fallback wording rather than a fake measurement rule.

### Automated checks

- `bash scripts/test_master_chef_artifacts.sh`
- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Run the artifact script and confirm it no longer expects fresh-per-step Builder behavior.
- Confirm the validator fails if docs regress to legacy fresh-Builder lifecycle wording.
- Confirm the harnesses require same-Builder continuation across normal step transitions and only allow replacement under defined recovery conditions.
- Confirm no proof surface forces a universal numeric context threshold without adapter support.

## Step 44 — Remove persistent-Builder contract drift from OpenClaw and root README, then harden proof coverage

### Goal

Make the OpenClaw remediation flow, the root Master Chef entrypoint docs, and the CI proof surfaces all agree on the current persistent-Builder contract: reuse the active Builder first when it remains usable, replace Builder only for recovery conditions, and describe split and kickoff behavior with the current compact policy rather than legacy fresh-Builder wording.

### Constraints

- Preserve the Step 41-43 contract already implemented:
  - persistent Builder is the normal path
  - step-boundary Builder compaction is attempted when supported
  - replacement is recovery-only
  - split is costed and last-resort
- Do not weaken adapter truthfulness or reintroduce speculative runtime claims.
- Keep the root README concise and operator-facing rather than turning it into another full contract restatement.
- Proof surfaces must fail on contradictory legacy remediation wording, not just on missing positive phrases.

### Tasks

- [x] Update `cdd-master-chef/openclaw/README.md` so QA rejection and continuation wording consistently says Master Chef reuses the same Builder first when it remains usable, and only falls back to a fresh replacement Builder when recovery conditions require it.
- [x] Update `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` so the procedural flow, QA rejection path, and continuation/recovery instructions no longer contain any stale default-to-fresh-Builder remediation wording that contradicts the persistent-Builder contract.
- [x] Update [README.md](/Users/ruph/Workspace/cdd-skills/README.md) so the top-level Master Chef entrypoint reflects the current compact package policy:
  - unknown session settings do not block kickoff
  - fresh runs can recommend a source feature branch and still create a managed worktree branch
  - persistent Builder continuation is the normal path after kickoff
  - oversized-looking steps are reviewed first and split only when split cost is justified
- [x] Update [scripts/validate_skills.py](/Users/ruph/Workspace/cdd-skills/scripts/validate_skills.py) so validation fails when OpenClaw docs or the root README reintroduce contradictory fresh-Builder default lifecycle or stale remediation wording.
- [x] Update [scripts/test_master_chef_artifacts.sh](/Users/ruph/Workspace/cdd-skills/scripts/test_master_chef_artifacts.sh) only as needed so the artifact layer and validator layer agree on which public Master Chef entrypoint surfaces are structurally guarded versus validator-guarded.
- [x] Keep root README and package README coverage intentionally separated: root README should stay brief and public-facing, while `cdd-master-chef/README.md` remains the compact package-level policy surface.

### Implementation notes

- Treat `fresh Builder` as valid only for recovery replacement, never as the default next-step or default QA-remediation path.
- The OpenClaw fix should remove contradictions, not add more prose.
- Prefer one stable phrase family for the lifecycle rule across docs and validator checks:
  - same Builder first when still usable
  - replacement only on recovery conditions
- If root README coverage moves into the validator, keep it compact and concept-based rather than forcing long sentence-shaped literals.

### Automated checks

- `bash scripts/test_master_chef_artifacts.sh`
- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read `cdd-master-chef/openclaw/README.md` and `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` and confirm QA rejection and same-step continuation both prefer the same Builder first when it remains usable.
- Read [README.md](/Users/ruph/Workspace/cdd-skills/README.md) and confirm it no longer advertises `fresh single-step Builder runs` as the normal lifecycle.
- Confirm the validator fails if OpenClaw docs regress to `send findings to a fresh Builder run` as the default remediation path.
- Confirm the validator or artifact coverage fails if the root README regresses to legacy Master Chef lifecycle wording.

## Step 45 — Make Master Chef verify TODO completion and emit post-run closeout recommendations

### Goal

Make Master Chef verify that completed TODO steps are actually written back as done, then end successful runs with a final mission report that recommends the next human actions clearly: run `cdd-implementation-audit` on the completed run scope, push if needed, open a PR when the branch is published, clean up the managed worktree when done, and return development to the source checkout.

### Constraints

- Preserve the current Step 41-44 contract: persistent Builder continuation, recovery-only replacement, branch-backed `env_ready` managed worktrees, and split as a costed last resort.
- Do not recommend actions that are already satisfied; recommendations must be conditional on real repo and run state.
- Keep hard technical or physical stops distinct from successful completion or budget stop reporting.
- Do not silently perform post-run cleanup or PR creation as part of the shared contract; this step is about verification and recommendations in reporting, not automatic side effects.
- Preserve concise final mission reporting while still making the next operator actions explicit.

### Tasks

- [x] Update `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/README.md` so a step cannot pass unless the selected TODO step is written back correctly and its task checklist reflects the completed work; the final mission report must name which TODO step ids were completed in the run and whether their task checklists are fully checked.
- [x] Update `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, and `cdd-master-chef/CLAUDE-RUNBOOK.md` so successful terminal states and `RUN_STOPPED` due to approved budget include a compact post-run recommendation bundle that conditionally covers:
  - run `[CDD-4] Implementation Audit` (`cdd-implementation-audit`) on the completed run scope, typically the completed TODO steps and the branch changes from that run
  - push the branch if the active branch is ahead of origin
  - open a PR once the branch is published upstream
  - clean up the managed worktree when no more work is planned there
  - return development to the source checkout or parent folder after worktree cleanup
- [x] Define the recommendation conditions explicitly in the shared contract so Master Chef does not recommend impossible or already-satisfied actions:
  - recommend `push` only when the active branch is ahead of its upstream or has no published upstream yet
  - recommend `open PR` only when the branch is pushed and PR creation is still pending
  - recommend worktree cleanup only when the run used a managed worktree that still exists and no immediate continuation is planned there
  - recommend returning to the source checkout only after cleanup or when the worktree is no longer the active development root
- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md` so final mission report prompts and pass criteria require:
  - completed TODO step ids
  - checklist completion status for those steps
  - decisions made and exact stop reason when relevant
  - the conditional post-run recommendation bundle above
- [x] Update `scripts/validate_skills.py` so validation fails if Master Chef terminal reporting omits TODO completion verification or regresses to generic final-report wording that never recommends audit, publish, cleanup, and source-checkout return actions when those recommendations are actually warranted.
- [x] Update `scripts/test_master_chef_artifacts.sh` only as needed so the artifact layer and validator layer remain aligned on whether final-report recommendation coverage is structural or validator-owned.

### Implementation notes

- Treat `TODO writeback` and `task checklist complete` as separate proof points. A step can still be wrong if the heading is present but task checkboxes do not reflect the shipped work.
- Keep the recommendation bundle compact and state-based. It should read like the next operator moves, not like a long tutorial.
- Distinguish `RUN_COMPLETE` from `RUN_STOPPED` clearly:
  - `RUN_COMPLETE` should recommend audit of the completed run and normal branch cleanup/publish actions
  - `RUN_STOPPED` from budget should recommend audit plus continuation/publish actions appropriate to the remaining work
  - hard-stop `STEP_BLOCKED` or `DEADLOCK_STOPPED` should prioritize blocker context first and should not pretend branch cleanup is the primary next move
- If the repo has no `docs/specs/*` surfaces, the final report should still recommend audit against `TODO.md`, `README.md`, and the current branch diff rather than inventing missing specs.

### Automated checks

- `bash scripts/test_master_chef_artifacts.sh`
- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Simulate a successful `RUN_COMPLETE` and confirm the final mission report names the completed TODO step ids, states their checklist completion, and recommends `cdd-implementation-audit` on the run scope.
- Simulate a branch that is already pushed and confirm the final report does not redundantly recommend `push`, but can still recommend `open PR` if appropriate.
- Simulate a completed managed-worktree run and confirm the final report recommends cleanup and returning to the source checkout only when that worktree still exists and no immediate continuation is planned there.
- Simulate a budget stop with remaining runnable work and confirm the final report distinguishes that from `RUN_COMPLETE` while still recommending audit of the work completed in the run so far.

## Step 46 — Make cdd-implementation-audit explicitly audit TODO step contracts

### Goal

Make `cdd-implementation-audit` explicitly audit selected TODO steps against their own step contract sections, so audits check whether the implementation actually satisfied each step’s goal, tasks, checks, and UAT rather than only comparing against broad TODO scope.

### Constraints

- Preserve `cdd-implementation-audit` as a read-only audit skill that routes approved findings back into `cdd-plan`.
- Keep step-contract auditing additive to the existing `README.md`, code, tests, and docs audit dimensions; do not narrow the skill into TODO-only review.
- Support all existing audit scopes, including one TODO step, multiple TODO steps, one TODO file, last commit, uncommitted changes, and whole codebase.
- Treat missing `docs/specs/*` surfaces as findings when the repo contract expects them; do not invent specs during the audit.
- Keep the public README description compact; the detailed behavior belongs in the skill file and validator.

### Tasks

- [x] Update `skills/cdd-implementation-audit/SKILL.md` so when the chosen audit scope resolves to one or more TODO steps, the audit must explicitly inspect each selected step’s:
  - `Goal`
  - `Constraints`
  - `Tasks`
  - `Implementation notes`
  - `Automated checks`
  - `UAT`
  and must report whether the implementation actually satisfies that step contract rather than only the broader TODO topic.
- [x] Define the TODO-step audit output contract explicitly in `skills/cdd-implementation-audit/SKILL.md`: the final audit summary for step-scoped audits must say which selected steps were checked, whether their checked tasks appear fully done, whether the observed implementation matches the step goal, whether automated checks and UAT evidence support the claimed completion, and where README, TODO, spec, or proof-surface drift remains.
- [x] Update the skill flow so step-scoped audits inspect the corresponding implementation, docs, tests, configs, manifests, and validation surfaces together, and treat unchecked TODO tasks, missing evidence for completed tasks, or implementation that misses the step goal as first-class findings.
- [x] Update [README.md](/Users/ruph/Workspace/cdd-skills/README.md) only if needed so the `[CDD-4] Implementation Audit` description stays accurate while remaining compact and user-facing.
- [x] Update `scripts/validate_skills.py` so validation fails if `cdd-implementation-audit` regresses to vague TODO-scope language and no longer requires explicit step-contract auditing for one-step or multi-step TODO audits.
- [x] Update generated OpenClaw Builder coverage only as needed so the shared skill validation still passes without changing the audit skill’s read-only contract.

### Implementation notes

- This is a contract refinement, not a request to make the audit skill implement fixes directly.
- Keep the strongest wording around step-scoped audits in the skill file itself:
  - selected step ids
  - step-section contract review
  - checked-task reality check
  - goal satisfaction
  - proof from automated checks and UAT
- For non-step scopes such as whole-codebase or uncommitted changes, preserve the current broader audit behavior.
- If a TODO step lacks one of the preferred sections, the audit should treat that as a contract weakness or missing proof surface rather than silently skipping it.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Audit one completed TODO step and confirm the summary explicitly states whether the step goal was achieved, whether the checked tasks are actually done, and whether the cited checks and UAT support completion.
- Audit multiple TODO steps from one run and confirm the summary distinguishes findings per selected step rather than collapsing them into one vague branch-level judgment.
- Confirm the validator fails if the audit skill is reduced back to broad TODO-scope auditing without explicit step-section review.
- Confirm missing repo specs still surface as findings where relevant instead of being silently ignored.
