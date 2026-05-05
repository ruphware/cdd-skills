---
name: cdd-master-chef
description: Start the cdd-master-chef autonomous workflow package. Use for non-trivial development where Master Chef ownership is wanted; current concrete adapters in this package are Codex, Claude Code, and OpenClaw, with OpenClaw carrying the current packaged runtime adapter and Codex and Claude Code provided as subagent-backed adapter docs.
user-invocable: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["git"],"config":[]}}}
---

# [CDD-6] Master Chef

Use this skill as the entrypoint for the shared `[CDD-6] Master Chef` workflow.

Adapter note:

- The runtime-agnostic Master Chef contract now lives beside this skill in `CONTRACT.md`, `RUNBOOK.md`, and `RUNTIME-CAPABILITIES.md`.
- Current concrete adapters in this package are Codex, Claude Code, and OpenClaw.
- Codex and Claude Code are current subagent-backed adapter docs in this package.
- OpenClaw is the current packaged runtime adapter in this package.
- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters, but no Hermes adapter ships here today.
- Codex and Claude Code adapters should ask for the run step budget and whether to spawn Builder now, then own that Builder handoff rather than pushing the Builder-start decision back to the human.
- Master Chef approval requests should use visible selector-based options, defaulting to `A.`, `B.`, `C.` when practical, and the selected option itself should count as the approval.
- The operating contract below describes the current OpenClaw runtime path.
- When this file repeats a shared rule, treat the shared contract as canonical and this file as the OpenClaw runtime mapping of that rule.

References:

- `{baseDir}/openclaw/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/openclaw/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. Use this skill for non-trivial development where Master Chef ownership is wanted.
   - Preferred path: an existing repo that is already CDD-ready with `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`
   - Allowed bootstrap path: a new or adoptable project folder that should be brought into the CDD contract first via `cdd-init-project`
2. The current runtime's main session is always Master Chef.
3. The Builder runs as a runtime-native subagent under the active adapter, not as a second Master Chef control loop.
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
   - otherwise, if the current session model and current session thinking are visible, recommend a candidate `Run config` that copies those values into `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`, surface it back to the human, and use it only after the human approves or edits it
   - otherwise, stop and ask the human for a `Run config`
   - the resolved `Run config` must contain `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`
   - treat the resolved `Run config` as the only per-run source of truth; do not infer model settings from repo docs, USER.md, memory, previous `run.json`, or earlier runs
   - keep shared docs and commits free of local-only operator overrides
7. Before autonomous work starts, inspect:
   - current git status and branch
   - upstream branch when present
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - whether the next runnable top-level TODO step is oversized for one Builder run
   - remaining unfinished top-level TODO step-heading count in the active TODO file when that count is finite
   - whether this looks like a fresh run from a long-lived branch and should first suggest a descriptive feature branch
   - whether the repo first needs `cdd-init-project` before the normal TODO loop can start
   - whether the source checkout is clean enough for managed worktree creation
8. Master Chef chooses the internal `cdd-*` routing model for the core `[CDD-0]` through `[CDD-5]` skills.
   - `[CDD-1] Init Project` (`cdd-init-project`): for a new or not-yet-CDD project, propose and normally start here in the main session before any autonomous TODO execution.
   - `[CDD-3] Implement TODO` (`cdd-implement-todo`): Builder default for the next runnable TODO step.
   - If the next runnable top-level TODO step is oversized for one Builder run, Master Chef may split it into smaller decision-complete TODO steps before delegation. Recompute the remaining unfinished top-level TODO step-heading count after the split, then treat the first new runnable step as the proposed delegated action.
   - `[CDD-2] Plan` (`cdd-plan`): Master Chef direct path that stays in the main session rather than being delegated to Builder.
   - `[CDD-4] Implementation Audit` (`cdd-implementation-audit`): installed direct audit helper for explicit implementation or codebase audits; approved findings still flow through `[CDD-2] Plan` before any delegated implementation begins.
   - External audit findings and review-derived work packages: normalize them through `[CDD-2] Plan` (`cdd-plan`) in the main session before any delegated implementation begins.
   - `[CDD-0] Boot` (`cdd-boot`): installed helper, but not part of the normal Master Chef routing flow.
   - `[CDD-5] Maintain` (`cdd-maintain`): installed direct maintenance helper for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review when one of those tasks is the actual next action.
   - Treat the installed `cdd-*` skills as internal Master Chef workflows, not standalone user commands during an active Master Chef run.
9. Use a managed worktree before implementation:
   - require a clean source checkout before kickoff; if dirty, stop and ask the human to stash, commit, or discard changes first
   - if this is a fresh run from a long-lived branch and no existing managed worktree is being resumed, suggest a descriptive feature branch first; if approved, create it in the source checkout before the per-run worktree branch
   - create a fresh per-run branch from the current branch `HEAD`
   - prefer `.cdd-runtime/master-chef/worktrees/<run-id>/` as the managed worktree path
   - record `source_repo`, `source_branch`, `source_head_sha`, `active_worktree_path`, `worktree_branch`, and `worktree_continue_mode` in runtime state
   - the active runtime adapter either continues in-session from the managed worktree or stops with exact relaunch instructions; keep `worktree_continue_mode` explicit
10. Before implementation starts, present one selector-driven kickoff approval that covers:
   - proposed next action
   - the approved `Run config`
   - any fresh-start feature-branch suggestion when the source checkout is still on a long-lived branch
   - the default/max run step-budget recommendation when the active TODO has a finite remaining top-level step count
   - the approved run step budget
   - whether to spawn Builder now and start the autonomous run
   - runtime initialization under `.cdd-runtime/master-chef/`
   - run lease creation
   - managed worktree creation and relaunch expectations
   - prefer `A. approve kickoff and start the autonomous run now`, `B. approve kickoff but do not spawn Builder yet`, `C. revise the next action, Run config, or step budget before kickoff`
11. Spawn the Builder as a subagent with the exact `builder_model` and `builder_thinking` from the approved `Run config`, for exactly one approved delegated action, tell it which internal `cdd-*` skill path to use, and require an early readiness ACK before deep work.
12. Use single-step Builder runs only.
   - Each Builder run covers exactly one approved delegated action.
   - After a step passes, blocks, or is abandoned as stale, Master Chef must re-inspect repo state and spawn a fresh Builder for the next delegated action, normally via `cdd-implement-todo`.
   - Do not treat Builder session resurrection or multi-step continuation as a normal path.
13. Both Master Chef and Builder must append JSONL logs with concrete evidence for Builder spawn, Builder readiness, step start, validation, blockers, completion, and reporting.
14. Use `hard_gate` and `soft_signal` validation classes:
   - `hard_gate`: failing tests, lint, typecheck, migrations, pushability, or repo-defined must-pass checks
   - `soft_signal`: discovery greps, file-presence scans, or other non-blocking heuristics
15. Use working-tree-aware discovery checks when unstaged files matter:
   - `rg --files`
   - `git ls-files --cached --others --exclude-standard`
16. After relaunch into the managed worktree, treat that worktree as the active repo root for QA, TODO inspection, commit, and push.
17. For each passed step:
   - increment `steps_completed_this_run`
   - ensure the Builder updated only the selected step in `TODO*.md`
   - run Master Chef QA
   - if QA rejects the Builder result, either push concrete findings to a fresh Builder run for the same step or fix the issue directly in Master Chef, then re-run QA before the step can pass
   - approve step-level UAT with explicit evidence
   - commit
   - push
   - advertise `STEP_PASS` with the full result, evidence, and decision trail in the current Master Chef session
   - if `run_step_budget` is a positive integer and `steps_completed_this_run` has reached it, stop cleanly with `RUN_STOPPED` and a summary instead of continuing automatically
   - otherwise, re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains
18. Reporting is session-native.
   - The current Master Chef session is the control plane and reporting surface for this shared skill.
   - Report lifecycle events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, and explicit stops in-session.
   - Keep shared skill docs and runtime state free of extra route config.
19. When Master Chef performs a Builder check in the main session, it may:
   - inspect runtime files and logs
   - inspect Builder health
   - use direct Builder status or progress surfaces when the runtime exposes them
   - replace the Builder with a fresh subagent run if stale
   - report blockers or completion
20. Direct Builder checks must not create a second control loop. Recovery stays in the main session, using fresh Builder replacement rather than normal session resurrection.
21. Healthy Builder checks may stay quiet, but they do not cancel in-session lifecycle reporting for events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, or an explicit stop.
22. Distinguish Builder boot/readiness from quiet work.
   - Record `builder_phase: booting` as soon as the spawn request succeeds. A returned Builder session key or spawned-agent line is not enough to prove that the Builder has started operating.
   - Keep `builder_phase: booting` until a runtime-reported child-started signal, a coherent Builder readiness ACK, or a Builder-authored `BUILDER_READY` record arrives in `builder.jsonl`.
   - Preferred boot prompt: `Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.`
   - The preferred readiness ACK confirms the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
   - Use a short boot window before the first boot-status probe; foreground Codex and Claude flows should default to about 2 minutes.
23. If the runtime does not expose live Builder thinking or streaming partial output, report Builder state as `running` or `unknown` during quiet periods rather than guessing.
   - Do not treat a returned session key, a missing diff, an empty `builder.jsonl`, or one short wait window as proof that Builder is fully started or has died.
   - For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless direct failure evidence arrives sooner.
   - In foreground Codex and Claude flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
   - Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
   - Use one direct status probe before replacement when the runtime supports it.
   - Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.
24. If repeated Builder replacements fail without progress, stop quickly and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` rather than limping on.
25. If a TODO step is blocked by a hard blocker, ambiguous scope, being oversized for one Builder run, or repeated failed Builder replacements:
   - stop the autonomous loop and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` in the current Master Chef session
   - revise the situation in Master Chef before any more Builder work
   - decompose the blocked work into smaller decision-complete TODO steps through Master-Chef-direct planning or TODO repair
   - clean only stale runtime/build artifacts needed for a coherent retry, and never revert unrelated user work
   - restart only from the next smaller actionable TODO step; do not retry the same broad blocked step unchanged
26. Manage Master Chef context explicitly during long runs:
   - keep Builder context fresh through single-step Builder runs; do not compact or resume Builders as the normal path
   - before Master Chef compaction, write `run.json`, `run.lock.json`, JSONL evidence, and `.cdd-runtime/master-chef/context-summary.md`
   - compact only at safe workflow boundaries, such as after kickoff state is durable, after Builder handoff, after `STEP_PASS`, after `STEP_BLOCKED` or `DEADLOCK_STOPPED`, after Master-Chef-direct planning/refactor work, or before a known large QA/planning phase once a checkpoint is written
   - do not compact while QA, commit, push, blocker strategy, or next-action decisions exist only in the live transcript
   - after compaction, resume from runtime files, `context-summary.md`, active TODO, and git state before continuing

Canonical `run.json` fields:

- `run_id`
- `repo`
- `source_repo`
- `master_model`
- `master_thinking`
- `builder_model`
- `builder_thinking`
- `builder_runtime`
- `master_session_key`
- `builder_session_key`
- `builder_phase`
- `builder_spawn_requested_at_utc`
- `builder_ready_at_utc`
- `last_builder_direct_signal_at_utc`
- `run_step_budget`
- `steps_completed_this_run`
- `active_todo_path`
- `active_step`
- `phase`
- `source_branch`
- `source_head_sha`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
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
- `BUILDER_SPAWNED`
- `BUILDER_READY`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

Reporting surface:

- the current Master Chef session carries full operational detail and lifecycle reporting
