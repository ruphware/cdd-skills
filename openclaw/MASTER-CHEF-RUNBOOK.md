# CDD Master Chef Runbook (OpenClaw-direct mode)

## 0) Purpose

Run autonomous development with one control loop:

- **Master Chef:** the current OpenClaw session
- **Builder:** an OpenClaw subagent
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
- choosing the skill-routing path
- next-step selection
- runtime initialization
- direct use of planning-oriented `cdd-*` skills when needed
- Builder spawn, replacement, and review
- direct Builder health checks when the session is active
- QA gate and step-level UAT approval
- commit and push
- direct status reporting
- final summary

### Builder

The Builder is an OpenClaw subagent. It owns:

- using the exact delegated internal `cdd-*` skill chosen by Master Chef
- implementing exactly one approved action
- running step validation
- writing `builder.jsonl`
- returning a structured report to Master Chef

There is no watchdog actor, cron wake-up, or second control loop.

If a Builder needs inspection, recovery, or reporting, Master Chef handles it directly in the main session while already active.

### Human

The human owns:

- the per-run Run config
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
2. The current session should already be using `master_model` from the chosen Run config.
3. The full Run config must be known before kickoff.
4. The repo must have a pushable upstream.
5. The OpenClaw shared skills install must already contain the internal skill pack Master Chef may route through, including:
   - `~/.openclaw/skills/cdd-master-chef`
   - `~/.openclaw/skills/cdd-boot`
   - `~/.openclaw/skills/cdd-maintain`
   - `~/.openclaw/skills/cdd-init-project`
   - `~/.openclaw/skills/cdd-plan`
   - `~/.openclaw/skills/cdd-implement-todo`
   - `~/.openclaw/skills/cdd-index`
   - `~/.openclaw/skills/cdd-refactor`
   - optional / mixed-role installs such as `cdd-audit-and-implement`
6. Confirm the Run config includes:
   - `control_route`: normally `current-session`
   - `status_route`: the standard default is the placeholder Telegram route shown in the example Run config below, unless changed for the run
   - `status_route_policy`: `best_effort` or `required`

If the repo is not CDD-ready, stop and route the user back to the core CDD workflow.

If upstream is missing, do not start autonomous execution.

### 2.1 Run config

For every run, resolve one explicit block in this shape:

```text
Run config:
  master_model: gpt-5.4
  master_thinking: xhigh
  builder_model: gpt-5.4
  builder_thinking: xhigh
  control_route: current-session
  status_route:
    kind: telegram
    channel: "<telegram-chat-title>"
    to: "<telegram-chat-id>"
    topic_id: <telegram-topic-id>
  status_route_policy: best_effort
```

Rules:

- This block is the only place per-run model and route settings are set.
- The user may either paste the block directly into the kickoff prompt or let Master Chef load it from the optional local-only file described in section `2.2 Local default Run config`.
- Master Chef must not infer or merge model or route settings from `USER.md`, memory, repo docs, previous `.cdd-runtime/master-chef/run.json`, or earlier conventions.
- After kickoff, copy the approved values into `.cdd-runtime/master-chef/run.json`. That file is the durable mirror of the approved Run config, not a second config source.
- If the human wants different models or a different reporting destination on a given run, change only this block for that run.
- Keep placeholder examples in shared docs. Real local route identifiers belong only in the local config file or the live prompt for that run.

### 2.2 Local default Run config

Optional local-only convenience path:

```text
~/.openclaw/config/master-chef/default-run-config.yaml
```

Resolution order:

1. If the kickoff prompt includes `Run config`, use that.
2. Otherwise, if the local default file exists, read it and show the resolved config back to the human before kickoff.
3. Otherwise, stop and ask the human for a Run config.

Privacy rule:

- Treat `~/.openclaw/config/master-chef/default-run-config.yaml` as local operator config.
- Do not copy raw ids, handles, channel names, or topic ids from it into repo docs, commits, or other shared artifacts.

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
3. Choose the next action and route it through the right internal skill:
   - default delegated path: next runnable TODO step handled through `cdd-implement-todo`
   - delegated exception: `cdd-index` when Master Chef explicitly wants an index refresh
   - Master Chef direct: `cdd-init-project`, `cdd-plan`, or `cdd-refactor` when the repo needs setup, plan repair, or refactor decomposition before Builder work
   - excluded by default: `cdd-audit-and-implement`, unless the process is intentionally adapted for its mixed role
4. Confirm the approved Run config:
   - `master_model`
   - `master_thinking`
   - `builder_model`
   - `builder_thinking`
   - `control_route`
   - `status_route`
   - `status_route_policy`
5. Initialize runtime files under `.cdd-runtime/master-chef/`.
6. Ensure `.cdd-runtime/` is locally ignored.
7. Acquire the run lease in `run.lock.json`.
8. Present one kickoff approval that includes:
   - repo state summary
   - proposed next action
   - the approved Run config
   - runtime initialization
   - run lease
   - optional direct status reporting
9. Do not spawn the Builder until the user approves kickoff.

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
    "channel": "<channel-or-chat-name>",
    "to": "<destination-id-or-handle>",
    "topic_id": "<telegram-topic-id>"
  },
  "status_route_policy": "best_effort",
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

The Builder relies on the shared OpenClaw `cdd-*` skills that are installed into
`~/.openclaw/skills` by `./scripts/install-openclaw.sh`. Those are OpenClaw-ready
internal variants generated from the canonical repo skill pack in `skills/`.

### 5.0 Routing model

Master Chef chooses the routing path.

**Builder delegated by default:**

- `cdd-implement-todo` — normal path for one approved runnable TODO step
- `cdd-index` — allowed when Master Chef explicitly wants an index refresh as the delegated action

**Manual / non-routed helper:**

- `cdd-boot` — best-effort vanilla `AGENTS.md` boot for direct human-driven work; installed in the shared pack but not part of the normal Master Chef routing flow
- `cdd-maintain` — archive cleanup, support-doc drift review, and repo doctoring helper for direct human-driven work; installed in the shared pack but not part of the normal Master Chef routing flow

**Master Chef direct:**

- `cdd-init-project`
- `cdd-plan`
- `cdd-refactor`

**Excluded from the normal flow:**

- `cdd-audit-and-implement` — avoid by default because it mixes roles in a way that conflicts with the clean Master Chef / Builder split

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

- use the exact internal `cdd-*` skill chosen by Master Chef
- default to `cdd-implement-todo` for a normal approved runnable TODO step
- use `cdd-index` only when Master Chef explicitly delegates that action
- not switch itself into planning or refactor mode; if the delegated path no longer fits, return a blocker instead
- implement exactly one approved action
- avoid scope creep
- avoid commit/push
- update only the selected TODO step when the step passes
- write `builder.jsonl`
- return a structured report with evidence, validation, UAT, risks, the exact delegated skill path used, and the exact TODO file/step it updated

---

## 6) Standard autonomous loop

After kickoff approval:

1. Initialize or refresh runtime files.
2. Write `run.json` and `run.lock.json`.
3. If the chosen action is Builder-delegated, spawn the Builder subagent with an explicit handoff that names the delegated internal skill path.
4. If the chosen action is Master-Chef-direct (`cdd-init-project`, `cdd-plan`, or `cdd-refactor`), run it in the main session before any Builder spawn.
5. Record the Builder session key in runtime state when a Builder is used.
6. If a Builder was spawned, let it work and then review the Builder report when it returns.
7. If the Builder appears stale during an active main-session turn, inspect it directly, steer or replace it in-session, and update runtime/log evidence immediately.
8. Run Master Chef QA and step-level UAT.
9. If the step passes:
   - commit
   - push
   - update runtime state
   - send full detail to control route
   - attempt concise direct status delivery if a `status_route` is configured
   - update `last_status_report_at_utc` if status delivery succeeds
10. Re-inspect TODO state.
11. If another runnable step exists, continue automatically.
12. If no runnable step remains, report `RUN_COMPLETE`.

Only stop autonomy when:

- the run is complete
- a hard blocker requires human input
- repeated Builder replacements fail without progress
- the user stops the run

---

## 7) Direct Builder check policy

There is no watchdog cron.

Master Chef checks Builder health directly in the main session when one of these is true:

1. the Builder just returned and its result needs review
2. the human asks for status, continuation, or stop
3. Master Chef is already active in the session and wants to inspect a long-running Builder before waiting again

When checking Builder health, read:

- `run.json`
- `run.lock.json`
- `master-chef.jsonl`
- `builder.jsonl`

Then inspect:

- active step
- lease freshness
- Builder session key
- `last_progress_at_utc`
- `last_master_log_at_utc`
- `last_builder_log_at_utc`
- current phase
- current Builder session status via native OpenClaw subagent/session tools

If healthy:

- keep the current Builder
- update runtime/log evidence only when that check adds meaningful operational value
- do not invent timer-based heartbeat chatter

If stale:

- try to steer the current Builder if supported
- otherwise replace it with a fresh Builder run for the same step
- increment `builder_restart_count`
- renew the lease
- update runtime files and logs
- send `BUILDER_RESTARTED` or `STEP_BLOCKED` if appropriate

If repeated replacements fail without forward progress:

- stop the run
- report `STEP_BLOCKED` or `DEADLOCK_STOPPED`

Default thresholds:

- Builder stale threshold: 10 minutes without Builder progress, evaluated only when Master Chef performs a check
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
- the delegated skill path was appropriate and evidenced clearly
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
A configured `status_route` means Master Chef must attempt direct delivery for key lifecycle events; control-route messages do not satisfy this requirement.

Attempt delivery for:

- `START`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `RUN_COMPLETE`

Keep them concise.

Do not send:

- raw log tails by default
- every Builder micro-update
- timer-based heartbeat updates
- internal debate between Master Chef and Builder

Runtime obligations:

- on successful status delivery, update `last_status_report_at_utc`
- on failed status delivery, append `STATUS_DELIVERY_FAILED` to `master-chef.jsonl`
- record the failed event label, route target, policy, and a short error summary when possible

If status delivery fails:

- `best_effort` -> attempt once, record `STATUS_DELIVERY_FAILED`, note it in control route, and continue
- `required` -> attempt once, record `STATUS_DELIVERY_FAILED`, stop the run, and report blocker

---

## 11) Failure policy

### If Builder fails or stalls

1. steer the current Builder if practical
2. otherwise replace Builder with a fresh subagent run
3. if 2 replacements fail without progress, stop the step

### If main session is interrupted

- resume manually from `run.json` and `run.lock.json`
- inspect repo diff and Builder logs
- either continue the same step or mark it blocked

The main session is the only control plane. Do not create a second control loop.

---

## 12) Event labels

Use these event labels:

- `START`
- `BUILDER_HANDOFF`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`
- `STATUS_DELIVERY_FAILED`
