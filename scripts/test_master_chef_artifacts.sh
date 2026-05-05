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

assert_topic_bundle() {
  local path="$1"
  local label="$2"
  shift 2

  local pattern
  for pattern in "$@"; do
    grep -E -- "$pattern" "$path" >/dev/null || {
      echo "Missing topic '$label' regex '$pattern' in $path" >&2
      exit 1
    }
  done
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
  'remaining unfinished top-level step-heading count.*default/max step budget' \
  'fresh run from a long-lived branch.*descriptive feature branch' \
  'split an oversized top-level step before (Builder handoff|delegation)' \
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
  builder_phase \
  builder_spawn_requested_at_utc \
  builder_ready_at_utc \
  last_builder_direct_signal_at_utc \
  run_step_budget \
  steps_completed_this_run \
  active_worktree_path \
  worktree_branch \
  worktree_continue_mode \
  builder_restart_count \
  current_blocker; do
  assert_contains "$SHARED_ROOT/CONTRACT.md" "- \`$field\`"
done
assert_topic_bundle "$SHARED_ROOT/CONTRACT.md" "contract monitoring topics" \
  'unfinished top-level TODO step-heading count' \
  'oversized for one Builder run' \
  'descriptive feature branch' \
  'nested checkboxes or sub-tasks' \
  'default/max run step budget.*all remaining steps' \
  'oversized for one Builder run.*split.*smaller decision-complete TODO steps' \
  'Builder monitoring.*live status.*partial output.*direct reasoning visibility' \
  'two phases:.*boot/readiness.*quiet-work' \
  'spawn evidence' \
  'Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>' \
  'BUILDER_READY' \
  'tool_access' \
  'mcp_access' \
  'timed-out wait.*no agent completed yet.*inconclusive' \
  'missing diff.*empty .*builder\.jsonl.*proof' \
  'boot window.*boot-status probe' \
  '(long-thinking|high-latency).*quiet-work window' \
  '10 minutes.*quiet-work window.*high-latency' \
  'quiet-work window.*builder_phase.*running' \
  'coherent Builder reply.*proof of life'

echo "[MasterChefArtifacts] INFO SharedRunbookFields file={RUNBOOK.md}"
for token in \
  "## 1) Managed worktree policy" \
  "## 2) Runtime-state additions" \
  "## 3) Continuation decision rule" \
  "## 4) Active worktree behavior" \
  "## 5) Cleanup" \
  "### Fresh-start feature branch suggestion" \
  "source_repo" \
  "active_worktree_path" \
  "worktree_continue_mode" \
  "builder_phase" \
  "builder_spawn_requested_at_utc" \
  "builder_ready_at_utc" \
  "last_builder_direct_signal_at_utc" \
  "run_step_budget" \
  "steps_completed_this_run" \
  "\`builder_phase\` is \`not_started\`, \`booting\`, \`running\`, \`blocked\`, \`completed\`, \`failed\`, or \`closed\`"; do
  assert_contains "$SHARED_ROOT/RUNBOOK.md" "$token"
done
assert_topic_bundle "$SHARED_ROOT/RUNBOOK.md" "runbook monitoring topics" \
  'fresh run.*long-lived branch.*descriptive feature branch' \
  'oversized for one Builder run.*split it first' \
  'unfinished top-level TODO step-heading count' \
  'default/max .*run_step_budget.*all remaining steps' \
  'does not expose live Builder reasoning.*do not pretend' \
  'Codex- or Claude-style adapters.*direct status.*completion/failure.*progress replies.*closure/errors' \
  'two phases:.*boot/readiness.*quiet-work' \
  'returned Builder handle.*not enough to prove' \
  'Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>' \
  'tool_access' \
  'mcp_access' \
  'timed-out wait.*no agent completed yet.*inconclusive' \
  'boot window.*2 minutes' \
  '(long-thinking|high-latency).*quiet-work window' \
  '10 minutes.*quiet-work window.*high-latency' \
  'quiet-work window.*builder_phase.*running' \
  'coherent discovery note.*proof of life'

echo "[MasterChefArtifacts] INFO RuntimeMatrix file={RUNTIME-CAPABILITIES.md}"
for token in \
  "| OpenClaw |" \
  "| Codex |" \
  "| Claude Code |" \
  "CODEX-ADAPTER.md" \
  "CLAUDE-ADAPTER.md" \
  "Builder-start decisions back to the human" \
  "run step budget" \
  "must not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it" \
  "must require a real Builder readiness signal before treating the child as live; a spawn handle alone is not enough"; do
  assert_contains "$SHARED_ROOT/RUNTIME-CAPABILITIES.md" "$token"
done

echo "[MasterChefArtifacts] INFO CodexAdapter file={CODEX-*}"
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CODEX-ADAPTER.md" "codex adapter topics" \
  'does not guarantee live access to Builder chain-of-thought|does not guarantee .*streaming partial output' \
  'spawn request' \
  'readiness ACK' \
  'empty .*builder\.jsonl.*prove.*died' \
  'runtime-reported completion/failure.*status replies.*closure/error' \
  'inconclusive unless Codex also reports closure or failure' \
  'proof of life rather than proof of death'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CODEX-RUNBOOK.md" "codex runbook topics" \
  '^## 7\) Builder monitoring' \
  'shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget' \
  'oversized next top-level TODO step' \
  'two phases:.*boot/readiness.*quiet-work' \
  'spawn evidence only' \
  'builder_phase: booting.*runtime child-started signal.*readiness ACK.*BUILDER_READY' \
  'Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>' \
  'no agent has completed yet.*running.*unknown.*dead' \
  '2 minutes.*boot-status probe' \
  '(long-thinking|high-latency).*quiet-work window' \
  '10 minutes.*high-latency' \
  'quiet-work window.*builder_phase.*running' \
  'coherent status or discovery reply.*proof of life'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CODEX-TEST-HARNESS.md" "codex harness topics" \
  '^### Prompt H - .*Builder monitoring' \
  '^### Prompt I - Builder boot readiness' \
  'remaining top-level-step count is stated when finite' \
  'feature-branch suggestion is surfaced when applicable' \
  'oversized top-level step is split in Master Chef before Builder handoff' \
  'exact remaining top-level-step count when that count is finite' \
  'direct evidence instead of guessing' \
  'spawn evidence, not readiness proof' \
  '((long-thinking|high-latency).*quiet-work window|quiet-work window.*(long-thinking|high-latency))' \
  'builder_phase.*running.*builder_ready_at_utc' \
  'inconclusive unless Codex also reports closure or failure' \
  'status or discovery reply.*proof of life' \
  'preferred boot prompt.*Hi\. You are Builder' \
  'READY.*BLOCKED: <reason>' \
  'ACK or runtime-ready signal rather than only a spawn handle'

echo "[MasterChefArtifacts] INFO ClaudeAdapter file={CLAUDE-*}"
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CLAUDE-ADAPTER.md" "claude adapter topics" \
  'does not guarantee live access to Builder chain-of-thought|does not guarantee .*streaming partial output' \
  'spawn request' \
  'readiness ACK' \
  'empty .*builder\.jsonl.*prove.*died' \
  'runtime-reported completion/failure.*status replies.*closure/error' \
  'inconclusive unless Claude also reports closure or failure' \
  'proof of life rather than proof of death'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CLAUDE-RUNBOOK.md" "claude runbook topics" \
  '^## 8\) Builder monitoring' \
  'shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget' \
  'oversized next top-level TODO step' \
  'two phases:.*boot/readiness.*quiet-work' \
  'spawn evidence only' \
  'builder_phase: booting.*runtime child-started signal.*readiness ACK.*BUILDER_READY' \
  'Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>' \
  'quiet wait with no completion.*running.*unknown.*dead' \
  '2 minutes.*boot-status probe' \
  '(long-thinking|high-latency).*quiet-work window' \
  '10 minutes.*high-latency' \
  'quiet-work window.*builder_phase.*running' \
  'coherent status or discovery reply.*proof of life'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/CLAUDE-TEST-HARNESS.md" "claude harness topics" \
  '^### Prompt H - .*Builder monitoring' \
  '^### Prompt I - Builder boot readiness' \
  'remaining top-level-step count is stated when finite' \
  'feature-branch suggestion is surfaced when applicable' \
  'oversized top-level step is split in Master Chef before Builder handoff' \
  'exact remaining top-level-step count when that count is finite' \
  'direct evidence instead of guessing' \
  'spawn evidence, not readiness proof' \
  '((long-thinking|high-latency).*quiet-work window|quiet-work window.*(long-thinking|high-latency))' \
  'builder_phase.*running.*builder_ready_at_utc' \
  'inconclusive unless Claude also reports closure or failure' \
  'status or discovery reply.*proof of life' \
  'preferred boot prompt.*Hi\. You are Builder' \
  'READY.*BLOCKED: <reason>' \
  'ACK or runtime-ready signal rather than only a spawn handle'

echo "[MasterChefArtifacts] INFO OpenClawAdapter package={openclaw}"
for rel in \
  "cdd-master-chef/openclaw/README.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" \
  "cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md"; do
  assert_exists "$ROOT_DIR/$rel"
done
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/SKILL.md" "shared skill runtime topics" \
  '\.cdd-runtime/master-chef/run\.json' \
  'current session model.*current session thinking.*recommend.*Run config' \
  'approved run step budget' \
  'unfinished top-level TODO step-heading count' \
  'descriptive feature branch' \
  'oversized for one Builder run' \
  'spawn Builder now.*start the autonomous run' \
  'source_repo' \
  'worktree_continue_mode'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/openclaw/README.md" "openclaw readme topics" \
  'current session model.*current session thinking.*recommend.*Run config' \
  'top-level TODO step-heading count' \
  'descriptive feature branch' \
  'oversized for one Builder run' \
  'default/max step budget'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" "openclaw runbook topics" \
  'Run config.*resolved and approved before kickoff' \
  'unfinished top-level TODO step-heading count' \
  'oversized for one Builder run.*split it in Master Chef first' \
  'shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget' \
  '"run_step_budget": 1' \
  '"steps_completed_this_run": 0'
assert_topic_bundle "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md" "openclaw harness prompts" \
  'Prompt A0 - Recommendation path' \
  'Prompt A1 - Oversized-step split before Builder handoff' \
  'Prompt J - QA reject remediation' \
  'Prompt L - Blocked-step decomposition' \
  'Prompt N - Context compaction and resume' \
  'remaining unfinished top-level TODO step-heading count is stated when finite' \
  'fresh-start feature-branch suggestion' \
  'remaining top-level-step count is recomputed after the split' \
  'exact remaining top-level-step count when that count is finite'

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
