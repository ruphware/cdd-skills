#!/usr/bin/env bash
set -euo pipefail

# Tiny local Codex smoke runner for installed CDD skills.
#
# This is intentionally small and read-only:
# - explicit `[CDD-8] Master Chef` invocation
# - implicit autonomous-run request
# - negative control that should not drift into Master Chef kickoff
#
# It is not suitable for CI by default because it depends on a working local
# Codex installation plus auth/session access.
#
# Examples:
#   bash scripts/test_codex_skill_smoke.sh
#   bash scripts/test_codex_skill_smoke.sh --strict
#   bash scripts/test_codex_skill_smoke.sh --keep-tmp

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-codex-skill-smoke.XXXXXX")"
STRICT=0
KEEP_TMP=0
SMOKE_REPO="$TMP_ROOT/smoke-repo"
SMOKE_REASONING_EFFORT="${SMOKE_REASONING_EFFORT:-low}"

usage() {
  cat <<'EOF'
Usage: bash scripts/test_codex_skill_smoke.sh [options]

Run a tiny read-only Codex smoke test against the currently installed skills.

Options:
  --strict    Fail instead of skipping when Codex/auth/runtime access is unavailable
  --keep-tmp  Preserve the temporary trace directory
  -h, --help  Show this help text

Environment:
  SMOKE_REASONING_EFFORT  Codex reasoning effort for the smoke run (default: low; use
                          `none` to leave the session default unchanged)
EOF
}

cleanup() {
  if [[ $KEEP_TMP -eq 1 ]]; then
    echo "[CodexSkillSmoke] INFO TmpPreserved root={$TMP_ROOT}"
  else
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=1
      shift
      ;;
    --keep-tmp)
      KEEP_TMP=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

skip_or_fail() {
  local reason="$1"
  if [[ $STRICT -eq 1 ]]; then
    echo "[CodexSkillSmoke] ERROR reason={$reason}" >&2
    exit 1
  fi
  echo "[CodexSkillSmoke] INFO Skipped reason={$reason}"
  exit 0
}

assert_matches() {
  local path="$1"
  local pattern="$2"
  grep -Ei -- "$pattern" "$path" >/dev/null || {
    echo "Expected regex '$pattern' in $path" >&2
    echo "--- $path ---" >&2
    cat "$path" >&2
    echo "-------------" >&2
    exit 1
  }
}

assert_not_matches() {
  local path="$1"
  local pattern="$2"
  if grep -Ei -- "$pattern" "$path" >/dev/null; then
    echo "Unexpected regex '$pattern' in $path" >&2
    echo "--- $path ---" >&2
    cat "$path" >&2
    echo "-------------" >&2
    exit 1
  fi
}

if ! command -v codex >/dev/null 2>&1; then
  skip_or_fail "missing_codex"
fi

if [[ ! -d "$HOME/.agents/skills/cdd-master-chef" ]]; then
  skip_or_fail "missing_installed_master_chef"
fi

if ! command -v git >/dev/null 2>&1; then
  skip_or_fail "missing_git"
fi

create_smoke_repo() {
  mkdir -p "$SMOKE_REPO"
  git -C "$SMOKE_REPO" init -q
  git -C "$SMOKE_REPO" config user.name "CDD Smoke"
  git -C "$SMOKE_REPO" config user.email "cdd-smoke@example.com"

  cat >"$SMOKE_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

GOAL:
- Follow the repo task exactly.

CONSTRAINTS:
- Keep answers concise.

METHOD:
- Inspect before changing.

ASSUMPTIONS:
- State assumptions briefly.

EXECUTION:
- Report what changed and how it was validated.

NEXT:
- Give the immediate next step.
EOF

  cat >"$SMOKE_REPO/README.md" <<'EOF'
# Smoke Repo

Tiny CDD-ready repo used only for local Codex skill smoke tests.
EOF

  cat >"$SMOKE_REPO/TODO.md" <<'EOF'
# TODO

## Step 01 — Demo smoke step

### Goal

Confirm the smoke repo can be used for read-only kickoff checks.

### Tasks

- [ ] Inspect the smoke repo and identify this as the next runnable step.
EOF

  git -C "$SMOKE_REPO" add AGENTS.md README.md TODO.md
  git -C "$SMOKE_REPO" commit -qm "init smoke repo"
}

create_smoke_repo

if [[ ! -f "$SMOKE_REPO/AGENTS.md" || ! -f "$SMOKE_REPO/README.md" || ! -f "$SMOKE_REPO/TODO.md" ]]; then
  skip_or_fail "failed_to_prepare_smoke_repo"
fi

case "$SMOKE_REASONING_EFFORT" in
  none|low|medium|high|xhigh)
    ;;
  *)
    echo "[CodexSkillSmoke] ERROR reason={invalid_reasoning_effort} value={$SMOKE_REASONING_EFFORT}" >&2
    exit 2
    ;;
esac

echo "[CodexSkillSmoke] INFO Config reasoning={$SMOKE_REASONING_EFFORT}"

CODEX_REASONING_ARGS=()
if [[ "$SMOKE_REASONING_EFFORT" != "none" ]]; then
  CODEX_REASONING_ARGS=(-c "model_reasoning_effort=\"$SMOKE_REASONING_EFFORT\"")
fi

run_case() {
  local label="$1"
  local prompt="$2"
  local trace="$TMP_ROOT/$label.jsonl"
  local stderr_log="$TMP_ROOT/$label.stderr"
  local last_msg="$TMP_ROOT/$label.last.txt"

  echo "[CodexSkillSmoke] INFO CaseStart label={$label}"

  local -a codex_cmd=(
    codex
    --ask-for-approval never
    exec
    --json
    --ephemeral
    --color never
    --sandbox read-only
    --cd "$SMOKE_REPO"
    --output-last-message "$last_msg"
  )

  if [[ ${#CODEX_REASONING_ARGS[@]} -gt 0 ]]; then
    codex_cmd=(
      codex
      "${CODEX_REASONING_ARGS[@]}"
      --ask-for-approval never
      exec
      --json
      --ephemeral
      --color never
      --sandbox read-only
      --cd "$SMOKE_REPO"
      --output-last-message "$last_msg"
    )
  fi

  if ! "${codex_cmd[@]}" \
    "$prompt" >"$trace" 2>"$stderr_log"; then
    if grep -Eiq "permission denied|cannot access session files|login|auth|credential|network|connection|thread/start failed" "$stderr_log"; then
      skip_or_fail "codex_runtime_unavailable"
    fi
    echo "[CodexSkillSmoke] ERROR label={$label} stderr_log={$stderr_log}" >&2
    cat "$stderr_log" >&2
    exit 1
  fi

  python3 - "$trace" "$last_msg" <<'PY'
import json
import sys
from pathlib import Path

trace_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
events = [json.loads(line) for line in trace_path.read_text(encoding="utf-8").splitlines() if line.strip()]
assert any(event.get("type") == "thread.started" for event in events), "missing thread.started"
assert any(event.get("type") == "turn.started" for event in events), "missing turn.started"
assert any(event.get("type") == "turn.completed" for event in events), "missing turn.completed"
messages = [
    event["item"]["text"]
    for event in events
    if event.get("type") == "item.completed"
    and event.get("item", {}).get("type") == "agent_message"
]
assert messages, "missing agent_message"
out_path.write_text(messages[-1], encoding="utf-8")
PY

  echo "[CodexSkillSmoke] INFO CasePassed label={$label} trace={$trace} reasoning={$SMOKE_REASONING_EFFORT}"
}

explicit_prompt=$'$cdd-master-chef\nRead only. Inspect this repo and stop before any file changes or Builder launch.\nReply under short headings for: next runnable TODO step, Run config, step budget, and Builder start.\nIf Run config is still needed, use the exact field names `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`.\nAsk how many TODO steps this run should cover and whether Master Chef should spawn Builder now.\nDo not start implementation.'

implicit_prompt=$'Start the autonomous development process for this repo in read-only mode only and stop at kickoff approval.\nReply under short headings for: next runnable TODO step, Run config, step budget, and Builder start.\nIf Run config is still needed, use the exact field names `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`.\nAsk how many TODO steps this run should cover and whether Master Chef should spawn Builder now.\nDo not start implementation.'

negative_prompt=$'Summarize this repo README in one sentence only.\nDo not discuss Run config, Builder, step budget, or autonomous workflow.'

run_case "explicit_master_chef" "$explicit_prompt"
run_case "implicit_master_chef" "$implicit_prompt"
run_case "negative_control" "$negative_prompt"

for case_path in \
  "$TMP_ROOT/explicit_master_chef.last.txt" \
  "$TMP_ROOT/implicit_master_chef.last.txt"; do
  assert_matches "$case_path" 'TODO|next runnable'
  assert_matches "$case_path" 'Run config|master_model|master_thinking|builder_model|builder_thinking'
  assert_matches "$case_path" 'step budget|how many TODO steps|until_blocked_or_complete'
  assert_matches "$case_path" 'spawn Builder now|Builder start|whether .*spawn Builder'
done

assert_not_matches "$TMP_ROOT/negative_control.last.txt" 'Run config|master_model|builder_model|spawn Builder|step budget|autonomous run|kickoff approval'

echo "[CodexSkillSmoke] INFO SmokePassed repo={$SMOKE_REPO}"
