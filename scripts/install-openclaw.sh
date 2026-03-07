#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./install-common.sh
source "$ROOT_DIR/scripts/install-common.sh"

# Install the OpenClaw-only cdd-master-chef skill.
#
# Usage:
#   ./scripts/install-openclaw.sh
#   ./scripts/install-openclaw.sh --update
#   ./scripts/install-openclaw.sh --uninstall
#   ./scripts/install-openclaw.sh --link
#   ./scripts/install-openclaw.sh --target ~/.openclaw/skills

SRC_DIR="$ROOT_DIR/openclaw"
TARGET_ROOT="$HOME/.openclaw/skills"
SKILL_NAME="cdd-master-chef"
BUILDER_SKILLS_ROOT="$HOME/.agents/skills"
REQUIRED_BUILDER_SKILLS=(
  cdd-init-project
  cdd-plan
  cdd-implement-todo
  cdd-index
  cdd-audit-and-implement
  cdd-refactor
)

UPDATE=0
UNINSTALL=0
LINK=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install-openclaw.sh [--target DIR] [--link] [--update] [--uninstall]

Install the OpenClaw-only cdd-master-chef skill.

Options:
  --target DIR  Install into DIR instead of ~/.openclaw/skills
  --update      Replace an existing install in place
  --link        Symlink the source folder instead of copying it
  --uninstall   List matching installed paths, ask y/N, and remove them
  -h, --help    Show this help text
EOF
}

check_builder_skills() {
  local missing=()
  local skill=""

  for skill in "${REQUIRED_BUILDER_SKILLS[@]}"; do
    [[ -f "$BUILDER_SKILLS_ROOT/$skill/SKILL.md" ]] || missing+=("$skill")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "Verified Builder skills -> $BUILDER_SKILLS_ROOT"
    return 0
  fi

  echo "Warning: missing Builder skills in $BUILDER_SKILLS_ROOT: ${missing[*]}" >&2
  echo "Install them with ./scripts/install.sh --target $BUILDER_SKILLS_ROOT, or ignore this warning if Codex loads them from another location." >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update)
      UPDATE=1
      shift
      ;;
    --uninstall)
      UNINSTALL=1
      shift
      ;;
    --link)
      LINK=1
      shift
      ;;
    --target)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --target" >&2
        exit 2
      fi
      TARGET_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      legacy_flag_error "--force" "Use --update instead."
      ;;
    --yes)
      fail_usage "--yes is not supported by ./scripts/install-openclaw.sh."
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ $UNINSTALL -eq 1 && ( $UPDATE -eq 1 || $LINK -eq 1 ) ]]; then
  fail_usage "--uninstall cannot be combined with --update or --link."
fi

if [[ $LINK -eq 1 ]]; then
  warn_link_mode
fi

DEST="$TARGET_ROOT/$SKILL_NAME"

if [[ $UNINSTALL -eq 1 ]]; then
  local_paths=()
  for path in "$DEST" "$TARGET_ROOT"/"$SKILL_NAME".bak.*; do
    path_exists "$path" || continue
    local_paths+=("$path")
  done
  if [[ ${#local_paths[@]} -gt 0 ]]; then
    remove_paths_with_confirmation "OpenClaw skill in $TARGET_ROOT" "${local_paths[@]}"
  else
    remove_paths_with_confirmation "OpenClaw skill in $TARGET_ROOT"
  fi
  exit 0
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing source dir: $SRC_DIR" >&2
  exit 1
fi

if [[ ! -f "$SRC_DIR/SKILL.md" ]]; then
  echo "Missing skill entrypoint: $SRC_DIR/SKILL.md" >&2
  exit 1
fi

mkdir -p "$TARGET_ROOT"

if [[ $UPDATE -eq 0 ]]; then
  fail_if_paths_exist_without_update "OpenClaw skill install in $TARGET_ROOT" "$DEST"
fi

remove_paths "$DEST"

if [[ $LINK -eq 1 ]]; then
  ln -s "$SRC_DIR" "$DEST"
  echo "Linked $SKILL_NAME -> $DEST"
else
  cp -a "$SRC_DIR" "$DEST"
  echo "Installed $SKILL_NAME -> $DEST"
fi

check_builder_skills
