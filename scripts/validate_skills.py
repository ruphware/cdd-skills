"""Validate Builder and OpenClaw skill structure for this repo.

Example:
  python3 scripts/validate_skills.py
"""

from __future__ import annotations

from pathlib import Path
import re
import subprocess
import sys
import tempfile


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.S)
MULTILINE_VALUE_RE = re.compile(r"^[a-zA-Z0-9_-]+:\s*[|>]\s*$", re.M)


def frontmatter(path: Path) -> str:
    """Return frontmatter text for a SKILL.md file or raise with a clear error."""
    text = path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)
    assert match, f"missing YAML frontmatter in {path}"
    meta = match.group(1)
    assert not MULTILINE_VALUE_RE.search(meta), (
        f"multiline frontmatter not allowed in {path}"
    )
    return meta


def require_field(meta: str, pattern: str, path: Path, label: str) -> None:
    """Assert that a frontmatter pattern exists for the given file."""
    assert re.search(pattern, meta, re.M), f"missing {label} in {path}"


def require_any_substring(
    skill_text: str, phrases: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that at least one expected phrase exists in the given skill text."""
    assert any(phrase in skill_text for phrase in phrases), f"missing {label} in {path}"


def validate_audit_and_implement_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the audit skill keeps its clarification and assumption guardrails."""
    require_any_substring(
        skill_text,
        (
            "Ask clarifying questions one at a time and keep them guided:",
            "Ask clarifying questions one at a time using the interaction contract above.",
        ),
        skill_md,
        "guided clarification flow",
    )
    require_any_substring(
        skill_text,
        (
            "mark one option as the recommended default and explain it briefly",
            "put the recommended option first and mark it clearly",
        ),
        skill_md,
        "recommended-option guidance",
    )
    assert (
        "If any material assumption would remain after the answers, list only those "
        "material assumptions and ask the user to confirm or correct them before continuing."
    ) in skill_text, f"material assumption confirmation guardrail missing in {skill_md}"
    assert (
        "If only minor defaults remain, disclose them briefly in the plan and proceed "
        "without blocking."
    ) in skill_text, f"minor default handling guardrail missing in {skill_md}"
    assert "Keep the plan KISS and CDD-style: minimal steps, minimal diffs, no invented structure." in skill_text, (
        f"KISS/CDD planning guardrail missing in {skill_md}"
    )
    require_any_substring(
        skill_text,
        (
            "Ask which of the newly created steps to implement first using guided options; recommend the first runnable new step by default.",
            "Ask which of the newly created steps to implement first using the same bottom-positioned guided options; recommend the first runnable new step by default.",
            "Ask which of the newly created steps to implement first using the same bottom-positioned, selector-prefixed guided options; recommend the first runnable new step by default.",
        ),
        skill_md,
        "guided implementation-step selection",
    )


def validate_selector_labeled_options(skill_text: str, skill_md: Path) -> None:
    """Assert interactive planning skills require visible option selectors."""
    assert (
        "prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key"
    ) in skill_text, f"selector-labeled option guidance missing in {skill_md}"
    assert (
        "default to letters: `A.`, `B.`, `C.`"
    ) in skill_text, f"default lettered option guidance missing in {skill_md}"
    assert (
        "use numbers only when the surrounding context is already numeric and that would be clearer"
    ) in skill_text, f"numeric option fallback guidance missing in {skill_md}"
    assert (
        "when practical, tell the user they can reply with just the selector"
    ) in skill_text, f"selector reply guidance missing in {skill_md}"


def validate_boot_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the boot skill keeps its graceful vanilla boot contract."""
    assert (
        "If `AGENTS.md` is missing, stop and tell the user the repo is not CDD-ready for vanilla boot."
    ) in skill_text, f"AGENTS hard-stop missing in {skill_md}"
    assert (
        "Read `AGENTS.md` first and treat it as the source of truth for role and response format."
    ) in skill_text, f"AGENTS-first boot contract missing in {skill_md}"
    assert (
        "Continue gracefully when `README.md`, `docs/INDEX.md`, `docs/specs/blueprint.md`, or `docs/JOURNAL.md` are missing."
    ) in skill_text, f"graceful missing-docs handling missing in {skill_md}"
    assert (
        "Use only the top of `docs/JOURNAL.md` or development fallback files; do not ingest full history unless the user explicitly asks."
    ) in skill_text, f"top-of-journal guardrail missing in {skill_md}"
    assert "Do not write or modify repo files." in skill_text, (
        f"read-only boot contract missing in {skill_md}"
    )
    assert "On success, recommend continuing in vanilla AGENTS-driven mode." in skill_text, (
        f"vanilla next-step guidance missing in {skill_md}"
    )


def validate_maintain_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the maintain skill keeps its archive and doctoring contract."""
    assert "Apply safe archive moves immediately." in skill_text, (
        f"safe archive behavior missing in {skill_md}"
    )
    assert "Ask before deleting stale adjacent `TODO*.md` files." in skill_text, (
        f"stale TODO deletion approval missing in {skill_md}"
    )
    assert "Retain the newest 3 step headings in each active TODO file." in skill_text, (
        f"TODO keep-3 rule missing in {skill_md}"
    )
    assert "Preserve top-to-bottom TODO history: archive only from the oldest contiguous archiveable block near the top of the active step list." in skill_text, (
        f"TODO top-contiguous archive rule missing in {skill_md}"
    )
    assert "Never archive a step from the middle or tail of the active TODO file." in skill_text, (
        f"TODO middle-archive guardrail missing in {skill_md}"
    )
    assert "Do not leapfrog an older incomplete or ambiguous step in order to archive later completed steps below it." in skill_text, (
        f"TODO leapfrog guardrail missing in {skill_md}"
    )
    assert "If the same-day archive file already exists, append the newly archived sections instead of overwriting it." in skill_text, (
        f"same-day archive append rule missing in {skill_md}"
    )
    assert "If older incomplete or ambiguous steps block a clean top trim, do not archive later completed steps; report archival as blocked by non-contiguous active history." in skill_text, (
        f"TODO non-contiguous history rule missing in {skill_md}"
    )
    assert "Archive `docs/JOURNAL.md` only according to the rules defined there." in skill_text, (
        f"journal archive rule missing in {skill_md}"
    )
    assert "If `docs/JOURNAL.md` has no clear archive rule near the top, do not invent one; skip journal archival and report that it was skipped." in skill_text, (
        f"journal skip rule missing in {skill_md}"
    )
    assert "Treat `README.md`, `docs/specs/prd.md`, and `docs/specs/blueprint.md` as canonical support docs." in skill_text, (
        f"support-doc scope missing in {skill_md}"
    )
    assert "Classify each support doc as `current`, `drifted`, `missing`, or `unclear`." in skill_text, (
        f"support-doc classification rule missing in {skill_md}"
    )
    assert "Do not silently refresh `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, `docs/INDEX.md`, or `docs/prompts/PROMPT-INDEX.md`." in skill_text, (
        f"support-doc no-silent-refresh rule missing in {skill_md}"
    )
    assert "Ask once for documentation approval using a single grouped confirmation such as: `Approve and apply these documentation updates?`" in skill_text, (
        f"documentation approval gate missing in {skill_md}"
    )
    assert "Keep documentation approval separate from stale TODO deletion approval so the user can approve doc updates without approving file deletions." in skill_text, (
        f"separate doc/deletion approval rule missing in {skill_md}"
    )
    assert "Report the exact age in days." in skill_text, (
        f"INDEX age reporting missing in {skill_md}"
    )
    assert "Never auto-delete code." in skill_text, (
        f"no-code-deletion guardrail missing in {skill_md}"
    )
    assert "Do not create TODO or refactor files automatically." in skill_text, (
        f"no-auto-refactor-artifacts guardrail missing in {skill_md}"
    )


def validate_init_project_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the init skill keeps the canonical boilerplate source guardrails."""
    assert (
        "Treat `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source when boilerplate material is needed."
    ) in skill_text, f"canonical bootstrap source rule missing in {skill_md}"
    assert (
        "Even when that canonical source is identified, do not copy, download, clone, or otherwise materialize boilerplate from it until the user gives separate explicit confirmation."
    ) in skill_text, f"bootstrap approval gate missing in {skill_md}"
    assert (
        "If the user explicitly prefers a local checkout or network access is unavailable, ask for a local path to an existing `cdd-boilerplate` checkout as the fallback bootstrap source."
    ) in skill_text, f"local checkout fallback rule missing in {skill_md}"
    assert "ask for a local path to a `cdd-boilerplate` checkout (preferred)" not in skill_text, (
        f"local checkout should not be preferred in {skill_md}"
    )


def validate_builder_skill(skill_dir: Path) -> None:
    """Validate one Builder skill directory under skills/."""
    skill_md = skill_dir / "SKILL.md"
    assert skill_md.exists(), f"missing {skill_md}"
    skill_text = skill_md.read_text(encoding="utf-8")
    meta = frontmatter(skill_md)
    require_field(meta, rf"^name:\s*{re.escape(skill_dir.name)}\s*$", skill_md, "name")
    require_field(meta, r"^description:\s*.+", skill_md, "description")
    require_field(
        meta,
        r"^disable-model-invocation:\s*true\b",
        skill_md,
        "disable-model-invocation: true",
    )

    openai_yaml = skill_dir / "agents" / "openai.yaml"
    assert openai_yaml.exists(), f"missing {openai_yaml}"
    yaml_text = openai_yaml.read_text(encoding="utf-8")
    assert "allow_implicit_invocation: false" in yaml_text, (
        f"implicit invocation not disabled in {openai_yaml}"
    )

    if skill_dir.name == "cdd-implement-todo":
        assert "update only the selected step in the active `TODO*.md` file" in skill_text, (
            f"TODO completion writeback missing in {skill_md}"
        )
        assert "Do not add a new step-level `Status:` field" in skill_text, (
            f"TODO completion guardrail missing in {skill_md}"
        )
    if skill_dir.name == "cdd-boot":
        validate_boot_skill_text(skill_text, skill_md)
    if skill_dir.name == "cdd-maintain":
        validate_maintain_skill_text(skill_text, skill_md)
    if skill_dir.name == "cdd-init-project":
        validate_init_project_skill_text(skill_text, skill_md)
    if skill_dir.name == "cdd-audit-and-implement":
        validate_audit_and_implement_skill_text(skill_text, skill_md)
    if skill_dir.name in {
        "cdd-plan",
        "cdd-init-project",
        "cdd-refactor",
        "cdd-audit-and-implement",
    }:
        validate_selector_labeled_options(skill_text, skill_md)


def validate_openclaw_skill(repo_root: Path) -> None:
    """Validate the OpenClaw-only skill package."""
    skill_md = repo_root / "openclaw" / "SKILL.md"
    assert skill_md.exists(), f"missing {skill_md}"
    skill_text = skill_md.read_text(encoding="utf-8")
    meta = frontmatter(skill_md)
    require_field(meta, r"^name:\s*cdd-master-chef\s*$", skill_md, "name")
    require_field(meta, r"^description:\s*.+", skill_md, "description")
    require_field(meta, r"^user-invocable:\s*true\b", skill_md, "user-invocable: true")
    assert "disable-model-invocation:" not in meta, (
        f"cdd-master-chef should stay model-visible for implicit invocation in {skill_md}"
    )
    require_field(meta, r"^metadata:\s*\{.+\}\s*$", skill_md, "metadata")
    assert "The Builder runs as an OpenClaw subagent, not ACP." in skill_text, (
        f"subagent Builder contract missing in {skill_md}"
    )
    assert "There is no watchdog cron or separate supervising agent; Master Chef checks Builder health directly in the main session when active." in skill_text, (
        f"direct main-session Builder-check contract missing in {skill_md}"
    )
    assert "Use one-step Builder runs only." in skill_text, (
        f"one-step Builder-run contract missing in {skill_md}"
    )
    assert "Do not treat Builder session resurrection or multi-step continuation as a normal path." in skill_text, (
        f"Builder session-resurrection guardrail missing in {skill_md}"
    )
    assert ".cdd-runtime/master-chef/run.json" in skill_text, (
        f"durable runtime state missing in {skill_md}"
    )
    assert "Master Chef chooses the internal `cdd-*` routing model." in skill_text, (
        f"OpenClaw routing model contract missing in {skill_md}"
    )
    assert "Treat the installed `cdd-*` skills as internal OpenClaw workflows, not user slash commands." in skill_text, (
        f"internal OpenClaw workflow contract missing in {skill_md}"
    )
    assert "Builder default: `cdd-implement-todo` for the next runnable TODO step." in skill_text, (
        f"default Builder routing contract missing in {skill_md}"
    )
    assert "Allowed bootstrap path: a new or adoptable project folder that should be brought into the CDD contract first via `cdd-init-project`" in skill_text, (
        f"new-project CDD bootstrap contract missing in {skill_md}"
    )


def validate_generated_openclaw_builder_skills(repo_root: Path) -> None:
    """Validate the generated OpenClaw Builder variants built from skills/."""
    generator = repo_root / "scripts" / "build_openclaw_builder_skills.py"
    assert generator.exists(), f"missing {generator}"

    skills_root = repo_root / "skills"
    canonical_names = sorted(path.name for path in skills_root.iterdir() if path.is_dir())
    assert canonical_names, f"no canonical Builder skills found in {skills_root}"

    with tempfile.TemporaryDirectory(prefix="cdd-openclaw-builder-") as tmp_dir:
        output_root = Path(tmp_dir) / "generated"
        subprocess.run(
            [sys.executable, str(generator), "--output", str(output_root)],
            check=True,
            capture_output=True,
            text=True,
        )

        for skill_name in canonical_names:
            generated_dir = output_root / skill_name
            skill_md = generated_dir / "SKILL.md"
            assert skill_md.exists(), f"missing generated {skill_md}"
            skill_text = skill_md.read_text(encoding="utf-8")
            meta = frontmatter(skill_md)
            require_field(
                meta,
                rf"^name:\s*{re.escape(skill_name)}\s*$",
                skill_md,
                "name",
            )
            require_field(
                meta,
                r"^description:\s*.+internal OpenClaw Builder skill.+$",
                skill_md,
                "internal Builder description",
            )
            require_field(
                meta,
                r"^user-invocable:\s*false\b",
                skill_md,
                "user-invocable: false",
            )
            assert "disable-model-invocation:" not in meta, (
                f"generated skill should be model-visible in {skill_md}"
            )
            assert "Internal OpenClaw Builder variant generated from the canonical `skills/` pack." in skill_text, (
                f"internal-use wrapper missing in {skill_md}"
            )
            assert "return that request to Master Chef" in skill_text, (
                f"Master Chef approval routing missing in {skill_md}"
            )

            if skill_name == "cdd-implement-todo":
                assert "update only the selected step in the active `TODO*.md` file" in skill_text, (
                    f"generated TODO completion writeback missing in {skill_md}"
                )
                assert "Do not add a new step-level `Status:` field" in skill_text, (
                    f"generated TODO completion guardrail missing in {skill_md}"
                )
            if skill_name == "cdd-boot":
                validate_boot_skill_text(skill_text, skill_md)
            if skill_name == "cdd-maintain":
                validate_maintain_skill_text(skill_text, skill_md)
            if skill_name == "cdd-init-project":
                validate_init_project_skill_text(skill_text, skill_md)
            if skill_name == "cdd-audit-and-implement":
                validate_audit_and_implement_skill_text(skill_text, skill_md)
            if skill_name in {
                "cdd-plan",
                "cdd-init-project",
                "cdd-refactor",
                "cdd-audit-and-implement",
            }:
                validate_selector_labeled_options(skill_text, skill_md)


def main() -> int:
    """Validate the current repository layout and print a success marker."""
    repo_root = Path(__file__).resolve().parent.parent
    skills_root = repo_root / "skills"
    assert skills_root.exists(), f"missing {skills_root}"

    skill_dirs = sorted(path for path in skills_root.iterdir() if path.is_dir())
    assert skill_dirs, f"no Builder skill directories found in {skills_root}"

    for skill_dir in skill_dirs:
        validate_builder_skill(skill_dir)

    validate_generated_openclaw_builder_skills(repo_root)
    validate_openclaw_skill(repo_root)
    print("skill structure checks passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
