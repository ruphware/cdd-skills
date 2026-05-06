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
- final mission report

### Builder

The Builder owns:

- using the exact delegated internal `cdd-*` skill chosen by Master Chef
- implementing exactly one approved action
- running step validation
- writing durable step evidence
- returning a structured report to Master Chef

Each Builder run covers exactly one approved delegated action. After that action finishes or is abandoned, Master Chef re-inspects repo state and spawns a fresh Builder run for the next delegated step.

### Human

The human owns:

- any optional Builder override when Builder should diverge from the active session
- the per-run step budget
- kickoff approval
- final review
- intervention when Master Chef reports a hard technical or physical stop or deadlock

## 2) Required repo state

Before autonomous work begins:

1. The target workspace must be either:
   - a repo that already contains `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`, or
   - a new or adoptable project folder that should first be brought into the CDD contract through `cdd-init-project`
2. Master Chef must observe the current session model and thinking when the runtime exposes them, resolve any optional Builder override, and continue kickoff even when one or both session-setting fields remain `unknown`.
3. A pushable upstream is required before the normal autonomous commit/push loop begins.
4. Master Chef must inspect:
   - current git status and branch
   - upstream branch when present
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - whether the next runnable top-level TODO step is oversized for one Builder run
   - remaining unfinished top-level TODO step-heading count in the active TODO file when that count is finite
   - whether this is a fresh run from a long-lived branch and should first suggest a descriptive feature branch
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
- `builder_settings_source`
- `builder_runtime`
- `master_session_key`
- `builder_session_key`
- `builder_phase`
- `builder_spawn_requested_at_utc`
- `builder_ready_at_utc`
- `last_builder_direct_signal_at_utc`
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

## 4) Session settings and Builder override

The active session is the only source of truth for:

- `master_model`
- `master_thinking`

Any unresolved session-setting field may be stored as `unknown`. Do not invent replacement `master_*` values.

Builder defaults:

- `builder_model` inherits the current session model
- `builder_thinking` inherits the current session thinking

When Builder should diverge from the active session, the human may provide an optional `Builder override` that contains `builder_model`, `builder_thinking`, or both.

If one current-session field is observable and the other is not, preserve the known value and record only the missing field as `unknown`. If Builder inherits from an unknown parent field and no explicit override replaces it, keep the inherited Builder field as `unknown`.

Before kickoff, Master Chef must report:

- current session model
- current session thinking
- effective `builder_model`
- effective `builder_thinking`
- whether Builder is using inherited settings or an explicit override
- a compact note when the runtime does not expose one or more exact session-setting fields and Master Chef is proceeding with the active session as-is

If the runtime cannot observe one or both current-session fields concretely enough to report them exactly, record only those unresolved fields as `unknown`, say the runtime does not expose them here, and proceed with the active session as-is. Do not ask the human to type replacement `master_*` settings.

If the runtime cannot honor a requested Builder override cleanly, say so explicitly and use inherited Builder settings rather than pretending the override landed.

Treat current-session `master_model` / `master_thinking` plus effective `builder_model` / `builder_thinking` as the only per-run source of truth. Do not infer model settings from repo docs, memory, previous `run.json`, or earlier runs.

Runtime adapters must define:

- how they observe the current session model and thinking, and how they report `unknown` when the runtime does not expose an exact value
- how an optional `Builder override` is supplied when Builder should diverge
- how Builder settings are inherited by default and how explicit overrides are honored or rejected
- how Builder monitoring works, including whether live status, partial output, or direct reasoning visibility actually exist in that runtime

Before kickoff, the run must also resolve an approved step budget for the current autonomous run:

- a positive integer TODO-step count such as `1` or `3`, or
- `until_blocked_or_complete`

For this rule, "steps left" means unfinished top-level TODO step headings only; do not count nested checkboxes or sub-tasks. When that count is finite, Master Chef must recommend that exact count as the default/max run step budget, meaning "all remaining steps". `until_blocked_or_complete` remains available when the human wants no numeric cap or no finite top-level step count is available.

Runtime adapters must ask for that step budget explicitly and record it in runtime state before implementation begins.

## 5) Routing model

Master Chef chooses the internal `cdd-*` routing model.

- For a new or not-yet-CDD project, propose and normally start with `cdd-init-project` in the main session before any autonomous TODO execution.
- Builder default: `cdd-implement-todo` for the next runnable TODO step.
- If the next runnable top-level TODO step is oversized for one Builder run, Master Chef may split it into smaller decision-complete TODO steps before delegation. Use one shared Builder-run-viability review for that choice: keep the step intact while one fresh Builder can plausibly finish it safely in one run; repair it in place if a minimal TODO fix restores that viability without changing scope; split it only when Master Chef already has strong evidence that one-run completion is too risky. Recompute the remaining unfinished top-level TODO step-heading count after the split, then delegate the first new runnable step.
- Master Chef direct: `cdd-init-project`, `cdd-plan`, and `cdd-maintain` stay in the main session rather than being delegated to Builder.
- Use `cdd-maintain` directly when the repo specifically needs doc drift review, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review before the normal TODO loop continues.
- `cdd-implementation-audit` is an installed direct audit helper for explicit implementation or codebase audits; approved findings still flow through `cdd-plan` in the main session before any delegated implementation begins.
- External audit findings and review-derived work packages must be normalized through `cdd-plan` in the main session before any delegated implementation begins.

Runtime adapters must define the install roots, invocation surface, and delegation mechanism for those internal workflows.

## 6) Managed worktree lifecycle

Master Chef runs against a managed worktree rather than mutating the source checkout in place.

- If this is a fresh run from a long-lived branch such as `main`, `master`, or `trunk`, and no existing managed worktree is being resumed, suggest creating a descriptive feature branch in the source checkout first.
- If the human approves that suggestion, create the feature branch in the source checkout and then create the managed worktree from that feature branch `HEAD`.
- Create the managed worktree from the current branch `HEAD`.
- Use a fresh per-run branch rather than reusing the source checkout branch.
- Record the source checkout path separately from the active worktree path.
- Initialize runtime state in the managed worktree before implementation begins.
- Continue in the worktree only when the runtime adapter can safely re-root the active control loop there.
- Otherwise, stop with exact relaunch instructions and mark the run as `relaunch_required` before any implementation starts.

Prefer a managed worktree path under:

```text
.cdd-runtime/worktrees/<run-id>/
```

Runtime adapters may use a different location only if they document that choice explicitly.

## 7) Kickoff and Builder lifecycle

Before implementation starts, present one kickoff approval that covers:

- proposed next action
- current session model
- current session thinking
- effective Builder settings
- any fresh-start feature-branch suggestion when the source checkout is still on a long-lived branch
- the default/max run step-budget recommendation when the active TODO has a finite remaining top-level step count
- the approved run step budget
- whether to spawn Builder now and start the autonomous run
- runtime initialization under `.cdd-runtime/master-chef/`
- run lease creation

Present that kickoff decision with selector-based options rather than a free-form approval question.

Use visible `A.`, `B.`, `C.` labels when practical, tell the human they can reply with just the selector, and let the selected option itself count as the kickoff approval.

- `A. approve kickoff and start the autonomous run now`
- `B. approve kickoff but do not spawn Builder yet`
- `C. revise the next action, Builder settings, or step budget before kickoff`

Once kickoff approval lands, Master Chef owns the mission under the approved run step budget. It keeps continuation, Builder restarts, blocker repair, TODO splitting, next-step routing, and terminal reporting in-session instead of handing ordinary decisions back to the human.

Use single-step Builder runs only.

- Each Builder run covers exactly one approved delegated action.
- After a step passes, blocks, or is abandoned as stale, Master Chef must re-inspect repo state and spawn a fresh Builder for the next delegated action, normally via `cdd-implement-todo`.
- Do not treat Builder session resurrection or multi-step continuation as a normal path.
- Immediately after a successful Builder spawn request, record `builder_session_key`, set `builder_phase: booting`, and write `builder_spawn_requested_at_utc`.
- A returned Builder handle or session key is spawn evidence only. It is not proof that Builder has fully started operating in the managed worktree.
- Before deep implementation begins, Builder must emit one early readiness signal. Preferred form: a concise ACK that confirms the active worktree path, the active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- Preferred boot prompt from Master Chef to Builder:

  ```text
  Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.
  ```

- When the first readiness signal arrives, set `builder_phase: running`, write `builder_ready_at_utc`, and refresh `last_builder_direct_signal_at_utc`.
- Minimal `BUILDER_READY` JSONL record:

  ```json
  {"ts":"<utc>","actor":"builder","event":"BUILDER_READY","run_id":"<run-id>","step":"<step>","status":"ready","summary":"Builder is ready to work.","evidence":{"builder_session_key":"<builder-session-key>","active_worktree_path":"<worktree-path>","active_step":"<step>","tool_access":"ready|blocked|unknown","mcp_access":"ready|blocked|unknown"}}
  ```

Both Master Chef and Builder must append durable evidence for Builder spawn, Builder readiness, step start, validation, blockers, completion, and reporting.

Builder monitoring must use direct runtime evidence before heuristics:

- If the runtime can expose direct Builder status, final messages, or explicit progress replies, use those surfaces first.
- If the runtime cannot expose live Builder reasoning or streaming partial output, say so explicitly and report Builder state as `running` or `unknown`, not `stale`, during quiet periods.
- Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second.
- Keep `builder_phase: booting` until a runtime-reported child-started signal, a coherent Builder readiness ACK, or a Builder-authored `BUILDER_READY` record lands in `builder.jsonl`.
- Treat a timed-out wait, a "no agent completed yet" result, or one unanswered progress request as inconclusive unless the runtime also reports closure or failure.
- Do not treat a returned session key, a missing diff, an empty `builder.jsonl`, or one short wait window with no completion as proof that Builder is fully started or has died.
- If no readiness signal arrives inside the adapter-defined boot window, use one explicit boot-status probe before classifying Builder as failed to start, blocked, or replaceable.
- For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before probing or replacing unless the runtime reports direct failure sooner.
- In foreground Codex and Claude flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
- Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
- Any coherent Builder reply, including a discovery-only or partial status report, is proof of life. Classify it as progress, route drift, or an explicit blocker, not as a dead Builder.
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
- if `run_step_budget` is a positive integer and `steps_completed_this_run` has reached it, stop cleanly with `RUN_STOPPED` and a final mission report instead of continuing automatically
- otherwise, re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains
- once the managed worktree becomes active, commit, push, QA, and TODO inspection happen against the active worktree path rather than the source checkout

## 9) Reporting and recovery

Report events:

- `START`
- `BUILDER_SPAWNED`
- `BUILDER_READY`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

When `BLOCKER_CLEARED` is emitted after a successful repair, record the original blocked step, the replacement step ids, the preserved remaining budget, and the next delegated action.

When the run ends with `RUN_COMPLETE`, `RUN_STOPPED`, a hard-stop `STEP_BLOCKED`, or `DEADLOCK_STOPPED`, emit a final mission report covering completed work, validations and pushes, Builder restarts or blocker repairs, unresolved session-setting fields, which effective Builder settings were concrete versus `unknown`, decisions made, and remaining work or the exact stop reason.

If repeated Builder replacements fail without progress, stop quickly and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` rather than limping on.

If a TODO step is blocked by a hard blocker, ambiguous scope, being oversized for one Builder run, or repeated failed Builder replacements:

- pause delegated implementation and report `STEP_BLOCKED` or `DEADLOCK_STOPPED`
- revise the situation in Master Chef before any more Builder work
- run the same continuation review again: inspect completed work, failed proof, remaining scope, likely recovery cost for a fresh Builder, and whether the remainder now forms cleaner child steps than the parent step did
- treat many checklist items, many touched files, or broad-looking wording as non-signals by themselves; use them only when they materially raise one-run failure risk
- treat repeated debug or validation churn, replanning pressure, expensive hard-gate recovery loops, or a remainder that now forms clearer executable chunks as supporting evidence that the current step boundary is too risky
- if a minimal TODO repair restores one-run viability without changing the true scope, repair the step in place and continue that same parent step with a fresh single-step Builder run
- otherwise, decompose only the remaining work into smaller decision-complete TODO steps through Master-Chef-direct planning or TODO repair
- clean only stale runtime or build artifacts when they are actually needed for a coherent retry, and never revert unrelated user work
- if repair or split yields a safe autonomous next step, emit `BLOCKER_CLEARED`, preserve the active run plus remaining `run_step_budget`, do not increment `steps_completed_this_run`, and continue from the same repaired parent step or the next smaller actionable child step with a fresh single-step Builder run
- if a hard technical or physical limit still prevents safe autonomous continuation after repair, keep the run stopped and report the exact limit plus the decisions made before stopping
- do not retry the same broad blocked step unchanged

## 10) Context compaction

Manage Master Chef context explicitly during long runs:

- keep Builder context fresh through single-step Builder runs; do not compact or resume Builders as the normal path
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
