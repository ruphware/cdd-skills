---
name: cdd-master-chef
description: Run autonomous CDD delivery in OpenClaw-direct mode: the main session is Master Chef, the Builder runs as an OpenClaw subagent, state lives under .cdd-runtime/master-chef in the repo, a cron systemEvent wakes the main session for watchdog ticks, and the main session sends optional status updates directly.
user-invocable: true
disable-model-invocation: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["git"],"config":[]}}}
---

# CDD Master Chef

Use this skill for a clean OpenClaw-native autonomous workflow.

References:

- `{baseDir}/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. Use this skill only in repos that are already CDD-ready:
   - `AGENTS.md`
   - `README.md`
   - `TODO.md` or `TODO-*.md`
2. The main OpenClaw session is always Master Chef.
3. The Builder runs as an OpenClaw subagent, not ACP.
4. The watchdog is a cron `systemEvent` that wakes the main session. It is not a separate supervising agent.
5. State is durable and repo-local:
   - `.cdd-runtime/master-chef/run.json`
   - `.cdd-runtime/master-chef/run.lock.json`
   - `.cdd-runtime/master-chef/master-chef.jsonl`
   - `.cdd-runtime/master-chef/builder.jsonl`
   - `.cdd-runtime/master-chef/watchdog.jsonl`
6. Before kickoff, confirm:
   - `control_route`: the current session
   - `status_route`: optional external route such as Slack
   - `status_route_policy`: `best_effort` or `required`
7. Before autonomous work starts, inspect:
   - current git status and branch
   - upstream branch
   - active TODO file
   - last completed step
   - next runnable TODO step
8. Master Chef chooses the internal `cdd-*` routing model.
   - Builder default: `cdd-implement-todo` for the next runnable TODO step.
   - Builder optional: `cdd-index` when Master Chef explicitly wants an index refresh as the delegated action.
   - Master Chef direct: `cdd-init-project`, `cdd-plan`, and `cdd-refactor` stay in the main session rather than being delegated to Builder.
   - Excluded from the normal flow: `cdd-audit-and-implement`, unless the process is explicitly adapted for its mixed role.
   - Treat the installed `cdd-*` skills as internal OpenClaw workflows, not user slash commands.
9. Before implementation starts, present one kickoff approval that covers:
   - proposed next action
   - runtime initialization under `.cdd-runtime/master-chef/`
   - run lease creation
   - one recurring watchdog cron as a main-session `systemEvent`
   - optional direct status updates to the chosen `status_route`
10. Spawn the Builder as a subagent with explicit model and thinking settings, and tell it which internal `cdd-*` skill path to use.
11. Prefer one-step Builder runs. Replace stale Builders with a fresh subagent run rather than relying on session recovery.
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
   - approve step-level UAT with explicit evidence
   - commit
   - push
   - send full detail to the control route
   - attempt concise direct status delivery to the status route if configured
   - update `last_status_report_at_utc` on successful status delivery
16. Status-route delivery is event-driven, not just watchdog-driven.
   - A configured `status_route` means Master Chef must attempt direct delivery for key lifecycle events.
   - `best_effort` means attempt delivery and continue if it fails.
   - `required` means attempt delivery and block/stop if it fails.
17. The watchdog tick runs in the main session and may:
   - inspect runtime files and logs
   - inspect Builder health
   - steer the current Builder if supported
   - replace the Builder with a fresh subagent run if stale
   - report blockers or completion
18. The watchdog tick must not create a second control loop. Recovery stays in the main session.
19. Healthy watchdog ticks may stay quiet, but they do not cancel status-route obligations for lifecycle events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, or an explicit stop.
20. If status-route delivery fails and policy is `best_effort`, record `STATUS_DELIVERY_FAILED`, note it in the control route, and continue. If policy is `required`, record `STATUS_DELIVERY_FAILED`, stop the run, and report the blocker.
21. If repeated Builder replacements fail without progress, stop and report `STEP_BLOCKED` or `DEADLOCK_STOPPED`.

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
- `control_route`
- `status_route`
- `status_route_policy`
- `watchdog_job_id`
- `watchdog_mode`
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
- `last_status_report_at_utc`
- `builder_restart_count`
- `dispute_loop_count`
- `current_blocker`

Report events:

- `START`
- `HEARTBEAT`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`
- `STATUS_DELIVERY_FAILED`

Route policy:

- `control_route`: full operational detail
- `status_route`: concise direct updates sent by the main session
