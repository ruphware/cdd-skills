#!/usr/bin/env bash
set -euo pipefail

# Install CDD skills into user skill directories.
# Default target: Codex/Codex CLI (~/.agents/skills)
#
# Usage:
#   ./scripts/install.sh                                 # copy into ~/.agents/skills
#   ./scripts/install.sh --force                         # overwrite existing skill dirs
#   ./scripts/install.sh --link                          # symlink instead of copy
#   ./scripts/install.sh --target ~/.agents/skills \
#                      --target ~/.claude/skills \
#                      --target ~/.openclaw/skills
#
# Optional hygiene:
#   ./scripts/install.sh --force --prune                 # also prune deprecated/invalid installed cdd-* skills
#   ./scripts/install.sh --force --prune --yes           # non-interactive prune confirmations
#
# Notes:
# - Prune is conservative: it only targets directories that look like CDD skills (name matches ^cdd-[a-z0-9-]+$).
# - By default, prune asks Y/N per candidate unless --yes is provided.
# - Prune never hard-deletes: it moves candidates to a timestamped backup dir (".pruned.<ts>") so you can recover.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/.agents/skills"

FORCE=0
LINK=0
PRUNE=0
YES=0
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --link) LINK=1; shift ;;
    --prune) PRUNE=1; shift ;;
    --yes|-y) YES=1; shift ;;
    --target) TARGETS+=("$2"); shift 2 ;;
    -h|--help)
      sed -n '1,200p' "$0"
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

# Capture a repo revision for provenance markers (best-effort).
REV="unknown"
if command -v git >/dev/null 2>&1 && [[ -d "$ROOT_DIR/.git" ]]; then
  REV="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

ORIGIN_MARKER_NAME=".cdd-skills-origin"

backup_dir() {
  local path="$1"
  local ts
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  echo "${path}.bak.${ts}"
}

prune_backup_dir() {
  local path="$1"
  local ts
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  echo "${path}.pruned.${ts}"
}

# Only consider directories that are "real" skill names, not backups.
looks_like_skill_name() {
  local name="$1"
  [[ "$name" =~ ^cdd-[a-z0-9-]+$ ]]
}

in_set() {
  local needle="$1"
  local hay="$2"
  grep -qxF "$needle" <<<"$hay"
}

# Build the canonical list of skills from source: directories that actually contain SKILL.md.
source_skill_names() {
  local d
  for d in "$SRC_DIR"/*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/SKILL.md" ]] || continue
    basename "$d"
  done
}

write_origin_marker() {
  local dest_dir="$1"
  # Do not write markers through symlinks (would mutate the source checkout).
  if [[ -L "$dest_dir" ]]; then
    return 0
  fi

  cat >"$dest_dir/$ORIGIN_MARKER_NAME" <<__CDD_ORIGIN__
cdd_skills_origin=ruphware/cdd-skills
installed_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_rev=${REV}
__CDD_ORIGIN__
}

prune_deprecated_in_target() {
  local dest_root="$1"

  local src_set
  src_set="$(source_skill_names || true)"

  local d
  for d in "$dest_root"/cdd-*; do
    [[ -d "$d" ]] || continue

    local name
    name="$(basename "$d")"

    looks_like_skill_name "$name" || continue

    local should_prune=0

    # Prune if missing SKILL.md (invalid install), or not present in current source set.
    if [[ ! -f "$d/SKILL.md" ]]; then
      should_prune=1
    elif ! in_set "$name" "$src_set"; then
      should_prune=1
    fi

    [[ $should_prune -eq 1 ]] || continue

    local has_marker=0
    if [[ -f "$d/$ORIGIN_MARKER_NAME" ]]; then
      has_marker=1
    fi

    # Non-interactive safety: require --yes.
    if [[ $YES -eq 0 && ! -t 0 ]]; then
      echo "Refusing to prune in non-interactive mode without --yes: $d" >&2
      exit 2
    fi

    # Auto-prune rules for --yes: only prune if (a) it's clearly invalid (no SKILL.md), or (b) it has our origin marker.
    if [[ $YES -eq 1 ]]; then
      if [[ ! -f "$d/SKILL.md" || $has_marker -eq 1 ]]; then
        local bak
        bak="$(prune_backup_dir "$d")"
        echo "Pruning: $d -> $bak" >&2
        mv "$d" "$bak"
      else
        echo "Skip prune (no origin marker; not obviously invalid): $d" >&2
      fi
      continue
    fi

    # Interactive confirm.
    echo "Prune candidate: $d" >&2
    if [[ -f "$d/SKILL.md" ]]; then
      echo "--- SKILL.md (first 20 lines) ---" >&2
      sed -n '1,20p' "$d/SKILL.md" >&2
      echo "--------------------------------" >&2
    else
      echo "(No SKILL.md found; this looks like an invalid/partial install.)" >&2
    fi

    local ans
    read -r -p "Prune (move aside) '$name' from $dest_root ? [y/N] " ans
    if [[ "$ans" == "y" || "$ans" == "Y" || "$ans" == "yes" || "$ans" == "YES" ]]; then
      local bak
      bak="$(prune_backup_dir "$d")"
      echo "Pruning: $d -> $bak" >&2
      mv "$d" "$bak"
    else
      echo "Keeping: $d" >&2
    fi
  done
}

install_one() {
  local dest_root="$1"
  mkdir -p "$dest_root"

  if [[ $PRUNE -eq 1 ]]; then
    prune_deprecated_in_target "$dest_root"
  fi

  local skill
  for skill in "$SRC_DIR"/*; do
    [[ -d "$skill" ]] || continue

    # Only install real skills (SKILL.md is the contract).
    [[ -f "$skill/SKILL.md" ]] || continue

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
      write_origin_marker "$dest"
      echo "Installed $name -> $dest"
    fi
  done
}

for t in "${TARGETS[@]}"; do
  install_one "$t"
done
