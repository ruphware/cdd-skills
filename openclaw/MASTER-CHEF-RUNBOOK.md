# CDD Master Chef Runbook (OpenClaw-direct mode)

## 0) Purpose

Run autonomous development with one control loop:

- **Master Chef:** the current OpenClaw session
- **Builder:** an OpenClaw subagent
- **Watchdog:** a cron `systemEvent` that wakes the main session
- **Status route:** optional external updates sent directly by the main session

Design principle: **soft reasoning, hard state**.

- Keep planning, review, QA, and blocker judgment LLM-driven.
- Keep runtime state, leases, logs, events, and recovery thresholds explicit and durable.

This runbook intentionally does **not** use ACP, isolated watchdog agents, or cross-session recovery logic.

---

## 1) Actor model

### Master Chef

The main session owns:

- repo inspection
- next-step selection
- runtime initialization
- Builder spawn, replacement, and review
- QA gate and step-level UAT approval
- commit and push
- direct status reporting
- final summary

### Builder

The Builder is an OpenClaw subagent. It owns:

- implementing exactly one approved TODO step
- running step validation
- writing `builder.jsonl`
- returning a structured report to Master Chef

### Watchdog

The watchdog is **not** a separate agent. It is a cron wake-up into the main session.

Its job is to remind Master Chef to:

- inspect runtime state
- inspect Builder health
- steer or replace a stale Builder
- send heartbeat or blocker reports when needed

### Human

The human owns:

- model selection for the main session
- Builder model/thinking selection
- kickoff approval
- final review
- intervention when Master Chef reports a blocker or deadlock

---

## 2) Startup prerequisites

Before `/cdd-master-chef` is used:

1. The repo must already contain:
   - `AGENTS.md`
   - `README.md`
   - `TODO.md` or `TODO-*.md`
2. The current session should already be using the chosen Master Chef model.
3. The Builder model and thinking level must be known before kickoff.
4. The repo must have a pushable upstream.
5. Confirm:
   - `control_route`: the current session
   - `status_route`: optional external route, such as Slack
   - `status_route_policy`: `best_effort` or `required`

If the repo is not CDD-ready, stop and route the user back to the core CDD workflow.

If upstream is missing, do not start autonomous execution.

---

## 3) Kickoff flow

On the first `/cdd-master-chef` turn:

1. Inspect repo readiness:
   - `git status --short`
   - `git branch --show-current`
   - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
2. Inspect development state:
   - active TODO file
   - last completed step
   - next runnable TODO step
   - obvious blockers in the working tree
3. Choose the next action:
   - default: next runnable TODO step
   - fallback: planning only if the TODO state is stale or ambiguous
4. Confirm:
   - Builder model
   - Builder thinking level
   - control route
   - status route and policy
5. Initialize runtime files under `.cdd-runtime/master-chef/`.
6. Ensure `.cdd-runtime/` is locally ignored.
7. Acquire the run lease in `run.lock.json`.
8. Present one kickoff approval that includes:
   - repo state summary
   - proposed next action
   - runtime initialization
   - run lease
   - one watchdog cron as a main-session `systemEvent`
   - optional direct status reporting
9. Do not create the cron job and do not spawn the Builder until the user approves kickoff.

After kickoff approval, the run becomes autonomous.

---

## 4) Runtime files

Store canonical runtime state inside the repo:

```text
.cdd-runtime/master-chef/
  run.json
  run.lock.json
  master-chef.jsonl
  builder.jsonl
  watchdog.jsonl
```

### 4.1 `run.json`

Keep it current after every material state change.

Suggested shape:

```json
{
  "run_id": "<utc-id>",
  "repo": "/abs/path/to/repo",
  "master_model": "<model>",
  "master_thinking": "xhigh",
  "builder_model": "<model>",
  "builder_thinking": "xhigh",
  "builder_runtime": "subagent",
  "master_session_key": "<main-session-key>",
  "builder_session_key": "<builder-session-key>",
  "control_route": {
    "kind": "current-session-route"
  },
  "status_route": {
    "kind": "slack|discord|telegram|none",
    "channel": "<channel>",
    "to": "<destination>"
  },
  "status_route_policy": "best_effort",
  "watchdog_job_id": "<cron-id>",
  "watchdog_mode": "main-system-event",
  "active_todo_path": "/abs/path/to/TODO.md",
  "active_step": "<exact step heading>",
  "phase": "kickoff|builder|qa|uat|commit|push|reporting|blocked|complete",
  "branch": "<branch>",
  "upstream": "<remote/ref>",
  "pre_step_head_sha": "<sha>",
  "last_pass_head_sha": "<sha>",
  "last_progress_at_utc": "<ts>",
  "last_master_log_at_utc": "<ts>",
  "last_builder_log_at_utc": "<ts>",
  "last_status_report_at_utc": "<ts>",
  "builder_restart_count": 0,
  "dispute_loop_count": 0,
  "current_blocker": ""
}
```

### 4.2 `run.lock.json`

Use the lease file only to prevent duplicate control loops and duplicate Builder spawns.

Suggested shape:

```json
{
  "run_id": "<utc-id>",
  "lease_id": "<lease-id>",
  "owner_session_key": "<main-session-key>",
  "builder_session_key": "<builder-session-key>",
  "repo": "/abs/path/to/repo",
  "started_at_utc": "<ts>",
  "last_renewed_at_utc": "<ts>",
  "generation": 1
}
```

Rules:

- renew the lease whenever progress happens
- renew the lease whenever the Builder is replaced
- do not start a second autonomous run while a coherent active lease exists

### 4.3 JSONL logs

Use JSONL logs so the main session can reason over durable evidence.

Required fields per line:

- `ts`
- `actor`
- `event`
- `run_id`
- `repo`
- `step`
- `phase`
- `status`
- `summary`
- `session_key`

Optional fields:

- `command`
- `validation`
- `validation_class`
- `evidence`
- `commit`
- `push`
- `blocker`
- `route`

---

## 5) Builder runtime

Use an OpenClaw subagent as the Builder.

Default spawn shape:

- `runtime: "subagent"`
- explicit `model`
- explicit `thinking`
- `cwd: <repo>`
- normally `mode: "run"`

Why `run` by default:

- one step at a time
- simpler lifecycle
- easier replacement
- fewer stale-session edge cases

Use a long-lived Builder session only when the repo or task genuinely needs persistent Builder context.

### 5.1 Builder contract

The Builder must:

- implement exactly one approved TODO step
- avoid scope creep
- avoid commit/push
- update only the selected TODO step when the step passes
- write `builder.jsonl`
- return a structured report with evidence, validation, UAT, and risks

---

## 6) Standard autonomous loop

After kickoff approval:

1. Initialize or refresh runtime files.
2. Write `run.json` and `run.lock.json`.
3. Create the watchdog cron as a main-session `systemEvent`.
4. Spawn the Builder subagent for the selected step.
5. Record the Builder session key in runtime state.
6. Let the Builder work.
7. Review the Builder report.
8. Run Master Chef QA and step-level UAT.
9. If the step passes:
   - commit
   - push
   - update runtime state
   - send full detail to control route
   - send concise direct status update if configured
10. Re-inspect TODO state.
11. If another runnable step exists, continue automatically.
12. If no runnable step remains, report `RUN_COMPLETE`.

Only stop autonomy when:

- the run is complete
- a hard blocker requires human input
- repeated Builder replacements fail without progress
- the user stops the run

---

## 7) Watchdog cron

Use one recurring cron job:

- cadence: every 5 minutes
- `sessionTarget: "main"`
- `payload.kind: "systemEvent"`
- delivery: none

The cron job does not report on its own. It only wakes the main session.

Example shape:

```json
{
  "name": "cdd-master-chef-watchdog:<repo>",
  "schedule": { "kind": "every", "everyMs": 300000 },
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Reminder: run the cdd-master-chef watchdog tick for <repo>. Check run.json, run.lock.json, Builder health, and runtime logs. If healthy, stay quiet. If stale, steer or replace the Builder and report only if needed."
  },
  "delivery": { "mode": "none" }
}
```

Remove the job when the run completes, blocks permanently, or is cancelled.

---

## 8) Watchdog tick policy

When the systemEvent fires, the **main session** should:

1. Read:
   - `run.json`
   - `run.lock.json`
   - `master-chef.jsonl`
   - `builder.jsonl`
   - `watchdog.jsonl`
2. Check:
   - active step
   - lease freshness
   - Builder session key
   - `last_progress_at_utc`
   - `last_master_log_at_utc`
   - `last_builder_log_at_utc`
   - current phase
3. Inspect Builder health using native OpenClaw subagent/session tools available to the main session.
4. If healthy:
   - record a watchdog tick when useful
   - send a `HEARTBEAT` only every ~15 minutes
5. If stale:
   - try to steer the current Builder if supported
   - otherwise replace it with a fresh Builder run for the same step
   - increment `builder_restart_count`
   - renew the lease
   - update runtime files and logs
   - send `BUILDER_RESTARTED` or `STEP_BLOCKED` if appropriate
6. If repeated replacements fail without forward progress:
   - stop the run
   - report `STEP_BLOCKED` or `DEADLOCK_STOPPED`

Default thresholds:

- Builder stale threshold: 10 minutes without Builder progress
- Heartbeat interval: 15 minutes
- Builder replacement budget before deadlock: 2 failed replacements without progress

---

## 9) Validation, QA, and UAT

Use two validation classes.

### `hard_gate`

Use for:

- tests
- lint/typecheck
- migrations
- push/auth/upstream checks
- repo-defined must-pass automated checks

### `soft_signal`

Use for:

- discovery greps
- file-presence scans
- coverage hints
- non-blocking heuristics

If unstaged files matter, use working-tree-aware discovery commands:

- `rg --files`
- `git ls-files --cached --others --exclude-standard`

Do not treat a discovery grep with no matches as equivalent to a failed test suite unless the step explicitly says it is a blocker.

### Step pass gate

A step is not passed unless all are true:

- diff matches the selected step
- Builder evidence is concrete
- `hard_gate` validations passed
- `soft_signal` failures were reviewed and do not hide a real blocker
- the selected TODO step was updated correctly
- step-level UAT is explicit and approved
- commit and push succeeded
- runtime files and logs reflect the new state

---

## 10) Reporting model

Use a simple dual-route model.

### Control route

The current session gets:

- kickoff summary
- Builder handoff summary
- QA/UAT verdicts
- recovery decisions
- blockers
- final summary

This route always gets full detail.

### Status route

The main session sends status updates directly to the optional external route.

Send only:

- `START`
- `HEARTBEAT`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `RUN_COMPLETE`

Keep them concise.

Do not send:

- raw log tails by default
- every Builder micro-update
- internal debate between Master Chef and Builder

If status delivery fails:

- `best_effort` -> note it in control route and continue
- `required` -> stop and report blocker

---

## 11) Failure policy

### If Builder fails or stalls

1. steer the current Builder if practical
2. otherwise replace Builder with a fresh subagent run
3. if 2 replacements fail without progress, stop the step

### If cron fails

- continue manually from the control route
- do not corrupt run ownership
- recreate cron only if needed

### If main session is interrupted

- resume manually from `run.json` and `run.lock.json`
- inspect repo diff and Builder logs
- either continue the same step or mark it blocked

The main session is the only control plane. Do not create a second control loop.

---

## 12) Event labels

Use these event labels:

- `START`
- `HEARTBEAT`
- `BUILDER_HANDOFF`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`
