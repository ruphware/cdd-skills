---
name: cdd-master-chef
description: Run the OpenClaw adapter for the shared cdd-master-chef autonomous workflow. Use for non-trivial development in an existing CDD repo or when starting a new project that should adopt CDD first; the main session is Master Chef, the Builder runs as fresh one-step OpenClaw subagent runs, repo state lives under .cdd-runtime/master-chef, and the main session handles Builder checks and operator-facing reporting without a watchdog cron.
user-invocable: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["git"],"config":[]}}}
---

# CDD Master Chef

Use this skill for the OpenClaw adapter of the shared Master Chef workflow.

Adapter note:

- The runtime-agnostic Master Chef contract now lives in the source repo under `master-chef/`.
- This skill defines how OpenClaw realizes that shared contract.
- When this file repeats a shared rule, treat the shared contract as canonical and this file as the OpenClaw runtime mapping of that rule.

References:

- `{baseDir}/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. Use this skill for non-trivial development where Master Chef ownership is wanted.
   - Preferred path: an existing repo that is already CDD-ready with `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`
   - Allowed bootstrap path: a new or adoptable project folder that should be brought into the CDD contract first via `cdd-init-project`
2. The main OpenClaw session is always Master Chef.
3. The Builder runs as an OpenClaw subagent, not ACP.
4. There is no watchdog cron or separate supervising agent; Master Chef checks Builder health directly in the main session when active.
5. State is durable and repo-local:
   - `.cdd-runtime/master-chef/run.json`
   - `.cdd-runtime/master-chef/run.lock.json`
   - `.cdd-runtime/master-chef/master-chef.jsonl`
   - `.cdd-runtime/master-chef/builder.jsonl`
   - `.cdd-runtime/master-chef/context-summary.md`
6. Before kickoff, resolve the `Run config`:
   - if the current prompt includes a `Run config` block, use that
   - otherwise, if `~/.openclaw/config/master-chef/default-run-config.yaml` exists, read it, surface the resolved config back to the human, and use it as the starting `Run config` for that run
   - the resolved `Run config` must contain `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`
   - treat the resolved `Run config` as the only per-run source of truth; do not infer model settings from repo docs, USER.md, memory, previous `run.json`, or earlier runs
   - keep shared docs and commits free of local-only operator overrides
7. Before autonomous work starts, inspect:
   - current git status and branch
   - upstream branch when present
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - whether the repo first needs `cdd-init-project` before the normal TODO loop can start
8. Master Chef chooses the internal `cdd-*` routing model.
   - For a new or not-yet-CDD project, propose and normally start with `cdd-init-project` in the main session before any autonomous TODO execution.
   - Builder default: `cdd-implement-todo` for the next runnable TODO step.
   - Builder optional: `cdd-index` when Master Chef explicitly wants an index refresh as the delegated action.
   - Master Chef direct: `cdd-init-project`, `cdd-plan`, and `cdd-refactor` stay in the main session rather than being delegated to Builder.
   - Excluded from the normal flow: `cdd-audit-and-implement`, unless the process is explicitly adapted for its mixed role.
   - Treat the installed `cdd-*` skills as internal OpenClaw workflows, not user slash commands.
9. Before implementation starts, present one kickoff approval that covers:
   - proposed next action
   - the approved `Run config`
   - runtime initialization under `.cdd-runtime/master-chef/`
   - run lease creation
10. Spawn the Builder as a subagent with the exact `builder_model` and `builder_thinking` from the approved `Run config`, for exactly one approved delegated action, and tell it which internal `cdd-*` skill path to use.
11. Use one-step Builder runs only.
   - One Builder run equals one approved delegated action.
   - After a step passes, blocks, or is abandoned as stale, Master Chef must re-inspect repo state and spawn a fresh Builder for the next delegated action, normally via `cdd-implement-todo`.
   - Do not treat Builder session resurrection or multi-step continuation as a normal path.
12. Both Master Chef and Builder must append JSONL logs with concrete evidence for step start, validation, blockers, completion, and reporting.
13. Use `hard_gate` and `soft_signal` validation classes:
   - `hard_gate`: failing tests, lint, typecheck, migrations, pushability, or repo-defined must-pass checks
   - `soft_signal`: discovery greps, file-presence scans, or other non-blocking heuristics
14. Use working-tree-aware discovery checks when unstaged files matter:
   - `rg --files`
   - `git ls-files --cached --others --exclude-standard`
15. For each passed step:
   - ensure the Builder updated only the selected step in `TODO*.md`
   - run Master Chef QA
   - if QA rejects the Builder result, either push concrete findings to a fresh Builder run for the same step or fix the issue directly in Master Chef, then re-run QA before the step can pass
   - approve step-level UAT with explicit evidence
   - commit
   - push
   - advertise `STEP_PASS` with the full result, evidence, and decision trail in the current Master Chef session
   - re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains
16. Reporting is session-native.
   - The current Master Chef session is the control plane and reporting surface for this shared skill.
   - Report lifecycle events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, and explicit stops in-session.
   - Keep shared skill docs and runtime state free of extra route config.
17. When Master Chef performs a Builder check in the main session, it may:
   - inspect runtime files and logs
   - inspect Builder health
   - replace the Builder with a fresh subagent run if stale
   - report blockers or completion
18. Direct Builder checks must not create a second control loop. Recovery stays in the main session, using fresh Builder replacement rather than normal session resurrection.
19. Healthy Builder checks may stay quiet, but they do not cancel in-session lifecycle reporting for events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, or an explicit stop.
20. If repeated Builder replacements fail without progress, stop quickly and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` rather than limping on.
21. If a TODO step is blocked by a hard blocker, ambiguous scope, or repeated failed Builder replacements:
   - stop the autonomous loop and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` in the current Master Chef session
   - revise the situation in Master Chef before any more Builder work
   - decompose the blocked work into smaller decision-complete TODO steps through Master-Chef-direct planning or TODO repair
   - clean only stale runtime/build artifacts needed for a coherent retry, and never revert unrelated user work
   - restart only from the next smaller actionable TODO step; do not retry the same broad blocked step unchanged
22. Manage Master Chef context explicitly during long runs:
   - keep Builder context fresh through one-step Builder runs; do not compact or resume Builders as the normal path
   - before Master Chef compaction, write `run.json`, `run.lock.json`, JSONL evidence, and `.cdd-runtime/master-chef/context-summary.md`
   - compact only at safe workflow boundaries, such as after kickoff state is durable, after Builder handoff, after `STEP_PASS`, after `STEP_BLOCKED` or `DEADLOCK_STOPPED`, after Master-Chef-direct planning/refactor work, or before a known large QA/planning phase once a checkpoint is written
   - do not compact while QA, commit, push, blocker strategy, or next-action decisions exist only in the live transcript
   - after compaction, resume from runtime files, `context-summary.md`, active TODO, and git state before continuing

Canonical `run.json` fields:

- `run_id`
- `repo`
- `master_model`
- `master_thinking`
- `builder_model`
- `builder_thinking`
- `builder_runtime`
- `master_session_key`
- `builder_session_key`
- `active_todo_path`
- `active_step`
- `phase`
- `branch`
- `upstream`
- `pre_step_head_sha`
- `last_pass_head_sha`
- `last_progress_at_utc`
- `last_master_log_at_utc`
- `last_builder_log_at_utc`
- `builder_restart_count`
- `dispute_loop_count`
- `current_blocker`

Report events:

- `START`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

Reporting surface:

- the current Master Chef session carries full operational detail and lifecycle reporting
