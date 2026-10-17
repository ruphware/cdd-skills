---
name: cdd-master-chef
description: Start the cdd-master-chef autonomous workflow package. Use for non-trivial development where Master Chef ownership is wanted; current concrete adapters in this package are Codex and Claude Code, provided as subagent-backed adapter docs.
user-invocable: true
homepage: https://github.com/ruphware/cdd-skills
---

# [CDD-6] Master Chef

Adapter note:

- This skill is the entrypoint; `CONTRACT.md`, `RUNBOOK.md`, and `RUNTIME-CAPABILITIES.md` are canonical, and when SKILL.md and CONTRACT.md disagree, CONTRACT.md wins.
- Current concrete adapters are Codex and Claude Code, shipped here as subagent-backed adapter docs.
- Adapters ask for the run step budget and whether to spawn Builder now, then own that Builder handoff instead of pushing the Builder-start decision back to the human.

## Read first

- Read [CONTRACT.md](CONTRACT.md) fully before kickoff.
- Use [RUNBOOK.md](RUNBOOK.md) for operations.
- Read [RUNTIME-CAPABILITIES.md](RUNTIME-CAPABILITIES.md) and the active runtime's adapter: [CODEX-ADAPTER.md](CODEX-ADAPTER.md) or [CLAUDE-ADAPTER.md](CLAUDE-ADAPTER.md).
- Follow `CONTRACT.md §7` for every human decision prompt (lettered choices, optional nested variants, the whole decision block last) and for the Builder lifecycle.

## Routing

Master Chef chooses the internal `cdd-*` routing for the core `[CDD-0]` through `[CDD-5]` skills.

- `[CDD-1] Init Project` (`cdd-init-project`): for a new or not-yet-CDD project, propose and normally start here in the main session before any autonomous TODO execution.
- `[CDD-3] Implement` (`cdd-implement`): Builder default for the next runnable TODO step; direct non-TODO use is explicit opt-in only.
- Oversized step: when the next runnable top-level step looks too large for one Builder run, its declared `points:` value is the primary signal: 8 is the one-run ceiling, 13 or 21 enters the review-first split before the first delegation, `>21` is planned, never delegated. Prefer delegating unchanged, then minimal in-place repair, then a split only when its cost is justified; the split-cost rules live in `CONTRACT.md §5`.
- `[CDD-2] Plan` (`cdd-plan`): Master Chef direct path in the main session, never delegated to Builder; approved audit or external-review findings go through it before any delegated implementation.
- `[CDD-4] Audit` (`cdd-audit`): installed direct helper for explicit implementation or codebase audits.
- `[CDD-0] Boot` (`cdd-boot`): installed, but outside the normal Master Chef routing flow.
- `[CDD-5] Maintain` (`cdd-maintain`): installed direct helper for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review when one of those is the actual next action.
- During an active run, the installed `cdd-*` skills are internal Master Chef workflows, not standalone user commands.

## Kickoff approval

Before implementation starts, present one selector-driven kickoff approval covering:

- proposed next action
- current session model and current session thinking
- effective Builder settings; any `Builder override` stays local, and shared docs and commits stay free of operator overrides
- effective Builder transport rung, plus the kickoff-declared permission profile on exec rungs
- the fresh-start worktree-branch suggestion when the source checkout sits on a long-lived branch
- run step budget: the default/max recommendation when the remaining top-level step count is finite, and the approved budget
- whether to spawn Builder now
- wave-parallel opt-in and `max_parallel` when the active TODO file carries `touches:` step annotations
- runtime initialization under `.cdd-runtime/master-chef/` and run lease creation
- managed worktree creation at `.cdd-runtime/worktrees/<run-id>/` and relaunch expectations
- active-worktree environment bootstrap before Builder or `hard_gate` validation runs

The selected option is the kickoff approval:

- `A. approve kickoff and start the autonomous run now`
- `B. approve kickoff but do not spawn Builder yet`
- `C. revise the next action, Builder settings, or step budget before kickoff`

## Report events

The current Master Chef session is the single control plane and reporting surface: no watchdog cron or separate supervising agent, and no extra route config in shared skill docs or runtime state. Healthy Builder checks may stay quiet, but they do not cancel in-session lifecycle reporting.

- `START`
- `BUILDER_SPAWNED`
- `BUILDER_READY`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

`CONTRACT.md §9` holds the full event list (including the Builder-stop events), the `BLOCKER_CLEARED` record, the final mission report, and the closeout bundles for `RUN_COMPLETE`, budget-stop `RUN_STOPPED`, and hard-stop `STEP_BLOCKED` or `DEADLOCK_STOPPED`.

## Section map

| Topic | CONTRACT.md section |
|---|---|
| Policy summary | §0.5 Compact policy flow |
| Actors and ownership | §1 Actors |
| Required repo state and pre-kickoff inspection | §2 Required repo state |
| Durable runtime state and `run.json` fields | §3 Durable runtime state |
| Session settings, Builder override, and Builder transport ladder | §4 Session settings and Builder override |
| Routing model and oversized-step split policy | §5 Routing model |
| Managed worktree lifecycle and environment bootstrap | §6 Managed worktree lifecycle |
| Kickoff, decision prompts, and Builder lifecycle | §7 Kickoff and Builder lifecycle |
| Validation, QA, per-step pass, and UAT | §8 Validation, QA, and UAT |
| Reporting, mission report, closeout, and blocker recovery | §9 Reporting and recovery |
| Context compaction | §10 Context compaction |
| Runtime adapter obligations | §11 Runtime adapter obligations |
| Wave-parallel execution | §12 Wave-parallel execution (opt-in) |
