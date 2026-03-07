#!/usr/bin/env bash
set -euo pipefail

# Install the OpenClaw-only cdd-master-chef skill.
#
# Usage:
#   ./scripts/install-openclaw.sh
#   ./scripts/install-openclaw.sh --force
#   ./scripts/install-openclaw.sh --link
#   ./scripts/install-openclaw.sh --target ~/.openclaw/skills

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/openclaw"
TARGET_ROOT="$HOME/.openclaw/skills"
SKILL_NAME="cdd-master-chef"

FORCE=0
LINK=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install-openclaw.sh [--target DIR] [--force] [--link]

Install the OpenClaw-only cdd-master-chef skill.

Options:
  --target DIR  Install into DIR instead of ~/.openclaw/skills
  --force       Replace an existing install in place
  --link        Symlink the source folder instead of copying it
  -h, --help    Show this help text
EOF
}

backup_dir() {
  local path="$1"
  local ts
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  echo "${path}.bak.${ts}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
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
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing source dir: $SRC_DIR" >&2
  exit 1
fi

if [[ ! -f "$SRC_DIR/SKILL.md" ]]; then
  echo "Missing skill entrypoint: $SRC_DIR/SKILL.md" >&2
  exit 1
fi

if [[ $LINK -eq 1 ]]; then
  echo "Warning: --link uses a symlink. Copy install is the safer default." >&2
fi

mkdir -p "$TARGET_ROOT"

DEST="$TARGET_ROOT/$SKILL_NAME"

if [[ -e "$DEST" || -L "$DEST" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    rm -rf "$DEST"
  else
    BAK="$(backup_dir "$DEST")"
    echo "Backing up existing install: $DEST -> $BAK" >&2
    mv "$DEST" "$BAK"
  fi
fi

if [[ $LINK -eq 1 ]]; then
  ln -s "$SRC_DIR" "$DEST"
  echo "Linked $SKILL_NAME -> $DEST"
else
  cp -a "$SRC_DIR" "$DEST"
  echo "Installed $SKILL_NAME -> $DEST"
fi

echo "Prerequisite: install the separate cdd-* Builder skills for Codex (for example with ./scripts/install.sh --target ~/.agents/skills)."
