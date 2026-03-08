---
name: cdd-master-chef
description: Run the OpenClaw Master Chef upgrade on top of the core CDD skills, with ACP Codex as the primary Builder path, repo-local runtime state, dual-route reporting, and an isolated LLM watchdog supervisor.
user-invocable: true
disable-model-invocation: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["codex","git"],"config":["acp.enabled","tools.sessions.visibility","agents.defaults.sandbox.sessionToolsVisibility"]}}}
---

# CDD Master Chef

Use this skill for the OpenClaw-driven autonomous upgrade described in:

- `{baseDir}/README.md`
- `{baseDir}/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. This skill is an upgrade on top of the core `cdd-*` Builder skills. Do not use it until the target repo already has the CDD boilerplate and the Builder skills are installed.
2. Before invoking `/cdd-master-chef`, the user must explicitly select both models with standalone directives:
   - `/model <master-model>`
   - `/acp model <builder-model>`
3. On startup, verify that the repo is already CDD-ready:
   - `AGENTS.md`
   - `README.md`
   - an active `TODO.md` or `TODO-*.md`
   If the repo is not CDD-ready, stop and direct the user back to the core CDD workflow first.
4. Before kickoff completes, confirm the reporting model:
   - `control_route`: the operator-facing route, normally the current TUI/OpenClaw session if the user explicitly accepts it
   - `status_route`: optional condensed reporting, for example Slack; record whether it is `best_effort` or `required`
5. Require session-tool visibility that can reach the Master Chef session from the isolated watchdog:
   - `tools.sessions.visibility` must be `agent` or `all`
   - if sandboxed, `agents.defaults.sandbox.sessionToolsVisibility` must not clamp access below the needed session scope
   If these checks fail, stop before autonomous execution.
6. Inspect where development is at before proposing work:
   - current git status and branch
   - upstream branch
   - active TODO file
   - last completed step
   - next runnable TODO step
7. The normal next action is the next runnable TODO step via `cdd-implement-todo`. Only fall back to `cdd-plan` when the TODO state is stale, ambiguous, or not executable.
8. Before any implementation starts, present one kickoff approval that covers:
   - the proposed next action
   - the selected routes and delivery policy
   - initialization of `.cdd-runtime/master-chef/`
   - creation of one 5-minute isolated watchdog cron job
   - duplicate-run protection via a run lease / lock
9. Runtime state must be durable in the target repo:
   - `.cdd-runtime/master-chef/run.json`
   - `.cdd-runtime/master-chef/run.lock.json`
   - `.cdd-runtime/master-chef/master-chef.jsonl`
   - `.cdd-runtime/master-chef/builder.jsonl`
   - `.cdd-runtime/master-chef/watchdog.jsonl`
   Ensure `.cdd-runtime/` is ignored locally before autonomous execution begins.
10. Watchdog scheduling is OpenClaw-native:
   - one recurring 5-minute cron job
   - run it in an isolated session, not the main session
   - capture the current Master Chef model at kickoff time
   - on each tick, do deterministic state checks first, then a compact Master Chef probe if needed
   - emit 15-minute `HEARTBEAT` summaries with both Master Chef and Builder status
   - store the cron job id and active lease id in `run.json`
11. The Builder runtime is ACP `codex` as the main path. Do not switch harnesses unless the user explicitly changes the process contract. Direct local Codex CLI is break-glass fallback only when ACP is unavailable or explicitly approved.
12. The Builder must use the separate `cdd-*` skill pack first. Freeform/manual coding is fallback-only and must be justified with a concrete blocker.
13. When a Builder session is needed, use `/acp spawn codex --mode persistent --thread auto --cwd <repo>` unless the current thread is already bound to the correct repo session.
14. After kickoff approval, continue automatically step to step until the run is complete, blocked, or deadlocked. The human mainly reviews final results, not each step.
15. Both Master Chef and Builder must append durable JSONL logs that the watchdog can process. Log at step start, phase changes, validation start/result, blockers, resumes, commits, pushes, and completion. Include validation class (`hard_gate` or `soft_signal`) and evidence references where relevant.
16. For each passed step:
   - update the selected step's task items in the active `TODO*.md` file to done, without modifying unrelated steps or inventing a new step-level status field
   - run the Master Chef QA gate
   - approve step-level UAT internally with explicit evidence
   - commit
   - push
   - report full detail to the `control_route`
   - report a condensed summary to the `status_route` if configured
17. Resolve Master Chef versus Builder disputes internally through evidence, tests, and challenge loops. After 2 failed loops on the same blocker, stop the run and report deadlock.
18. The watchdog is an isolated LLM supervisor. It may do bounded agent-like checks, but it must not become a second planner or Builder. It must:
   - read deterministic state first (`run.json`, lease, log freshness, restart counts, session refs)
   - if Builder is stale and Master Chef is healthy, instruct Master Chef to resume Builder and report `BUILDER_RESUMED`
   - if Master Chef is stale or dead, probe it with session tools and, if that fails, rehydrate the run from `run.json`, restart Master Chef in the saved session, and report `MASTER_CHEF_RESTARTED`
   - stop and report blockers rather than pretending the run is healthy when control-route delivery, cron, push, or repeated restart logic fails
   - if `status_route` delivery fails and its policy is `best_effort`, report the degraded state in the `control_route` and continue safely

Canonical runtime state fields in `run.json`:

- `run_id`
- `repo`
- `master_model`
- `builder_model`
- `master_session_key`
- `control_route`
- `status_route`
- `status_route_policy`
- `watchdog_job_id`
- `run_lease_id`
- `active_todo_path`
- `active_step`
- `phase`
- `builder_session_ref`
- `branch`
- `upstream`
- `pre_step_head_sha`
- `last_pass_head_sha`
- `last_progress_at_utc`
- `last_master_log_at_utc`
- `last_builder_log_at_utc`
- `last_control_report_at_utc`
- `last_status_report_at_utc`
- `master_restart_count`
- `builder_restart_count`
- `dispute_loop_count`
- `current_blocker`

Report events:

- `START`
- `HEARTBEAT`
- `MASTER_CHEF_RESTARTED`
- `BUILDER_RESUMED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `DISPUTE_RESOLVED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

Status reports must include:

- `EVENT`
- `STEP`
- `PHASE`
- `MASTER_CHEF_STATUS`
- `BUILDER_STATUS`
- `LAST_PROGRESS`
- `CHANGES`
- `VALIDATION`
- `BLOCKERS`
- `RESTART_COUNTS`
- `NEXT`

`STEP_PASS` must also include:

- `MASTER CHEF UAT APPROVED`
- `COMMIT`
- `PUSH`

Route verbosity:

- `control_route`: full operational detail, recovery reasoning, blockers, and final summaries
- `status_route`: concise progress, heartbeat, recovery, blocker, and completion summaries

Test-only note:

- Synthetic watchdog prompts are allowed in the harness as manual stand-ins for real isolated cron events.
