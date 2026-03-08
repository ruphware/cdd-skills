# cdd-master-chef Test Harness Checklist

Goal: validate the full flow **model selection -> repo inspection -> kickoff approval -> isolated watchdog cron -> ACP Codex Builder -> autonomous progression -> dual-route reporting -> final results**.

## 1) Preflight (2-3 min)

- [ ] Installed skill exists:
  ```bash
  ls ~/.openclaw/skills/cdd-master-chef/SKILL.md >/dev/null
  ```

- [ ] ACP backend is healthy:
  ```text
  /acp doctor
  ```

- [ ] Codex CLI is reachable:
  ```bash
  codex --version
  ```

- [ ] Separate core CDD Builder skills are available:
  ```bash
  ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null
  ```

- [ ] OpenClaw session tools are configured broadly enough for an isolated watchdog to reach the active Master Chef session.

- [ ] A control route is identified:
  - usually the current TUI/OpenClaw session

- [ ] A status route is identified or intentionally omitted:
  - for example Slack `#testering`

---

## 2) Create a throwaway CDD repo with pushable upstream (2 min)

```bash
TEST_ROOT=/home/norman/.openclaw/workspace/tmp/mc-harness
SRC=/home/norman/Workspace/cdd-boilerplate
TS=$(date -u +%Y%m%dT%H%M%SZ)
REMOTE_REPO="$TEST_ROOT/remote-$TS.git"
TEST_REPO="$TEST_ROOT/repo-$TS"

mkdir -p "$TEST_ROOT"
git clone --bare "$SRC" "$REMOTE_REPO"
git clone "$REMOTE_REPO" "$TEST_REPO"

echo "$TEST_REPO"
```

- [ ] Confirm the repo has the CDD boilerplate:
  ```bash
  ls "$TEST_REPO/AGENTS.md" "$TEST_REPO/README.md" >/dev/null
  ls "$TEST_REPO"/TODO*.md >/dev/null
  ```

- [ ] Confirm the clone has an upstream:
  ```bash
  git -C "$TEST_REPO" rev-parse --abbrev-ref --symbolic-full-name @{upstream}
  ```

---

## 3) Prompt sequence (copy/paste into OpenClaw chat)

### Prompt A - Select the Master Chef model

```text
/model <MASTER_MODEL>
```

- [ ] Expected: the session now uses the chosen Master Chef model.

### Prompt B - Select the Builder model

```text
/acp model <BUILDER_MODEL>
```

- [ ] Expected: ACP now uses the chosen Builder model.

### Prompt C - Kickoff inspection only

```text
/cdd-master-chef Use the Master Chef process for repo <TEST_REPO>.
Treat this session as the control route.
Treat <STATUS_ROUTE> as the optional status route with policy best_effort unless I say otherwise.
Inspect the repo, tell me which TODO step is next,
and wait for my kickoff approval before creating the watchdog cron.
```

- [ ] Expected:
  - model status checks
  - repo readiness checks
  - session-tool visibility check
  - current git/TODO state summary
  - proposed next action, normally the next runnable `cdd-implement-todo` step
  - explicit route confirmation
  - one explicit kickoff approval request

### Prompt D - Approve kickoff and create cron

```text
/cdd-master-chef Approve the proposed next action.
Use this session as the control route.
Use <STATUS_ROUTE> as the status route with policy best_effort.
Initialize .cdd-runtime/master-chef/, acquire the run lease,
create the 5-minute isolated watchdog cron, and continue autonomously after kickoff.
```

- [ ] Expected:
  - `.cdd-runtime/master-chef/` is initialized
  - `run.json`, `run.lock.json`, `master-chef.jsonl`, `builder.jsonl`, and `watchdog.jsonl` exist
  - one isolated cron watchdog is created
  - the first Builder action begins through ACP Codex
  - Master Chef does not ask for another approval before the first step starts

### Prompt E - Verify the cron exists

```bash
openclaw cron list | rg cdd-master-chef-watchdog
```

- [ ] Expected: exactly one watchdog cron entry for the active repo/session.

### Prompt F - Verify runtime files exist

```bash
ls "$TEST_REPO/.cdd-runtime/master-chef/run.json" \
   "$TEST_REPO/.cdd-runtime/master-chef/run.lock.json" \
   "$TEST_REPO/.cdd-runtime/master-chef/master-chef.jsonl" \
   "$TEST_REPO/.cdd-runtime/master-chef/builder.jsonl" \
   "$TEST_REPO/.cdd-runtime/master-chef/watchdog.jsonl" >/dev/null
```

- [ ] Expected: all runtime state and log files exist.

### Prompt G - Test-only healthy watchdog probe

```text
/cdd-master-chef TEST ONLY: simulate one isolated watchdog tick now.
Do deterministic checks first, then probe Master Chef.
Confirm Builder is healthy and do not restart or resume anything.
```

- [ ] Expected:
  - no false restart
  - no false resume
  - watchdog notes a healthy Master Chef and Builder state

### Prompt H - Test-only 15-minute heartbeat

```text
/cdd-master-chef TEST ONLY: simulate that 15 minutes passed since the last status report.
Send HEARTBEAT with both Master Chef and Builder summaries.
Send full detail to the control route and condensed detail to the status route.
```

- [ ] Expected:
  - `HEARTBEAT` report in the control route with full context
  - `HEARTBEAT` report in the status route with condensed context

### Prompt I - Test-only stale Builder with healthy Master Chef

```text
/cdd-master-chef TEST ONLY: simulate that Builder logs went stale but Master Chef probe succeeds.
Have the watchdog tell Master Chef to resume Builder, then report BUILDER_RESUMED.
```

- [ ] Expected: resumed Builder flow and `BUILDER_RESUMED`.

### Prompt J - Test-only stale Master Chef

```text
/cdd-master-chef TEST ONLY: simulate that Master Chef logs are stale and the session probe fails.
Use run.json and run.lock.json to rehydrate the same run, avoid starting a second autonomous run,
and report MASTER_CHEF_RESTARTED.
```

- [ ] Expected:
  - same run is restored
  - no duplicate autonomous run is created
  - `MASTER_CHEF_RESTARTED` is reported

### Prompt K - Test-only duplicate-run prevention

```text
/cdd-master-chef TEST ONLY: simulate a second autonomous start attempt while a healthy active lease exists.
Refuse to start a duplicate run and report the active lease owner.
```

- [ ] Expected:
  - no duplicate run starts
  - lease conflict is reported clearly

### Prompt L - Test-only working-tree-aware discovery check

```text
/cdd-master-chef TEST ONLY: simulate a step that creates new unstaged files matching a discovery grep.
Confirm the Builder uses a working-tree-aware discovery check rather than tracked-files-only discovery.
Do not fail the step solely because the files are not staged yet.
```

- [ ] Expected:
  - Master Chef / Builder distinguish working-tree discovery from tracked-files-only discovery
  - new untracked files are discoverable
  - no false blocker from tracked-files-only grep behavior

### Prompt M - Test-only soft signal vs hard gate

```text
/cdd-master-chef TEST ONLY: classify these validations:
- pnpm test
- pnpm typecheck
- rg --files | rg "workspace|kpi"
- git ls-files --cached --others --exclude-standard | rg "questionnaire|kpi"
Explain which are hard_gate and which are soft_signal, then show how a soft_signal failure should be reported.
```

- [ ] Expected:
  - tests and typecheck are `hard_gate`
  - discovery checks are `soft_signal` unless the step explicitly makes them blocking
  - soft-signal failure is reported without collapsing the run incorrectly

### Prompt N - Let the autonomous run continue

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final results summary.
```

- [ ] Expected:
  - passed steps include QA, Master Chef UAT approval, commit, push, and `STEP_PASS`
  - if another runnable step exists, Master Chef continues without another approval request
  - if the run is done, Master Chef reports `RUN_COMPLETE`

### Prompt O - Test-only status-route failure policy

```text
/cdd-master-chef TEST ONLY: simulate that the status route is failing while control-route reporting still works.
First treat the status route as best_effort, then as required.
Show the different outcomes.
```

- [ ] Expected:
  - `best_effort` -> degraded external reporting noted in control route, run continues
  - `required` -> run stops and reports blocker

### Prompt P - Test-only deadlock

```text
/cdd-master-chef TEST ONLY: simulate two failed recoveries without forward progress.
Stop the run, remove the cron, and report DEADLOCK_STOPPED.
```

- [ ] Expected: halted run, removed cron, and `DEADLOCK_STOPPED`.

---

## 4) Pass criteria

- [ ] Model selection happened before `/cdd-master-chef` kickoff.
- [ ] Master Chef refused to start implementation before inspecting the repo and proposing the next action.
- [ ] `control_route` was confirmed before kickoff.
- [ ] `status_route` policy was confirmed or intentionally omitted before kickoff.
- [ ] Exactly one isolated watchdog cron job was created after kickoff approval.
- [ ] `.cdd-runtime/master-chef/` was created and kept out of tracked project files.
- [ ] `run.lock.json` exists and duplicate-run protection works.
- [ ] Builder used ACP Codex as the primary execution path.
- [ ] Builder used `cdd-implement-todo` for the normal next runnable step, or `cdd-plan` only if the TODO state was not execution-ready.
- [ ] After a passed step, the selected step's task items are marked done in the active `TODO*.md` file and unrelated steps were left alone.
- [ ] Both `master-chef.jsonl` and `builder.jsonl` contain fresh entries during active work.
- [ ] Step reports explicitly include `Master Chef UAT approved`.
- [ ] Heartbeat reports summarize both Master Chef and Builder status.
- [ ] Control-route reports are more detailed than status-route reports.
- [ ] Current branch head matches upstream after a passed step:
  ```bash
  test "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse @{upstream})"
  ```
- [ ] If another runnable TODO step exists, Master Chef continues automatically without another human approval.
- [ ] Discovery checks are working-tree-aware when unstaged files matter.
- [ ] Soft-signal failures do not incorrectly collapse the run.
- [ ] The run ends with either a final results summary or a blocked/deadlock report.

---

## 5) Cleanup

If the watchdog cron is still present after the harness:

```bash
openclaw cron list | rg cdd-master-chef-watchdog
openclaw cron rm <job-id>
```

If the ACP Builder is still active:

```text
/acp cancel
```

If the runtime path should be removed from the throwaway repo:

```bash
rm -rf "$TEST_REPO/.cdd-runtime/master-chef"
```
