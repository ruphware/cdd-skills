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
for token in \
  "how Builder monitoring works, including whether live status, partial output, or direct reasoning visibility actually exist in that runtime" \
  "Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second." \
  "A returned Builder handle or session key is spawn evidence only." \
  "Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot." \
  "\"event\":\"BUILDER_READY\"" \
  "\"tool_access\":\"ready|blocked|unknown\"" \
  "\"mcp_access\":\"ready|blocked|unknown\"" \
  "Treat a timed-out wait, a \"no agent completed yet\" result, or one unanswered progress request as inconclusive unless the runtime also reports closure or failure." \
  "Do not treat a returned session key, a missing diff, an empty \`builder.jsonl\`, or one short wait window with no completion as proof that Builder is fully started or has died." \
  "If no readiness signal arrives inside the adapter-defined boot window, use one explicit boot-status probe before classifying Builder as failed to start, blocked, or replaceable." \
  "For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before probing or replacing unless the runtime reports direct failure sooner." \
  "about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency" \
  "Apply the chosen quiet-work window only after \`builder_phase\` reaches \`running\`." \
  "Any coherent Builder reply, including a discovery-only or partial status report, is proof of life." \
  "- \`BUILDER_READY\`"; do
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
  "builder_phase" \
  "builder_spawn_requested_at_utc" \
  "builder_ready_at_utc" \
  "last_builder_direct_signal_at_utc" \
  "run_step_budget" \
  "steps_completed_this_run" \
  "\`builder_phase\` is \`not_started\`, \`booting\`, \`running\`, \`blocked\`, \`completed\`, \`failed\`, or \`closed\`" \
  "If the runtime does not expose live Builder reasoning or guaranteed streaming partial output, do not pretend it does." \
  "In Codex- or Claude-style adapters, direct status usually means final completion/failure notifications, explicit progress replies, or runtime-reported closure/errors, not live thinking traces." \
  "Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second." \
  "A returned Builder handle or session key is not enough to prove that the child has loaded its usable repo and tool context." \
  "Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot." \
  "\`tool_access\`" \
  "\`mcp_access\`" \
  "A timed-out wait, a \"no agent completed yet\" result, or one unanswered status request is still inconclusive unless the runtime also reports closure or failure." \
  "Use a short adapter-defined boot window before the first boot-status probe; foreground Codex and Claude flows should default to about 2 minutes." \
  "For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless the runtime reports direct failure sooner." \
  "about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency" \
  "Apply the chosen quiet-work window only after \`builder_phase\` reaches \`running\`." \
  "If Builder replies with a coherent discovery note, partial status, or other non-final report, treat that as proof of life"; do
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
  "must not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it" \
  "must require a real Builder readiness signal before treating the child as live; a spawn handle alone is not enough"; do
  assert_contains "$SHARED_ROOT/RUNTIME-CAPABILITIES.md" "$token"
done

echo "[MasterChefArtifacts] INFO CodexAdapter file={CODEX-*}"
for token in \
  "does not guarantee live access to Builder chain-of-thought or streaming partial output" \
  "A returned Builder handle or session key proves only that Codex accepted the spawn request." \
  "Master Chef should require one early Builder readiness ACK before treating the child as fully live." \
  "missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died" \
  "Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Codex exposes them." \
  "A timed-out wait or one unanswered progress request is still inconclusive unless Codex also reports closure or failure." \
  "Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death." \
  "## 7) Builder monitoring" \
  "Direct surfaces in this adapter are limited to final completion/failure notifications, explicit status replies, and runtime-reported closure/errors when Codex exposes them." \
  "Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second." \
  "A returned spawn handle or \`builder_session_key\` is spawn evidence only." \
  "Keep \`builder_phase: booting\` until Codex surfaces a runtime child-started signal, a coherent Builder readiness ACK, or a Builder-authored \`BUILDER_READY\` record in \`builder.jsonl\`." \
  "Use the shared boot prompt: \`Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.\`" \
  "A \`wait\` result that says no agent has completed yet means \`running\` or \`unknown\`, not \`dead\`." \
  "One unanswered direct status request is still inconclusive unless Codex also reports closure or failure." \
  "Use a short boot window, about 2 minutes in foreground Codex flows, before the first boot-status probe." \
  "For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless Codex reports direct failure sooner." \
  "about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency" \
  "Apply the chosen quiet-work window only after \`builder_phase\` reaches \`running\`." \
  "If Builder sends any coherent status or discovery reply, treat that as proof of life" \
  "### Prompt H - Long-thinking Builder monitoring" \
  "### Prompt I - Builder boot readiness" \
  "Long-thinking Builder monitoring used direct evidence instead of guessing." \
  "a returned \`builder_session_key\` alone is treated as spawn evidence, not readiness proof" \
  "the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label" \
  "foreground Codex usually uses about 10 minutes when the approved Builder effort is clearly high-latency" \
  "the chosen quiet-work window starts only after \`builder_phase\` reaches \`running\` and \`builder_ready_at_utc\` is recorded" \
  "a \`wait\` timeout or one unanswered status request is still treated as inconclusive unless Codex also reports closure or failure" \
  "a coherent status or discovery reply counts as proof of life even if the step is not finished yet" \
  "the preferred boot prompt starts with \`Hi. You are Builder\`" \
  "the preferred boot prompt asks for \`READY\` or \`BLOCKED: <reason>\`" \
  "Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle."; do
  case "$token" in
    "does not guarantee live access to Builder chain-of-thought or streaming partial output"|"A returned Builder handle or session key proves only that Codex accepted the spawn request."|"Master Chef should require one early Builder readiness ACK before treating the child as fully live."|"missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died"|"Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Codex exposes them."|"A timed-out wait or one unanswered progress request is still inconclusive unless Codex also reports closure or failure."|"Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.")
      assert_contains "$ROOT_DIR/cdd-master-chef/CODEX-ADAPTER.md" "$token"
      ;;
    "### Prompt H - Long-thinking Builder monitoring"|"### Prompt I - Builder boot readiness"|"Long-thinking Builder monitoring used direct evidence instead of guessing."|"a returned \`builder_session_key\` alone is treated as spawn evidence, not readiness proof"|"the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label"|"foreground Codex usually uses about 10 minutes when the approved Builder effort is clearly high-latency"|"the chosen quiet-work window starts only after \`builder_phase\` reaches \`running\` and \`builder_ready_at_utc\` is recorded"|"a \`wait\` timeout or one unanswered status request is still treated as inconclusive unless Codex also reports closure or failure"|"a coherent status or discovery reply counts as proof of life even if the step is not finished yet"|"the preferred boot prompt starts with \`Hi. You are Builder\`"|"the preferred boot prompt asks for \`READY\` or \`BLOCKED: <reason>\`"|"Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle.")
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
  "A returned Builder handle or session key proves only that Claude accepted the spawn request." \
  "Master Chef should require one early Builder readiness ACK before treating the child as fully live." \
  "missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died" \
  "Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Claude exposes them." \
  "A quiet wait or one unanswered progress request is still inconclusive unless Claude also reports closure or failure." \
  "Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death." \
  "## 8) Builder monitoring" \
  "Direct surfaces in this adapter are limited to final completion/failure notifications, explicit status replies, and runtime-reported closure/errors when Claude exposes them." \
  "Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second." \
  "A returned spawn handle or \`builder_session_key\` is spawn evidence only." \
  "Keep \`builder_phase: booting\` until Claude surfaces a runtime child-started signal, a coherent Builder readiness ACK, or a Builder-authored \`BUILDER_READY\` record in \`builder.jsonl\`." \
  "Use the shared boot prompt: \`Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.\`" \
  "A quiet wait with no completion means \`running\` or \`unknown\`, not \`dead\`." \
  "One unanswered direct status request is still inconclusive unless Claude also reports closure or failure." \
  "Use a short boot window, about 2 minutes in foreground Claude flows, before the first boot-status probe." \
  "For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless Claude reports direct failure sooner." \
  "about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency" \
  "Apply the chosen quiet-work window only after \`builder_phase\` reaches \`running\`." \
  "If Builder sends any coherent status or discovery reply, treat that as proof of life" \
  "### Prompt H - Long-thinking Builder monitoring" \
  "### Prompt I - Builder boot readiness" \
  "Long-thinking Builder monitoring used direct evidence instead of guessing." \
  "a returned \`builder_session_key\` alone is treated as spawn evidence, not readiness proof" \
  "the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label" \
  "foreground Claude usually uses about 10 minutes when the approved Builder effort is clearly high-latency" \
  "the chosen quiet-work window starts only after \`builder_phase\` reaches \`running\` and \`builder_ready_at_utc\` is recorded" \
  "a quiet wait or one unanswered status request is still treated as inconclusive unless Claude also reports closure or failure" \
  "a coherent status or discovery reply counts as proof of life even if the step is not finished yet" \
  "the preferred boot prompt starts with \`Hi. You are Builder\`" \
  "the preferred boot prompt asks for \`READY\` or \`BLOCKED: <reason>\`" \
  "Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle."; do
  case "$token" in
    "does not guarantee live access to Builder chain-of-thought or streaming partial output"|"A returned Builder handle or session key proves only that Claude accepted the spawn request."|"Master Chef should require one early Builder readiness ACK before treating the child as fully live."|"missing diff, or empty \`builder.jsonl\` is not enough by itself to prove that Builder has died"|"Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Claude exposes them."|"A quiet wait or one unanswered progress request is still inconclusive unless Claude also reports closure or failure."|"Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.")
      assert_contains "$ROOT_DIR/cdd-master-chef/CLAUDE-ADAPTER.md" "$token"
      ;;
    "### Prompt H - Long-thinking Builder monitoring"|"### Prompt I - Builder boot readiness"|"Long-thinking Builder monitoring used direct evidence instead of guessing."|"a returned \`builder_session_key\` alone is treated as spawn evidence, not readiness proof"|"the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label"|"foreground Claude usually uses about 10 minutes when the approved Builder effort is clearly high-latency"|"the chosen quiet-work window starts only after \`builder_phase\` reaches \`running\` and \`builder_ready_at_utc\` is recorded"|"a quiet wait or one unanswered status request is still treated as inconclusive unless Claude also reports closure or failure"|"a coherent status or discovery reply counts as proof of life even if the step is not finished yet"|"the preferred boot prompt starts with \`Hi. You are Builder\`"|"the preferred boot prompt asks for \`READY\` or \`BLOCKED: <reason>\`"|"Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle.")
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
