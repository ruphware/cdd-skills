# cdd-master-chef Test Harness Checklist

Goal: validate the full upgrade flow **model selection -> repo inspection -> kickoff approval -> cron watchdog -> ACP Codex Builder -> autonomous progression -> final results**.

## 1) Preflight (2–3 min)

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

## 3) Prompt sequence (copy/paste into OpenClaw chat)

### Prompt A — Select the Master Chef model

```text
/model <MASTER_MODEL>
```

- [ ] Expected: the session now uses the chosen Master Chef model.

### Prompt B — Select the Builder model

```text
/acp model <BUILDER_MODEL>
```

- [ ] Expected: ACP now uses the chosen Builder model.

### Prompt C — Kickoff inspection only

```text
/cdd-master-chef Use the Master Chef process for repo <TEST_REPO>.
Inspect where development is at, tell me which TODO step is next, and use this session as the reporting channel.
Do not create the watchdog cron and do not start implementation until I approve the kickoff.
```

- [ ] Expected:
  - model status checks
  - repo readiness checks
  - current git/TODO state summary
  - proposed next action, normally the next runnable `cdd-implement-todo` step
  - one explicit kickoff approval request

### Prompt D — Approve kickoff and create cron

```text
/cdd-master-chef Approve the proposed next action.
Use this session as the reporting channel, create the 5-minute watchdog cron, and continue autonomously after kickoff.
```

- [ ] Expected:
  - control block is opened
  - one cron watchdog is created
  - the first Builder action begins
  - Master Chef does not ask for another human approval before the first step starts

### Prompt E — Verify the cron exists

```bash
openclaw cron list | rg cdd-master-chef-watchdog
```

- [ ] Expected: exactly one watchdog cron entry for the active repo/session.

### Prompt F — Test-only synthetic watchdog tick (healthy run)

```text
/cdd-master-chef TEST ONLY: simulate one watchdog tick now.
If the Builder is healthy, do not resume the run.
```

- [ ] Expected: no false resume.

### Prompt G — Test-only synthetic 15-minute heartbeat

```text
/cdd-master-chef TEST ONLY: simulate that 15 minutes passed since the last status report and send HEARTBEAT.
```

- [ ] Expected: `HEARTBEAT` report in the current session.

### Prompt H — Test-only dead Builder resume

```text
/cdd-master-chef TEST ONLY: simulate that the active Builder session died after the last progress update.
Run the watchdog logic once, resume the same step, and report RESUME.
```

- [ ] Expected: resumed Builder flow and `RESUME`.

### Prompt I — Let the autonomous run continue

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final results summary.
```

- [ ] Expected:
  - passed steps include QA, Master Chef UAT approval, commit, push, and `STEP_PASS`
  - if another runnable step exists, Master Chef continues without another approval request
  - if the run is done, Master Chef reports `RUN_COMPLETE`

### Prompt J — Test-only deadlock

```text
/cdd-master-chef TEST ONLY: simulate the same blocker surviving 2 full Master Chef <-> Builder challenge loops without progress.
Stop the run, remove the cron, and report DEADLOCK_STOPPED.
```

- [ ] Expected: halted run, removed cron, and `DEADLOCK_STOPPED`.

## 4) Pass criteria

- [ ] Model selection happened before `/cdd-master-chef` kickoff.
- [ ] Master Chef refused to start implementation before inspecting the repo and proposing the next action.
- [ ] The current session was used as the reporting channel.
- [ ] Exactly one watchdog cron job was created after kickoff approval.
- [ ] Builder used `cdd-implement-todo` for the normal next runnable step, or `cdd-plan` only if the TODO state was not execution-ready.
- [ ] After a passed step, the selected step's task items are marked done in the active `TODO*.md` file and unrelated steps were left alone.
- [ ] Step reports explicitly include `Master Chef UAT approved`.
- [ ] Current branch head matches upstream after a passed step:
  ```bash
  test "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse @{upstream})"
  ```
- [ ] If another runnable TODO step exists, Master Chef continues automatically without another human approval.
- [ ] The run ends with either a final results summary or a blocked/deadlock report.

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
