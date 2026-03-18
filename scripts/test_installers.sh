#!/usr/bin/env bash
set -euo pipefail

# Smoke-test installer behaviors for the Builder and OpenClaw skill packs.
#
# Example:
#   bash scripts/test_installers.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skills-ci.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_symlink() {
  local path="$1"
  [[ -L "$path" ]] || {
    echo "Expected symlink at: $path" >&2
    exit 1
  }
}

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

assert_no_match() {
  local root="$1"
  local pattern="$2"
  local found
  found="$(find_one "$root" "$pattern")"
  [[ -z "$found" ]] || {
    echo "Unexpected match for pattern '$pattern': $found" >&2
    exit 1
  }
}

assert_command_fails_with() {
  local expected="$1"
  shift

  local log="$TMP_ROOT/failure.log"
  if "$@" >"$log" 2>&1; then
    echo "Expected command to fail: $*" >&2
    cat "$log" >&2
    exit 1
  fi

  if ! grep -F "$expected" "$log" >/dev/null; then
    echo "Expected failure output to contain: $expected" >&2
    cat "$log" >&2
    exit 1
  fi
}

assert_command_output_contains() {
  local expected="$1"
  shift

  local log="$TMP_ROOT/output.log"
  "$@" >"$log" 2>&1

  if ! grep -F "$expected" "$log" >/dev/null; then
    echo "Expected command output to contain: $expected" >&2
    cat "$log" >&2
    exit 1
  fi
}

find_one() {
  local root="$1"
  local pattern="$2"
  find "$root" -maxdepth 1 -name "$pattern" -print -quit
}

BUILDER_INSTALL="$TMP_ROOT/builder-install"
BUILDER_UPDATE="$TMP_ROOT/builder-update"
BUILDER_LINK="$TMP_ROOT/builder-link"
BUILDER_PRUNE="$TMP_ROOT/builder-prune"
BUILDER_UNINSTALL="$TMP_ROOT/builder-uninstall"
OPENCLAW_INSTALL="$TMP_ROOT/openclaw-install"
OPENCLAW_UPDATE="$TMP_ROOT/openclaw-update"
OPENCLAW_LINK="$TMP_ROOT/openclaw-link"
OPENCLAW_UNINSTALL="$TMP_ROOT/openclaw-uninstall"

echo "[CI] INFO LegacyFlagMigration root={$TMP_ROOT}"
assert_command_fails_with "Unsupported flag: --force" \
  "$ROOT_DIR/scripts/install.sh" --force
assert_command_fails_with "Unsupported flag: --prune" \
  "$ROOT_DIR/scripts/install.sh" --prune
assert_command_fails_with "Unsupported flag: --force" \
  "$ROOT_DIR/scripts/install-openclaw.sh" --force

echo "[CI] INFO BuilderInstallFresh root={$BUILDER_INSTALL}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_INSTALL"
assert_exists "$BUILDER_INSTALL/cdd-boot/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-maintain/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-plan/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-implement-todo/SKILL.md"
assert_command_fails_with "Rerun with --update" \
  "$ROOT_DIR/scripts/install.sh" --target "$BUILDER_INSTALL"

echo "[CI] INFO BuilderInstallUpdate root={$BUILDER_UPDATE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE"
touch "$BUILDER_UPDATE/cdd-plan/EXTRA.txt"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE" --update
assert_exists "$BUILDER_UPDATE/cdd-plan/SKILL.md"
assert_not_exists "$BUILDER_UPDATE/cdd-plan/EXTRA.txt"
assert_no_match "$BUILDER_UPDATE" 'cdd-plan.bak.*'

echo "[CI] INFO BuilderInstallLink root={$BUILDER_LINK}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_LINK" --link
assert_symlink "$BUILDER_LINK/cdd-plan"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_LINK" --link --update
assert_symlink "$BUILDER_LINK/cdd-plan"

echo "[CI] INFO BuilderInstallPrune root={$BUILDER_PRUNE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_PRUNE"
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
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_PRUNE" --update --yes
assert_exists "$(find_one "$BUILDER_PRUNE" 'cdd-obsolete.pruned.*')"
assert_exists "$(find_one "$BUILDER_PRUNE" 'cdd-invalid.pruned.*')"
assert_exists "$BUILDER_PRUNE/cdd-foreign/SKILL.md"
assert_exists "$BUILDER_PRUNE/cdd-refactor/SKILL.md"

echo "[CI] INFO BuilderUninstall root={$BUILDER_UNINSTALL}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UNINSTALL"
mkdir -p "$BUILDER_UNINSTALL/cdd-obsolete"
cat >"$BUILDER_UNINSTALL/cdd-obsolete/SKILL.md" <<'EOF'
---
name: cdd-obsolete
description: old skill
disable-model-invocation: true
---
EOF
echo "cdd_skills_origin=ruphware/cdd-skills" >"$BUILDER_UNINSTALL/cdd-obsolete/.cdd-skills-origin"
mkdir -p "$BUILDER_UNINSTALL/cdd-invalid"
touch "$BUILDER_UNINSTALL/cdd-invalid/NOT_SKILL.txt"
mkdir -p "$BUILDER_UNINSTALL/cdd-plan.bak.legacy"
mkdir -p "$BUILDER_UNINSTALL/cdd-obsolete.pruned.legacy"
mkdir -p "$BUILDER_UNINSTALL/cdd-foreign"
cat >"$BUILDER_UNINSTALL/cdd-foreign/SKILL.md" <<'EOF'
---
name: cdd-foreign
description: foreign skill
disable-model-invocation: true
---
EOF
printf 'n\n' | "$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UNINSTALL" --uninstall
assert_exists "$BUILDER_UNINSTALL/cdd-plan/SKILL.md"
assert_exists "$BUILDER_UNINSTALL/cdd-obsolete/SKILL.md"
assert_exists "$BUILDER_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-obsolete.pruned.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-foreign/SKILL.md"
printf 'y\n' | "$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UNINSTALL" --uninstall
assert_not_exists "$BUILDER_UNINSTALL/cdd-boot"
assert_not_exists "$BUILDER_UNINSTALL/cdd-maintain"
assert_not_exists "$BUILDER_UNINSTALL/cdd-plan"
assert_not_exists "$BUILDER_UNINSTALL/cdd-obsolete"
assert_not_exists "$BUILDER_UNINSTALL/cdd-invalid"
assert_not_exists "$BUILDER_UNINSTALL/cdd-plan.bak.legacy"
assert_not_exists "$BUILDER_UNINSTALL/cdd-obsolete.pruned.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-foreign/SKILL.md"

echo "[CI] INFO OpenClawInstallFresh root={$OPENCLAW_INSTALL}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_INSTALL"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/README.md"
assert_exists "$OPENCLAW_INSTALL/cdd-boot/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-maintain/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-plan/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-implement-todo/SKILL.md"
assert_command_output_contains "user-invocable: false" sed -n '1,40p' "$OPENCLAW_INSTALL/cdd-plan/SKILL.md"
assert_command_fails_with "Rerun with --update" \
  "$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_INSTALL"

echo "[CI] INFO OpenClawInstallUpdate root={$OPENCLAW_UPDATE}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UPDATE"
touch "$OPENCLAW_UPDATE/cdd-master-chef/EXTRA.txt"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UPDATE" --update
assert_exists "$OPENCLAW_UPDATE/cdd-master-chef/SKILL.md"
assert_not_exists "$OPENCLAW_UPDATE/cdd-master-chef/EXTRA.txt"
assert_no_match "$OPENCLAW_UPDATE" 'cdd-master-chef.bak.*'
touch "$OPENCLAW_UPDATE/cdd-plan/EXTRA.txt"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UPDATE" --update
assert_exists "$OPENCLAW_UPDATE/cdd-plan/SKILL.md"
assert_not_exists "$OPENCLAW_UPDATE/cdd-plan/EXTRA.txt"
assert_no_match "$OPENCLAW_UPDATE" 'cdd-plan.bak.*'

echo "[CI] INFO OpenClawInstallLink root={$OPENCLAW_LINK}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_LINK" --link
assert_symlink "$OPENCLAW_LINK/cdd-master-chef"
assert_exists "$OPENCLAW_LINK/cdd-plan/SKILL.md"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_LINK" --link --update
assert_symlink "$OPENCLAW_LINK/cdd-master-chef"
assert_exists "$OPENCLAW_LINK/cdd-implement-todo/SKILL.md"

echo "[CI] INFO OpenClawUninstall root={$OPENCLAW_UNINSTALL}"
"$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UNINSTALL"
mkdir -p "$OPENCLAW_UNINSTALL/cdd-master-chef.bak.legacy"
mkdir -p "$OPENCLAW_UNINSTALL/cdd-plan.bak.legacy"
mkdir -p "$OPENCLAW_UNINSTALL/cdd-foreign"
cat >"$OPENCLAW_UNINSTALL/cdd-foreign/SKILL.md" <<'EOF'
---
name: cdd-foreign
description: foreign skill
disable-model-invocation: true
---
EOF
printf 'n\n' | "$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UNINSTALL" --uninstall
assert_exists "$OPENCLAW_UNINSTALL/cdd-master-chef/SKILL.md"
assert_exists "$OPENCLAW_UNINSTALL/cdd-plan/SKILL.md"
assert_exists "$OPENCLAW_UNINSTALL/cdd-master-chef.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-foreign/SKILL.md"
printf 'y\n' | "$ROOT_DIR/scripts/install-openclaw.sh" --target "$OPENCLAW_UNINSTALL" --uninstall
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-master-chef"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-boot"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-maintain"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-plan"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-implement-todo"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-master-chef.bak.legacy"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-foreign/SKILL.md"

echo "[CI] INFO InstallerSmokePassed root={$TMP_ROOT}"
