#!/usr/bin/env bash
set -euo pipefail

# Smoke-test installer behaviors for the unified installer across core and OpenClaw targets.
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

  if ! grep -F -- "$expected" "$log" >/dev/null; then
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

  if ! grep -F -- "$expected" "$log" >/dev/null; then
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
CLAUDE_INSTALL="$TMP_ROOT/claude-install"
OPENCLAW_INSTALL="$TMP_ROOT/openclaw-install"
OPENCLAW_UPDATE="$TMP_ROOT/openclaw-update"
OPENCLAW_LINK="$TMP_ROOT/openclaw-link"
OPENCLAW_UNINSTALL="$TMP_ROOT/openclaw-uninstall"
ALL_HOME="$TMP_ROOT/all-home"
ALL_PARTIAL_HOME="$TMP_ROOT/all-partial-home"
ALL_REMOVE_HOME="$TMP_ROOT/all-remove-home"
REMOTE_HOME="$TMP_ROOT/remote-home"
REMOTE_ARCHIVE="$TMP_ROOT/cdd-skills.tar.gz"
BUILDER_RETIRED="$TMP_ROOT/builder-retired"

echo "[CI] INFO LegacyFlagMigration root={$TMP_ROOT}"
assert_command_fails_with "Unsupported flag: --force" \
  "$ROOT_DIR/scripts/install.sh" --force
assert_command_fails_with "Unsupported flag: --prune" \
  "$ROOT_DIR/scripts/install.sh" --prune
assert_command_fails_with "Unsupported flag: --force" \
  "$ROOT_DIR/scripts/install-openclaw.sh" --force
assert_command_output_contains "Deprecated: use ./scripts/install.sh --runtime openclaw" \
  "$ROOT_DIR/scripts/install-openclaw.sh" --help
assert_command_fails_with "--all cannot be combined with --runtime" \
  "$ROOT_DIR/scripts/install.sh" --all --runtime claude
assert_command_fails_with "--all cannot be combined with --target" \
  "$ROOT_DIR/scripts/install.sh" --all --target "$TMP_ROOT/custom"
tar -czf "$REMOTE_ARCHIVE" -C "$ROOT_DIR" .

echo "[CI] INFO ConfirmDefaultYes root={$TMP_ROOT}"
assert_command_output_contains "default-yes-accepted" \
  bash -lc "source '$ROOT_DIR/scripts/install-common.sh'; if printf '\n' | confirm_yes_no_default_yes 'Proceed? [Y/n] '; then echo default-yes-accepted; else exit 1; fi"
assert_command_output_contains "default-yes-rejected" \
  bash -lc "source '$ROOT_DIR/scripts/install-common.sh'; if printf 'n\n' | confirm_yes_no_default_yes 'Proceed? [Y/n] '; then exit 1; else echo default-yes-rejected; fi"

echo "[CI] INFO BuilderInstallFresh root={$BUILDER_INSTALL}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_INSTALL"
assert_exists "$BUILDER_INSTALL/cdd-boot/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-maintain/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-plan/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-implement-todo/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-implementation-audit/SKILL.md"
assert_not_exists "$BUILDER_INSTALL/cdd-audit-and-implement"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/SKILL.md"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/agents/openai.yaml"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/README.md"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/CODEX-ADAPTER.md"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/CLAUDE-ADAPTER.md"
assert_exists "$BUILDER_INSTALL/cdd-master-chef/openclaw/README.md"
assert_command_output_contains 'display_name: "[CDD-6] Master Chef"' sed -n '1,20p' "$BUILDER_INSTALL/cdd-master-chef/agents/openai.yaml"
assert_not_exists "$BUILDER_INSTALL/cdd-index"
assert_not_exists "$BUILDER_INSTALL/cdd-refactor"
assert_command_fails_with "Rerun with --update" \
  "$ROOT_DIR/scripts/install.sh" --target "$BUILDER_INSTALL"

echo "[CI] INFO BuilderInstallUpdate root={$BUILDER_UPDATE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE"
touch "$BUILDER_UPDATE/cdd-plan/EXTRA.txt"
touch "$BUILDER_UPDATE/cdd-master-chef/EXTRA.txt"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UPDATE" --update
assert_exists "$BUILDER_UPDATE/cdd-plan/SKILL.md"
assert_not_exists "$BUILDER_UPDATE/cdd-plan/EXTRA.txt"
assert_exists "$BUILDER_UPDATE/cdd-master-chef/SKILL.md"
assert_not_exists "$BUILDER_UPDATE/cdd-master-chef/EXTRA.txt"
assert_no_match "$BUILDER_UPDATE" 'cdd-plan.bak.*'

echo "[CI] INFO BuilderInstallLink root={$BUILDER_LINK}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_LINK" --link
assert_symlink "$BUILDER_LINK/cdd-plan"
assert_symlink "$BUILDER_LINK/cdd-master-chef"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_LINK" --link --update
assert_symlink "$BUILDER_LINK/cdd-plan"
assert_symlink "$BUILDER_LINK/cdd-master-chef"
assert_exists "$BUILDER_LINK/cdd-master-chef/CODEX-RUNBOOK.md"

echo "[CI] INFO BuilderInstallRetiredCleanup root={$BUILDER_RETIRED}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_RETIRED"
mkdir -p "$BUILDER_RETIRED/cdd-index"
cat >"$BUILDER_RETIRED/cdd-index/SKILL.md" <<'EOF'
---
name: cdd-index
description: retired skill
disable-model-invocation: true
---
EOF
mkdir -p "$BUILDER_RETIRED/cdd-refactor"
cat >"$BUILDER_RETIRED/cdd-refactor/SKILL.md" <<'EOF'
---
name: cdd-refactor
description: retired skill
disable-model-invocation: true
---
EOF
mkdir -p "$BUILDER_RETIRED/cdd-index.pruned.legacy"
touch "$BUILDER_RETIRED/cdd-index.pruned.legacy/SKILL.md"
mkdir -p "$BUILDER_RETIRED/cdd-refactor.pruned.legacy"
touch "$BUILDER_RETIRED/cdd-refactor.pruned.legacy/SKILL.md"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_RETIRED" --update
assert_not_exists "$BUILDER_RETIRED/cdd-index"
assert_not_exists "$BUILDER_RETIRED/cdd-refactor"
assert_not_exists "$BUILDER_RETIRED/cdd-index.pruned.legacy"
assert_not_exists "$BUILDER_RETIRED/cdd-refactor.pruned.legacy"

echo "[CI] INFO BuilderInstallPrune root={$BUILDER_PRUNE}"
"$ROOT_DIR/scripts/install.sh" --target "$BUILDER_PRUNE"
mkdir -p "$BUILDER_PRUNE/cdd-audit-and-implement"
cat >"$BUILDER_PRUNE/cdd-audit-and-implement/SKILL.md" <<'EOF'
---
name: cdd-audit-and-implement
description: retired skill
disable-model-invocation: true
---
EOF
echo "cdd_skills_origin=ruphware/cdd-skills" >"$BUILDER_PRUNE/cdd-audit-and-implement/.cdd-skills-origin"
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
mkdir -p "$BUILDER_PRUNE/cdd-audit-and-implement.pruned.20260505T080008Z"
touch "$BUILDER_PRUNE/cdd-audit-and-implement.pruned.20260505T080008Z/SKILL.md"
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
assert_not_exists "$BUILDER_PRUNE/cdd-audit-and-implement"
assert_no_match "$BUILDER_PRUNE" 'cdd-audit-and-implement.pruned.*'
assert_exists "$BUILDER_PRUNE/cdd-foreign/SKILL.md"
assert_not_exists "$BUILDER_PRUNE/cdd-index"
assert_not_exists "$BUILDER_PRUNE/cdd-refactor"

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
assert_exists "$BUILDER_UNINSTALL/cdd-master-chef/SKILL.md"
assert_exists "$BUILDER_UNINSTALL/cdd-obsolete/SKILL.md"
assert_exists "$BUILDER_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-obsolete.pruned.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-foreign/SKILL.md"
printf 'y\n' | "$ROOT_DIR/scripts/install.sh" --target "$BUILDER_UNINSTALL" --uninstall
assert_not_exists "$BUILDER_UNINSTALL/cdd-boot"
assert_not_exists "$BUILDER_UNINSTALL/cdd-maintain"
assert_not_exists "$BUILDER_UNINSTALL/cdd-plan"
assert_not_exists "$BUILDER_UNINSTALL/cdd-implementation-audit"
assert_not_exists "$BUILDER_UNINSTALL/cdd-master-chef"
assert_not_exists "$BUILDER_UNINSTALL/cdd-obsolete"
assert_not_exists "$BUILDER_UNINSTALL/cdd-invalid"
assert_not_exists "$BUILDER_UNINSTALL/cdd-plan.bak.legacy"
assert_not_exists "$BUILDER_UNINSTALL/cdd-obsolete.pruned.legacy"
assert_exists "$BUILDER_UNINSTALL/cdd-foreign/SKILL.md"

echo "[CI] INFO ClaudeInstallFresh root={$CLAUDE_INSTALL}"
"$ROOT_DIR/scripts/install.sh" --runtime claude --target "$CLAUDE_INSTALL"
assert_exists "$CLAUDE_INSTALL/cdd-plan/SKILL.md"
assert_exists "$CLAUDE_INSTALL/cdd-implementation-audit/SKILL.md"
assert_not_exists "$CLAUDE_INSTALL/cdd-audit-and-implement"
assert_exists "$CLAUDE_INSTALL/cdd-master-chef/SKILL.md"
assert_exists "$CLAUDE_INSTALL/cdd-master-chef/agents/openai.yaml"
assert_exists "$CLAUDE_INSTALL/cdd-master-chef/CLAUDE-ADAPTER.md"
assert_exists "$CLAUDE_INSTALL/cdd-master-chef/openclaw/README.md"
assert_command_fails_with "Rerun with --update" \
  "$ROOT_DIR/scripts/install.sh" --runtime claude --target "$CLAUDE_INSTALL"

echo "[CI] INFO OpenClawInstallFresh root={$OPENCLAW_INSTALL}"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_INSTALL"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/agents/openai.yaml"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/README.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/CONTRACT.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/CODEX-ADAPTER.md"
assert_exists "$OPENCLAW_INSTALL/cdd-master-chef/openclaw/README.md"
assert_exists "$OPENCLAW_INSTALL/cdd-boot/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-maintain/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-plan/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-implement-todo/SKILL.md"
assert_exists "$OPENCLAW_INSTALL/cdd-implementation-audit/SKILL.md"
assert_not_exists "$OPENCLAW_INSTALL/cdd-audit-and-implement"
assert_command_output_contains "user-invocable: false" sed -n '1,40p' "$OPENCLAW_INSTALL/cdd-plan/SKILL.md"
assert_command_fails_with "Rerun with --update" \
  "$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_INSTALL"

echo "[CI] INFO OpenClawInstallUpdate root={$OPENCLAW_UPDATE}"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UPDATE"
touch "$OPENCLAW_UPDATE/cdd-master-chef/EXTRA.txt"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UPDATE" --update
assert_exists "$OPENCLAW_UPDATE/cdd-master-chef/SKILL.md"
assert_not_exists "$OPENCLAW_UPDATE/cdd-master-chef/EXTRA.txt"
assert_no_match "$OPENCLAW_UPDATE" 'cdd-master-chef.bak.*'
touch "$OPENCLAW_UPDATE/cdd-plan/EXTRA.txt"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UPDATE" --update
assert_exists "$OPENCLAW_UPDATE/cdd-plan/SKILL.md"
assert_not_exists "$OPENCLAW_UPDATE/cdd-plan/EXTRA.txt"
assert_no_match "$OPENCLAW_UPDATE" 'cdd-plan.bak.*'

echo "[CI] INFO OpenClawInstallLink root={$OPENCLAW_LINK}"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_LINK" --link
assert_symlink "$OPENCLAW_LINK/cdd-master-chef"
assert_exists "$OPENCLAW_LINK/cdd-master-chef/RUNBOOK.md"
assert_exists "$OPENCLAW_LINK/cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md"
assert_exists "$OPENCLAW_LINK/cdd-plan/SKILL.md"
assert_exists "$OPENCLAW_LINK/cdd-implementation-audit/SKILL.md"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_LINK" --link --update
assert_symlink "$OPENCLAW_LINK/cdd-master-chef"
assert_exists "$OPENCLAW_LINK/cdd-implement-todo/SKILL.md"

echo "[CI] INFO OpenClawUninstall root={$OPENCLAW_UNINSTALL}"
"$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UNINSTALL"
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
printf 'n\n' | "$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UNINSTALL" --uninstall
assert_exists "$OPENCLAW_UNINSTALL/cdd-master-chef/SKILL.md"
assert_exists "$OPENCLAW_UNINSTALL/cdd-plan/SKILL.md"
assert_exists "$OPENCLAW_UNINSTALL/cdd-master-chef.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-foreign/SKILL.md"
printf 'y\n' | "$ROOT_DIR/scripts/install.sh" --runtime openclaw --target "$OPENCLAW_UNINSTALL" --uninstall
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-master-chef"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-boot"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-maintain"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-plan"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-implement-todo"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-implementation-audit"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-master-chef.bak.legacy"
assert_not_exists "$OPENCLAW_UNINSTALL/cdd-plan.bak.legacy"
assert_exists "$OPENCLAW_UNINSTALL/cdd-foreign/SKILL.md"

echo "[CI] INFO InstallAllExistingHomes root={$ALL_HOME}"
mkdir -p "$ALL_HOME/.agents" "$ALL_HOME/.claude" "$ALL_HOME/.openclaw"
HOME="$ALL_HOME" "$ROOT_DIR/scripts/install.sh" --all
assert_exists "$ALL_HOME/.agents/skills/cdd-master-chef/SKILL.md"
assert_exists "$ALL_HOME/.claude/skills/cdd-master-chef/SKILL.md"
assert_exists "$ALL_HOME/.openclaw/skills/cdd-master-chef/SKILL.md"
assert_not_exists "$ALL_HOME/.agents/skills/cdd-audit-and-implement"
assert_not_exists "$ALL_HOME/.claude/skills/cdd-audit-and-implement"
assert_not_exists "$ALL_HOME/.openclaw/skills/cdd-audit-and-implement"
assert_exists "$ALL_HOME/.agents/skills/cdd-implementation-audit/SKILL.md"
assert_exists "$ALL_HOME/.claude/skills/cdd-implementation-audit/SKILL.md"
assert_exists "$ALL_HOME/.openclaw/skills/cdd-implementation-audit/SKILL.md"
assert_command_output_contains "user-invocable: false" sed -n '1,40p' "$ALL_HOME/.openclaw/skills/cdd-plan/SKILL.md"
touch "$ALL_HOME/.agents/skills/cdd-master-chef/EXTRA.txt"
touch "$ALL_HOME/.openclaw/skills/cdd-plan/EXTRA.txt"
mkdir -p "$ALL_HOME/.agents/skills/cdd-audit-and-implement"
cat >"$ALL_HOME/.agents/skills/cdd-audit-and-implement/SKILL.md" <<'EOF'
---
name: cdd-audit-and-implement
description: retired skill
disable-model-invocation: true
---
EOF
echo "cdd_skills_origin=ruphware/cdd-skills" >"$ALL_HOME/.agents/skills/cdd-audit-and-implement/.cdd-skills-origin"
mkdir -p "$ALL_HOME/.agents/skills/cdd-audit-and-implement.pruned.20260505T080008Z"
HOME="$ALL_HOME" "$ROOT_DIR/scripts/install.sh" --all --update
assert_not_exists "$ALL_HOME/.agents/skills/cdd-master-chef/EXTRA.txt"
assert_not_exists "$ALL_HOME/.openclaw/skills/cdd-plan/EXTRA.txt"
assert_not_exists "$ALL_HOME/.agents/skills/cdd-audit-and-implement"
assert_no_match "$ALL_HOME/.agents/skills" 'cdd-audit-and-implement.pruned.*'

echo "[CI] INFO InstallAllSkipsMissingHomes root={$ALL_PARTIAL_HOME}"
mkdir -p "$ALL_PARTIAL_HOME/.agents" "$ALL_PARTIAL_HOME/.openclaw"
HOME="$ALL_PARTIAL_HOME" "$ROOT_DIR/scripts/install.sh" --all
assert_exists "$ALL_PARTIAL_HOME/.agents/skills/cdd-master-chef/SKILL.md"
assert_exists "$ALL_PARTIAL_HOME/.openclaw/skills/cdd-master-chef/SKILL.md"
assert_not_exists "$ALL_PARTIAL_HOME/.claude/skills"

echo "[CI] INFO InstallAllUninstall root={$ALL_REMOVE_HOME}"
mkdir -p "$ALL_REMOVE_HOME/.agents" "$ALL_REMOVE_HOME/.claude" "$ALL_REMOVE_HOME/.openclaw"
HOME="$ALL_REMOVE_HOME" "$ROOT_DIR/scripts/install.sh" --all
printf 'n\nn\nn\n' | HOME="$ALL_REMOVE_HOME" "$ROOT_DIR/scripts/install.sh" --all --uninstall
assert_exists "$ALL_REMOVE_HOME/.agents/skills/cdd-master-chef/SKILL.md"
assert_exists "$ALL_REMOVE_HOME/.claude/skills/cdd-master-chef/SKILL.md"
assert_exists "$ALL_REMOVE_HOME/.openclaw/skills/cdd-master-chef/SKILL.md"
printf 'y\ny\ny\n' | HOME="$ALL_REMOVE_HOME" "$ROOT_DIR/scripts/install.sh" --all --uninstall
assert_not_exists "$ALL_REMOVE_HOME/.agents/skills/cdd-master-chef"
assert_not_exists "$ALL_REMOVE_HOME/.claude/skills/cdd-master-chef"
assert_not_exists "$ALL_REMOVE_HOME/.openclaw/skills/cdd-master-chef"
assert_not_exists "$ALL_REMOVE_HOME/.openclaw/skills/cdd-plan"
assert_not_exists "$ALL_REMOVE_HOME/.openclaw/skills/cdd-implementation-audit"

echo "[CI] INFO RemoteInstallAndUpdate root={$REMOTE_HOME}"
mkdir -p "$REMOTE_HOME/.agents" "$REMOTE_HOME/.claude"
HOME="$REMOTE_HOME" CDD_SKILLS_ARCHIVE_URL="file://$REMOTE_ARCHIVE" \
  "$ROOT_DIR/install-remote.sh" --all
assert_exists "$REMOTE_HOME/.agents/skills/cdd-master-chef/SKILL.md"
assert_exists "$REMOTE_HOME/.claude/skills/cdd-master-chef/SKILL.md"
mkdir -p "$REMOTE_HOME/.agents/skills/cdd-audit-and-implement.pruned.20260505T080008Z"
HOME="$REMOTE_HOME" CDD_SKILLS_ARCHIVE_URL="file://$REMOTE_ARCHIVE" \
  "$ROOT_DIR/install-remote.sh" --all --update --yes
assert_no_match "$REMOTE_HOME/.agents/skills" 'cdd-audit-and-implement.pruned.*'
printf 'y\ny\n' | HOME="$REMOTE_HOME" CDD_SKILLS_ARCHIVE_URL="file://$REMOTE_ARCHIVE" \
  "$ROOT_DIR/uninstall-remote.sh" --all
assert_not_exists "$REMOTE_HOME/.agents/skills/cdd-master-chef"
assert_not_exists "$REMOTE_HOME/.claude/skills/cdd-master-chef"

echo "[CI] INFO InstallerSmokePassed root={$TMP_ROOT}"
