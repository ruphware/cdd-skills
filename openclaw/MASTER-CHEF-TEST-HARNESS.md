# Tiny Master Chef Test Harness Checklist (v4 — ACP/Codex + CDD-first)

Goal: validate the loop **OpenClaw (Master Chef) -> Codex (ACP Builder) -> QA gate** with strong `cdd-*` usage.

## 1) Preflight (2–3 min)

- [ ] ACP backend is healthy:
  ```text
  /acp doctor
  ```

- [ ] Codex defaults are set (ACP inherits):
  ```bash
  grep -nE '^(model|model_reasoning_effort)\s*=' ~/.codex/config.toml
  ```
  Expected:
  - `model = "gpt-5.4"`
  - `model_reasoning_effort = "xhigh"`

- [ ] CDD skills are available:
  ```bash
  ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null
  ```

## 2) Create throwaway test repo (1 min)

```bash
TEST_ROOT=/home/norman/.openclaw/workspace/tmp/mc-harness
SRC=/home/norman/Workspace/cdd-boilerplate
TS=$(date -u +%Y%m%dT%H%M%SZ)
TEST_REPO="$TEST_ROOT/repo-$TS"
mkdir -p "$TEST_ROOT"
git clone "$SRC" "$TEST_REPO"
echo "$TEST_REPO"
```

- [ ] Keep `TEST_REPO` handy (paste into prompts below).

## 3) Prompt sequence (copy/paste into OpenClaw chat)

### Prompt 0 — Spawn + pin Builder model/effort

```text
/acp spawn codex --mode persistent --thread off --cwd <TEST_REPO>
/acp model gpt-5.4
/acp set model_reasoning_effort xhigh
```

Notes:
- On thread-capable surfaces (e.g. Discord), `--thread auto` is fine.

### Prompt A — CDD context + plan (draft only)

```text
Master Chef mode ON.
In the ACP Codex session (cwd: <TEST_REPO>), run cdd-index first, then run $cdd-plan.
Target tiny change:
- Add docs/SMOKE.md with a 5-line "how this repo works" summary.
- Add one link to docs/SMOKE.md in README.md.
Draft first only. Do not apply until I approve.
```

- [ ] Expected: cdd-index/cdd-plan evidence + draft edits + explicit approval question.

### Prompt B — Apply plan

```text
Approve and apply those planned edits exactly. No implementation yet.
```

- [ ] Expected: TODO/plan edits only.

### Prompt C — Implement one approved step (CDD-first)

```text
Now run $cdd-implement-todo for the approved step (exact heading).
Implement only that step.
Do not bypass cdd-* unless blocked; if blocked, stop and report blocker.
After Codex finishes, you (Master Chef) must re-check and report:
GOAL, SCOPE, CHANGES, VALIDATION, UAT, STATUS, NEXT.
```

- [ ] Expected: implementation patch + checks + QA report.

### Prompt D — Sign off

```text
UAT PASS. Mark the step done and suggest commit message.
```

## 4) Pass criteria

- [ ] Exactly one step was planned + implemented.
- [ ] `docs/SMOKE.md` exists and is linked from `README.md`.
- [ ] Builder used `cdd-index`, `cdd-plan`, and `cdd-implement-todo` (or explicitly documented approved exception).
- [ ] Validation commands were run and reported with outputs.
- [ ] Master-chef report includes GOAL/SCOPE/CHANGES/VALIDATION/UAT/STATUS/NEXT.
- [ ] No unrelated file churn.

## 5) Abort / recovery

If run drifts/hangs:

```text
/acp cancel
STOP. Summarize partial changes only.
```
