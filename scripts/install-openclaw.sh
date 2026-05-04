#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Deprecated: use ./scripts/install.sh --runtime openclaw ..." >&2
exec "$ROOT_DIR/scripts/install.sh" --runtime openclaw "$@"
