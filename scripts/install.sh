#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./install-common.sh
source "$ROOT_DIR/scripts/install-common.sh"

# Install Builder CDD skills into user skill directories.
# Default target: Codex/Codex CLI (~/.agents/skills)
#
# Usage:
#   ./scripts/install.sh                                 # copy into ~/.agents/skills
#   ./scripts/install.sh --update                        # replace existing installed skills in place
#   ./scripts/install.sh --uninstall                     # remove installed skills and installer artifacts after confirmation
#   ./scripts/install.sh --link                          # symlink instead of copy
#   ./scripts/install.sh --target ~/.agents/skills \
#                      --target ~/.claude/skills
#
# Notes:
# - Fresh install fails if one of the managed skill directories already exists in the target root.
# - Use --update to replace current installs in place; Builder prune runs automatically during --update.
# - Prune is conservative: it only targets directories that look like CDD skills (name matches ^cdd-[a-z0-9-]+$).
# - By default, prune asks Y/N per candidate unless --yes is provided.
# - Prune never hard-deletes: it moves candidates to a timestamped backup dir (".pruned.<ts>") so you can recover.

SRC_DIR="$ROOT_DIR/skills"

UPDATE=0
UNINSTALL=0
LINK=0
YES=0
TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--target DIR ...] [--link] [--update] [--yes] [--uninstall]

Install Builder CDD skills into runtime skill directories.

Options:
  --target DIR   Install into DIR instead of ~/.agents/skills; may be repeated
  --link         Symlink source skill directories instead of copying them
  --update       Replace existing managed installs in place and run conservative prune
  --yes, -y      Auto-confirm prune prompts during --update
  --uninstall    List managed installs and installer artifacts, ask y/N, and remove them
  -h, --help     Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --link) LINK=1; shift ;;
    --yes|-y) YES=1; shift ;;
    --target) TARGETS+=("$2"); shift 2 ;;
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      legacy_flag_error "--force" "Use --update instead."
      ;;
    --prune)
      legacy_flag_error "--prune" "Prune now runs automatically during --update."
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ $UNINSTALL -eq 1 && ( $UPDATE -eq 1 || $LINK -eq 1 || $YES -eq 1 ) ]]; then
  fail_usage "--uninstall cannot be combined with --update, --link, or --yes."
fi

if [[ $YES -eq 1 && $UPDATE -eq 0 ]]; then
  fail_usage "--yes is only valid with --update."
fi

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

REV="unknown"
if command -v git >/dev/null 2>&1 && [[ -d "$ROOT_DIR/.git" ]]; then
  REV="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

ORIGIN_MARKER_NAME=".cdd-skills-origin"

prune_backup_dir() {
  local path="$1"
  echo "${path}.pruned.$(timestamp_utc)"
}

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

    if [[ $YES -eq 0 && ! -t 0 ]]; then
      echo "Refusing to prune in non-interactive mode without --yes: $d" >&2
      exit 2
    fi

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

uninstall_from_target() {
  local dest_root="$1"
  local src_set
  src_set="$(source_skill_names || true)"

  local paths=()
  local skill
  for skill in "$SRC_DIR"/*; do
    [[ -d "$skill" ]] || continue
    [[ -f "$skill/SKILL.md" ]] || continue
    local name
    name="$(basename "$skill")"
    local dest="$dest_root/$name"
    if path_exists "$dest"; then
      paths+=("$dest")
    fi
  done

  local d
  for d in "$dest_root"/cdd-*; do
    path_exists "$d" || continue

    local name
    name="$(basename "$d")"

    case "$name" in
      *.bak.*|*.pruned.*)
        paths+=("$d")
        continue
        ;;
    esac

    looks_like_skill_name "$name" || continue

    if in_set "$name" "$src_set"; then
      continue
    fi

    if [[ ! -f "$d/SKILL.md" || -f "$d/$ORIGIN_MARKER_NAME" ]]; then
      paths+=("$d")
    fi
  done

  if [[ ${#paths[@]} -gt 0 ]]; then
    remove_paths_with_confirmation "Builder skills in $dest_root" "${paths[@]}"
  else
    remove_paths_with_confirmation "Builder skills in $dest_root"
  fi
}

install_one() {
  local dest_root="$1"

  if [[ $UNINSTALL -eq 1 ]]; then
    uninstall_from_target "$dest_root"
    return 0
  fi

  mkdir -p "$dest_root"

  if [[ $UPDATE -eq 1 ]]; then
    prune_deprecated_in_target "$dest_root"
  fi

  local existing=()
  local skill
  for skill in "$SRC_DIR"/*; do
    [[ -d "$skill" ]] || continue
    [[ -f "$skill/SKILL.md" ]] || continue

    local name
    name="$(basename "$skill")"
    local dest="$dest_root/$name"

    if path_exists "$dest"; then
      existing+=("$dest")
    fi
  done

  if [[ $UPDATE -eq 0 ]]; then
    if [[ ${#existing[@]} -gt 0 ]]; then
      fail_if_paths_exist_without_update "Builder skill installs in $dest_root" "${existing[@]}"
    else
      fail_if_paths_exist_without_update "Builder skill installs in $dest_root"
    fi
  fi

  if [[ ${#existing[@]} -gt 0 ]]; then
    remove_paths "${existing[@]}"
  fi

  for skill in "$SRC_DIR"/*; do
    [[ -d "$skill" ]] || continue
    [[ -f "$skill/SKILL.md" ]] || continue

    local name
    name="$(basename "$skill")"
    local dest="$dest_root/$name"

    if [[ $LINK -eq 1 ]]; then
      ln -s "$skill" "$dest"
      echo "Linked $name -> $dest"
    else
      cp -a "$skill" "$dest"
      write_origin_marker "$dest"
      echo "Installed $name -> $dest"
    fi
  done
}

for t in "${TARGETS[@]}"; do
  install_one "$t"
done
