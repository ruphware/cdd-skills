# Master Chef Shared Contract

This file is the runtime-agnostic source of truth for `cdd-master-chef`.

Runtime adapters must satisfy this contract without claiming runtime behavior they cannot actually provide. Adapter docs may be stricter than this shared contract, but they must not be looser.

## 0) Purpose

Run autonomous development with one control loop:

- **Master Chef:** the main controlling session for the run
- **Builder:** a delegated worker run that executes exactly one approved action
- **Reporting surface:** the runtime-defined session where lifecycle updates are shown to the human

Design principle: **soft reasoning, hard state**.

- Keep planning, review, QA, and blocker judgment LLM-driven.
- Keep runtime state, leases, logs, events, and recovery thresholds explicit and durable.

## 1) Actors

### Master Chef

Master Chef owns:

- repo inspection
- choosing the skill-routing path
- next-step selection
- runtime initialization
- direct use of planning-oriented `cdd-*` skills when needed
- Builder spawn, replacement, and review
- direct Builder health checks when the runtime allows them
- QA gate and step-level UAT approval
- commit and push
- lifecycle reporting
- final summary

### Builder

The Builder owns:

- using the exact delegated internal `cdd-*` skill chosen by Master Chef
- implementing exactly one approved action
- running step validation
- writing durable step evidence
- returning a structured report to Master Chef

One Builder run equals one approved delegated action. After that action finishes or is abandoned, Master Chef re-inspects repo state and spawns a fresh Builder run for the next delegated step.

### Human

The human owns:

- the per-run Run config
- the per-run step budget
- kickoff approval
- final review
- intervention when Master Chef reports a blocker or deadlock

## 2) Required repo state

Before autonomous work begins:

1. The target workspace must be either:
   - a repo that already contains `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`, or
   - a new or adoptable project folder that should first be brought into the CDD contract through `cdd-init-project`
2. The full Run config must be resolved and approved before kickoff.
3. A pushable upstream is required before the normal autonomous commit/push loop begins.
4. Master Chef must inspect:
   - current git status and branch
   - upstream branch when present
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - whether the repo first needs `cdd-init-project`
5. Before kickoff, the source checkout must be clean. If it is dirty, stop and ask the human to stash, commit, or discard changes before managed worktree creation.

## 3) Durable runtime state

State is durable and repo-local:

- `.cdd-runtime/master-chef/run.json`
- `.cdd-runtime/master-chef/run.lock.json`
- `.cdd-runtime/master-chef/master-chef.jsonl`
- `.cdd-runtime/master-chef/builder.jsonl`
- `.cdd-runtime/master-chef/context-summary.md`

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

## 4) Run config

The resolved `Run config` must contain:

- `master_model`
- `master_thinking`
- `builder_model`
- `builder_thinking`

Runtime adapters may help resolve the `Run config` in one of three ways:

- an inline `Run config` block in the kickoff prompt
- a local default Run config file when the adapter supports one
- a recommended candidate derived from the current session model and thinking when the runtime can surface both concretely

A current-session recommendation must copy those current session values into all four Run config fields, show the full candidate block back to the human, and wait for explicit approval or edits before kickoff. Do not silently assume current session settings.

Treat the resolved `Run config` as the only per-run source of truth. Do not infer model settings from repo docs, memory, previous `run.json`, or earlier runs.

Runtime adapters must define:

- how the Run config is supplied
- whether they support local default Run config files
- whether they can inspect the current session model and thinking well enough to recommend a candidate Run config when one is missing
- how the model and thinking fields are honored, inherited, constrained, or downgraded
- how Builder monitoring works, including whether live status, partial output, or direct reasoning visibility actually exist in that runtime

Before kickoff, the run must also resolve an approved step budget for the current autonomous run:

- a positive integer TODO-step count such as `1` or `3`, or
- `until_blocked_or_complete`

Runtime adapters must ask for that step budget explicitly and record it in runtime state before implementation begins.

## 5) Routing model

Master Chef chooses the internal `cdd-*` routing model.

- For a new or not-yet-CDD project, propose and normally start with `cdd-init-project` in the main session before any autonomous TODO execution.
- Builder default: `cdd-implement-todo` for the next runnable TODO step.
- Builder optional: `cdd-index` when Master Chef explicitly wants an index refresh as the delegated action.
- Master Chef direct: `cdd-init-project`, `cdd-plan`, and `cdd-refactor` stay in the main session rather than being delegated to Builder.
- Excluded from the normal flow: `cdd-audit-and-implement`, unless the process is explicitly adapted for its mixed role.

Runtime adapters must define the install roots, invocation surface, and delegation mechanism for those internal workflows.

## 6) Managed worktree lifecycle

Master Chef runs against a managed worktree rather than mutating the source checkout in place.

- Create the managed worktree from the current branch `HEAD`.
- Use a fresh per-run branch rather than reusing the source checkout branch.
- Record the source checkout path separately from the active worktree path.
- Initialize runtime state in the managed worktree before implementation begins.
- Continue in the worktree only when the runtime adapter can safely re-root the active control loop there.
- Otherwise, stop with exact relaunch instructions and mark the run as `relaunch_required` before any implementation starts.

Prefer a managed worktree path under:

```text
.cdd-runtime/master-chef/worktrees/<run-id>/
```

Runtime adapters may use a different location only if they document that choice explicitly.

## 7) Kickoff and Builder lifecycle

Before implementation starts, present one kickoff approval that covers:

- proposed next action
- the approved `Run config`
- the approved run step budget
- whether to spawn Builder now and start the autonomous run
- runtime initialization under `.cdd-runtime/master-chef/`
- run lease creation

Use one-step Builder runs only.

- One Builder run equals one approved delegated action.
- After a step passes, blocks, or is abandoned as stale, Master Chef must re-inspect repo state and spawn a fresh Builder for the next delegated action, normally via `cdd-implement-todo`.
- Do not treat Builder session resurrection or multi-step continuation as a normal path.

Both Master Chef and Builder must append durable evidence for step start, validation, blockers, completion, and reporting.

Builder monitoring must use direct runtime evidence before heuristics:

- If the runtime can expose direct Builder status, final messages, or explicit progress replies, use those surfaces first.
- If the runtime cannot expose live Builder reasoning or streaming partial output, say so explicitly and report Builder state as `running` or `unknown`, not `stale`, during quiet periods.
- Do not treat a missing diff, an empty `builder.jsonl`, or one short wait window with no completion as proof that Builder has died.
- For long-effort Builders, especially `builder_thinking: xhigh`, allow a longer quiet window before probing or replacing unless the runtime reports direct failure sooner.
- Replace Builder only after direct failure or closure, an explicit Builder blocker, or no response to a direct status probe after the adapter-defined grace window.

## 8) Validation, QA, and UAT

Use `hard_gate` and `soft_signal` validation classes:

- `hard_gate`: failing tests, lint, typecheck, migrations, pushability, or repo-defined must-pass checks
- `soft_signal`: discovery greps, file-presence scans, or other non-blocking heuristics

Use working-tree-aware discovery checks when unstaged files matter:

- `rg --files`
- `git ls-files --cached --others --exclude-standard`

For each passed step:

- increment `steps_completed_this_run`
- ensure the Builder updated only the selected step in `TODO*.md`
- run Master Chef QA
- if QA rejects the Builder result, either push concrete findings to a fresh Builder run for the same step or fix the issue directly in Master Chef, then re-run QA before the step can pass
- approve step-level UAT with explicit evidence
- commit
- push
- advertise `STEP_PASS` with the full result, evidence, and decision trail in the reporting surface
- if `run_step_budget` is a positive integer and `steps_completed_this_run` has reached it, stop cleanly with `RUN_STOPPED` and a summary instead of continuing automatically
- otherwise, re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains
- once the managed worktree becomes active, commit, push, QA, and TODO inspection happen against the active worktree path rather than the source checkout

## 9) Reporting and recovery

Report events:

- `START`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

If repeated Builder replacements fail without progress, stop quickly and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` rather than limping on.

If a TODO step is blocked by a hard blocker, ambiguous scope, or repeated failed Builder replacements:

- stop the autonomous loop and report `STEP_BLOCKED` or `DEADLOCK_STOPPED`
- revise the situation in Master Chef before any more Builder work
- decompose the blocked work into smaller decision-complete TODO steps through Master-Chef-direct planning or TODO repair
- clean only stale runtime or build artifacts needed for a coherent retry, and never revert unrelated user work
- restart only from the next smaller actionable TODO step; do not retry the same broad blocked step unchanged

## 10) Context compaction

Manage Master Chef context explicitly during long runs:

- keep Builder context fresh through one-step Builder runs; do not compact or resume Builders as the normal path
- before Master Chef compaction, write `run.json`, `run.lock.json`, JSONL evidence, and `.cdd-runtime/master-chef/context-summary.md`
- compact only at safe workflow boundaries, such as after kickoff state is durable, after Builder handoff, after `STEP_PASS`, after `STEP_BLOCKED` or `DEADLOCK_STOPPED`, after Master-Chef-direct planning or refactor work, or before a known large QA or planning phase once a checkpoint is written
- do not compact while QA, commit, push, blocker strategy, or next-action decisions exist only in the live transcript
- after compaction, resume from runtime files, `context-summary.md`, active TODO, and git state before continuing

## 11) Runtime adapter obligations

Runtime adapters must define:

- how Master Chef and Builder sessions are created
- whether subagent delegation is explicit, automatic, or unavailable
- nested delegation limits
- how tools and MCP access are inherited or restricted
- how child working directories are selected
- how worktree creation and hand-off are realized or limited
- whether they continue in the managed worktree in-session or stop with relaunch instructions
- how the reporting surface maps onto the runtime
- any runtime-specific stop conditions or safety restrictions that are stricter than the shared contract
