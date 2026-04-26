# CDD Master Chef Runbook (OpenClaw-direct mode)

## 0) Purpose

Run autonomous development with one control loop:

- **Master Chef:** the current OpenClaw session
- **Builder:** an OpenClaw subagent
- **Reporting surface:** the current Master Chef session

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
- in-session lifecycle reporting
- final summary

### Builder

The Builder is an OpenClaw subagent. It owns:

- using the exact delegated internal `cdd-*` skill chosen by Master Chef
- implementing exactly one approved action
- running step validation
- writing `builder.jsonl`
- returning a structured report to Master Chef

One Builder run equals one approved delegated action. After that action finishes or is abandoned, Master Chef re-inspects repo state and spawns a fresh Builder run for the next delegated step.

There is no watchdog actor, cron wake-up, second control loop, or normal Builder-session resurrection path.

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

1. The target workspace must be either:
   - a repo that already contains `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`, or
   - a new/adoptable project folder that should first be brought into the CDD contract through `cdd-init-project`
2. The current session should already be using `master_model` from the chosen Run config.
3. The full Run config must be known before kickoff.
4. A pushable upstream is required before the normal autonomous commit/push loop begins.
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
   - `master_model`
   - `master_thinking`
   - `builder_model`
   - `builder_thinking`

The current Master Chef session is implicitly the control/reporting surface.

If the repo is not yet CDD-ready but the request is a legitimate new-project or adoption flow, route first through `cdd-init-project` in the main session.

If the repo is not CDD-ready and the request is not an init/adoption flow, stop and route the user back to the core CDD workflow.

If upstream is missing, do not start autonomous implementation/commit/push execution.

### 2.1 Run config

For every run, resolve one explicit block in this shape:

```text
Run config:
  master_model: gpt-5.4
  master_thinking: xhigh
  builder_model: gpt-5.4
  builder_thinking: xhigh
```

Rules:

- This block is the only place per-run model settings are set.
- The user may either paste the block directly into the kickoff prompt or let Master Chef load it from the optional local-only file described in section `2.2 Local default Run config`.
- Master Chef must not infer or merge model settings from `USER.md`, memory, repo docs, previous `.cdd-runtime/master-chef/run.json`, or earlier conventions.
- After kickoff, copy the approved values into `.cdd-runtime/master-chef/run.json`. That file is the durable mirror of the approved Run config, not a second config source.
- If the human wants different models on a given run, change only this block for that run.
- Keep shared docs and commits free of local-only operator transport details.

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
- Do not copy unrelated local-only overrides from it into repo docs, commits, or other shared artifacts.

---

## 3) Kickoff flow

On the first `/cdd-master-chef` turn:

1. Inspect repo readiness:
   - `git status --short`
   - `git branch --show-current`
   - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
2. Inspect development state:
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - obvious blockers in the working tree
   - whether the repo first needs `cdd-init-project`
3. Choose the next action and route it through the right internal skill:
   - bootstrap path: `cdd-init-project` in the main session when the user wants a new project or when the repo must adopt CDD before the normal loop can begin
   - default delegated path: next runnable TODO step handled through `cdd-implement-todo`
   - delegated exception: `cdd-index` when Master Chef explicitly wants an index refresh
   - Master Chef direct: `cdd-init-project`, `cdd-plan`, or `cdd-refactor` when the repo needs setup, plan repair, or refactor decomposition before Builder work
   - excluded by default: `cdd-audit-and-implement`, unless the process is intentionally adapted for its mixed role
4. Confirm the approved Run config:
   - `master_model`
   - `master_thinking`
   - `builder_model`
   - `builder_thinking`
5. Initialize runtime files under `.cdd-runtime/master-chef/`.
6. Ensure `.cdd-runtime/` is locally ignored.
7. Acquire the run lease in `run.lock.json`.
8. Present one kickoff approval that includes:
   - repo state summary
   - proposed next action
   - the approved Run config
   - runtime initialization
   - run lease
   - in-session reporting expectations
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
- `mode: "run"`

Why `run` for the normal flow:

- one step at a time
- simpler lifecycle
- easier replacement
- fewer stale-session edge cases

Do not use long-lived Builder sessions or session resurrection as the normal path. If exceptional manual debugging ever requires session reuse, treat it as outside the standard contract and return to fresh one-step Builder runs immediately after.

### 5.1 Builder contract

The Builder must:

- use the exact internal `cdd-*` skill chosen by Master Chef
- default to `cdd-implement-todo` for a normal approved runnable TODO step
- use `cdd-index` only when Master Chef explicitly delegates that action
- not switch itself into planning or refactor mode; if the delegated path no longer fits, return a blocker instead
- implement exactly one approved action
- end after that one approved action instead of continuing into the next TODO step
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
6. If a Builder was spawned, let it work, review the Builder report when it returns, and treat that Builder run as finished for that approved action.
7. If the Builder appears stale during an active main-session turn, inspect it directly, replace it quickly with a fresh one-step Builder run for the same step, and update runtime/log evidence immediately.
8. Run Master Chef QA and step-level UAT.
9. If Master Chef QA rejects the Builder result:
   - record the QA findings in `master-chef.jsonl`
   - either push the findings to a fresh Builder run for the same step or fix the issue directly in Master Chef
   - re-run Master Chef QA and step-level UAT before passing the step
10. If the step passes:
   - commit
   - push
   - update runtime state
   - advertise `STEP_PASS` with full detail in the current Master Chef session
11. Re-inspect TODO state.
12. If another runnable step exists, continue automatically by spawning a fresh Builder run for that next delegated action, normally via `cdd-implement-todo`.
13. If no runnable step remains, report `RUN_COMPLETE`.

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

- replace it quickly with a fresh Builder run for the same step
- increment `builder_restart_count`
- renew the lease
- update runtime files and logs
- send `BUILDER_RESTARTED` or `STEP_BLOCKED` if appropriate

Do not use Builder-session resurrection as the normal recovery path. If a Builder session died, drifted, or returned without a usable report, replace it with a fresh one-step Builder run for the same step.

If repeated replacements fail without forward progress:

- stop the run
- report `STEP_BLOCKED` or `DEADLOCK_STOPPED`

Default thresholds:

- Builder stale threshold: 5 minutes without Builder progress, evaluated only when Master Chef performs a check
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
- any Master Chef QA rejection was remediated and rechecked
- the selected TODO step was updated correctly
- step-level UAT is explicit and approved
- commit and push succeeded
- runtime files and logs reflect the new state
- `STEP_PASS` was advertised in the current Master Chef session before automatic continuation

### QA rejection path

When Master Chef rejects Builder output during QA, the step stays active and cannot be passed, committed, pushed, or advertised as `STEP_PASS`. Master Chef must preserve concrete QA findings, choose either a fresh one-step Builder run for the same step or a direct Master Chef fix, then re-run QA and UAT before the normal commit, push, `STEP_PASS`, TODO re-inspection, and automatic continuation path resumes.

---

## 10) Reporting model

Use a single in-session reporting model.

### Master Chef session

The current session gets:

- kickoff summary
- Builder handoff summary
- QA/UAT verdicts
- recovery decisions
- blockers
- final summary
- lifecycle events such as `START`, `BUILDER_RESTARTED`, `STEP_PASS`, `STEP_BLOCKED`, `BLOCKER_CLEARED`, `RUN_STOPPED`, and `RUN_COMPLETE`

Keep full operational detail here.

Do not create or persist separate route metadata fields in the shared skill docs or runtime state.

Do not send:

- raw log tails by default
- every Builder micro-update
- timer-based heartbeat updates
- internal debate between Master Chef and Builder

Runtime obligations:

- append lifecycle and recovery events to `master-chef.jsonl`
- keep `run.json` focused on run state rather than extra route metadata
- report blockers and completion clearly in the current session

---

## 11) Failure policy

### If Builder fails or stalls

1. replace Builder quickly with a fresh one-step subagent run for the same step
2. do not use session resurrection as the normal recovery path
3. if 2 replacements fail without progress, stop the step instead of limping on

### If main session is interrupted

- resume manually from `run.json` and `run.lock.json`
- inspect repo diff and Builder logs
- either continue the same step with a fresh Builder run or mark it blocked

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
