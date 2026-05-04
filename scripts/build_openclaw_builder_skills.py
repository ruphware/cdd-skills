"""Compatibility wrapper for the generalized runtime Builder skill generator.

Example:
  python3 scripts/build_openclaw_builder_skills.py --output /tmp/openclaw-builder-skills
"""

from __future__ import annotations

import sys

from build_runtime_builder_skills import main as runtime_main


def main() -> int:
    """Forward to the generalized runtime Builder skill generator."""
    return runtime_main(["--runtime", "openclaw", *sys.argv[1:]])


if __name__ == "__main__":
    raise SystemExit(main())
