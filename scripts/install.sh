#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./install-common.sh
source "$ROOT_DIR/scripts/install-common.sh"

# Install CDD skills into runtime skill directories.
#
# Default path:
# - generic/codex-style targets -> ~/.agents/skills
# - claude runtime            -> ~/.claude/skills
# - openclaw runtime          -> ~/.openclaw/skills
#
# Usage:
#   ./scripts/install.sh
#   ./scripts/install.sh --runtime claude
#   ./scripts/install.sh --runtime openclaw
#   ./scripts/install.sh --target ~/.agents/skills --target ~/.claude/skills
#   ./scripts/install.sh --runtime openclaw --target ~/.openclaw/skills

SKILLS_SRC_ROOT="$ROOT_DIR/skills"
MASTER_CHEF_SRC_ROOT="$ROOT_DIR/cdd-master-chef"
OPENCLAW_SRC_ROOT="$MASTER_CHEF_SRC_ROOT/openclaw"
RUNTIME_BUILDER_GENERATOR="$ROOT_DIR/scripts/build_runtime_builder_skills.py"

UPDATE=0
UNINSTALL=0
LINK=0
YES=0
ALL=0
RUNTIME="generic"
RUNTIME_EXPLICIT=0
TARGETS=()
SOURCE_PACKAGES=()
BUILD_ROOT=""

cleanup() {
  if [[ -n "$BUILD_ROOT" && -d "$BUILD_ROOT" ]]; then
    rm -rf "$BUILD_ROOT"
  fi
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--runtime NAME] [--target DIR ...] [--link] [--update] [--yes] [--uninstall] [--all]

Install CDD skills into runtime skill directories.

Runtimes:
  generic     Canonical cdd-* skills plus the canonical cdd-master-chef package
  codex       Alias for generic with ~/.agents/skills as the default target
  claude      Canonical cdd-* skills plus the canonical cdd-master-chef package, default target ~/.claude/skills
  openclaw    Canonical cdd-master-chef package plus generated internal OpenClaw Builder skills

Options:
  --runtime NAME  Select package/runtime mode; default: generic
  --target DIR    Install into DIR instead of the runtime default; may be repeated
  --all           Install, update, or uninstall across every existing default runtime home
  --link          Symlink canonical source skill directories when possible instead of copying them
  --update        Replace existing managed installs in place and run conservative prune
  --yes, -y       Auto-confirm prune prompts during --update
  --uninstall     List managed installs and installer artifacts, ask y/N, and remove them
  -h, --help      Show this help text
EOF
}

runtime_default_target() {
  case "$RUNTIME" in
    claude)
      echo "$HOME/.claude/skills"
      ;;
    openclaw)
      echo "$HOME/.openclaw/skills"
      ;;
    codex|generic)
      echo "$HOME/.agents/skills"
      ;;
    *)
      fail_usage "Unsupported runtime: $RUNTIME"
      ;;
  esac
}

runtime_is_core() {
  [[ "$RUNTIME" == "generic" || "$RUNTIME" == "codex" || "$RUNTIME" == "claude" ]]
}

runtime_home_root() {
  case "$RUNTIME" in
    claude)
      echo "$HOME/.claude"
      ;;
    openclaw)
      echo "$HOME/.openclaw"
      ;;
    codex|generic)
      echo "$HOME/.agents"
      ;;
    *)
      fail_usage "Unsupported runtime: $RUNTIME"
      ;;
  esac
}

build_source_packages() {
  SOURCE_PACKAGES=()

  if runtime_is_core; then
    local skill_dir
    for skill_dir in "$SKILLS_SRC_ROOT"/*; do
      [[ -d "$skill_dir" ]] || continue
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      SOURCE_PACKAGES+=("$skill_dir")
    done
    SOURCE_PACKAGES+=("$MASTER_CHEF_SRC_ROOT")
    return 0
  fi

  if [[ "$RUNTIME" != "openclaw" ]]; then
    fail_usage "Unsupported runtime: $RUNTIME"
  fi

  SOURCE_PACKAGES+=("$MASTER_CHEF_SRC_ROOT")
  BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skills-build.XXXXXX")"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "Missing required binary: python3" >&2
    exit 1
  fi

  if [[ ! -f "$RUNTIME_BUILDER_GENERATOR" ]]; then
    echo "Missing generator script: $RUNTIME_BUILDER_GENERATOR" >&2
    exit 1
  fi

  python3 "$RUNTIME_BUILDER_GENERATOR" --runtime openclaw --output "$BUILD_ROOT/openclaw-builder" >/dev/null
  for skill_dir in "$BUILD_ROOT/openclaw-builder"/*; do
    [[ -d "$skill_dir" ]] || continue
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    SOURCE_PACKAGES+=("$skill_dir")
  done
}

install_all_runtimes() {
  local original_runtime="$RUNTIME"
  local found_any=0
  local runtime

  for runtime in generic claude openclaw; do
    RUNTIME="$runtime"

    local runtime_home
    runtime_home="$(runtime_home_root)"
    if [[ ! -d "$runtime_home" ]]; then
      echo "Skipping $runtime (missing runtime home: $runtime_home)" >&2
      continue
    fi

    TARGETS=("$(runtime_default_target)")
    build_source_packages

    local target
    for target in "${TARGETS[@]}"; do
      install_one "$target"
    done

    found_any=1
  done

  RUNTIME="$original_runtime"

  if [[ $found_any -eq 0 ]]; then
    echo "No existing runtime homes found under $HOME/.agents, $HOME/.claude, or $HOME/.openclaw." >&2
    exit 1
  fi
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

source_skill_names() {
  local d
  for d in "${SOURCE_PACKAGES[@]}"; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/SKILL.md" ]] || continue
    basename "$d"
  done
}

REV="unknown"
if command -v git >/dev/null 2>&1 && [[ -d "$ROOT_DIR/.git" ]]; then
  REV="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

ORIGIN_MARKER_NAME=".cdd-skills-origin"

write_origin_marker() {
  local dest_dir="$1"
  if [[ -L "$dest_dir" ]]; then
    return 0
  fi

  cat >"$dest_dir/$ORIGIN_MARKER_NAME" <<__CDD_ORIGIN__
cdd_skills_origin=ruphware/cdd-skills
installed_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_rev=${REV}
runtime=${RUNTIME}
__CDD_ORIGIN__
}

prune_backup_dir() {
  local path="$1"
  echo "${path}.pruned.$(timestamp_utc)"
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
  local package_dir
  for package_dir in "${SOURCE_PACKAGES[@]}"; do
    [[ -d "$package_dir" ]] || continue
    [[ -f "$package_dir/SKILL.md" ]] || continue
    local name
    name="$(basename "$package_dir")"
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
    remove_paths_with_confirmation "CDD skills in $dest_root" "${paths[@]}"
  else
    remove_paths_with_confirmation "CDD skills in $dest_root"
  fi
}

should_link_source() {
  local source_dir="$1"
  [[ $LINK -eq 1 && ( "$source_dir" == "$SKILLS_SRC_ROOT"/* || "$source_dir" == "$MASTER_CHEF_SRC_ROOT" ) ]]
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
  local package_dir
  for package_dir in "${SOURCE_PACKAGES[@]}"; do
    [[ -d "$package_dir" ]] || continue
    [[ -f "$package_dir/SKILL.md" ]] || continue

    local name
    name="$(basename "$package_dir")"
    local dest="$dest_root/$name"

    if path_exists "$dest"; then
      existing+=("$dest")
    fi
  done

  if [[ $UPDATE -eq 0 ]]; then
    if [[ ${#existing[@]} -gt 0 ]]; then
      fail_if_paths_exist_without_update "CDD skill installs in $dest_root" "${existing[@]}"
    else
      fail_if_paths_exist_without_update "CDD skill installs in $dest_root"
    fi
  fi

  if [[ ${#existing[@]} -gt 0 ]]; then
    remove_paths "${existing[@]}"
  fi

  for package_dir in "${SOURCE_PACKAGES[@]}"; do
    [[ -d "$package_dir" ]] || continue
    [[ -f "$package_dir/SKILL.md" ]] || continue

    local name
    name="$(basename "$package_dir")"
    local dest="$dest_root/$name"

    if should_link_source "$package_dir"; then
      ln -s "$package_dir" "$dest"
      echo "Linked $name -> $dest"
    else
      cp -a "$package_dir" "$dest"
      write_origin_marker "$dest"
      echo "Installed $name -> $dest"
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)
      if [[ $# -lt 2 ]]; then
        fail_usage "Missing value for --runtime."
      fi
      RUNTIME="$2"
      RUNTIME_EXPLICIT=1
      shift 2
      ;;
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
    --yes|-y)
      YES=1
      shift
      ;;
    --target)
      if [[ $# -lt 2 ]]; then
        fail_usage "Missing value for --target."
      fi
      TARGETS+=("$2")
      shift 2
      ;;
    --all)
      ALL=1
      shift
      ;;
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

case "$RUNTIME" in
  generic|codex|claude|openclaw) ;;
  *)
    fail_usage "Unsupported runtime: $RUNTIME"
    ;;
esac

if [[ $UNINSTALL -eq 1 && ( $UPDATE -eq 1 || $LINK -eq 1 || $YES -eq 1 ) ]]; then
  fail_usage "--uninstall cannot be combined with --update, --link, or --yes."
fi

if [[ $YES -eq 1 && $UPDATE -eq 0 ]]; then
  fail_usage "--yes is only valid with --update."
fi

if [[ $ALL -eq 1 && ${#TARGETS[@]} -gt 0 ]]; then
  fail_usage "--all cannot be combined with --target."
fi

if [[ $ALL -eq 1 && $RUNTIME_EXPLICIT -eq 1 ]]; then
  fail_usage "--all cannot be combined with --runtime."
fi

if [[ ! -d "$SKILLS_SRC_ROOT" ]]; then
  echo "Missing source skills dir: $SKILLS_SRC_ROOT" >&2
  exit 1
fi

if [[ ! -d "$MASTER_CHEF_SRC_ROOT" ]]; then
  echo "Missing canonical Master Chef package dir: $MASTER_CHEF_SRC_ROOT" >&2
  exit 1
fi

if [[ ! -f "$MASTER_CHEF_SRC_ROOT/SKILL.md" ]]; then
  echo "Missing Master Chef skill entrypoint: $MASTER_CHEF_SRC_ROOT/SKILL.md" >&2
  exit 1
fi

if [[ "$RUNTIME" == "openclaw" ]]; then
  if [[ ! -d "$OPENCLAW_SRC_ROOT" ]]; then
    echo "Missing OpenClaw adapter source dir: $OPENCLAW_SRC_ROOT" >&2
    exit 1
  fi
  if [[ ! -f "$OPENCLAW_SRC_ROOT/README.md" ]]; then
    echo "Missing OpenClaw adapter docs: $OPENCLAW_SRC_ROOT/README.md" >&2
    exit 1
  fi
fi

if [[ $LINK -eq 1 ]]; then
  echo "Warning: --link symlinks canonical source skill directories when possible. Generated runtime Builder skills are still copied." >&2
fi

if [[ $ALL -eq 1 ]]; then
  install_all_runtimes
else
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS+=("$(runtime_default_target)")
  fi

  build_source_packages

  for t in "${TARGETS[@]}"; do
    install_one "$t"
  done
fi
