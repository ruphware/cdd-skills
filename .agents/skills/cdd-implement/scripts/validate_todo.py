#!/usr/bin/env python3
"""
validate_todo.py — deterministic TODO.md structure checker for CDD.

Usage:
  python .agents/skills/cdd-ship-step/scripts/validate_todo.py [path/to/TODO.md]

Checks:
- Each "## Step" section includes: Goal, Deliverable, Changes, Automated checks, UAT

Exit codes:
- 0: OK
- 1: Validation failed
- 2: File not found / unreadable
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple

STEP_HEADER_RE = re.compile(r"^##\s+Step\b.*$", re.MULTILINE)

REQUIRED_FIELDS = [
    "Goal:",
    "Deliverable:",
    "Changes:",
    "Automated checks:",
    "UAT:",
]


@dataclass(frozen=True)
class StepIssue:
    step_heading: str
    missing_fields: List[str]


def _log(level: str, event: str, **fields: str) -> None:
    kv = " ".join([f'{k}="{v}"' for k, v in fields.items()])
    print(f"[CDDValidateTodo] {level} {event} {kv}".strip(), file=sys.stderr)


def _split_steps(todo_text: str) -> List[Tuple[str, str]]:
    headers = list(STEP_HEADER_RE.finditer(todo_text))
    steps: List[Tuple[str, str]] = []
    for i, m in enumerate(headers):
        start = m.start()
        end = headers[i + 1].start() if i + 1 < len(headers) else len(todo_text)
        block = todo_text[start:end].strip()
        heading = m.group(0).strip()
        steps.append((heading, block))
    return steps


def validate(todo_path: Path) -> List[StepIssue]:
    if not todo_path.exists():
        raise FileNotFoundError(str(todo_path))

    text = todo_path.read_text(encoding="utf-8", errors="strict")
    steps = _split_steps(text)
    _log("INFO", "ParsedSteps", steps=str(len(steps)))

    issues: List[StepIssue] = []
    for heading, block in steps:
        missing = [f for f in REQUIRED_FIELDS if f not in block]
        if missing:
            issues.append(StepIssue(step_heading=heading, missing_fields=missing))
    return issues


def main(argv: List[str]) -> int:
    todo_path = Path(argv[1]) if len(argv) > 1 else Path("TODO.md")
    try:
        issues = validate(todo_path)
    except FileNotFoundError:
        _log("ERROR", "TodoNotFound", path=str(todo_path))
        return 2
    except Exception as e:
        _log("ERROR", "TodoReadFailed", path=str(todo_path), msg=str(e))
        return 2

    if not issues:
        _log("INFO", "TodoValid", path=str(todo_path))
        return 0

    for issue in issues:
        _log(
            "ERROR",
            "StepMissingFields",
            step=issue.step_heading,
            missing=",".join(issue.missing_fields),
        )
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
