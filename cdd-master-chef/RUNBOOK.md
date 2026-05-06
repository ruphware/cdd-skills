# Master Chef Shared Runbook

Use this runbook for shared operational procedures that apply across runtime adapters.

Adapter docs may add runtime-specific detail, but they must not contradict this shared runbook.

When a shared approval or decision point is surfaced to the human through an adapter, use visible selector-based options when practical and let the human reply with just the selector.

## 0) Session settings

- Read the current session model and thinking directly from the active runtime surface.
- Treat those values as read-only Master Chef facts for the run.
- If one or both fields are not exposed exactly, record only those fields as `unknown`, say the runtime does not expose them here, and continue with the active session as-is.
- Default Builder to inherit those values unless an explicit `Builder override` is present.
- If a requested `Builder override` cannot be honored cleanly, state that explicitly and fall back to inherited Builder settings before kickoff.
- If Builder inherits from an unresolved parent field and no explicit override replaces it, keep the inherited Builder field as `unknown`.
- Do not ask the human to type replacement `master_*` settings when the runtime cannot expose them.
- Kickoff and final mission reporting must disclose any unresolved session-setting fields explicitly and note which effective Builder settings are concrete versus `unknown`.

## 1) Managed worktree policy

Master Chef runs against a managed worktree rather than mutating the source checkout in place.

### Preflight

Before kickoff, the source checkout must be clean.

- if `git status --short` shows tracked or staged changes, stop before worktree creation
- ask the human to stash, commit, or discard changes first
- do not promise dirty-state transfer into the managed worktree in v1

### Worktree location

Preferred managed location:

```text
<source-repo>/.cdd-runtime/worktrees/<run-id>/
```

Adapters may use a runtime-managed external location only if they document that choice explicitly.

### Branch naming

Create a fresh per-run branch from the current branch `HEAD`.

Preferred pattern:

```text
master-chef/<run-id>
```

Rules:

- do not reuse the source checkout branch for the managed worktree
- respect Git's one-branch-per-worktree rule
- do not tell the human or runtime to check out the same branch in multiple worktrees

### Fresh-start feature branch suggestion

If this is a fresh run and the source checkout is still on a long-lived branch such as `main`, `master`, or `trunk`, suggest creating a descriptive feature branch before provisioning the managed worktree.

If the human approves that suggestion:

- create the feature branch in the source checkout first
- treat that feature branch as `source_branch` for the run
- still create a separate per-run managed worktree branch such as `master-chef/<run-id>`

### Creation sequence

1. Inspect the source checkout path, branch, and `HEAD` SHA.
2. If this is a fresh run from a long-lived branch and no existing managed worktree is being resumed, recommend a descriptive feature branch first. If approved, create it in the source checkout and refresh `source_branch` and `source_head_sha`.
3. If the next runnable top-level TODO step is oversized for one Builder run, split it first only when the shared Builder-run-viability review says one-run completion already looks too risky. Otherwise keep the step intact while one fresh Builder can still finish it safely in one run, or repair it in place if a minimal TODO fix restores that viability without changing scope.
4. If the active TODO file has a finite remaining unfinished top-level TODO step-heading count, recommend that exact count as the default/max `run_step_budget`, meaning "all remaining steps", after any step split.
5. Choose the managed worktree path and fresh per-run branch name.
6. Run `git worktree add <path> -b <branch> HEAD` from the source checkout.
7. Initialize runtime state in the managed worktree, including `source_branch_decision`.
8. Record the active worktree path and continuation mode in runtime state.
9. Continue in the managed worktree only if the runtime adapter can safely re-root Master Chef and Builder there.
10. Otherwise, stop with exact relaunch instructions that point the next Master Chef session at the managed worktree path.
11. Once the managed worktree becomes active, inspect repo-native manifests, runbook commands, and validation entrypoints from that worktree.
12. Run the required dependency, build, install, or test-prep bootstrap commands in the active worktree, record the commands or checks in durable evidence, and keep `worktree_env_status` at `preparing` until the worktree is either `env_ready`, `partial`, or `blocked`.
13. Do not let Builder or `hard_gate` validation rely on the active worktree until `worktree_env_status` reaches `env_ready`.

## 2) Runtime-state additions

### `run.json`

Keep the existing fields and add:

- `source_repo`
- `source_branch`
- `source_head_sha`
- `source_branch_decision`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `worktree_env_status`
- `worktree_env_prepared_at_utc`
- `worktree_env_bootstrap_summary`
- `builder_phase`
- `builder_settings_source`
- `builder_spawn_requested_at_utc`
- `builder_ready_at_utc`
- `last_builder_direct_signal_at_utc`
- `run_step_budget`
- `steps_completed_this_run`

Field meanings:

- `repo` is the active repo root for the running session once the worktree becomes active
- `source_repo` is the original checkout path where the run was requested
- `active_worktree_path` is the managed worktree path for the run
- `worktree_continue_mode` is `in_session` or `relaunch_required`
- `source_branch_decision` is `accepted`, `declined`, or `not_applicable` for the default feature-branch recommendation
- `worktree_env_status` is `not_started`, `preparing`, `env_ready`, `partial`, or `blocked`
- `worktree_env_prepared_at_utc` records the latest time the active worktree bootstrap state became usable evidence
- `worktree_env_bootstrap_summary` is a concise summary of the latest repo-native bootstrap commands or checks that prepared or blocked the active worktree
- `builder_phase` is `not_started`, `booting`, `running`, `blocked`, `completed`, `failed`, or `closed`
- `builder_settings_source` is `inherited` or `override`
- `builder_spawn_requested_at_utc` records when Master Chef received a Builder handle from the runtime
- `builder_ready_at_utc` records the first direct readiness signal that proves Builder started operating
- `last_builder_direct_signal_at_utc` tracks the latest direct Builder ACK, status reply, or runtime-native child-status signal
- `run_step_budget` is either a positive integer step count or `until_blocked_or_complete`
- `steps_completed_this_run` counts passed TODO steps in the current autonomous run
- unresolved `master_*` or `builder_*` setting fields are stored as `unknown` rather than blocking kickoff

### `run.lock.json`

Keep the existing fields and add:

- `source_repo`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `builder_phase`
- `run_step_budget`

### `context-summary.md`

The durable checkpoint must now also record:

- current session model and thinking, with any unresolved field recorded as `unknown`
- effective Builder settings, whether they were inherited or overridden, and which fields are concrete versus `unknown`
- source checkout path
- whether the default feature-branch recommendation was accepted, declined, or not applicable
- active worktree path
- worktree branch
- worktree continuation mode
- worktree environment status, preparation time, and concise bootstrap summary
- whether relaunch is still pending or the worktree session is active
- the approved run step budget and how many steps have already passed in this run
- the remaining top-level TODO step count when it drove the default budget recommendation

## 3) Continuation decision rule

Use this shared rule after worktree creation:

- if the runtime adapter can safely keep Master Chef and Builder operating from the managed worktree without losing control-plane coherence, set `worktree_continue_mode: in_session` and continue there
- otherwise, set `worktree_continue_mode: relaunch_required`, write exact relaunch instructions, and stop before implementation begins

Once kickoff approval lands and implementation starts, Master Chef owns the mission under the approved run step budget. It keeps continuation, Builder restarts, blocker repair, TODO splitting, and next-step routing in-session unless a hard technical or physical limit forces a stop.

Adapters that support subagent-backed Builder runs should prefer `worktree_continue_mode: in_session` when Master Chef can keep both its own commands and Builder delegation rooted at `active_worktree_path` coherently.

### Shared Builder-run viability review

Use the same split-decision rule before Builder handoff and again after any non-passing Builder attempt.

- Ask whether one fresh Builder can plausibly finish the current step end-to-end without reopening planning, leaning on large context recovery, or falling into long repeated edit-validate-debug loops.
- Do not treat many checklist items, many touched files, or broad-looking wording as split reasons by themselves.
- Treat repeated debug or validation churn, replanning pressure, expensive hard-gate recovery loops, or a remainder that would naturally separate into clearer executable chunks if the attempt stalls as supporting evidence that the current step boundary is too risky.
- If a minimal TODO repair makes the step decision-complete and restores one-run viability without changing the true scope, repair it in place.
- Otherwise split only when Master Chef already has strong evidence that continuing as one Builder-sized run carries too much failure risk.

### Builder monitoring evidence

Use runtime-native Builder status surfaces before indirect repo heuristics.

- If the runtime does not expose live Builder reasoning or guaranteed streaming partial output, do not pretend it does.
- In Codex- or Claude-style adapters, direct status usually means final completion/failure notifications, explicit progress replies, or runtime-reported closure/errors, not live thinking traces.
- Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second.
- Immediately after spawn, record `builder_phase: booting`. A returned Builder handle or session key is not enough to prove that the child has loaded its usable repo and tool context.
- In Codex- or Claude-style adapters, the preferred readiness signal is one early Builder ACK that confirms the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or blocked.
- Use this shared boot prompt:

  ```text
  Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.
  ```

- A runtime-reported child-started signal or a Builder-authored `BUILDER_READY` record in `builder.jsonl` is also acceptable readiness evidence when the adapter can expose it coherently.
- Minimal `BUILDER_READY` evidence should include `builder_session_key`, `active_worktree_path`, `active_step`, `tool_access`, and `mcp_access`.
- During quiet periods, report `running` or `unknown` rather than `stale` unless direct failure evidence exists.
- A timed-out wait, a "no agent completed yet" result, or one unanswered status request is still inconclusive unless the runtime also reports closure or failure.
- A returned session key, a missing diff, an empty `builder.jsonl`, or a short wait with no completion is not enough to justify Builder replacement.
- Use a short adapter-defined boot window before the first boot-status probe; foreground Codex and Claude flows should default to about 2 minutes.
- For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless the runtime reports direct failure sooner.
- In foreground Codex and Claude flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
- Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
- After that grace window, use one explicit status probe before replacement when the runtime supports it.
- If Builder replies with a coherent discovery note, partial status, or other non-final report, treat that as proof of life and decide whether the issue is route drift or normal progress rather than declaring the Builder dead.

Exact relaunch instructions must include:

- the managed worktree path
- the branch name
- the required session or command shape for restarting Master Chef there
- the instruction to treat the managed worktree as the active repo root for commit, push, QA, and TODO inspection after relaunch

Terminal mission reports must cover completed work, validations and pushes, Builder restarts or blocker repairs, decisions made, and remaining work or the exact stop reason.

## 4) Active worktree behavior

Once the managed worktree becomes active:

- all repo inspection happens against the active worktree path
- repo-native manifests, runbook commands, and validation entrypoints are discovered from the active worktree path
- environment bootstrap commands and checks run in the active worktree rather than the source checkout
- QA, UAT, commit, and push happen against the active worktree path
- TODO inspection and TODO writeback happen against the active worktree path
- runtime files live under the active worktree's `.cdd-runtime/master-chef/`

Bootstrap the active worktree before Builder or `hard_gate` validation depend on it:

- set `worktree_env_status: preparing` when bootstrap begins
- run the repo-native dependency, build, install, credential, or test-prep commands needed for the approved Builder action and the repo's declared hard-gate path
- record the commands or checks that ran in durable evidence and write a concise `worktree_env_bootstrap_summary` in runtime state
- move `worktree_env_status` to `env_ready` only when the worktree is prepared enough for Builder and the repo's hard-gate validation path
- use `partial` when some bootstrap work succeeded but the worktree still is not ready for Builder or hard-gate reliance
- use `blocked` when a hard technical or physical limit prevents the worktree from becoming ready
- set `worktree_env_prepared_at_utc` whenever `env_ready`, `partial`, or `blocked` evidence is written
- do not let Builder or `hard_gate` validation rely on the worktree until `worktree_env_status` is `env_ready`

Keep the source checkout path in runtime state for traceability and cleanup decisions.

## 5) Cleanup

Cleanup is approval-gated.

- do not remove user branches, commits, or worktrees without explicit approval
- cleanup may remove stale managed worktree directories or runtime artifacts only after the run is complete, abandoned, or superseded
- if cleanup is skipped, leave enough runtime metadata for the human to identify the active or stale managed worktree
