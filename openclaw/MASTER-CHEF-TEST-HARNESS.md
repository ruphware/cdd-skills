# cdd-master-chef Test Harness Checklist (OpenClaw-direct mode)

Goal: validate the flow **kickoff -> Master-Chef skill routing -> repo-local runtime state -> Builder subagent -> direct in-session Builder checks -> in-session lifecycle reporting -> final results**.

## 1) Preflight

- [ ] Installed skill pack exists:
  ```bash
  ls ~/.openclaw/skills/cdd-master-chef/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-boot/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-maintain/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-init-project/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-plan/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-implement-todo/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-index/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-refactor/SKILL.md >/dev/null
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

- [ ] One explicit Run config block is prepared.

- [ ] Main session is using `master_model` from that Run config.

- [ ] `builder_model` and `builder_thinking` are known from that same Run config.

- [ ] The Run config stays model-only:

  ```text
  Run config:
    master_model: gpt-5.4
    master_thinking: xhigh
    builder_model: gpt-5.4
    builder_thinking: xhigh
  ```

---

## 2) Prompt sequence

### Prompt A - Inspection only

```text
/cdd-master-chef Use the Master Chef process for repo <REPO>.
Run config:
<RUN_CONFIG>
Inspect the repo, tell me which TODO step is next, and wait for kickoff approval before creating runtime state or spawning the Builder.
```

- [ ] Expected:
  - repo readiness check
  - branch/upstream check
  - TODO inspection
  - proposed next runnable step
  - explicit routing choice: usually Builder via `cdd-implement-todo`, sometimes Builder via `cdd-index`, otherwise Master Chef direct for setup/planning/refactor work
  - explicit kickoff approval request

### Prompt B - Kickoff approval

```text
/cdd-master-chef Approve the proposed next action.
Run config:
<RUN_CONFIG>
Initialize .cdd-runtime/master-chef/, acquire the run lease, route the approved action through the correct internal cdd skill, spawn the Builder only if the action is delegated, and continue autonomously.
```

- [ ] Expected:
  - `.cdd-runtime/master-chef/` exists
  - `run.json`, `run.lock.json`, `master-chef.jsonl`, and `builder.jsonl` exist
  - `run.json` records the exact approved Run config
  - no watchdog cron is created
  - Builder starts as a one-step subagent run only when the chosen action is delegated
  - the routing choice is named explicitly in the handoff or main-session action

### Prompt C - Verify runtime files

```bash
ls <REPO>/.cdd-runtime/master-chef/run.json \
   <REPO>/.cdd-runtime/master-chef/run.lock.json \
   <REPO>/.cdd-runtime/master-chef/master-chef.jsonl \
   <REPO>/.cdd-runtime/master-chef/builder.jsonl >/dev/null
```

- [ ] Expected: all runtime files exist.

### Prompt D - Verify no cron exists

```bash
openclaw cron list | rg cdd-master-chef-watchdog
```

- [ ] Expected: no watchdog cron exists.

### Prompt E - Healthy Builder check

```text
/cdd-master-chef TEST ONLY: simulate one direct Builder health check in the main session.
Check runtime files and Builder health. If healthy, do not replace Builder and do not send unnecessary extra chatter.
A healthy Builder check may stay quiet, but lifecycle events should still be reported clearly in-session when they actually happen.
```

- [ ] Expected:
  - no false restart
  - no false blocker
  - Builder-check reasoning happens in the main session
  - healthy tick silence does not redefine or bypass in-session lifecycle reporting expectations

### Prompt F - Stale Builder

```text
/cdd-master-chef TEST ONLY: simulate that Builder progress has gone stale.
Replace it quickly with a fresh Builder subagent for the same step rather than resurrecting the old session.
Keep the same TODO step, update runtime state, and report BUILDER_RESTARTED.
```

- [ ] Expected:
  - Builder recovery happens in the main session
  - stale recovery prefers fresh replacement over session resurrection
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

### Prompt H - Routing model

```text
/cdd-master-chef TEST ONLY: explain the routing choice for the current repo state.
Use Builder via cdd-implement-todo for a normal runnable TODO step.
Use Builder via cdd-index only when an index refresh is the delegated action.
Explain why cdd-boot is a manual helper rather than part of the normal flow.
Explain why cdd-maintain is a manual helper rather than part of the normal flow.
Use cdd-init-project, cdd-plan, or cdd-refactor directly in Master Chef when setup, planning, or refactor decomposition is needed.
Explain why cdd-audit-and-implement is excluded from the normal flow.
```

- [ ] Expected:
  - `cdd-boot` is called out as a manual / non-routed helper
  - `cdd-maintain` is called out as a manual / non-routed helper
  - `cdd-implement-todo` is the default Builder path
  - `cdd-index` is treated as a delegated exception, not the default
  - `cdd-init-project`, `cdd-plan`, and `cdd-refactor` are treated as Master-Chef-direct skills
  - `cdd-audit-and-implement` is called out as excluded / non-default

### Prompt I - Continue the run

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final results summary.
```

- [ ] Expected:
  - Master Chef reviews Builder output
  - the delegated path matches the routing choice rather than defaulting blindly
  - if another runnable delegated step exists, Master Chef starts a fresh one-step Builder run for it, normally via `cdd-implement-todo`
  - passed steps include TODO writeback, QA, UAT, commit, push, and `STEP_PASS`
  - lifecycle events such as `START` / `STEP_PASS` / `STEP_BLOCKED` / `RUN_COMPLETE` are reported clearly in the current session

### Prompt J - QA reject remediation

```text
/cdd-master-chef TEST ONLY: simulate that Builder returned a result that fails Master Chef QA.
Keep the same TODO step active, record concrete QA findings, choose either a fresh Builder run for the same step or a direct Master Chef fix, re-run QA/UAT, and only then commit, push, advertise STEP_PASS, and continue automatically.
```

- [ ] Expected:
  - no `STEP_PASS`, commit, or push happens before remediation and re-run QA
  - QA findings are recorded in `master-chef.jsonl`
  - remediation uses either a fresh one-step Builder run for the same step or a direct Master Chef fix
  - after QA passes, `STEP_PASS` is advertised in the current Master Chef session before TODO re-inspection and automatic continuation

### Prompt K - Deadlock

```text
/cdd-master-chef TEST ONLY: simulate two failed Builder replacements without forward progress.
Stop the run and report DEADLOCK_STOPPED.
```

- [ ] Expected:
  - run stops cleanly
  - deadlock is reported clearly

### Prompt L - In-session reporting contract

```text
/cdd-master-chef TEST ONLY: simulate one successful STEP_PASS update and one STEP_BLOCKED update.
Report them in the current session and update runtime evidence exactly as the reporting contract requires.
```

- [ ] Expected:
  - both lifecycle updates are reported in the current Master Chef session
  - `master-chef.jsonl` records the lifecycle events
  - `run.json` stays focused on run state and does not grow route metadata

---

## 3) Pass criteria

- [ ] Main session acted as the only control plane.
- [ ] Builder ran as an OpenClaw subagent.
- [ ] No watchdog cron or second supervising loop was used.
- [ ] Runtime files were created in the repo.
- [ ] Duplicate-run prevention worked.
- [ ] Builder recovery stayed inside the main session.
- [ ] Master Chef chose the correct routing path for the repo state.
- [ ] `cdd-implement-todo` remained the default delegated path for normal step execution.
- [ ] Builder runs stayed one-step only; the next delegated step got a fresh Builder run.
- [ ] Builder session resurrection was not used as the normal continuation or recovery path.
- [ ] Passed Builder steps updated only the selected TODO step on success.
- [ ] Passed steps included QA, UAT, commit, push, and reporting.
- [ ] QA-rejected Builder output was remediated and rechecked before `STEP_PASS`, commit, push, and automatic continuation.
- [ ] Lifecycle events were reported in the Master Chef session.
- [ ] Run config and runtime state stayed free of extra route metadata.
- [ ] Repeated failed Builder replacements stopped the run instead of limping onward.
- [ ] Run ended with `RUN_COMPLETE`, `STEP_BLOCKED`, or `DEADLOCK_STOPPED`.

---

## 4) Cleanup

If the runtime directory should be removed from the test repo:

```bash
rm -rf <REPO>/.cdd-runtime/master-chef
```
