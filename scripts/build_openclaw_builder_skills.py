"""Build OpenClaw-ready internal Builder skills from the canonical cdd-* pack.

Example:
  python3 scripts/build_openclaw_builder_skills.py --output /tmp/openclaw-builder-skills
"""

from __future__ import annotations

from pathlib import Path
import argparse
import re
import shutil
import sys


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.S)
EXPLICIT_ONLY_RE = re.compile(r"\s*\(explicit-only\)")
SKILL_REF_RE = re.compile(r"\$?(cdd-[a-z0-9-]+)")


def parse_args() -> argparse.Namespace:
    """Parse CLI args for the build output directory."""
    parser = argparse.ArgumentParser(
        description=(
            "Generate OpenClaw-internal Builder skill variants from the canonical "
            "skills/ tree."
        )
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Directory where generated OpenClaw Builder skills will be written.",
    )
    return parser.parse_args()


def repo_root() -> Path:
    """Return the repository root from the current script location."""
    return Path(__file__).resolve().parent.parent


def canonical_skill_dirs(skills_root: Path) -> list[Path]:
    """Return the canonical cdd-* skill directories in stable order."""
    return sorted(
        path for path in skills_root.iterdir() if path.is_dir() and (path / "SKILL.md").is_file()
    )


def split_frontmatter(skill_md: Path) -> tuple[list[str], str]:
    """Return frontmatter lines and markdown body for a canonical skill file."""
    text = skill_md.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)
    if not match:
        raise ValueError(f"missing YAML frontmatter in {skill_md}")
    frontmatter = match.group(1).splitlines()
    body = text[match.end() :]
    return frontmatter, body


def rewrite_description(line: str) -> str:
    """Convert an explicit-only description into an internal Builder description."""
    _, value = line.split(":", 1)
    description = value.strip().strip('"')
    description = EXPLICIT_ONLY_RE.sub("", description).strip()
    if description.endswith("."):
        description = description[:-1]
    return (
        'description: "'
        + f"{description} (internal OpenClaw Builder skill)."
        + '"'
    )


def rewrite_frontmatter(lines: list[str]) -> list[str]:
    """Produce OpenClaw-compatible internal-use frontmatter for one Builder skill."""
    rewritten: list[str] = []
    saw_description = False

    for line in lines:
        if line.startswith("description:"):
            rewritten.append(rewrite_description(line))
            saw_description = True
            continue
        if line.startswith("disable-model-invocation:"):
            continue
        if line.startswith("user-invocable:"):
            continue
        rewritten.append(line)

    if not saw_description:
        raise ValueError("canonical skill missing description")

    rewritten.append("user-invocable: false")
    return rewritten


def rewrite_body(skill_name: str, body: str) -> str:
    """Add the OpenClaw internal-use wrapper and normalize runtime-specific phrasing."""
    lines = body.splitlines()
    if lines and lines[0].startswith("# "):
        lines[0] = EXPLICIT_ONLY_RE.sub("", lines[0])
    normalized_body = "\n".join(lines)
    normalized_body = EXPLICIT_ONLY_RE.sub("", normalized_body)
    normalized_body = SKILL_REF_RE.sub(r"\1", normalized_body)

    preamble = "\n".join(
        [
            "",
            "> Internal OpenClaw Builder variant generated from the canonical `skills/` pack.",
            ">",
            f"> Use `{skill_name}` as an internal workflow for Master Chef or the Builder subagent.",
            "> Treat `cdd-*` references as internal skill names, not user slash commands.",
            "> If the workflow says to ask for approval, return that request to Master Chef unless explicit human escalation is required.",
            "",
        ]
    )

    if normalized_body.startswith("# "):
        title, rest = normalized_body.split("\n", 1)
        return f"{title}{preamble}{rest}\n"
    return f"{preamble}{normalized_body}\n"


def write_skill(output_root: Path, skill_dir: Path) -> None:
    """Write one generated Builder skill directory."""
    skill_name = skill_dir.name
    frontmatter_lines, body = split_frontmatter(skill_dir / "SKILL.md")
    target_dir = output_root / skill_name
    target_dir.mkdir(parents=True, exist_ok=True)
    skill_md = target_dir / "SKILL.md"
    rewritten = "\n".join(
        [
            "---",
            *rewrite_frontmatter(frontmatter_lines),
            "---",
            rewrite_body(skill_name, body).rstrip(),
            "",
        ]
    )
    skill_md.write_text(rewritten, encoding="utf-8")


def build(output_root: Path) -> None:
    """Generate all OpenClaw Builder skills into the requested output directory."""
    root = repo_root()
    skills_root = root / "skills"
    if not skills_root.is_dir():
        raise ValueError(f"missing canonical skills root: {skills_root}")

    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    for skill_dir in canonical_skill_dirs(skills_root):
        write_skill(output_root, skill_dir)


def main() -> int:
    """Generate the OpenClaw Builder skill pack and print the output directory."""
    args = parse_args()
    output_root = Path(args.output).resolve()
    build(output_root)
    print(f"Generated OpenClaw Builder skills -> {output_root}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover - CLI error surface
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
