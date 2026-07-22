#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the canonical cdd-master-chef package. This test is
# local-only and deterministic.
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

PACKAGE_ROOT="$ROOT_DIR/skills/cdd-master-chef"
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
  CONTRACT.md; do
  assert_contains "$SHARED_ROOT/$rel" "$new_worktree_root"
  assert_not_contains "$SHARED_ROOT/$rel" "$legacy_worktree_root"
done
assert_contains "$SHARED_ROOT/RUNBOOK.md" "$runbook_worktree_root"
assert_not_contains "$SHARED_ROOT/RUNBOOK.md" "$legacy_worktree_root"
assert_contains "$ROOT_DIR/.gitignore" ".cdd-runtime/"

# Step 59: Builder lifecycle policy lives in CONTRACT.md §7 only. Every
# satellite must point there, and the previously-duplicated `Builder timing
# summary` bullet group must be gone.
echo "[MasterChefArtifacts] INFO BuilderLifecycleConsolidation file={CONTRACT.md §7}"
assert_contains "$SHARED_ROOT/CONTRACT.md" "<!-- canonical: Builder lifecycle policy"
for rel in \
  SKILL.md \
  RUNBOOK.md \
  RUNTIME-CAPABILITIES.md \
  CLAUDE-ADAPTER.md \
  CLAUDE-RUNBOOK.md \
  CODEX-ADAPTER.md \
  CODEX-RUNBOOK.md; do
  if ! grep -E "CONTRACT\.md\`?[[:space:]]*§7" "$SHARED_ROOT/$rel" >/dev/null; then
    echo "Expected 'CONTRACT.md §7' pointer in $SHARED_ROOT/$rel" >&2
    exit 1
  fi
done

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
  "unrecoverable" \
  "pending"; do
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

# Step 67: Builder transport ladder, exec permission profiles, cross-runtime
# preflight, and targeted-tests default live in CONTRACT.md; subagent adapter
# docs carry runtime mechanics only and must not restate the escalation rule.
echo "[MasterChefArtifacts] INFO TransportLadder file={CONTRACT.md §4}"
for phrase in \
  "### Builder transport ladder" \
  "native_subagent" \
  "agent_config" \
  "exec_same_runtime" \
  "exec_cross_runtime" \
  "builder_transport" \
  "builder_permission_profile" \
  "no silent mid-run transport switching" \
  "Cross-runtime preflight" \
  "### Exec-transport Builder mapping" \
  "effective Builder transport" \
  "directly affected tests"; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "$phrase"
done
assert_contains "$SHARED_ROOT/CODEX-ADAPTER.md" "codex exec resume"
assert_contains "$SHARED_ROOT/CLAUDE-ADAPTER.md" "claude -p --resume"
for rel in \
  CODEX-ADAPTER.md \
  CLAUDE-ADAPTER.md; do
  if ! grep -E "CONTRACT\.md\`?[[:space:]]*§4" "$SHARED_ROOT/$rel" >/dev/null; then
    echo "Expected 'CONTRACT.md §4' transport-ladder pointer in $SHARED_ROOT/$rel" >&2
    exit 1
  fi
  assert_not_contains "$SHARED_ROOT/$rel" "Escalate to the next rung"
done

# Step 68: opt-in wave-parallel contract lives in CONTRACT.md §12; adapters and
# the capabilities matrix point there and carry per-slot mechanics only.
echo "[MasterChefArtifacts] INFO WaveParallel file={CONTRACT.md §12}"
for phrase in \
  "## 12) Wave-parallel execution (opt-in)" \
  "max_parallel" \
  "serial merge queue" \
  "ascending step-id order" \
  "textual merge conflict is an integration failure" \
  "wave barrier" \
  "-b<slot>" \
  "Unannotated TODO files always run serial" \
  "Master Chef checks off the selected step at merge time" \
  "builders[]" \
  "wave_id" \
  "wave_step_ids" \
  "wave_merge_queue"; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "$phrase"
done
for rel in \
  CODEX-ADAPTER.md \
  CLAUDE-ADAPTER.md \
  RUNTIME-CAPABILITIES.md; do
  if ! grep -E "CONTRACT\.md\`?[[:space:]]*§12" "$SHARED_ROOT/$rel" >/dev/null; then
    echo "Expected 'CONTRACT.md §12' wave-mode pointer in $SHARED_ROOT/$rel" >&2
    exit 1
  fi
done
for rel in \
  CODEX-ADAPTER.md \
  CLAUDE-ADAPTER.md; do
  assert_not_contains "$SHARED_ROOT/$rel" "serial merge queue"
done

# Previous versions asserted that scripts/validate_skills.py contained specific
# named regex constants for master-chef prose coverage. That was brittleness on
# top of brittleness — testing an internal variable name in another test. The
# validator is now structural-only; semantic coverage moves to trigger evals
# and behavioral evals, not regex-on-prose. See validate_skills.py header.

echo "[MasterChefArtifacts] INFO ArtifactSmokePassed root={$ROOT_DIR}"
