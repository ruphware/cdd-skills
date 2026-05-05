#!/usr/bin/env bash
set -euo pipefail

OWNER="${CDD_SKILLS_OWNER:-ruphware}"
REPO="${CDD_SKILLS_REPO:-cdd-skills}"
REF="${CDD_SKILLS_REF:-main}"
ARCHIVE_URL="${CDD_SKILLS_ARCHIVE_URL:-https://codeload.github.com/${OWNER}/${REPO}/tar.gz/refs/heads/${REF}}"

for bin in curl tar mktemp; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Missing required command: $bin" >&2
    exit 1
  fi
done

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skills-remote.XXXXXX")"
cleanup() {
  if [[ -n "${WORKDIR:-}" && -d "${WORKDIR:-}" ]]; then
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

curl -fsSL "$ARCHIVE_URL" | tar -xzf - -C "$WORKDIR" --strip-components=1

if [[ ! -x "$WORKDIR/scripts/install.sh" ]]; then
  echo "Downloaded archive does not contain scripts/install.sh" >&2
  exit 1
fi

exec "$WORKDIR/scripts/install.sh" --uninstall "$@"
