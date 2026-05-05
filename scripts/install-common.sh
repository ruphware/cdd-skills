#!/usr/bin/env bash

# Common helpers for the repo install scripts.

timestamp_utc() {
  date -u +%Y%m%dT%H%M%SZ
}

path_exists() {
  [[ -e "$1" || -L "$1" ]]
}

warn_link_mode() {
  echo "Warning: --link uses symlinks. Copy install is the safer default." >&2
}

fail_usage() {
  echo "$1" >&2
  exit 2
}

legacy_flag_error() {
  local flag="$1"
  local hint="$2"
  fail_usage "Unsupported flag: $flag. $hint"
}

print_paths() {
  local path
  for path in "$@"; do
    echo "  - $path"
  done
}

remove_paths() {
  local path
  for path in "$@"; do
    path_exists "$path" || continue
    rm -rf "$path"
  done
}

confirm_yes_no() {
  local prompt="${1:-Proceed? [y/N] }"
  local ans=""
  read -r -p "$prompt" ans || true

  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

confirm_yes_no_default_yes() {
  local prompt="${1:-Proceed? [Y/n] }"
  local ans=""
  read -r -p "$prompt" ans || true

  case "$ans" in
    n|N|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

remove_paths_with_confirmation() {
  local label="$1"
  shift

  local paths=()
  local path
  for path in "$@"; do
    path_exists "$path" || continue
    paths+=("$path")
  done

  if [[ ${#paths[@]} -eq 0 ]]; then
    echo "Nothing to uninstall from $label."
    return 0
  fi

  echo "The following paths will be removed from $label:"
  print_paths "${paths[@]}"

  if confirm_yes_no "Proceed? [y/N] "; then
    remove_paths "${paths[@]}"
    echo "Removed paths from $label."
  else
    echo "Uninstall aborted."
  fi
}

fail_if_paths_exist_without_update() {
  local label="$1"
  shift

  local existing=()
  local path
  for path in "$@"; do
    path_exists "$path" || continue
    existing+=("$path")
  done

  if [[ ${#existing[@]} -eq 0 ]]; then
    return 0
  fi

  {
    echo "Existing $label detected:"
    print_paths "${existing[@]}"
    echo "Rerun with --update to replace in place, or --uninstall to remove them first."
  } >&2
  exit 1
}
