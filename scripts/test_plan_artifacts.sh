#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the cdd-plan open-decisions contract and its
# deterministic fixture case.
#
# Example:
#   bash scripts/test_plan_artifacts.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="$ROOT_DIR/skills/cdd-plan/SKILL.md"
VALIDATOR_PY="$ROOT_DIR/scripts/validate_skills.py"
FIXTURE_MD="$ROOT_DIR/skills/cdd-plan/fixtures/open-decisions-response.md"

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || {
    echo "Missing expected path: $path" >&2
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

echo "[PlanArtifacts] INFO Contract path={$SKILL_MD}"
assert_exists "$SKILL_MD"
assert_contains "$SKILL_MD" "## Clarification floor and architecture options"
assert_contains "$SKILL_MD" "## Open decisions queue"
assert_contains "$SKILL_MD" 'must ask one substantive clarification or decision question'
assert_contains "$SKILL_MD" 'For audit-derived planning, default the first question to remediation shape'
assert_contains "$SKILL_MD" 'visible `Open decisions` section'
assert_contains "$SKILL_MD" 'A repo-backed recommendation is not closure'
assert_contains "$SKILL_MD" '`asking now`'
assert_contains "$SKILL_MD" '`queued`'
assert_contains "$SKILL_MD" 'Do not emit a finished runnable TODO step while a plan-shaping `Open decisions` item remains unresolved'

echo "[PlanArtifacts] INFO Validator path={$VALIDATOR_PY}"
assert_exists "$VALIDATOR_PY"
assert_contains "$VALIDATOR_PY" 'REQUIRED_SECTIONS: dict[str, tuple[str, ...]]'
assert_contains "$VALIDATOR_PY" '"cdd-plan": ('
assert_contains "$VALIDATOR_PY" '"## Clarification floor and architecture options"'
assert_contains "$VALIDATOR_PY" '"## Open decisions queue"'

# Step 68: crisp output-style and step-annotation contracts.
echo "[PlanArtifacts] INFO OutputStyleAndAnnotations path={$SKILL_MD}"
assert_contains "$SKILL_MD" "## Plan output style"
assert_contains "$SKILL_MD" "## Step annotations"
assert_contains "$SKILL_MD" "high-entropy"
assert_contains "$SKILL_MD" "ASCII diagrams"
assert_contains "$SKILL_MD" 'deps: <comma-separated step ids | none>'
assert_contains "$SKILL_MD" 'touches: <comma-separated path globs or boundary names>'
assert_contains "$SKILL_MD" "serial barrier"
assert_contains "$SKILL_MD" "Unannotated TODO files always run serial"
assert_contains "$VALIDATOR_PY" '"## Plan output style"'
assert_contains "$VALIDATOR_PY" '"## Step annotations"'

echo "[PlanArtifacts] INFO Fixture path={$FIXTURE_MD}"
assert_exists "$FIXTURE_MD"
assert_contains "$FIXTURE_MD" "### Architecture / implementation options"
assert_contains "$FIXTURE_MD" "### Open decisions (queued for one-at-a-time loop)"
assert_contains "$FIXTURE_MD" "Status: asking now"
assert_contains "$FIXTURE_MD" "Status: queued"
assert_contains "$FIXTURE_MD" "**Options**"
assert_contains "$FIXTURE_MD" '`## Step`'
assert_contains "$FIXTURE_MD" '`### Goal`'
assert_contains "$FIXTURE_MD" '`### Tasks`'

echo "[PlanArtifacts] INFO ArtifactSmokePassed root={$ROOT_DIR}"
