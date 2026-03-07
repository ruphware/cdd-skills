# cdd-master-chef Test Harness Checklist

Goal: validate the full loop **OpenClaw (Master Chef + Watchdog) -> ACP Codex (Builder) -> QA/UAT -> commit/push/reporting**.

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

- [ ] Separate CDD Builder skills are available:
  ```bash
  ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null
  ```

Model and reasoning settings are intentionally managed outside this skill. Inspect or override them only if your environment requires it.

## 2) Create a throwaway repo and reporting stub (2 min)

```bash
TEST_ROOT=/home/norman/.openclaw/workspace/tmp/mc-harness
SRC=/home/norman/Workspace/cdd-boilerplate
TS=$(date -u +%Y%m%dT%H%M%SZ)
REMOTE_REPO="$TEST_ROOT/remote-$TS.git"
TEST_REPO="$TEST_ROOT/repo-$TS"
REPORT_LOG="$TEST_ROOT/report-$TS.log"
REPORTER="$TEST_ROOT/report-status.sh"

mkdir -p "$TEST_ROOT"
git clone --bare "$SRC" "$REMOTE_REPO"
git clone "$REMOTE_REPO" "$TEST_REPO"

cat >"$REPORTER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'TARGET=%s EVENT=%s STEP=%s STATUS=%s\n' "\${CDD_REPORT_TARGET:?}" "\${CDD_REPORT_EVENT:?}" "\${CDD_REPORT_STEP:-}" "\${CDD_REPORT_STATUS:-}" >>"$REPORT_LOG"
printf '%s\n\n' "\${CDD_REPORT_BODY:-}" >>"$REPORT_LOG"
EOF
chmod +x "$REPORTER"

echo "$TEST_REPO"
echo "$REPORTER"
echo "$REPORT_LOG"
```

- [ ] Keep `TEST_REPO`, `REPORTER`, and `REPORT_LOG` handy for the prompts below.
- [ ] Confirm the clone has an upstream:
  ```bash
  git -C "$TEST_REPO" rev-parse --abbrev-ref --symbolic-full-name @{upstream}
  ```

## 3) Prompt sequence (copy/paste into OpenClaw chat)

### Prompt A — Bootstrap and draft

```text
/cdd-master-chef Use the Master Chef process for repo <TEST_REPO>.
REPORTING_COMMAND=<REPORTER>
REPORTING_TARGET=test-log

Open the control block, send START, run preflight, and spawn or reuse an ACP Codex Builder session for that repo.
In the Builder, run cdd-index first and then cdd-plan.
Target tiny change:
- Add docs/SMOKE.md with a 5-line "how this repo works" summary.
- Add one link to docs/SMOKE.md in README.md.
Draft only. Do not apply anything until I approve.
```

- [ ] Expected: startup contract confirmation, control block, `START` report, preflight evidence, ACP Codex session evidence, `cdd-index` plus `cdd-plan` evidence, draft edits, and an explicit approval question.

### Prompt B — Apply the planning step only

```text
/cdd-master-chef Approve and apply those planned TODO or contract edits exactly.
After Master Chef QA, approve step-level UAT, commit, push, and send STEP_PASS.
```

- [ ] Expected: planning/TODO edits only, Master Chef QA, explicit `Master Chef UAT approved`, commit, push, and `STEP_PASS`.

### Prompt C — Start implementation but leave it active

```text
/cdd-master-chef Start the approved implementation step through ACP Codex.
Run cdd-implement-todo for the exact approved step.
Stop after the Builder is actively running and the control block is updated.
Do not close the step yet.
```

- [ ] Expected: active Builder session, active control block, no final commit/push yet.

### Prompt D — 5-minute watchdog tick

```text
/cdd-master-chef WATCHDOG_TICK 5m.
Check the control block and Builder health.
If the process is healthy, keep it running and do not send RESUME.
```

- [ ] Expected: watchdog inspection only, no false resume.

### Prompt E — 15-minute heartbeat tick

```text
/cdd-master-chef WATCHDOG_TICK 15m.
Send the required HEARTBEAT report for the active step.
```

- [ ] Expected: `HEARTBEAT` report with step, phase, last progress timestamp, blocker, restart count, and next action.

### Prompt F — Simulate Builder death and resume

```text
/cdd-master-chef Assume the active Builder process died after the last recorded progress update.
WATCHDOG_TICK 5m.
Use the control block to resume the same step, increment restart state, and send RESUME.
```

- [ ] Expected: resumed Builder flow and `RESUME` report.

### Prompt G — Finish the implementation step

```text
/cdd-master-chef Complete the same approved step.
Re-run the Master Chef QA gate, approve step-level UAT, commit, push, and send STEP_PASS.
```

- [ ] Expected: implementation patch, validation commands, Master Chef UAT approval, commit, push, and `STEP_PASS`.

### Prompt H — Simulate a resolved dispute

```text
/cdd-master-chef Simulate a technical dispute for the next step.
Builder argues that the README link should be omitted; Master Chef argues it is required by the approved step.
Resolve the dispute internally through evidence and challenge, then send DISPUTE_RESOLVED.
Do not ask me to break the tie.
```

- [ ] Expected: both positions, evidence, final decision, and `DISPUTE_RESOLVED`.

### Prompt I — Simulate deadlock after 2 loops

```text
/cdd-master-chef Simulate the same blocker surviving 2 full Master Chef <-> Builder challenge loops without clear progress.
Stop the step and send DEADLOCK_STOPPED with the smallest recovery path.
```

- [ ] Expected: halted step and `DEADLOCK_STOPPED`.

## 4) Pass criteria

- [ ] Exactly one real approved implementation step was planned and implemented.
- [ ] Builder used `cdd-index`, `cdd-plan`, and `cdd-implement-todo`, or documented an approved exception.
- [ ] Control block was opened and maintained.
- [ ] Master Chef reports explicitly include `Master Chef UAT approved`.
- [ ] Current branch head matches upstream after `STEP_PASS`:
  ```bash
  test "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse @{upstream})"
  ```
- [ ] `REPORT_LOG` contains all required event types:
  ```bash
  rg -n 'EVENT=START|EVENT=HEARTBEAT|EVENT=RESUME|EVENT=STEP_PASS|EVENT=DISPUTE_RESOLVED|EVENT=DEADLOCK_STOPPED' "$REPORT_LOG"
  ```
- [ ] Validation commands were run and reported with outputs.
- [ ] No unrelated file churn.

## 5) Abort / recovery

If the run drifts or hangs:

```text
/acp cancel
STOP. Summarize partial changes only.
```
