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
  active_worktree_path \
  worktree_branch \
  worktree_continue_mode \
  builder_restart_count \
  current_blocker; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "- \`$field\`"
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
  "worktree_continue_mode"; do
  assert_contains "$SHARED_ROOT/RUNBOOK.md" "$token"
done

echo "[MasterChefArtifacts] INFO RuntimeMatrix file={RUNTIME-CAPABILITIES.md}"
for token in \
  "| OpenClaw |" \
  "| Codex |" \
  "| Claude Code |" \
  "CODEX-ADAPTER.md" \
  "CLAUDE-ADAPTER.md"; do
  assert_contains "$SHARED_ROOT/RUNTIME-CAPABILITIES.md" "$token"
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
