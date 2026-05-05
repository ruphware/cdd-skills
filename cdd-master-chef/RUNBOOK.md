# Master Chef Shared Runbook

Use this runbook for shared operational procedures that apply across runtime adapters.

Adapter docs may add runtime-specific detail, but they must not contradict this shared runbook.

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
<source-repo>/.cdd-runtime/master-chef/worktrees/<run-id>/
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
3. If the active TODO file has a finite remaining unfinished top-level TODO step-heading count, recommend that exact count as the default/max `run_step_budget`, meaning "all remaining steps".
4. Choose the managed worktree path and fresh per-run branch name.
5. Run `git worktree add <path> -b <branch> HEAD` from the source checkout.
6. Initialize runtime state in the managed worktree.
7. Record the active worktree path and continuation mode in runtime state.
8. Continue in the managed worktree only if the runtime adapter can safely re-root Master Chef and Builder there.
9. Otherwise, stop with exact relaunch instructions that point the next Master Chef session at the managed worktree path.

## 2) Runtime-state additions

### `run.json`

Keep the existing fields and add:

- `source_repo`
- `source_branch`
- `source_head_sha`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `builder_phase`
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
- `builder_phase` is `not_started`, `booting`, `running`, `blocked`, `completed`, `failed`, or `closed`
- `builder_spawn_requested_at_utc` records when Master Chef received a Builder handle from the runtime
- `builder_ready_at_utc` records the first direct readiness signal that proves Builder started operating
- `last_builder_direct_signal_at_utc` tracks the latest direct Builder ACK, status reply, or runtime-native child-status signal
- `run_step_budget` is either a positive integer step count or `until_blocked_or_complete`
- `steps_completed_this_run` counts passed TODO steps in the current autonomous run

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

- source checkout path
- active worktree path
- worktree branch
- worktree continuation mode
- whether relaunch is still pending or the worktree session is active
- the approved run step budget and how many steps have already passed in this run
- the remaining top-level TODO step count when it drove the default budget recommendation

## 3) Continuation decision rule

Use this shared rule after worktree creation:

- if the runtime adapter can safely keep Master Chef and Builder operating from the managed worktree without losing control-plane coherence, set `worktree_continue_mode: in_session` and continue there
- otherwise, set `worktree_continue_mode: relaunch_required`, write exact relaunch instructions, and stop before implementation begins

Adapters that support subagent-backed Builder runs should prefer `worktree_continue_mode: in_session` when Master Chef can keep both its own commands and Builder delegation rooted at `active_worktree_path` coherently.

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

## 4) Active worktree behavior

Once the managed worktree becomes active:

- all repo inspection happens against the active worktree path
- QA, UAT, commit, and push happen against the active worktree path
- TODO inspection and TODO writeback happen against the active worktree path
- runtime files live under the active worktree's `.cdd-runtime/master-chef/`

Keep the source checkout path in runtime state for traceability and cleanup decisions.

## 5) Cleanup

Cleanup is approval-gated.

- do not remove user branches, commits, or worktrees without explicit approval
- cleanup may remove stale managed worktree directories or runtime artifacts only after the run is complete, abandoned, or superseded
- if cleanup is skipped, leave enough runtime metadata for the human to identify the active or stale managed worktree
