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

# Step 59: Builder lifecycle policy lives in CONTRACT.md §7 only. Every
# satellite must point there, and the previously-duplicated `Builder timing
# summary` bullet group plus the openclaw README three-bullet ladder must be
# gone.
echo "[MasterChefArtifacts] INFO BuilderLifecycleConsolidation file={CONTRACT.md §7}"
assert_contains "$SHARED_ROOT/CONTRACT.md" "<!-- canonical: Builder lifecycle policy"
for rel in \
  SKILL.md \
  RUNBOOK.md \
  RUNTIME-CAPABILITIES.md \
  CLAUDE-ADAPTER.md \
  CLAUDE-RUNBOOK.md \
  CODEX-ADAPTER.md \
  CODEX-RUNBOOK.md \
  openclaw/README.md \
  openclaw/MASTER-CHEF-RUNBOOK.md; do
  if ! grep -E "CONTRACT\.md\`?[[:space:]]*§7" "$SHARED_ROOT/$rel" >/dev/null; then
    echo "Expected 'CONTRACT.md §7' pointer in $SHARED_ROOT/$rel" >&2
    exit 1
  fi
done
assert_not_contains "$SHARED_ROOT/openclaw/MASTER-CHEF-RUNBOOK.md" "Builder timing summary"
assert_not_contains "$SHARED_ROOT/openclaw/README.md" "30 minutes of total running silence"

# Step 60: Builder replacement requires a clear stop signal; investigation
# stage, JSONL events, and runtime-state fields are documented in CONTRACT.md.
echo "[MasterChefArtifacts] INFO ClearStopPolicy file={CONTRACT.md}"
for phrase in \
  "clear stop signal" \
  "Builder-stop investigation" \
  "BUILDER_STOPPED" \
  "BUILDER_INVESTIGATION_RESOLVED" \
  "BUILDER_INVESTIGATION_ESCALATED" \
  "builder_stop_reason" \
  "builder_stop_classification" \
  "builder_stop_evidence_summary" \
  "missing_requirements" \
  "solvable_blocker" \
  "route_drift" \
  "unrecoverable"; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "$phrase"
done
# Silence- and probe-count-based replacement triggers must not return: forbid
# the phrases when they co-occur with `Replace` / `replacement` on the same
# grep line, so legitimate non-replacement narrative is not false-flagged.
for forbidden in \
  "30 minutes of total running silence" \
  "2 consecutive unanswered explicit status probes" \
  "2 consecutive unanswered explicit probes"; do
  if grep -E "(Replace|replacement)" "$SHARED_ROOT/CONTRACT.md" \
      | grep -F -- "$forbidden" >/dev/null; then
    echo "CONTRACT.md reintroduces silence-based replacement trigger '$forbidden'" >&2
    exit 1
  fi
done

echo "[MasterChefArtifacts] INFO OpenclawAdapterFiles root={$ROOT_DIR}"
for rel in \
  "cdd-master-chef/openclaw/README.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md"; do
  assert_exists "$ROOT_DIR/$rel"
done
# Previous versions asserted that scripts/validate_skills.py contained specific
# named regex constants for master-chef prose coverage. That was brittleness on
# top of brittleness — testing an internal variable name in another test. The
# validator is now structural-only; semantic coverage moves to trigger evals
# and behavioral evals, not regex-on-prose. See validate_skills.py header.

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
