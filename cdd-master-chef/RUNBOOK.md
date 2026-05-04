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

### Creation sequence

1. Record the source checkout path, branch, and `HEAD` SHA.
2. Choose the managed worktree path and fresh per-run branch name.
3. Run `git worktree add <path> -b <branch> HEAD` from the source checkout.
4. Initialize runtime state in the managed worktree.
5. Record the active worktree path and continuation mode in runtime state.
6. Continue in the managed worktree only if the runtime adapter can safely re-root Master Chef and Builder there.
7. Otherwise, stop with exact relaunch instructions that point the next Master Chef session at the managed worktree path.

## 2) Runtime-state additions

### `run.json`

Keep the existing fields and add:

- `source_repo`
- `source_branch`
- `source_head_sha`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `run_step_budget`
- `steps_completed_this_run`

Field meanings:

- `repo` is the active repo root for the running session once the worktree becomes active
- `source_repo` is the original checkout path where the run was requested
- `active_worktree_path` is the managed worktree path for the run
- `worktree_continue_mode` is `in_session` or `relaunch_required`
- `run_step_budget` is either a positive integer step count or `until_blocked_or_complete`
- `steps_completed_this_run` counts passed TODO steps in the current autonomous run

### `run.lock.json`

Keep the existing fields and add:

- `source_repo`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `run_step_budget`

### `context-summary.md`

The durable checkpoint must now also record:

- source checkout path
- active worktree path
- worktree branch
- worktree continuation mode
- whether relaunch is still pending or the worktree session is active
- the approved run step budget and how many steps have already passed in this run

## 3) Continuation decision rule

Use this shared rule after worktree creation:

- if the runtime adapter can safely keep Master Chef and Builder operating from the managed worktree without losing control-plane coherence, set `worktree_continue_mode: in_session` and continue there
- otherwise, set `worktree_continue_mode: relaunch_required`, write exact relaunch instructions, and stop before implementation begins

Adapters that support subagent-backed Builder runs should prefer `worktree_continue_mode: in_session` when Master Chef can keep both its own commands and Builder delegation rooted at `active_worktree_path` coherently.

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
