---
name: cdd-master-chef
description: Orchestrate the OpenClaw Master Chef, Builder, and Watchdog loop with ACP Codex, reporting, and CDD-first execution.
user-invocable: true
disable-model-invocation: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["codex","git"],"config":["acp.enabled"]}}}
---

# CDD Master Chef

Use this skill for the OpenClaw-driven development process described in:

- `{baseDir}/README.md`
- `{baseDir}/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. Treat this as a three-actor process:
   - Master Chef: planning, delegation, QA, step-level UAT approval, commit, push, reporting
   - Builder: ACP `codex` implementation worker for one approved step
   - Watchdog: 5-minute health checks, 15-minute heartbeat reports, resume on death, deadlock reporting
2. The Builder runtime is ACP `codex`. Do not switch harnesses unless the user explicitly changes the process contract.
3. The Builder must use the separate `cdd-*` skill pack first. Freeform/manual coding is fallback-only and must be justified with a concrete blocker.
4. Before any Builder work, establish and confirm the startup contract:
   - `REPO`
   - `REPORTING_COMMAND` as an executable path
   - `REPORTING_TARGET` as the user-selected channel or destination
   - optional `BRANCH` / `UPSTREAM` override; otherwise use the current branch and its configured upstream
5. Use this exact reporting command contract:
   - `CDD_REPORT_TARGET="<target>" CDD_REPORT_EVENT="<event>" CDD_REPORT_REPO="<repo>" CDD_REPORT_STEP="<step-or-none>" CDD_REPORT_STATUS="<status>" CDD_REPORT_BODY="<markdown>" "$REPORTING_COMMAND"`
6. Maintain an explicit control block in the chat for the active run:
   - `REPO`
   - `REPORTING_COMMAND`
   - `REPORTING_TARGET`
   - `BRANCH`
   - `UPSTREAM`
   - `ACTIVE_STEP`
   - `PHASE`
   - `BUILDER_SESSION`
   - `LAST_PROGRESS_AT_UTC`
   - `LAST_REPORT_AT_UTC`
   - `LAST_RESUME_AT_UTC`
   - `RESTART_COUNT`
   - `DISPUTE_LOOP_COUNT`
   - `CURRENT_BLOCKER`
7. Before implementation, run a preflight: verify the repo path, verify the active `TODO*.md`, run `/acp doctor`, confirm Codex is reachable, confirm the required `cdd-*` skills are available to the Builder, confirm the current branch and upstream, and prove the reporting command works with a `START` report.
8. When a Builder session is needed, use `/acp spawn codex --mode persistent --thread auto --cwd <repo>` unless the current thread is already bound to the correct repo session.
9. Keep runtime options outside this skill. Do not hardcode or invent model defaults. Inspect with `/acp status`, and change ACP or OpenClaw model settings only when the user explicitly asks or provides operator policy.
10. Delegate implementation with the Builder handoff and QA rules from `{baseDir}/MASTER-CHEF-RUNBOOK.md`.
11. Watchdog behavior is mandatory:
    - every 5 minutes, inspect the control block and process health
    - every 15 minutes, send a `HEARTBEAT` report
    - if the active process dies before the step is complete, resume it, increment `RESTART_COUNT`, and send a `RESUME` report
12. Resolve Master Chef versus Builder disputes internally through evidence, tests, and challenge loops. When resolved, send `DISPUTE_RESOLVED`. After 2 failed challenge loops on the same blocker, or repeated death/resume without progress, stop the step and send `DEADLOCK_STOPPED`.
13. Every passed step, including planning or TODO-edit steps, ends with Master Chef step-level UAT approval, commit, push, and a status report that explicitly says `Master Chef UAT approved`.
14. If ACP permissions, reporting failures, missing prerequisites, push failures, or deadlocks block execution, stop and report the blocker with the smallest concrete recovery step.
15. Humans own product intent, reporting-channel selection, and final overall ship/no-ship.

When operating:

- If the work is not yet an approved TODO step, have the Builder run `cdd-index` if needed and then `cdd-plan` in draft mode first.
- If a step is approved, have the Builder run `cdd-implement-todo` for exactly that step.
- Keep the Builder scoped to the selected step only.
- External report events are:
  - `START`
  - `HEARTBEAT`
  - `RESUME`
  - `STEP_PASS`
  - `STEP_BLOCKED`
  - `DISPUTE_RESOLVED`
  - `DEADLOCK_STOPPED`
- Master Chef reports in chat and to the reporting channel with:
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

If a report cannot be delivered, retry once. If reporting still fails, stop unattended progress and report the failure in chat as `STEP_BLOCKED`.
