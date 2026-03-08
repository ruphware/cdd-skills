# CDD Master Chef Runbook (OpenClaw + ACP Codex + isolated LLM watchdog + CDD-first)

## 0) Purpose

Run autonomous development as an upgrade on top of the core CDD Builder workflow.

Design principle: **Soft reasoning, hard state.**

- Keep repo understanding, QA judgment, dispute resolution, and UAT reasoning LLM-driven.
- Keep runtime state, route selection, logs, leases, event labels, and recovery thresholds explicit and durable.

Actor model:

- **OpenClaw (Master Chef):** inspects repo state, selects the next action, drives the Builder, approves step-level UAT, commits, pushes, and reports status
- **ACP Codex (Builder):** primary Builder path; executes repo work for one approved step at a time
- **OpenClaw isolated cron (Watchdog):** runs every 5 minutes as a separate LLM supervisor turn, reads durable run state plus actor logs, probes Master Chef health, and restores the run if needed
- **Human:** selects models, confirms kickoff, selects routes, and mainly reviews final results or critical blockers

This runbook assumes the repo already has the CDD boilerplate and the core `cdd-*` skills are installed.

---

## 1) Two skill blocks

Keep the distinction explicit:

- **Core CDD Skills** are the primary single-agent workflow:
  - one coding agent
  - human in the loop for approvals and acceptance
  - direct use of `cdd-plan`, `cdd-implement-todo`, `cdd-index`, and related skills
- **CDD Master Chef** is the OpenClaw upgrade:
  - the human approves the kickoff once
  - Master Chef then drives the Builder across TODO steps autonomously
  - Watchdog supervises both Master Chef and Builder
  - the human mainly reviews final results, blockers, or deadlocks

Never use Master Chef to paper over a repo that is not already CDD-ready.

---

## 2) Startup prerequisites

Before `/cdd-master-chef` is invoked:

1. The user must select the Master Chef model with a standalone directive:
   - `/model <master-model>`
2. The user must select the Builder model with a standalone directive:
   - `/acp model <builder-model>`
3. The target repo must already contain the CDD boilerplate:
   - `AGENTS.md`
   - `README.md`
   - `TODO.md` or `TODO-*.md`
4. The user must confirm the reporting model:
   - `control_route`: the operator-facing route, normally the current TUI/OpenClaw session if explicitly accepted
   - `status_route`: optional condensed reporting route, for example Slack
5. Session tools must be visible enough for an isolated watchdog turn to reach the active Master Chef session:
   - `tools.sessions.visibility` should be `agent` or `all`
   - if sandboxing is enabled, `agents.defaults.sandbox.sessionToolsVisibility` must preserve enough reach to probe and send into the active session

If model selection has not been made explicitly, stop and ask the user to run the directives first. Do not pick models on the user's behalf.

If the repo is not CDD-ready, stop and route the user back to the core CDD workflow or `cdd-init-project`.

If session-tool visibility is too narrow for cross-session supervision, do not start the autonomous run.

---

## 3) Kickoff flow

On the first `/cdd-master-chef` turn:

1. Verify model selection and environment:
   - `/model status`
   - `/acp status`
   - `/acp doctor`
2. Verify repo readiness:
   - `AGENTS.md` exists
   - `README.md` exists
   - one active TODO file exists
   - `git status --short`
   - `git branch --show-current`
3. Verify pushability:
   - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
4. Inspect where development is at:
   - current branch and upstream
   - active TODO file
   - last completed step
   - next runnable TODO step
   - any obvious blockers in the working tree
5. Choose the next action:
   - default: the next runnable TODO step via `cdd-implement-todo`
   - fallback: `cdd-plan` only when the TODO state is stale, ambiguous, or not executable
6. Confirm routes:
   - `control_route`: default to the current session only if the user explicitly accepts it
   - `status_route`: capture the exact route and delivery policy:
     - `best_effort`
     - `required`
7. Initialize the runtime path:
   - `.cdd-runtime/master-chef/run.json`
   - `.cdd-runtime/master-chef/run.lock.json`
   - `.cdd-runtime/master-chef/master-chef.jsonl`
   - `.cdd-runtime/master-chef/builder.jsonl`
   - `.cdd-runtime/master-chef/watchdog.jsonl`
8. Ensure `.cdd-runtime/` is ignored locally before autonomous work starts:
   - prefer `.git/info/exclude`
   - do not commit runtime files
9. Acquire a run lease before autonomous execution:
   - create `run.lock.json`
   - assign `run_id`
   - assign `run_lease_id`
   - record the owning Master Chef session key
10. Present one kickoff approval that includes:
   - repo state summary
   - proposed next action
   - selected `control_route`
   - selected `status_route` plus delivery policy
   - runtime-state initialization
   - run lease / duplicate-run protection
   - creation of the 5-minute isolated watchdog cron
11. Do not create the cron job and do not start implementation until the user confirms the kickoff.

After kickoff approval, the run becomes autonomous.

---

## 4) Roles and ownership

**Master Chef owns:**

- repo inspection and next-step selection
- kickoff proposal quality
- Builder handoff quality
- updating `run.json` after each material state change
- renewing the run lease while healthy
- writing Master Chef runtime logs
- QA gate and step-level UAT approval
- commit, push, and status reporting after each passed step
- autonomous progression to subsequent TODO steps
- final results summary

**Builder owns:**

- code changes for one approved step
- running checks with command evidence
- writing Builder runtime logs
- reporting exact `cdd-*` usage and blockers
- defending technical choices with concrete evidence when challenged

**Watchdog owns:**

- reading `run.json`, `run.lock.json`, and actor logs every 5 minutes
- probing Master Chef health before taking recovery action
- nudging a healthy Master Chef to resume a stale Builder
- restarting a stale or dead Master Chef from durable run state
- writing Watchdog runtime logs
- sending heartbeat and recovery updates through the configured reporting model

**Human owns:**

- model selection
- kickoff approval
- route selection
- final review of results
- intervention only when Master Chef reports a blocker or deadlock

---

## 5) Runtime state and logs

Do not keep the canonical run state only in chat history. Use the target repo runtime path:

```text
.cdd-runtime/master-chef/
  run.json
  run.lock.json
  master-chef.jsonl
  builder.jsonl
  watchdog.jsonl
```

### 5.1 `run.json`

This file is the canonical restart snapshot. Keep it current after every material state change:

```json
{
  "run_id": "<utc-id>",
  "repo": "/abs/path/to/repo",
  "master_model": "<selected-master-model>",
  "builder_model": "<selected-builder-model>",
  "master_session_key": "<session-key>",
  "control_route": {
    "kind": "current-session-route",
    "channel": "<channel>",
    "to": "<destination>",
    "account_id": "<optional>"
  },
  "status_route": {
    "kind": "slack|discord|telegram|none",
    "channel": "<channel>",
    "to": "<destination>"
  },
  "status_route_policy": "best_effort",
  "watchdog_job_id": "<cron-id>",
  "run_lease_id": "<lease-id>",
  "active_todo_path": "/abs/path/to/TODO.md",
  "active_step": "<exact step heading>",
  "phase": "<kickoff|builder|qa|uat|commit|push|reporting|blocked|complete>",
  "builder_session_ref": "<acp session/thread ref>",
  "branch": "<branch>",
  "upstream": "<remote/ref>",
  "pre_step_head_sha": "<sha>",
  "last_pass_head_sha": "<sha>",
  "last_progress_at_utc": "<ts>",
  "last_master_log_at_utc": "<ts>",
  "last_builder_log_at_utc": "<ts>",
  "last_control_report_at_utc": "<ts>",
  "last_status_report_at_utc": "<ts>",
  "master_restart_count": 0,
  "builder_restart_count": 0,
  "dispute_loop_count": 0,
  "current_blocker": ""
}
```

### 5.2 `run.lock.json`

This file prevents duplicate autonomous runs:

```json
{
  "run_id": "<utc-id>",
  "lease_id": "<lease-id>",
  "owner_session_key": "<master-session-key>",
  "owner_model": "<master-model>",
  "repo": "/abs/path/to/repo",
  "started_at_utc": "<ts>",
  "last_renewed_at_utc": "<ts>",
  "generation": 1
}
```

Rules:

- the active Master Chef renews the lease whenever material progress happens
- the watchdog may only replace the lease during a bounded recovery after probe failure
- no second autonomous run may start while a coherent active lease exists

### 5.3 JSONL actor logs

All three actors write JSONL so the watchdog can process them deterministically.

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

Optional fields when relevant:

- `command`
- `validation`
- `validation_class`
- `evidence`
- `commit`
- `push`
- `blocker`
- `route`

### 5.4 Minimum logging cadence

**Master Chef must log at:**

- kickoff start
- kickoff approval
- Builder handoff
- Builder result received
- QA start/result
- UAT approval
- commit start/result
- push start/result
- each status report
- each dispute loop
- run completion or stop

**Builder must log at:**

- step start
- each `cdd-*` invocation
- validation start/result
- blocker
- handoff back to Master Chef

**Watchdog must log at:**

- tick start
- deterministic state summary
- probe start/result
- Builder stale detection
- Master Chef stale detection
- restart/resume decision
- each report sent

---

## 6) Builder skill map

The Builder should use these CDD skills by default:

- `cdd-init-project` — bootstrap or adopt CDD for a repo
- `cdd-plan` — convert scope into approval-ready TODO edits
- `cdd-implement-todo` — implement exactly one approved TODO step
- `cdd-index` — refresh architecture or index context
- `cdd-audit-and-implement` — turn audit findings into TODOs and implement the first step
- `cdd-refactor` — build a refactor TODO plan from the current index

### 6.1 CDD-first execution rule

- If a matching `cdd-*` skill exists for the current phase, use it first.
- Do not bypass to freeform/manual coding unless:
  1. the skill is missing or broken, or
  2. the skill cannot express the approved step
- If bypass is needed, Builder must stop and report a precise blocker plus the smallest workable fallback.

### 6.2 ACP Codex is the primary Builder path

- Use ACP Codex persistent thread mode by default.
- Use direct local Codex CLI only as break-glass fallback when ACP is unavailable or explicitly approved.
- Log any fallback clearly in `builder.jsonl` with blocker and rationale.

---

## 7) Standard autonomous loop

After the kickoff approval:

1. Create or refresh `.cdd-runtime/master-chef/`.
2. Write `run.json` with selected models, routes, branch/upstream, active step, and session references.
3. Acquire and record the active lease in `run.lock.json`.
4. Create the isolated watchdog cron and record its id.
5. Spawn or reuse the Builder session:
   - `/acp spawn codex --mode persistent --thread auto --cwd <repo>`
6. Hand the selected step to the Builder.
7. Require the Builder to write logs while working.
8. Collect the Builder report: diff summary, checks, risks, blockers, and exact `cdd-*` command evidence.
9. Run the Master Chef QA gate.
10. Run step-level UAT internally from repo state plus Builder evidence.
11. If the step passes:
    - commit
    - push
    - report full detail to `control_route`
    - report condensed summary to `status_route` if configured
12. Re-inspect the TODO state.
13. If another runnable step exists, continue automatically without a new human approval.
14. If no runnable step remains and the autonomous scope is complete, send final results and report `RUN_COMPLETE`.

Only stop autonomy when:

- the run is complete
- a hard blocker requires human input
- a deadlock is declared
- cron, control-route delivery, or push behavior fails in a way that makes unattended progress unsafe

---

## 8) Builder handoff template

Use this every time:

```text
You are the Builder. Execute exactly one approved TODO step.

REPO:
- <path>

STEP:
- <exact Step NN - Title heading>

RUNTIME LOG PATH:
- .cdd-runtime/master-chef/builder.jsonl

MANDATORY CONTEXT (read first):
- AGENTS.md
- README.md
- the active TODO file(s): TODO.md / TODO-*.md
- docs/specs/prd.md and docs/specs/blueprint.md (if present)
- docs/JOURNAL.md (skim top)
- docs/INDEX.md (if present)

CONSTRAINTS:
- Implement only this step; no scope creep
- Keep the patch minimal
- Preserve existing behavior unless the step says otherwise
- Use CDD skill-first execution:
  - planning work -> cdd-plan
  - step implementation -> cdd-implement-todo
  - indexing, audit, refactor -> matching cdd-* skill
- ACP Codex is the primary Builder path
- If a required cdd skill is missing, broken, or insufficient, STOP and report one precise blocker
- Do not commit or push; Master Chef owns commit, push, and reporting
- Write JSONL log lines for step start, each cdd invocation, validation start/result, blocker, and completion
- If the step passes, update only the selected step in the active `TODO*.md` file to mark its task items done before handing control back:
  - existing checkbox tasks -> `[x]`
  - plain task bullets -> checked markdown checkboxes
  - do not add a new step-level status field
  - do not touch future or unrelated steps
- If Master Chef challenges a claim, answer with exact files, commands, outputs, and rationale

VALIDATION:
- Run the step-listed automated checks, plus any stricter AGENTS.md checks
- Classify each validation item as either:
  - `hard_gate` -> failure blocks the step
  - `soft_signal` -> failure informs review but does not alone justify a step fail unless explicitly required
- Prefer working-tree-aware discovery checks when unstaged files matter:
  - `rg --files`
  - `git ls-files --cached --others --exclude-standard`
- Do not treat a discovery grep with no matches as equivalent to a failed test suite unless the step explicitly defines it as a hard gate
- Include exact cdd commands and exact validation commands

DELIVERABLE:
- Report using the repo AGENTS.md "Output Format Per Turn"
- Include command evidence for cdd usage and validation
- Include a short UAT checklist and a suggested commit message

When fully done, end with:
DONE_BUILDER: <short summary>
```

---

## 9) Watchdog cron

Use one recurring OpenClaw cron job:

- cadence: every 5 minutes
- target: isolated session
- payload: agent turn, not a main-session system event
- model: the Master Chef model captured at kickoff time
- delivery: prefer route-aware reporting logic inside the watchdog turn itself

The watchdog is an isolated LLM supervisor, not a shell loop.

Operating envelope:

- inspect structured runtime state, recent logs, and Master Chef session health
- do bounded agent-like probes into the Master Chef session
- resume or rehydrate only within the defined recovery policy
- never become a second planner, second Builder, or independent run owner

Preferred behavior:

- use the gateway `cron.add` tool when available
- otherwise use the documented CLI equivalent
- prefer cron delivery `none` when the watchdog itself handles dual-route reporting
- if only one delivery target is available, prioritize `control_route`

Canonical shape:

```json
{
  "name": "cdd-master-chef-watchdog:<repo>",
  "schedule": { "kind": "every", "everyMs": 300000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "text": "Run the cdd-master-chef watchdog tick for <repo> using .cdd-runtime/master-chef/run.json, run.lock.json, and actor logs. Apply deterministic checks first, then probe Master Chef if needed. Return HEARTBEAT_OK if no report is needed."
  },
  "model": "<selected-master-model>",
  "wakeMode": "now",
  "deleteAfterRun": false,
  "delivery": {
    "mode": "none"
  }
}
```

Record the returned cron id in `watchdog_job_id`.

On completion, blocker, cancellation, or deadlock, remove the job:

```bash
openclaw cron rm <job-id>
```

---

## 10) Watchdog policy

On each 5-minute watchdog tick:

1. Read `.cdd-runtime/master-chef/run.json`.
2. Read `.cdd-runtime/master-chef/run.lock.json`.
3. Read the last lines of:
   - `master-chef.jsonl`
   - `builder.jsonl`
   - `watchdog.jsonl`
4. If no active step exists and the run is complete or stopped, do nothing except confirm the cron should be removed.
5. If an active run exists, compare:
   - `last_progress_at_utc`
   - `last_master_log_at_utc`
   - `last_builder_log_at_utc`
   - `last_control_report_at_utc`
   - current phase
   - lease freshness
6. Run deterministic checks first:
   - does `run_id` match the lease file?
   - is the lease still fresh?
   - is the expected Master Chef session key present?
   - is the Builder session ref present when phase implies Builder work?
   - did progress timestamps move since the last watchdog judgment?
7. If deterministic checks look suspicious, probe Master Chef with a compact status request:
   - current step
   - current phase
   - Builder health
   - last progress
   - next action
8. If the probe succeeds and the state is coherent, treat Master Chef as healthy.
9. If Builder logs are stale while Master Chef is healthy:
   - send a targeted instruction into the Master Chef session to inspect and resume Builder
   - increment `builder_restart_count` only when Builder is actually resumed
   - report `BUILDER_RESUMED` once the resume is confirmed
10. If Master Chef logs are stale or the probe fails:
   - attempt one bounded recovery by replacing the lease generation and sending a rehydration prompt to `master_session_key`
   - the recovery prompt must tell Master Chef to reload `run.json`, `run.lock.json`, inspect actor logs, continue the same step, and avoid creating a second autonomous run
   - if recovery succeeds, increment `master_restart_count` and report `MASTER_CHEF_RESTARTED`
11. If 15 minutes have elapsed since the last status-route report, send `HEARTBEAT`.

### 10.1 Probe rule

Do not restart Master Chef without probing first unless the session key is missing and the current run is clearly stale.

### 10.2 Staleness thresholds

Default thresholds unless the repo or run overrides them explicitly:

- Builder phase stale threshold: 10 minutes without Builder-log movement
- Master Chef phase stale threshold: 10 minutes without Master-Chef-log movement during active work
- Report heartbeat interval: 15 minutes
- Recovery cooldown after a restart/resume: 5 minutes
- Master Chef restart budget before deadlock: 2 failed recoveries without forward progress
- Builder resume budget before deadlock: 2 resumes without forward progress

### 10.3 Deadlock rules

Declare `DEADLOCK_STOPPED` and stop the run when any of these are true:

- the same Builder phase needed 2 resumes without forward movement in `last_progress_at_utc`
- Master Chef needed 2 recoveries without forward movement in `last_progress_at_utc`
- the same blocker survived 2 full dispute loops
- cron or control-route behavior is broken enough that unattended supervision is no longer trustworthy

If `status_route` delivery fails:

- if policy is `best_effort`, log it, report degradation in `control_route`, and continue
- if policy is `required`, stop the run and report the blocker

---

## 11) QA, validation classes, UAT, commit, and push gate

A step is not passed unless all are true:

- [ ] Diff matches the selected step only
- [ ] Appropriate `cdd-*` skill was used, or the approved exception is documented
- [ ] Automated checks executed and classified correctly
- [ ] All `hard_gate` validations passed, or failure is explicitly justified and approved
- [ ] `soft_signal` failures were reviewed and do not hide a real blocker
- [ ] No unexplained file changes
- [ ] The selected step's task items in the active `TODO*.md` are marked done, and unrelated steps were not changed
- [ ] PRD, Blueprint, TODO, JOURNAL, and INDEX consistency was preserved when required by repo contract
- [ ] Builder evidence is concrete enough to challenge and retest
- [ ] Master Chef step-level UAT is clear, runnable, and explicitly approved
- [ ] Commit was created on the configured branch
- [ ] Push to the configured upstream succeeded
- [ ] Actor logs, lease, and `run.json` reflect the final step state
- [ ] Reports were sent using the configured route policy

### 11.1 Validation class guidance

Use `hard_gate` for:

- tests
- lint/typecheck
- migrations
- repo-defined must-pass automated checks
- push/auth/upstream checks

Use `soft_signal` for:

- discovery greps
- coverage hints
- file-presence sanity scans when unstaged files may exist
- non-blocking heuristics

If a step wants a discovery check to be a true blocker, the step text must make that explicit.

---

## 12) Reporting model

Use a dual-route reporting model.

### 12.1 Control route

The `control_route` is the operator-facing route, usually the TUI/OpenClaw session where Master Chef was launched.

Send to `control_route`:

- kickoff summary
- Builder handoff summary
- QA and UAT verdicts
- recovery reasoning
- blockers and deadlocks
- final summary
- any degraded status-route notices

This route gets full operational detail.

### 12.2 Status route

The `status_route` is an optional condensed progress route, for example Slack.

Send to `status_route`:

- `START`
- `HEARTBEAT`
- `STEP_PASS`
- `STEP_BLOCKED`
- `MASTER_CHEF_RESTARTED`
- `BUILDER_RESUMED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

This route gets concise summaries only.

Do not send to `status_route` by default:

- raw log tails
- every Builder micro-update
- internal dispute back-and-forth
- long validation transcripts unless failure context requires it

### 12.3 Report fields

Include in normal reports:

- **EVENT**
- **STEP**
- **PHASE**
- **MASTER_CHEF_STATUS**
- **BUILDER_STATUS**
- **LAST_PROGRESS**
- **CHANGES**
- **VALIDATION**
- **BLOCKERS**
- **RESTART_COUNTS**
- **NEXT**

`STEP_PASS` must also include:

- **MASTER CHEF UAT APPROVED**
- **COMMIT**
- **PUSH**

`RUN_COMPLETE` must include:

- completed steps summary
- final branch / head commit
- remaining TODO items, if any
- known risks
- exact final review actions for the human

---

## 13) Dispute and deadlock policy

Disputes between Master Chef and Builder must be resolved internally first.

Use this loop:

1. Master Chef states the exact disputed claim or design choice.
2. Builder responds with concrete evidence, commands, and reasoning.
3. Master Chef challenges weak assumptions, requests re-tests, or proposes a tighter alternative.
4. Builder either proves its position or adjusts to the stronger solution.
5. Master Chef decides the winning path and records why.

After a resolved dispute, report `DISPUTE_RESOLVED` with:

- disputed issue
- Builder position
- Master Chef position
- evidence used to decide
- final chosen solution

`dispute_loop_count` increments for each full challenge cycle on the same blocker.

If 2 full dispute loops finish without clear forward progress, declare deadlock, stop the run, remove the cron job, and report `DEADLOCK_STOPPED`.

---

## 14) Preflight checks

Before implementation begins, verify:

- Master Chef model status:
  - `/model status`
- Builder model status:
  - `/acp status`
- ACP backend healthy:
  - `/acp doctor`
- Codex CLI reachable:
  - `codex --version`
- required CDD Builder skills installed:
  - `ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null`
- repo contains the CDD boilerplate:
  - `ls AGENTS.md README.md >/dev/null`
  - `ls TODO*.md >/dev/null`
- target repo identified and clean enough for work:
  - `git status --short`
- active branch known:
  - `git branch --show-current`
- upstream exists and is resolvable:
  - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
- session-tool visibility is sufficient for isolated watchdog supervision:
  - `tools.sessions.visibility` is `agent` or `all`
  - sandbox session-tool visibility is not overly restrictive
- route configuration is clear:
  - `control_route` confirmed
  - `status_route` confirmed or intentionally omitted

If upstream is missing, do not proceed into implementation. Stop and report the missing push target.

If the active TODO state is not runnable, stop the implementation path and propose `cdd-plan` instead.

If `.cdd-runtime/` would be tracked, fix ignore policy before kickoff approval.

---

## 15) Failure policy

If a Builder run fails:

1. Retry once with tighter prompt constraints.
2. If it still fails, isolate the failure cause and decide whether it is:
   - a normal blocker -> report `STEP_BLOCKED`
   - a technical dispute -> enter the dispute loop
   - a dead process -> let Master Chef resume it
   - a cyclical failure or deadlock -> report `DEADLOCK_STOPPED`

If Master Chef becomes stale:

- probe the session first
- recover from `run.json` and `run.lock.json` only if the probe fails or state is incoherent
- do not spawn a second parallel autonomous run

If push fails:

- do not mark the step passed
- report `STEP_BLOCKED`
- include the failing command, branch, upstream, and smallest recovery action

If cron setup fails before kickoff:

- do not start autonomous execution
- ask the human to resolve the cron setup first

If the `control_route` is not the intended one:

- do not start autonomous execution
- have the user reopen `/cdd-master-chef` in the correct route or explicitly re-confirm the route

If the `status_route` is misconfigured:

- if policy is `best_effort`, continue and report degraded external reporting in `control_route`
- if policy is `required`, do not proceed

Never silently pivot architecture mid-step.
