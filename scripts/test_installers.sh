#!/usr/bin/env bash
set -euo pipefail

# Smoke-test installer behaviors for the Builder and OpenClaw skill packs.
#
# Example:
#   bash scripts/test_installers.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skills-ci.XXXXXX")"
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

find_one() {
  local root="$1"
  local pattern="$2"
  find "$root" -maxdepth 1 -name "$pattern" -print -quit
}

BUILDER_INSTALL="$TMP_ROOT/builder-install"
BUILDER_UPDATE="$TMP_ROOT/builder-update"
BUILDER_FORCE="$TMP_ROOT/builder-force"
BUILDER_LINK="$TMP_ROOT/builder-link"
BUILDER_PRUNE="$TMP_ROOT/builder-prune"
OPENCLAW_INSTALL="$TMP_ROOT/openclaw-install"
OPENCLAW_UPDATE="$TMP_ROOT/openclaw-update"
OPENCLAW_FORCE="$TMP_ROOT/openclaw-force"
OPENCLAW_LINK="$TMP_ROOT/openclaw-link"

echo "[CI] INFO BuilderInstallFresh root={$BUILDER_INSTALL}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_INSTALL" --force
assert_exists "$BUILDER_INSTALL/cdd-plan/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-implement-todo/SKILL.md"

echo "[CI] INFO BuilderInstallUpdate root={$BUILDER_UPDATE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE" --force
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE"
assert_exists "$BUILDER_UPDATE/cdd-plan/SKILL.md"
assert_exists "$(find_one "$BUILDER_UPDATE" 'cdd-plan.bak.*')"

echo "[CI] INFO BuilderInstallForce root={$BUILDER_FORCE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_FORCE" --force
touch "$BUILDER_FORCE/cdd-plan/EXTRA.txt"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_FORCE" --force
assert_not_exists "$BUILDER_FORCE/cdd-plan/EXTRA.txt"
assert_exists "$BUILDER_FORCE/cdd-plan/SKILL.md"

echo "[CI] INFO BuilderInstallLink root={$BUILDER_LINK}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_LINK" --link --force
[[ -L "$BUILDER_LINK/cdd-plan" ]] || {
  echo "Expected symlink install at $BUILDER_LINK/cdd-plan" >&2
  exit 1
}

echo "[CI] INFO BuilderInstallPrune root={$BUILDER_PRUNE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_PRUNE" --force
mkdir -p "$BUILDER_PRUNE/cdd-obsolete"
cat >"$BUILDER_PRUNE/cdd-obsolete/SKILL.md" <<'EOF'
---
name: cdd-obsolete
description: old skill
disable-model-invocation: true
---
EOF
echo "cdd_skills_origin=ruphware/cdd-skills" >"$BUILDER_PRUNE/cdd-obsolete/.cdd-skills-origin"
mkdir -p "$BUILDER_PRUNE/cdd-invalid"
touch "$BUILDER_PRUNE/cdd-invalid/NOT_SKILL.txt"
mkdir -p "$BUILDER_PRUNE/cdd-foreign"
cat >"$BUILDER_PRUNE/cdd-foreign/SKILL.md" <<'EOF'
---
name: cdd-foreign
description: foreign skill
disable-model-invocation: true
---
EOF
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_PRUNE" --force --prune --yes
assert_exists "$(find_one "$BUILDER_PRUNE" 'cdd-obsolete.pruned.*')"
assert_exists "$(find_one "$BUILDER_PRUNE" 'cdd-invalid.pruned.*')"
assert_exists "$BUILDER_PRUNE/cdd-foreign/SKILL.md"
assert_exists "$BUILDER_PRUNE/cdd-refactor/SKILL.md"

echo "[CI] INFO OpenClawInstallFresh root={$OPENCLAW_INSTALL}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_INSTALL" --force
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/README.md"

echo "[CI] INFO OpenClawInstallUpdate root={$OPENCLAW_UPDATE}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UPDATE" --force
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UPDATE"
assert_exists "$OPENCLAW_UPDATE/cdd-master-chef/SKILL.md"
assert_exists "$(find_one "$OPENCLAW_UPDATE" 'cdd-master-chef.bak.*')"

echo "[CI] INFO OpenClawInstallForce root={$OPENCLAW_FORCE}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_FORCE" --force
touch "$OPENCLAW_FORCE/cdd-master-chef/EXTRA.txt"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_FORCE" --force
assert_not_exists "$OPENCLAW_FORCE/cdd-master-chef/EXTRA.txt"
assert_exists "$OPENCLAW_FORCE/cdd-master-chef/MASTER-CHEF-RUNBOOK.md"

echo "[CI] INFO OpenClawInstallLink root={$OPENCLAW_LINK}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_LINK" --link --force
[[ -L "$OPENCLAW_LINK/cdd-master-chef" ]] || {
  echo "Expected symlink install at $OPENCLAW_LINK/cdd-master-chef" >&2
  exit 1
}

echo "[CI] INFO InstallerSmokePassed root={$TMP_ROOT}"
