#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the canonical cdd-master-chef package and generated
# runtime Builder surfaces. This test is local-only and deterministic.
#
# Example:
#   bash scripts/test_master_chef_artifacts.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-master-chef-artifacts.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || {
    echo "Missing expected path: $path" >&2
    exit 1
  }
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || {
    echo "Unexpected path exists: $path" >&2
    exit 1
  }
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  grep -F -- "$pattern" "$path" >/dev/null || {
    echo "Expected '$pattern' in $path" >&2
    exit 1
  }
}

assert_matches() {
  local path="$1"
  local pattern="$2"
  grep -E -- "$pattern" "$path" >/dev/null || {
    echo "Expected regex '$pattern' in $path" >&2
    exit 1
  }
}

assert_not_contains() {
  local path="$1"
  local pattern="$2"
  if grep -F -- "$pattern" "$path" >/dev/null; then
    echo "Did not expect '$pattern' in $path" >&2
    exit 1
  fi
}

PACKAGE_ROOT="$ROOT_DIR/cdd-master-chef"
SHARED_ROOT="$PACKAGE_ROOT"

echo "[MasterChefArtifacts] INFO SharedContractRoot path={$SHARED_ROOT}"
for rel in \
  SKILL.md \
  agents/openai.yaml \
  README.md \
  CONTRACT.md \
  RUNBOOK.md \
  RUNTIME-CAPABILITIES.md \
  CODEX-ADAPTER.md \
  CODEX-RUNBOOK.md \
  CODEX-TEST-HARNESS.md \
  CLAUDE-ADAPTER.md \
  CLAUDE-RUNBOOK.md \
  CLAUDE-TEST-HARNESS.md; do
  assert_exists "$SHARED_ROOT/$rel"
done
assert_contains "$SHARED_ROOT/agents/openai.yaml" 'display_name: "[CDD-8] Master Chef"'
assert_contains "$SHARED_ROOT/agents/openai.yaml" "allow_implicit_invocation: true"

echo "[MasterChefArtifacts] INFO LegacyStubPaths root={$ROOT_DIR}"
assert_exists "$ROOT_DIR/master-chef/README.md"
assert_not_exists "$ROOT_DIR/master-chef/CONTRACT.md"
assert_exists "$ROOT_DIR/openclaw/README.md"
assert_not_exists "$ROOT_DIR/openclaw/SKILL.md"

echo "[MasterChefArtifacts] INFO RootInstallStory file={README.md}"
for token in \
  "npx skills add https://github.com/ruphware/cdd-skills/" \
  "./scripts/install.sh --all" \
  "Current concrete adapters in this repo:"; do
  assert_contains "$ROOT_DIR/README.md" "$token"
done
for pattern in \
  'Use the core .*cdd-\*.*single coding agent' \
  'Use .*(cdd-master-chef|\[CDD-8\] Master Chef).*kickoff approval' \
  'For `\[CDD-8\] Master Chef`:' \
  'start `(\$|/)?cdd-master-chef`.*main session.*runtime you want to control' \
  'Run config block.*current session model.*thinking.*approve or edit' \
  'how many TODO steps this run should cover' \
  'whether (Master Chef|it) should spawn Builder now' \
  'Adapter docs.*maintainers.*debugging.*runtime support' \
  'OpenClaw.*packaged adapter.*install\.sh --runtime openclaw' \
  'Codex.*CODEX-ADAPTER\.md.*CODEX-RUNBOOK\.md' \
  'Claude Code.*CLAUDE-ADAPTER\.md.*CLAUDE-RUNBOOK\.md' \
  'No Hermes adapter ships in this repo today\.'; do
  assert_matches "$ROOT_DIR/README.md" "$pattern"
done
for token in \
  "wrong \`npx skills add\` entrypoint" \
  "docs-only surrogate" \
  "very experimental" \
  "the current OpenClaw adapter fits your runtime" \
  "only packaged Master Chef runtime" \
  "For current Codex or Claude Code \`[CDD-8] Master Chef\` adapter work:" \
  "treat those as the current subagent-backed adapter paths in development"; do
  assert_not_contains "$ROOT_DIR/README.md" "$token"
done

echo "[MasterChefArtifacts] INFO SharedAdapterStory file={cdd-master-chef/README.md}"
for token in \
  "Current concrete adapters in this package:" \
  "The top-level \`master-chef/\` and \`openclaw/\` directories are compatibility stubs only; this directory is the single canonical source tree."; do
  assert_contains "$SHARED_ROOT/README.md" "$token"
done
for pattern in \
  'OpenClaw.*packaged runtime adapter.*generated Builder install flow' \
  'Codex.*subagent-backed adapter docs' \
  'Claude Code.*subagent-backed adapter docs' \
  'No Hermes adapter ships in this package today\.'; do
  assert_matches "$SHARED_ROOT/README.md" "$pattern"
done
for token in \
  "only packaged Master Chef runtime today" \
  "very experimental" \
  "docs-only surrogate"; do
  assert_not_contains "$SHARED_ROOT/README.md" "$token"
done

echo "[MasterChefArtifacts] INFO SharedContractFields file={CONTRACT.md}"
for field in \
  run_id \
  repo \
  source_repo \
  run_step_budget \
  steps_completed_this_run \
  active_worktree_path \
  worktree_branch \
  worktree_continue_mode \
  builder_restart_count \
  current_blocker; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "- \`$field\`"
done
for token in \
  "how Builder monitoring works, including whether live status, partial output, or direct reasoning visibility actually exist in that runtime" \
  "Do not treat a missing diff, an empty \`builder.jsonl\`, or one short wait window with no completion as proof that Builder has died." \
  "For long-effort Builders, especially \`builder_thinking: xhigh\`, allow a longer quiet window before probing or replacing unless the runtime reports direct failure sooner."; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "$token"
done

echo "[MasterChefArtifacts] INFO SharedRunbookFields file={RUNBOOK.md}"
for token in \
  "## 1) Managed worktree policy" \
  "## 2) Runtime-state additions" \
  "## 3) Continuation decision rule" \
  "## 4) Active worktree behavior" \
  "## 5) Cleanup" \
  "source_repo" \
  "active_worktree_path" \
  "worktree_continue_mode" \
  "run_step_budget" \
  "steps_completed_this_run" \
  "If the runtime does not expose live Builder reasoning or guaranteed streaming partial output, do not pretend it does." \
  "For \`builder_thinking: xhigh\`, allow at least a 10-minute quiet window before the first stale probe unless the runtime reports direct failure sooner."; do
  assert_contains "$SHARED_ROOT/RUNBOOK.md" "$token"
done

echo "[MasterChefArtifacts] INFO RuntimeMatrix file={RUNTIME-CAPABILITIES.md}"
for token in \
  "| OpenClaw |" \
  "| Codex |" \
  "| Claude Code |" \
  "CODEX-ADAPTER.md" \
  "CLAUDE-ADAPTER.md" \
  "Builder-start decisions back to the human" \
  "run step budget" \
  "must not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it"; do
  assert_contains "$SHARED_ROOT/RUNTIME-CAPABILITIES.md" "$token"
done

echo "[MasterChefArtifacts] INFO CodexAdapter file={CODEX-*}"
for token in \
  "does not guarantee live access to Builder chain-of-thought or streaming partial output" \
  "missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died" \
  "## 7) Builder monitoring" \
  "A \`wait\` result that says no agent has completed yet means \`running\` or \`unknown\`, not \`dead\`." \
  "For \`builder_thinking: xhigh\`, allow at least a 10-minute quiet window before the first stale probe unless Codex reports direct failure sooner." \
  "### Prompt H - Long-thinking Builder monitoring" \
  "Long-thinking Builder monitoring used direct evidence instead of guessing."; do
  case "$token" in
    "does not guarantee live access to Builder chain-of-thought or streaming partial output"|"missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died")
      assert_contains "$ROOT_DIR/cdd-master-chef/CODEX-ADAPTER.md" "$token"
      ;;
    "### Prompt H - Long-thinking Builder monitoring"|"Long-thinking Builder monitoring used direct evidence instead of guessing.")
      assert_contains "$ROOT_DIR/cdd-master-chef/CODEX-TEST-HARNESS.md" "$token"
      ;;
    *)
      assert_contains "$ROOT_DIR/cdd-master-chef/CODEX-RUNBOOK.md" "$token"
      ;;
  esac
done

echo "[MasterChefArtifacts] INFO ClaudeAdapter file={CLAUDE-*}"
for token in \
  "does not guarantee live access to Builder chain-of-thought or streaming partial output" \
  "missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died" \
  "## 8) Builder monitoring" \
  "A quiet wait with no completion means \`running\` or \`unknown\`, not \`dead\`." \
  "For \`builder_thinking: xhigh\`, allow at least a 10-minute quiet window before the first stale probe unless Claude reports direct failure sooner." \
  "### Prompt H - Long-thinking Builder monitoring" \
  "Long-thinking Builder monitoring used direct evidence instead of guessing."; do
  case "$token" in
    "does not guarantee live access to Builder chain-of-thought or streaming partial output"|"missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died")
      assert_contains "$ROOT_DIR/cdd-master-chef/CLAUDE-ADAPTER.md" "$token"
      ;;
    "### Prompt H - Long-thinking Builder monitoring"|"Long-thinking Builder monitoring used direct evidence instead of guessing.")
      assert_contains "$ROOT_DIR/cdd-master-chef/CLAUDE-TEST-HARNESS.md" "$token"
      ;;
    *)
      assert_contains "$ROOT_DIR/cdd-master-chef/CLAUDE-RUNBOOK.md" "$token"
      ;;
  esac
done

echo "[MasterChefArtifacts] INFO OpenClawAdapter package={openclaw}"
for rel in \
  "cdd-master-chef/openclaw/README.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md"; do
  assert_exists "$ROOT_DIR/$rel"
done
for token in \
  ".cdd-runtime/master-chef/run.json" \
  "if the current session model and current session thinking are visible, recommend a candidate \`Run config\`" \
  "The full Run config must be resolved and approved before kickoff." \
  "recommend a candidate Run config from the current session model and current session thinking" \
  "the approved run step budget" \
  "whether to spawn Builder now and start the autonomous run" \
  "\"run_step_budget\": 1" \
  "\"steps_completed_this_run\": 0" \
  "source_repo" \
  "worktree_continue_mode" \
  "Prompt A0 - Recommendation path" \
  "Prompt J - QA reject remediation" \
  "Prompt L - Blocked-step decomposition" \
  "Prompt N - Context compaction and resume"; do
  case "$token" in
    Prompt*)
      assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md" "$token"
      ;;
    "recommend a candidate Run config from the current session model and current session thinking")
      assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/README.md" "$token"
      ;;
    "The full Run config must be resolved and approved before kickoff.")
      assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" "$token"
      ;;
    "\"run_step_budget\": 1"|"\"steps_completed_this_run\": 0")
      assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" "$token"
      ;;
    *)
      assert_contains "$ROOT_DIR/cdd-master-chef/SKILL.md" "$token"
      ;;
  esac
done

echo "[MasterChefArtifacts] INFO GeneratedBuilder runtime={openclaw}"
python3 "$ROOT_DIR/scripts/build_runtime_builder_skills.py" \
  --runtime openclaw \
  --output "$TMP_ROOT/generated" >/dev/null

for skill_dir in "$ROOT_DIR"/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  skill_name="$(basename "$skill_dir")"
  generated_skill="$TMP_ROOT/generated/$skill_name/SKILL.md"
  assert_exists "$generated_skill"
  assert_contains "$generated_skill" "user-invocable: false"
  assert_contains "$generated_skill" "Internal OpenClaw Builder variant generated from the canonical \`skills/\` pack."
done

echo "[MasterChefArtifacts] INFO ArtifactSmokePassed root={$ROOT_DIR}"
