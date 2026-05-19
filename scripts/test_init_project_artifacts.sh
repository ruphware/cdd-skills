#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the cdd-init-project open-decisions contract and
# its deterministic fixture case.
#
# Example:
#   bash scripts/test_init_project_artifacts.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="$ROOT_DIR/skills/cdd-init-project/SKILL.md"
VALIDATOR_PY="$ROOT_DIR/scripts/validate_skills.py"
FIXTURE_MD="$ROOT_DIR/skills/cdd-init-project/fixtures/open-decisions-response.md"

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

echo "[InitProjectArtifacts] INFO Contract path={$SKILL_MD}"
assert_exists "$SKILL_MD"
assert_contains "$SKILL_MD" "## Open decisions queue"
assert_contains "$SKILL_MD" 'visible `Open decisions` section'
assert_contains "$SKILL_MD" 'A repo-backed recommendation is not closure'
assert_contains "$SKILL_MD" '`asking now`'
assert_contains "$SKILL_MD" '`queued`'
assert_contains "$SKILL_MD" 'Do not emit a finished init or adoption plan while a plan-shaping `Open decisions` item remains unresolved'

echo "[InitProjectArtifacts] INFO Validator path={$VALIDATOR_PY}"
assert_exists "$VALIDATOR_PY"
assert_contains "$VALIDATOR_PY" 'REQUIRED_SECTIONS: dict[str, tuple[str, ...]]'
assert_contains "$VALIDATOR_PY" '"cdd-init-project": ('
assert_contains "$VALIDATOR_PY" '"## Open decisions queue"'

echo "[InitProjectArtifacts] INFO Fixture path={$FIXTURE_MD}"
assert_exists "$FIXTURE_MD"
assert_contains "$FIXTURE_MD" "### Open decisions (queued for one-at-a-time loop)"
assert_contains "$FIXTURE_MD" "Status: asking now"
assert_contains "$FIXTURE_MD" "Status: queued"
assert_contains "$FIXTURE_MD" "**Options**"
assert_contains "$FIXTURE_MD" '`## Proposed edits`'
assert_contains "$FIXTURE_MD" '`### README.md`'
assert_contains "$FIXTURE_MD" '`A. apply now`'

echo "[InitProjectArtifacts] INFO ArtifactSmokePassed root={$ROOT_DIR}"
