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
new_worktree_root=".cdd-runtime/worktrees/<run-id>/"
runbook_worktree_root="<source-repo>/.cdd-runtime/worktrees/<run-id>/"
legacy_worktree_root=".cdd-runtime/master-chef/worktrees/<run-id>/"

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
assert_contains "$SHARED_ROOT/agents/openai.yaml" 'display_name: "[CDD-6] Master Chef"'
assert_contains "$SHARED_ROOT/agents/openai.yaml" "allow_implicit_invocation: true"

echo "[MasterChefArtifacts] INFO LegacyStubPaths root={$ROOT_DIR}"
assert_not_exists "$ROOT_DIR/master-chef"
assert_not_exists "$ROOT_DIR/openclaw"

echo "[MasterChefArtifacts] INFO SharedContractFields file={CONTRACT.md}"
for rel in \
  SKILL.md \
  CONTRACT.md \
  openclaw/README.md \
  openclaw/MASTER-CHEF-RUNBOOK.md; do
  assert_contains "$SHARED_ROOT/$rel" "$new_worktree_root"
  assert_not_contains "$SHARED_ROOT/$rel" "$legacy_worktree_root"
done
assert_contains "$SHARED_ROOT/RUNBOOK.md" "$runbook_worktree_root"
assert_not_contains "$SHARED_ROOT/RUNBOOK.md" "$legacy_worktree_root"
assert_contains "$ROOT_DIR/.gitignore" ".cdd-runtime/"
echo "[MasterChefArtifacts] INFO CoverageDelegated validator={scripts/validate_skills.py}"
# Structural smoke stays here. Prose/topic coverage belongs to the Python
# validator so the repo has one source of truth for persistent-Builder,
# step-boundary compaction, fallback, and recovery-only regex bundles.
for rel in \
  "cdd-master-chef/openclaw/README.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md"; do
  assert_exists "$ROOT_DIR/$rel"
done
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "MASTER_CHEF_SAME_BUILDER_REGEX"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "MASTER_CHEF_STEP_COMPACTION_REGEX"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "MASTER_CHEF_COMPACTION_FALLBACK_REGEX"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "MASTER_CHEF_REPLACEMENT_ONLY_REGEX"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "LEGACY_BUILDER_LIFECYCLE_STRINGS"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "ROOT_README_LEGACY_MASTER_CHEF_STRINGS"
assert_contains "$ROOT_DIR/scripts/validate_skills.py" "OPENCLAW_LEGACY_QA_REMEDIATION_REGEXES"

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
