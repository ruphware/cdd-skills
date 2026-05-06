# [CDD-6] Master Chef Runbook (OpenClaw adapter)

## 0) Purpose

This runbook is the OpenClaw adapter over the shared `[CDD-6] Master Chef` contract.

Use the parent `cdd-master-chef/` package docs as the runtime-agnostic source of truth. Use this runbook for the OpenClaw-specific realization details and packaged smoke-test behavior.

OpenClaw-specific deltas over the shared policy:

- unresolved current-session fields are recorded as `unknown`, reported honestly, and do not block kickoff
- the current adapter provisions the managed worktree, records runtime state there, and then requires relaunch instead of assuming safe in-session cwd switching
- Builder readiness and monitoring evidence comes from the relaunched session, runtime files, and explicit Builder ACKs rather than any claim of live reasoning visibility

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
- final mission report

### Builder

The Builder is an OpenClaw subagent. It owns:

- using the exact delegated internal `cdd-*` skill chosen by Master Chef
- implementing exactly one approved action
- running step validation
- writing `builder.jsonl`
- returning a structured report to Master Chef

Builder is persistent for the active autonomous run after relaunch into the managed worktree unless recovery conditions force replacement. It still handles exactly one approved delegated action at a time, but the same Builder normally continues across later delegated steps in the same run after Master Chef re-inspects state and performs any supported beginning-of-step compaction.

There is no watchdog actor, cron wake-up, second control loop, or normal Builder-session resurrection path.

If a Builder needs inspection, recovery, or reporting, Master Chef handles it directly in the main session while already active.

### Human

The human owns:

- any optional Builder override when Builder should diverge from the active session
- the per-run step budget
- kickoff approval
- final review
- intervention when Master Chef reports a hard technical or physical stop or deadlock

---

## 2) Startup prerequisites

Before `/cdd-master-chef` is used:

1. The target workspace must be either:
   - a repo that already contains `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`, or
   - a new/adoptable project folder that should first be brought into the CDD contract through `cdd-init-project`
2. The current session model and thinking should be mirrored into runtime state when OpenClaw exposes them; any unresolved field is recorded as `unknown` and does not block kickoff.
3. Any optional `Builder override` must be resolved before kickoff.
4. A pushable upstream is required before the normal autonomous commit/push loop begins.
5. The OpenClaw shared skills install must already contain the internal skill pack Master Chef may route through, including:
   - `~/.openclaw/skills/cdd-master-chef`
   - `~/.openclaw/skills/cdd-boot`
   - `~/.openclaw/skills/cdd-maintain`
   - `~/.openclaw/skills/cdd-init-project`
   - `~/.openclaw/skills/cdd-plan`
   - `~/.openclaw/skills/cdd-implement-todo`
   - `~/.openclaw/skills/cdd-implementation-audit`
6. If Builder should diverge from the active session, prepare an optional `Builder override` that contains `builder_model`, `builder_thinking`, or both.

The current Master Chef session is implicitly the control/reporting surface.

If the repo is not yet CDD-ready but the request is a legitimate new-project or adoption flow, route first through `cdd-init-project` in the main session.

If the repo is not CDD-ready and the request is not an init/adoption flow, stop and route the user back to the core CDD workflow.

If upstream is missing, do not start autonomous implementation/commit/push execution.

### 2.1 Optional Builder override

Builder inherits the active session model and thinking by default.

If Builder should diverge, use an optional block in this shape:

```text
Builder override:
  builder_model: gpt-5.4
  builder_thinking: xhigh
```

Rules:

- This block is optional; if it is absent, Builder inherits the current session settings.
- If only one `builder_*` field is present, the missing field still inherits from the active session.
- Master Chef must not infer or merge model settings from `USER.md`, memory, repo docs, previous `.cdd-runtime/master-chef/run.json`, or earlier conventions.
- If the current OpenClaw path cannot honor a requested Builder override cleanly, say so explicitly and use inherited Builder settings instead.
- If OpenClaw cannot expose one current-session field exactly, preserve any known field and record only the missing field as `unknown`; if Builder inherits from that unresolved field without an explicit replacement, keep the inherited Builder field as `unknown`.
- After kickoff, copy the effective `master_*` and `builder_*` values into `.cdd-runtime/master-chef/run.json`, record whether Builder is using inherited settings or an explicit override, and never ask the human to type replacement `master_*` values.
- Keep shared docs and commits free of local-only operator transport details.

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
   - whether the next runnable top-level TODO step is oversized for one Builder run
   - remaining unfinished top-level TODO step-heading count in the active TODO file when that count is finite
   - whether this is a fresh run from a long-lived branch and should first suggest a descriptive feature branch
   - obvious blockers in the working tree
   - whether the repo first needs `cdd-init-project`
3. Choose the next action and route it through the right internal skill:
   - bootstrap path: `[CDD-1] Init Project` (`cdd-init-project`) in the main session when the user wants a new project or when the repo must adopt CDD before the normal loop can begin
   - default delegated path: next runnable TODO step handled through `[CDD-3] Implement TODO` (`cdd-implement-todo`)
   - if the next runnable top-level TODO step looks oversized for one Builder run, review it in Master Chef first and keep it intact unless the parent step is not safely delegable as one coherent Builder action and the split cost is clearly justified; only then split into smaller decision-complete TODO steps and recompute the remaining top-level-step count
   - Master Chef direct: `[CDD-1] Init Project` (`cdd-init-project`), `[CDD-2] Plan` (`cdd-plan`), `[CDD-4] Implementation Audit` (`cdd-implementation-audit`), or `[CDD-5] Maintain` (`cdd-maintain`) when the repo needs setup, planning, implementation audit, doc drift review, codebase cleanup, `docs/INDEX.md` refresh, or refactor architecture audit before Builder work
   - approved findings from `[CDD-4] Implementation Audit` or external review: normalize them through `[CDD-2] Plan` (`cdd-plan`) before any delegated Builder work
4. Report session-derived Master Chef settings and effective Builder settings:
   - current session model as `master_model`, or `unknown` when OpenClaw does not expose it exactly
   - current session thinking as `master_thinking`, or `unknown` when OpenClaw does not expose it exactly
   - effective `builder_model`
   - effective `builder_thinking`
   - whether Builder is inherited or overridden
   - a compact note when OpenClaw does not expose one or more exact session-setting fields and Master Chef is proceeding with the active session as-is
5. Initialize runtime files under `.cdd-runtime/master-chef/`.
6. Ensure `.cdd-runtime/` is locally ignored.
7. Acquire the run lease in `run.lock.json`.
8. Present one selector-driven kickoff approval that includes:
   - repo state summary
   - proposed next action
   - current session model and thinking
   - effective Builder settings
   - the shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget
   - the approved run step budget
   - whether to spawn Builder now and start the autonomous run
   - runtime initialization
   - run lease
   - in-session reporting expectations
9. Do not spawn the Builder until the user approves kickoff.

Use the shared selector contract.

- `A. approve kickoff and start the autonomous run now`
- `B. approve kickoff but do not spawn Builder yet`
- `C. revise the next action, Builder settings, or step budget before kickoff`

After kickoff approval, the run becomes autonomous.

### 3.1 Managed worktree kickoff

Before implementation starts:

1. Require a clean source checkout.
   - If `git status --short` shows tracked or staged changes, stop and ask the human to stash, commit, or discard changes first.
2. Record the source checkout path, source branch, and source `HEAD` SHA.
3. If this is a fresh run from a long-lived branch and kickoff approved a descriptive feature branch, create that feature branch in the source checkout first and refresh `source_branch` and `source_head_sha`.
4. If the active TODO file has a finite remaining unfinished top-level TODO step-heading count, recommend that exact count as the default/max run step budget, meaning "all remaining steps", after any step split.
5. Choose a managed worktree path under:

   ```text
   .cdd-runtime/worktrees/<run-id>/
   ```

6. Create a fresh per-run branch from the current branch `HEAD`, preferably:

   ```text
   master-chef/<run-id>
   ```

7. Create the managed worktree from the source checkout with that fresh branch.
8. Initialize runtime files inside the managed worktree so `.cdd-runtime/master-chef/` is relative to the active repo root after relaunch.
9. Record `source_repo`, `source_branch`, `source_head_sha`, `source_branch_decision`, `active_worktree_path`, `worktree_branch`, and `worktree_continue_mode`.
10. The current OpenClaw adapter must set `worktree_continue_mode` to `relaunch_required`, then stop with exact relaunch instructions before any delegated implementation starts.
11. After relaunch into the managed worktree, treat that path as the active repo root for TODO inspection, environment bootstrap, QA, commit, push, and runtime files.
12. Inspect repo-native manifests, runbook commands, and validation entrypoints from the active worktree.
13. Run the required dependency, build, install, credential, or test-prep commands in that worktree, record the commands or checks in durable evidence, and keep `worktree_env_status` at `preparing` until the worktree is either `env_ready`, `partial`, or `blocked`.
14. Do not spawn Builder or run `hard_gate` validation until `worktree_env_status` is `env_ready`. If bootstrap hits a hard technical or physical limit, stop and report it explicitly instead of falling back to the source checkout.

---

## 4) Runtime files

Store canonical runtime state inside the repo:

```text
.cdd-runtime/master-chef/
  run.json
  run.lock.json
  master-chef.jsonl
  builder.jsonl
  context-summary.md
```

### 4.1 `run.json`

Keep it current after every material state change.

Suggested shape:

```json
{
  "run_id": "<utc-id>",
  "repo": "/abs/path/to/repo",
  "source_repo": "/abs/path/to/source-repo",
  "master_model": "<model-or-unknown>",
  "master_thinking": "<thinking-or-unknown>",
  "builder_model": "<model-or-unknown>",
  "builder_thinking": "<thinking-or-unknown>",
  "builder_settings_source": "inherited",
  "run_step_budget": 1,
  "steps_completed_this_run": 0,
  "builder_runtime": "subagent",
  "master_session_key": "<main-session-key>",
  "builder_session_key": "<builder-session-key>",
  "active_todo_path": "/abs/path/to/TODO.md",
  "active_step": "<exact step heading>",
  "phase": "kickoff|builder|qa|uat|commit|push|reporting|blocked|complete",
  "source_branch": "<source-branch>",
  "source_head_sha": "<source-sha>",
  "source_branch_decision": "accepted|declined|not_applicable",
  "active_worktree_path": "/abs/path/to/source-repo/.cdd-runtime/worktrees/<run-id>",
  "worktree_branch": "<worktree-branch>",
  "worktree_continue_mode": "relaunch_required|in_session",
  "worktree_env_status": "not_started|preparing|env_ready|partial|blocked",
  "worktree_env_prepared_at_utc": "<ts>",
  "worktree_env_bootstrap_summary": "<summary>",
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
  "source_repo": "/abs/path/to/source-repo",
  "active_worktree_path": "/abs/path/to/source-repo/.cdd-runtime/worktrees/<run-id>",
  "worktree_branch": "<worktree-branch>",
  "worktree_continue_mode": "relaunch_required|in_session",
  "source_branch_decision": "accepted|declined|not_applicable",
  "worktree_env_status": "not_started|preparing|env_ready|partial|blocked",
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

### 4.4 `context-summary.md`

Use `context-summary.md` as the durable Master Chef checkpoint for long runs and context compaction. It is a compact run synopsis, not a raw transcript dump, external route config, or secret store.

Required sections:

- `Run`: run id, repo, source repo, active worktree path, branch, upstream, master session key, active Builder session key when present
- `State`: active TODO path, active step, phase, worktree branch, worktree continuation mode, source branch decision, worktree environment status, last pass SHA, current blocker, current Builder status
- `Recent decisions`: routing choices, QA/UAT verdicts, remediation decisions, blocker strategy, and why they were chosen
- `Current diff`: working-tree summary, files changed, commands already run, and unresolved risks
- `Pending proof`: checks, QA, UAT, commit, push, reporting, or worktree bootstrap still needed
- `Next action`: the exact next Master Chef action after compaction or resume

Keep this file current before any deliberate Master Chef compaction and after material lifecycle events such as kickoff, Builder handoff, `STEP_PASS`, `STEP_BLOCKED`, `DEADLOCK_STOPPED`, plan repair, or direct Master Chef fixes.

---

## 5) Builder runtime

Use an OpenClaw subagent as the Builder.

The Builder relies on the shared OpenClaw `cdd-*` skills that are installed into
`~/.openclaw/skills` by `./scripts/install.sh --runtime openclaw`. Those are OpenClaw-ready
internal variants generated from the canonical repo skill pack in `skills/`.

### 5.0 Routing model

Master Chef chooses the routing path.

**Builder delegated by default:**

- `[CDD-3] Implement TODO` (`cdd-implement-todo`) — normal path for one approved runnable TODO step

**Manual / non-routed helper:**

- `[CDD-0] Boot` (`cdd-boot`) — best-effort vanilla `AGENTS.md` boot for direct human-driven work; installed in the shared pack but not part of the normal Master Chef routing flow
- `[CDD-5] Maintain` (`cdd-maintain`) — direct maintenance helper for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review when one of those tasks is the actual next action

**Master Chef direct:**

- `[CDD-1] Init Project` (`cdd-init-project`)
- `[CDD-2] Plan` (`cdd-plan`)
- `[CDD-4] Implementation Audit` (`cdd-implementation-audit`) when the human explicitly wants an implementation or codebase audit checkpoint
- `[CDD-5] Maintain` (`cdd-maintain`) when the repo needs maintenance, cleanup, index refresh, or refactor architecture audit before delegated implementation

**Audit findings:**

- approved findings from `[CDD-4] Implementation Audit` or external review are normalized through `[CDD-2] Plan` (`cdd-plan`) in the main session, then delegate the selected runnable step through `[CDD-3] Implement TODO` (`cdd-implement-todo`)

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

Persistent Builder continuation is the normal path after the managed-worktree relaunch. Do not use dead-session resurrection as the normal recovery path. If OpenClaw later exposes a supported Builder compaction operation, use it at delegated-step boundaries; otherwise keep the same Builder and rely on native context management instead of inventing a manual compaction command.

### 5.1 Builder contract

The Builder must:

- use the exact internal `cdd-*` skill chosen by Master Chef
- default to `cdd-implement-todo` for a normal approved runnable TODO step
- not switch itself into planning or maintain mode; if the delegated path no longer fits, return a blocker instead
- implement exactly one approved action
- stop after that one approved action and wait for the next explicit Master Chef handoff instead of self-selecting the next TODO step
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
4. If the chosen action is Master-Chef-direct (`cdd-init-project`, `cdd-plan`, `cdd-implementation-audit`, or `cdd-maintain`), run it in the main session before any Builder spawn.
5. Record the Builder session key in runtime state when a Builder is used.
6. If a Builder was spawned, let it work, review the Builder report when it returns, and treat that delegated action as finished while keeping the Builder session available for same-run continuation when it remains usable.
7. If the Builder appears stale during an active main-session turn, inspect it directly, replace it quickly with a fresh single-step Builder run for the same step, and update runtime/log evidence immediately.
8. Run Master Chef QA and step-level UAT.
9. If Master Chef QA rejects the Builder result:
   - record the QA findings in `master-chef.jsonl`
   - either keep the same Builder when it remains usable, send the findings to a fresh replacement Builder for the same step when recovery conditions require it, or fix the issue directly in Master Chef
   - re-run Master Chef QA and step-level UAT before passing the step
10. If the step passes:
   - commit
   - push
   - update runtime state
   - advertise `STEP_PASS` with full detail in the current Master Chef session
11. Re-inspect TODO state.
12. If another runnable step exists, re-inspect repo and TODO state, attempt Builder compaction only when the active OpenClaw surface exposes a supported operation, and continue automatically with the same Builder when it remains usable; otherwise spawn a fresh Builder run for that next delegated action, normally via `cdd-implement-todo`.
13. If no runnable step remains, report `RUN_COMPLETE` with the final mission report.
14. If Master Chef context is getting large, update `context-summary.md` at the boundary reached above, then compact before continuing.

All QA, TODO inspection, commit, and push actions after worktree activation happen against the active managed worktree path rather than the original source checkout.

Only stop autonomy when:

- the run is complete
- a hard technical or physical limitation prevents safe autonomous continuation
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
- do not claim a parent-visible Builder fullness meter or a manual Builder compaction command unless the active OpenClaw surface actually exposes one

If stale:

- replace it quickly with a fresh Builder run for the same step
- increment `builder_restart_count`
- renew the lease
- update runtime files and logs
- send `BUILDER_RESTARTED` or `STEP_BLOCKED` if appropriate

Do not use Builder-session resurrection as the normal recovery path. If a Builder session died, drifted, returned without a usable report, or cannot continue safely after status or compaction checks, replace it with a fresh single-step Builder run for the same step.

If repeated replacements fail without forward progress:

- stop the run
- report `STEP_BLOCKED` or `DEADLOCK_STOPPED`
- revise the situation before any more Builder work

### If a TODO step is blocked

Treat every non-passing Builder attempt, including QA reject, explicit blocker, or stale replacement with no usable pass result, as a continuation-review boundary. When that review shows that the current step cannot safely pass as-is, pause delegated implementation instead of spawning another Builder for the same broad step blindly.

Blocked-step recovery procedure:

1. Set the run phase to `blocked`, preserve the Builder report and failed validation evidence, and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` in the current Master Chef session.
2. Inspect `git status`, the current diff, `run.json`, `master-chef.jsonl`, `builder.jsonl`, failed commands, and the selected TODO step.
3. Review completed work, failed proof, whether the remainder is still one bounded implementation action, whether a fresh Builder would spend most of its effort on recovery rather than completion, whether preserving the parent step is still cheaper than a split, and whether the unfinished remainder now has cleaner sub-step boundaries than the original parent step.
4. Choose one explicit outcome:
   - `continue_same_step` when progress is coherent, the step boundary still holds, and the active Builder can plausibly finish the remainder without reopening planning, or one recovery replacement Builder can do so if the active one is no longer usable
   - `repair_in_place` when the step boundary still holds but the TODO step needs a tighter contract, sequencing note, or proof note before the next Builder run
   - `split_remainder_into_child_steps` only when the unfinished portion is now too risky to keep as one Builder run and preserving the parent step would cost more total retry churn than the split
   - `hard_stop` when a hard technical or physical limit still prevents safe continuation
5. Treat split as expensive because it adds Builder restarts, hard-gate reruns, QA cycles, mission delay, and extra proof boundaries. Do not pay that cost merely because the step looks broad or is expected to need several validation cycles.
6. Clean only stale runtime or build artifacts when they materially increase retry risk or obscure the true remainder; do not revert unrelated user work or discard useful failure evidence.
7. If the outcome is `continue_same_step`, keep the parent step, preserve the existing approval, and continue it with the same Builder when it remains usable after status or compaction checks; otherwise continue it with a fresh single-step Builder run.
8. If the outcome is `repair_in_place`, use Master-Chef-direct planning or TODO repair to tighten the same parent step, then continue that same step with the same Builder when safe, otherwise with a fresh single-step Builder run.
9. If the outcome is `split_remainder_into_child_steps`, record what part of the parent step is already done, what exact remainder is being separated, why the first child is the next runnable step, what checks, UAT, and invariants carry forward to each child, and why that split cost was justified before delegating again.
10. If repair or split yields a safe autonomous next step, emit `BLOCKER_CLEARED` in the current session and `master-chef.jsonl`, recording the original blocked step, replacement step ids when applicable, preserved remaining `run_step_budget`, and the next delegated action. Do not re-run kickoff, reset the run step budget, or increment `steps_completed_this_run` for the repair itself.
11. Re-inspect TODO state and continue the same run from the same repaired parent step or the first runnable child step, as chosen by the continuation review.
12. If the outcome is `hard_stop`, keep the run stopped and report the exact limit plus the decisions Master Chef made before stopping.

Default thresholds:

- Builder stale threshold: 5 minutes without Builder progress, evaluated only when Master Chef performs a check
- Builder replacement budget before deadlock: 2 failed replacements without progress

---

## 8) Master Chef context compaction

Builder continuation and Master Chef compaction are separate concerns. The normal path is one persistent Builder across delegated steps in the same run, normally through `cdd-implement-todo`, with each delegated action still handled one at a time. This repo does not currently document a manual OpenClaw Builder compaction command, so step-boundary compaction falls back to native context management unless the active surface exposes more later. Master Chef is long-lived, so it must make its own memory durable before compaction.

### Safe compaction points

Master Chef may compact only after durable state is written to `run.json`, `run.lock.json` when applicable, `master-chef.jsonl`, `builder.jsonl`, and `context-summary.md`.

Safe points:

- after kickoff state, run config, and lease are written
- after Builder handoff is recorded
- after a Builder returns and its result is recorded
- after `STEP_PASS`, including QA/UAT, commit, push, reporting, TODO re-inspection, and next action
- after `STEP_BLOCKED` or `DEADLOCK_STOPPED`, including blocker evidence and strategy
- after Master-Chef-direct planning, refactor decomposition, TODO repair, or direct fixes
- before a known large QA, planning, or refactor phase, once the current state and intended next action are checkpointed

### Unsafe compaction windows

Do not compact:

- before runtime files exist for the run
- while QA findings or UAT decisions are only in the live transcript
- between QA pass and commit/push unless a checkpoint records the exact pending action
- while a blocker strategy, TODO decomposition, or cleanup decision is only in the live transcript
- while uncommitted direct Master Chef fixes have no diff summary in `context-summary.md`

If context pressure appears during an unsafe window, first write the missing state, logs, and `context-summary.md`, then compact from the next safe boundary.

### Resume after compaction

After compaction, Master Chef must reconstruct state from durable sources instead of trusting transcript memory:

1. Read `AGENTS.md`, `README.md`, the active `TODO*.md`, `run.json`, `run.lock.json`, `context-summary.md`, `master-chef.jsonl`, and `builder.jsonl`.
2. Run `git status --short`, confirm branch/upstream, and inspect the current diff.
3. Verify the active TODO file, active step, run phase, Builder session key/status, last pass SHA, blocker state, pending proof, and next action against the repo state.
4. If the checkpoint conflicts with repo state, stop and report `RUN_STOPPED` or `STEP_BLOCKED` rather than guessing.
5. Continue only after the next action is explicit and supported by runtime evidence.

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
- the selected TODO step's task checklist reflects the completed work
- step-level UAT is explicit and approved
- commit and push succeeded
- runtime files and logs reflect the new state
- `STEP_PASS` was advertised in the current Master Chef session before automatic continuation

### QA rejection path

When Master Chef rejects Builder output during QA, the step stays active and cannot be passed, committed, pushed, or advertised as `STEP_PASS`. Master Chef must preserve concrete QA findings, choose either the same Builder when it remains usable, a fresh single-step Builder run for the same step when recovery requires replacement, or a direct Master Chef fix, then re-run QA and UAT before the normal commit, push, `STEP_PASS`, TODO re-inspection, and automatic continuation path resumes.

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
- final mission report
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
- when `BLOCKER_CLEARED` is reported, include the original blocked step, replacement step ids, preserved remaining budget, and the next delegated action
- when the run ends with `RUN_COMPLETE`, `RUN_STOPPED`, a hard-stop `STEP_BLOCKED`, or `DEADLOCK_STOPPED`, emit a final mission report covering completed work, completed TODO step ids plus whether their task checklists are fully checked, validations and pushes, Builder restarts or blocker repairs, unresolved session-setting fields, which effective Builder settings were concrete versus `unknown`, decisions made, and remaining work or the exact stop reason
- for `RUN_COMPLETE` and budget-stop `RUN_STOPPED`, append a compact post-run recommendation bundle: run `cdd-implementation-audit` on the completed run scope, push only when the active branch is ahead of origin or still unpublished, open a PR only once the branch is published and PR creation is still pending, clean up the managed worktree only when it still exists and no immediate continuation is planned there, and return to the source checkout or parent folder after cleanup or once that worktree is no longer the active development root
- for hard-stop `STEP_BLOCKED` or `DEADLOCK_STOPPED`, prioritize blocker context and exact stop reason first rather than presenting cleanup as the primary next move

---

## 11) Failure policy

### If Builder fails or stalls

1. replace Builder quickly with a fresh single-step subagent run for the same step
2. do not use session resurrection as the normal recovery path
3. if 2 replacements fail without progress, stop the step, report the blocker, and repair or decompose TODO before restarting from a smaller actionable step

### If main session is interrupted

- resume manually from `run.json` and `run.lock.json`
- inspect repo diff and Builder logs
- either continue the same step with the same Builder when it remains usable, continue with a fresh Builder run when recovery requires replacement, or mark it blocked

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
