# cdd-master-chef Test Harness Checklist (OpenClaw-direct mode)

Goal: validate the flow **kickoff -> repo-local runtime state -> internal OpenClaw `cdd-*` Builder skills -> Builder subagent -> main-session watchdog wakeups -> direct status updates -> final results**.

## 1) Preflight

- [ ] Installed skill pack exists:
  ```bash
  ls ~/.openclaw/skills/cdd-master-chef/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-plan/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-implement-todo/SKILL.md >/dev/null
  ```

- [ ] Repo is CDD-ready:
  ```bash
  ls <REPO>/AGENTS.md <REPO>/README.md >/dev/null
  ls <REPO>/TODO*.md >/dev/null
  ```

- [ ] Repo has an upstream:
  ```bash
  git -C <REPO> rev-parse --abbrev-ref --symbolic-full-name @{upstream}
  ```

- [ ] Main session is using the intended Master Chef model.

- [ ] Builder model and thinking level are known.

- [ ] Control route is the current session.

- [ ] Status route is confirmed or intentionally omitted.

---

## 2) Prompt sequence

### Prompt A - Inspection only

```text
/cdd-master-chef Use the Master Chef process for repo <REPO>.
Treat this session as the control route.
Treat <STATUS_ROUTE> as the optional status route with policy best_effort unless I say otherwise.
Use Builder model <BUILDER_MODEL> with thinking <BUILDER_THINKING>.
Inspect the repo, tell me which TODO step is next, and wait for kickoff approval before creating runtime state or the cron.
```

- [ ] Expected:
  - repo readiness check
  - branch/upstream check
  - TODO inspection
  - proposed next runnable step
  - proposed Builder path is normally `cdd-implement-todo`
  - explicit kickoff approval request

### Prompt B - Kickoff approval

```text
/cdd-master-chef Approve the proposed next action.
Use this session as the control route.
Use <STATUS_ROUTE> as the status route with policy best_effort.
Use Builder model <BUILDER_MODEL> with thinking <BUILDER_THINKING>.
Initialize .cdd-runtime/master-chef/, acquire the run lease, create the watchdog cron as a main-session systemEvent, spawn the Builder subagent, have it use the shared OpenClaw cdd-* skill pack, and continue autonomously.
```

- [ ] Expected:
  - `.cdd-runtime/master-chef/` exists
  - `run.json`, `run.lock.json`, `master-chef.jsonl`, `builder.jsonl`, and `watchdog.jsonl` exist
  - exactly one watchdog cron exists
  - Builder starts as a subagent
  - Builder handoff names the internal `cdd-implement-todo` path for normal step execution

### Prompt C - Verify runtime files

```bash
ls <REPO>/.cdd-runtime/master-chef/run.json \
   <REPO>/.cdd-runtime/master-chef/run.lock.json \
   <REPO>/.cdd-runtime/master-chef/master-chef.jsonl \
   <REPO>/.cdd-runtime/master-chef/builder.jsonl \
   <REPO>/.cdd-runtime/master-chef/watchdog.jsonl >/dev/null
```

- [ ] Expected: all runtime files exist.

### Prompt D - Verify cron exists

```bash
openclaw cron list | rg cdd-master-chef-watchdog
```

- [ ] Expected: exactly one watchdog cron exists.

### Prompt E - Healthy watchdog tick

```text
/cdd-master-chef TEST ONLY: simulate one watchdog tick in the main session.
Check runtime files and Builder health. If healthy, do not replace Builder and do not send unnecessary status.
```

- [ ] Expected:
  - no false restart
  - no false blocker
  - watchdog reasoning happens in the main session

### Prompt F - Stale Builder

```text
/cdd-master-chef TEST ONLY: simulate that Builder progress has gone stale.
Try steering the current Builder if possible. If not, replace it with a fresh Builder subagent for the same step.
Keep the same TODO step, update runtime state, and report BUILDER_RESTARTED.
```

- [ ] Expected:
  - Builder recovery happens in the main session
  - runtime state is updated
  - no duplicate control loop is created

### Prompt G - Duplicate-run prevention

```text
/cdd-master-chef TEST ONLY: simulate a second kickoff attempt while an active coherent lease exists.
Refuse to start a duplicate run and report the active lease owner.
```

- [ ] Expected:
  - no duplicate run starts
  - lease conflict is reported clearly

### Prompt H - Builder skill path

```text
/cdd-master-chef TEST ONLY: explain which internal Builder skill should be used for the current runnable step and why.
If the TODO state is executable, prefer cdd-implement-todo.
If the TODO state is stale or ambiguous, explain why cdd-plan is the correct fallback.
```

- [ ] Expected:
  - `cdd-implement-todo` is the default Builder path
  - fallback to `cdd-plan` is justified only when the TODO state is not execution-ready

### Prompt I - Continue the run

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final results summary.
```

- [ ] Expected:
  - Master Chef reviews Builder output
  - Builder uses the internal OpenClaw `cdd-*` workflow rather than a Codex or ACP-only path
  - passed steps include TODO writeback, QA, UAT, commit, push, and `STEP_PASS`

### Prompt J - Deadlock

```text
/cdd-master-chef TEST ONLY: simulate two failed Builder replacements without forward progress.
Stop the run, remove the cron, and report DEADLOCK_STOPPED.
```

- [ ] Expected:
  - run stops cleanly
  - cron is removed
  - deadlock is reported clearly

---

## 3) Pass criteria

- [ ] Main session acted as the only control plane.
- [ ] Builder ran as an OpenClaw subagent.
- [ ] Watchdog was a main-session `systemEvent`, not an isolated agent.
- [ ] Runtime files were created in the repo.
- [ ] Duplicate-run prevention worked.
- [ ] Builder recovery stayed inside the main session.
- [ ] Master Chef chose `cdd-implement-todo` for normal step execution.
- [ ] Passed Builder steps updated only the selected TODO step on success.
- [ ] Passed steps included QA, UAT, commit, push, and reporting.
- [ ] Run ended with `RUN_COMPLETE`, `STEP_BLOCKED`, or `DEADLOCK_STOPPED`.

---

## 4) Cleanup

If the watchdog cron still exists:

```bash
openclaw cron list | rg cdd-master-chef-watchdog
openclaw cron rm <job-id>
```

If the runtime directory should be removed from the test repo:

```bash
rm -rf <REPO>/.cdd-runtime/master-chef
```
