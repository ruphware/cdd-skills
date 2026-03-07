---
name: cdd-master-chef
description: Run the OpenClaw Master Chef upgrade on top of the core CDD skills, with ACP Codex, repo-state inspection, and a cron watchdog.
user-invocable: true
disable-model-invocation: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["codex","git"],"config":["acp.enabled"]}}}
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
4. The current OpenClaw session is the reporting channel. If the user wants a different reporting channel, stop and have them relaunch `/cdd-master-chef` there before autonomous execution begins.
5. Inspect where development is at before proposing work:
   - current git status and branch
   - active TODO file
   - last completed step
   - next runnable TODO step
6. The normal next action is the next runnable TODO step via `cdd-implement-todo`. Only fall back to `cdd-plan` when the TODO state is stale, ambiguous, or not executable.
7. Before any implementation starts, present one kickoff approval that covers:
   - the proposed next action
   - use of the current session as the reporting channel
   - creation of one 5-minute watchdog cron job
8. Watchdog scheduling is OpenClaw-native:
   - one recurring 5-minute cron job
   - target the current main session with a system event
   - keep the control block in-session
   - send `HEARTBEAT` every 15 minutes from that same loop
   - store the cron job id in the control block
9. The Builder runtime is ACP `codex`. Do not switch harnesses unless the user explicitly changes the process contract.
10. The Builder must use the separate `cdd-*` skill pack first. Freeform/manual coding is fallback-only and must be justified with a concrete blocker.
11. When a Builder session is needed, use `/acp spawn codex --mode persistent --thread auto --cwd <repo>` unless the current thread is already bound to the correct repo session.
12. After kickoff approval, continue automatically step to step until the run is complete, blocked, or deadlocked. The human mainly reviews final results, not each step.
13. For each passed step:
   - update the selected step's task items in the active `TODO*.md` file to done, without modifying unrelated steps or inventing a new step-level status field
   - run the Master Chef QA gate
   - approve step-level UAT internally
   - commit
   - push
   - report status in the reporting session
14. Resolve Master Chef versus Builder disputes internally through evidence, tests, and challenge loops. After 2 failed loops on the same blocker, stop the run and report deadlock.
15. If the active process dies, the watchdog resumes it. If reporting, cron, push, or repeated resume logic fails, stop and report the blocker rather than pretending the run is healthy.

Control block fields:

- `REPO`
- `MASTER_MODEL`
- `BUILDER_MODEL`
- `REPORTING_SESSION`
- `WATCHDOG_CRON_ID`
- `ACTIVE_STEP`
- `PHASE`
- `BUILDER_SESSION`
- `LAST_PROGRESS_AT_UTC`
- `LAST_HEARTBEAT_AT_UTC`
- `LAST_RESUME_AT_UTC`
- `RESTART_COUNT`
- `DISPUTE_LOOP_COUNT`
- `CURRENT_BLOCKER`

Report events:

- `START`
- `HEARTBEAT`
- `RESUME`
- `STEP_PASS`
- `STEP_BLOCKED`
- `DISPUTE_RESOLVED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

Master Chef status reports in the reporting session must include:

- `GOAL`
- `STEP`
- `PHASE`
- `CHANGES`
- `VALIDATION`
- `UAT`
- `STATUS`
- `MASTER CHEF UAT APPROVED`
- `COMMIT`
- `PUSH`
- `NEXT`

Test-only note:

- Synthetic `WATCHDOG_TICK` prompts are allowed in the harness as manual stand-ins for real cron events.
