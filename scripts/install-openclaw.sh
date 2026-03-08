#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./install-common.sh
source "$ROOT_DIR/scripts/install-common.sh"

# Install the OpenClaw-only cdd-master-chef skill pack and internal Builder skills.
#
# Usage:
#   ./scripts/install-openclaw.sh
#   ./scripts/install-openclaw.sh --update
#   ./scripts/install-openclaw.sh --uninstall
#   ./scripts/install-openclaw.sh --link
#   ./scripts/install-openclaw.sh --target ~/.openclaw/skills

SRC_DIR="$ROOT_DIR/openclaw"
BUILDER_SRC_ROOT="$ROOT_DIR/skills"
BUILDER_GENERATOR="$ROOT_DIR/scripts/build_openclaw_builder_skills.py"
TARGET_ROOT="$HOME/.openclaw/skills"
SKILL_NAME="cdd-master-chef"
BUILDER_SKILL_NAMES=()

for path in "$BUILDER_SRC_ROOT"/*; do
  [[ -d "$path" ]] || continue
  [[ -f "$path/SKILL.md" ]] || continue
  BUILDER_SKILL_NAMES+=("$(basename "$path")")
done

if [[ ${#BUILDER_SKILL_NAMES[@]} -eq 0 ]]; then
  echo "No canonical Builder skills found in $BUILDER_SRC_ROOT" >&2
  exit 1
fi

UPDATE=0
UNINSTALL=0
LINK=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install-openclaw.sh [--target DIR] [--link] [--update] [--uninstall]

Install the OpenClaw cdd-master-chef skill pack, including internal cdd-* Builder skills.

Options:
  --target DIR  Install into DIR instead of ~/.openclaw/skills
  --update      Replace an existing install in place
  --link        Symlink cdd-master-chef instead of copying it; generated Builder skills are still copied
  --uninstall   List matching installed paths, ask y/N, and remove them
  -h, --help    Show this help text
EOF
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
BUILDER_DESTS=()
for skill in "${BUILDER_SKILL_NAMES[@]}"; do
  BUILDER_DESTS+=("$TARGET_ROOT/$skill")
done

if [[ $UNINSTALL -eq 1 ]]; then
  local_paths=()
  for path in "$DEST" "$TARGET_ROOT"/"$SKILL_NAME".bak.*; do
    path_exists "$path" || continue
    local_paths+=("$path")
  done
  for skill in "${BUILDER_SKILL_NAMES[@]}"; do
    for path in "$TARGET_ROOT/$skill" "$TARGET_ROOT"/"$skill".bak.*; do
      path_exists "$path" || continue
      local_paths+=("$path")
    done
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

if [[ ! -x "$(command -v python3)" ]]; then
  echo "Missing required binary: python3" >&2
  exit 1
fi

if [[ ! -f "$BUILDER_GENERATOR" ]]; then
  echo "Missing generator script: $BUILDER_GENERATOR" >&2
  exit 1
fi

mkdir -p "$TARGET_ROOT"

if [[ $UPDATE -eq 0 ]]; then
  fail_if_paths_exist_without_update "OpenClaw skill pack install in $TARGET_ROOT" "$DEST" "${BUILDER_DESTS[@]}"
fi

remove_paths "$DEST" "${BUILDER_DESTS[@]}"

BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-openclaw-build.XXXXXX")"
trap 'rm -rf "$BUILD_ROOT"' EXIT

python3 "$BUILDER_GENERATOR" --output "$BUILD_ROOT" >/dev/null

if [[ $LINK -eq 1 ]]; then
  ln -s "$SRC_DIR" "$DEST"
  echo "Linked $SKILL_NAME -> $DEST"
else
  cp -a "$SRC_DIR" "$DEST"
  echo "Installed $SKILL_NAME -> $DEST"
fi

for skill in "${BUILDER_SKILL_NAMES[@]}"; do
  cp -a "$BUILD_ROOT/$skill" "$TARGET_ROOT/$skill"
  echo "Installed $skill -> $TARGET_ROOT/$skill"
done
