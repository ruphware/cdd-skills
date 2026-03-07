# cdd-master-chef Test Harness Checklist

Goal: validate the loop **OpenClaw (Master Chef) -> ACP Codex (Builder) -> QA gate** with strong `cdd-*` usage.

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

## 2) Create a throwaway test repo (1 min)

```bash
TEST_ROOT=/home/norman/.openclaw/workspace/tmp/mc-harness
SRC=/home/norman/Workspace/cdd-boilerplate
TS=$(date -u +%Y%m%dT%H%M%SZ)
TEST_REPO="$TEST_ROOT/repo-$TS"
mkdir -p "$TEST_ROOT"
git clone "$SRC" "$TEST_REPO"
echo "$TEST_REPO"
```

- [ ] Keep `TEST_REPO` handy for the prompts below.

## 3) Prompt sequence (copy/paste into OpenClaw chat)

### Prompt A — Draft only

```text
/cdd-master-chef Use the Master Chef process for repo <TEST_REPO>.
First run the Builder preflight. Then spawn or reuse an ACP Codex Builder session for that repo.
In the Builder, run cdd-index first and then cdd-plan.
Target tiny change:
- Add docs/SMOKE.md with a 5-line "how this repo works" summary.
- Add one link to docs/SMOKE.md in README.md.
Draft only. Do not apply anything until I approve.
```

- [ ] Expected: preflight evidence, ACP Codex session evidence, `cdd-index` plus `cdd-plan` evidence, draft edits, and an explicit approval question.

### Prompt B — Apply the plan only

```text
/cdd-master-chef Approve and apply those planned TODO or contract edits exactly. No implementation yet.
```

- [ ] Expected: TODO or contract edits only.

### Prompt C — Implement one approved step

```text
/cdd-master-chef Implement the approved step through ACP Codex.
Run cdd-implement-todo for the exact approved step.
Implement only that step.
Do not bypass cdd-* unless blocked. If blocked, stop and report the blocker.
After Codex finishes, re-run the Master Chef QA gate and report:
GOAL, SCOPE, CHANGES, VALIDATION, UAT, STATUS, NEXT.
```

- [ ] Expected: implementation patch, validation commands, and Master Chef QA report.

### Prompt D — Sign off

```text
/cdd-master-chef UAT PASS. Mark the step done and suggest a commit message.
```

## 4) Pass criteria

- [ ] Exactly one step was planned and implemented.
- [ ] `docs/SMOKE.md` exists and is linked from `README.md`.
- [ ] Builder used `cdd-index`, `cdd-plan`, and `cdd-implement-todo`, or documented an approved exception.
- [ ] Validation commands were run and reported with outputs.
- [ ] Master Chef report includes `GOAL`, `SCOPE`, `CHANGES`, `VALIDATION`, `UAT`, `STATUS`, and `NEXT`.
- [ ] No unrelated file churn.

## 5) Abort / recovery

If the run drifts or hangs:

```text
/acp cancel
STOP. Summarize partial changes only.
```
