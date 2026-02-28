#!/usr/bin/env bash
set -euo pipefail

# Install CDD skills into user skill directories.
# Default target: Codex/Codex CLI (~/.agents/skills)
#
# Usage:
#   ./scripts/install.sh            # safe copy into ~/.agents/skills
#   ./scripts/install.sh --force    # overwrite existing skill dirs
#   ./scripts/install.sh --link     # symlink instead of copy
#   ./scripts/install.sh --target ~/.agents/skills --target ~/.claude/skills

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/.agents/skills"

FORCE=0
LINK=0
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --link) LINK=1; shift ;;
    --target) TARGETS+=("$2"); shift 2 ;;
    -h|--help)
      sed -n '1,120p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing source skills dir: $SRC_DIR" >&2
  exit 1
fi

if [[ $LINK -eq 1 ]]; then
  echo "Warning: --link uses symlinks. Some tools may not reliably discover symlinked skills; copy install is recommended." >&2
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS+=("$HOME/.agents/skills")
fi

mkdir -p "$ROOT_DIR/scripts" >/dev/null 2>&1 || true

backup_dir() {
  local path="$1"
  local ts
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  echo "${path}.bak.${ts}"
}

install_one() {
  local dest_root="$1"
  mkdir -p "$dest_root"

  local skill
  for skill in "$SRC_DIR"/*; do
    [[ -d "$skill" ]] || continue
    local name
    name="$(basename "$skill")"
    local dest="$dest_root/$name"

    if [[ -e "$dest" && $FORCE -eq 0 ]]; then
      local bak
      bak="$(backup_dir "$dest")"
      echo "Backing up existing: $dest -> $bak" >&2
      mv "$dest" "$bak"
    elif [[ -e "$dest" && $FORCE -eq 1 ]]; then
      rm -rf "$dest"
    fi

    if [[ $LINK -eq 1 ]]; then
      ln -s "$skill" "$dest"
      echo "Linked $name -> $dest"
    else
      # cp -a preserves perms and is portable.
      cp -a "$skill" "$dest"
      echo "Installed $name -> $dest"
    fi
  done
}

for t in "${TARGETS[@]}"; do
  install_one "$t"
done
