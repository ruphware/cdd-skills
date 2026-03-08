# cdd-master-chef Test Harness Checklist (OpenClaw-direct mode)

Goal: validate the flow **kickoff -> repo-local runtime state -> Builder subagent -> main-session watchdog wakeups -> direct status updates -> final results**.

## 1) Preflight

- [ ] Installed skill exists:
  ```bash
  ls ~/.openclaw/skills/cdd-master-chef/SKILL.md >/dev/null
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
  - explicit kickoff approval request

### Prompt B - Kickoff approval

```text
/cdd-master-chef Approve the proposed next action.
Use this session as the control route.
Use <STATUS_ROUTE> as the status route with policy best_effort.
Use Builder model <BUILDER_MODEL> with thinking <BUILDER_THINKING>.
Initialize .cdd-runtime/master-chef/, acquire the run lease, create the watchdog cron as a main-session systemEvent, spawn the Builder subagent, and continue autonomously.
```

- [ ] Expected:
  - `.cdd-runtime/master-chef/` exists
  - `run.json`, `run.lock.json`, `master-chef.jsonl`, `builder.jsonl`, and `watchdog.jsonl` exist
  - exactly one watchdog cron exists
  - Builder starts as a subagent

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
Try steering the current Builder if possible. If not, replace it with a fresh Builder subagent for the same step. Update runtime state and report BUILDER_RESTARTED.
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

### Prompt H - Working-tree-aware discovery checks

```text
/cdd-master-chef TEST ONLY: simulate a step that creates new unstaged files matching a discovery grep.
Use working-tree-aware discovery and show why this remains a soft_signal unless the step explicitly says otherwise.
```

- [ ] Expected:
  - working-tree-aware discovery is used
  - unstaged files are discoverable
  - no false hard failure

### Prompt I - Status-route direct send

```text
/cdd-master-chef TEST ONLY: simulate a START and a HEARTBEAT event.
Send concise direct status updates to <STATUS_ROUTE> from the main session.
```

- [ ] Expected:
  - status is sent directly by the main session
  - watchdog cron itself does not announce independently

### Prompt J - Status-route failure policy

```text
/cdd-master-chef TEST ONLY: simulate status-route failure.
First treat it as best_effort, then as required, and show the different outcomes.
```

- [ ] Expected:
  - `best_effort` -> control route notes degraded reporting and run continues
  - `required` -> run stops and reports blocker

### Prompt K - Continue the run

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final results summary.
```

- [ ] Expected:
  - Master Chef reviews Builder output
  - passed steps include QA, UAT, commit, push, and `STEP_PASS`
  - run continues automatically when appropriate

### Prompt L - Deadlock

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
- [ ] Working-tree-aware discovery checks were used when needed.
- [ ] `soft_signal` and `hard_gate` behavior stayed distinct.
- [ ] Status updates were sent directly by the main session.
- [ ] Status-route failure behavior matched policy.
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
