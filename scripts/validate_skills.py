"""Structural validation for CDD skills and the shared master-chef contract.

This validator is intentionally narrow. It asserts:
  - file presence (skill SKILL.md and openai.yaml per skill; full master-chef
    contract file set; generated openclaw builder skills)
  - frontmatter shape (name regex, description present, disable-model-invocation
    flag for user-facing skills, user-invocable flag for generated variants)
  - openai.yaml display names and implicit-invocation flags
  - required H2 section headings by name only (not by body content)
  - master-chef SKILL.md references each installed skill by name

Prose / phrase / topic matching used to live here and broke on every wording
edit; that layer was removed in favor of trigger evals and behavioral evals
(planned as a follow-on). Don't reintroduce phrase-matching here — it is the
brittleness this rewrite removed. If you want to assert a semantic behavior,
add it as a trigger eval or an LLM-rubric check, not a regex on skill prose.

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


CDD_DISPLAY_NAMES = {
    "cdd-boot": "[CDD-0] Boot",
    "cdd-init-project": "[CDD-1] Init Project",
    "cdd-plan": "[CDD-2] Plan",
    "cdd-implement-todo": "[CDD-3] Implement TODO",
    "cdd-audit": "[CDD-4] Audit",
    "cdd-maintain": "[CDD-5] Maintain",
}
MASTER_CHEF_DISPLAY_NAME = "[CDD-6] Master Chef"

MASTER_CHEF_FILES = (
    "SKILL.md",
    "agents/openai.yaml",
    "README.md",
    "CONTRACT.md",
    "RUNBOOK.md",
    "RUNTIME-CAPABILITIES.md",
    "CODEX-ADAPTER.md",
    "CODEX-RUNBOOK.md",
    "CODEX-TEST-HARNESS.md",
    "CLAUDE-ADAPTER.md",
    "CLAUDE-RUNBOOK.md",
    "CLAUDE-TEST-HARNESS.md",
    "openclaw/README.md",
    "openclaw/MASTER-CHEF-RUNBOOK.md",
    "openclaw/MASTER-CHEF-TEST-HARNESS.md",
)

# Required H2 section headings per skill. Section presence is a structural
# contract; the prose inside each section is intentionally not validated.
# When you add or rename a section in a skill, update the matching tuple here.
REQUIRED_SECTIONS: dict[str, tuple[str, ...]] = {
    "cdd-boot": (
        "## Required contract",
        "## Preferred inputs",
        "## Graceful fallback rules",
        "## Follow-up contract",
        "## Worktree check",
        "## Output",
    ),
    "cdd-init-project": (
        "## Canonical contract",
        "## High-impact action guardrails",
        "## Canonical bootstrap source",
        "## Required README CDD footnote footer",
        "## Contract-surface taxonomy and drift rules",
        "## Intent and assumption checkpoint",
        "## Open decisions queue",
        "## Interactive planning contract",
        "## State detection",
    ),
    "cdd-plan": (
        "## Runnable TODO step contract",
        "## Audit-input normalization",
        "## Edge-case review",
        "## Intent and assumption checkpoint",
        "## Open decisions queue",
        "## Interactive planning contract",
        "## Question economy",
        "## Planning anti-patterns",
        "## Flow",
    ),
    "cdd-implement-todo": (),
    "cdd-audit": (
        "## Sources of truth",
        "## Scope resolution",
        "## Step-scoped TODO contract audit",
        "## Audit dimensions",
        "## Finding normalization",
        "## Interaction contract",
        "## Flow",
        "## Guardrails",
    ),
    "cdd-maintain": (
        "## Shared routing read",
        "## Mode-scoped read discipline",
        "## Mode selection",
        "## Approval contract",
        "## Safe write behavior",
        "## Mode A",
        "## Mode B",
        "## Mode C",
        "## Mode D",
        "## INDEX freshness",
        "## Output",
    ),
}


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)
    assert match, f"missing YAML frontmatter in {path}"
    meta = match.group(1)
    assert not MULTILINE_VALUE_RE.search(meta), (
        f"unexpected multiline value in {path} frontmatter; values must be single-line"
    )
    return meta


def require_field(meta: str, pattern: str, path: Path, label: str) -> None:
    assert re.search(pattern, meta, re.M), f"missing {label} in {path}"


def require_section(text: str, heading: str, path: Path) -> None:
    """Assert an H2 starting with `heading` exists.

    Matches the heading exactly, or as a prefix followed by ` —`, ` (`, or end
    of line. Anchored to start of line so it cannot accidentally match inside
    prose or an H3.
    """
    pattern = r"^" + re.escape(heading) + r"(\s+—|\s+\(|\s*$)"
    assert re.search(pattern, text, re.M), (
        f"missing required section `{heading}` in {path}"
    )


def validate_skill(skill_dir: Path) -> None:
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
    expected_display_name = CDD_DISPLAY_NAMES.get(skill_dir.name)
    assert expected_display_name, f"missing display-name mapping for {skill_dir.name}"
    assert f'display_name: "{expected_display_name}"' in yaml_text, (
        f"unexpected display name in {openai_yaml}"
    )
    assert "allow_implicit_invocation: false" in yaml_text, (
        f"implicit invocation not disabled in {openai_yaml}"
    )

    for heading in REQUIRED_SECTIONS.get(skill_dir.name, ()):
        require_section(skill_text, heading, skill_md)


MASTER_CHEF_CONSOLIDATION_SATELLITES = (
    "SKILL.md",
    "RUNBOOK.md",
    "RUNTIME-CAPABILITIES.md",
    "CLAUDE-ADAPTER.md",
    "CLAUDE-RUNBOOK.md",
    "CODEX-ADAPTER.md",
    "CODEX-RUNBOOK.md",
    "openclaw/README.md",
    "openclaw/MASTER-CHEF-RUNBOOK.md",
)

MASTER_CHEF_CANONICAL_ANCHOR = (
    "<!-- canonical: Builder lifecycle policy "
    "(cadence, boot timeout, suspect classification, replacement) -->"
)

# Step 59 anchors. `CONTRACT.md §7` may appear with or without backticks around
# the filename; both forms are accepted as a pointer to the canonical surface.
MASTER_CHEF_POINTER_RE = re.compile(r"`?CONTRACT\.md`?\s*§7")

# Threshold-restatement detector: a sentence pairing one of the monitoring
# numbers with policy vocabulary. Run on sentence-segmented prose after
# stripping fenced code blocks, so JSON examples and shell snippets in
# satellite docs do not produce false positives.
MASTER_CHEF_THRESHOLD_SENTENCE_RE = re.compile(
    r"\b(5|10|20|30)\s*minutes?\b[^.\n]*"
    r"\b(cadence|boot|suspect|silence|replace|replacement|probe)\b",
    re.IGNORECASE,
)
MASTER_CHEF_LEGACY_LADDER_RE = re.compile(
    r"5\s*/\s*10\s*/\s*20[\w-]*\s*/\s*30[\w-]*\s*(?:monitoring\s+)?ladder",
    re.IGNORECASE,
)
MASTER_CHEF_PROBES_PHRASE_RE = re.compile(
    r"2\s+consecutive\s+unanswered\s+explicit\s+(?:status\s+)?probes",
    re.IGNORECASE,
)
MASTER_CHEF_TIMING_SUMMARY_RE = re.compile(
    r"(?mi)^\s*(?:#+\s*)?Builder timing summary\b"
)

MASTER_CHEF_FENCED_CODE_RE = re.compile(r"```.*?```", re.S)


def _check_master_chef_consolidation(package_root: Path) -> None:
    """Step 59: enforce single-canonical-surface Builder lifecycle policy.

    Asserts:
      - CONTRACT.md §7 carries the canonical-surface anchor comment.
      - Each of the nine satellite docs contains a `CONTRACT.md §7` pointer.
      - No satellite restates the 5/10/20/30-minute thresholds as policy.
      - No satellite restates the `5/10/20-soft/30-hard` legacy ladder shape.
      - No satellite restates `2 consecutive unanswered explicit probes`.
      - The OpenClaw runbook no longer carries a `Builder timing summary`
        heading or bullet group.
    """
    contract_path = package_root / "CONTRACT.md"
    contract_text = contract_path.read_text(encoding="utf-8")
    assert MASTER_CHEF_CANONICAL_ANCHOR in contract_text, (
        f"missing canonical Builder lifecycle anchor in {contract_path}"
    )

    for rel in MASTER_CHEF_CONSOLIDATION_SATELLITES:
        doc_path = package_root / rel
        text = doc_path.read_text(encoding="utf-8")
        assert MASTER_CHEF_POINTER_RE.search(text), (
            f"{doc_path} missing `CONTRACT.md §7` pointer for Builder lifecycle"
        )

        scan = MASTER_CHEF_FENCED_CODE_RE.sub("", text)
        threshold_hit = MASTER_CHEF_THRESHOLD_SENTENCE_RE.search(scan)
        assert threshold_hit is None, (
            f"{doc_path} restates Builder threshold "
            f"({threshold_hit.group(0)!r}); this lives in CONTRACT.md §7 only"
        )
        ladder_hit = MASTER_CHEF_LEGACY_LADDER_RE.search(scan)
        assert ladder_hit is None, (
            f"{doc_path} restates the 5/10/20-soft/30-hard monitoring ladder"
        )
        probes_hit = MASTER_CHEF_PROBES_PHRASE_RE.search(scan)
        assert probes_hit is None, (
            f"{doc_path} restates `2 consecutive unanswered explicit probes`"
        )

    openclaw_runbook = package_root / "openclaw" / "MASTER-CHEF-RUNBOOK.md"
    openclaw_text = openclaw_runbook.read_text(encoding="utf-8")
    timing_summary_hit = MASTER_CHEF_TIMING_SUMMARY_RE.search(openclaw_text)
    assert timing_summary_hit is None, (
        f"{openclaw_runbook} retains a `Builder timing summary` heading"
    )


def validate_master_chef(repo_root: Path) -> None:
    package_root = repo_root / "cdd-master-chef"
    assert package_root.exists(), f"missing {package_root}"
    for rel in MASTER_CHEF_FILES:
        assert (package_root / rel).exists(), f"missing {package_root / rel}"
    yaml_path = package_root / "agents" / "openai.yaml"
    yaml_text = yaml_path.read_text(encoding="utf-8")
    assert f'display_name: "{MASTER_CHEF_DISPLAY_NAME}"' in yaml_text, (
        f"unexpected display name in {yaml_path}"
    )
    assert "allow_implicit_invocation: true" in yaml_text, (
        f"master-chef should allow implicit invocation in {yaml_path}"
    )
    # Routing: master-chef SKILL.md must reference each installed core skill by
    # name so the routing model in the package stays in sync with the installed
    # cdd-* skill set.
    skill_text = (package_root / "SKILL.md").read_text(encoding="utf-8")
    for skill_name in CDD_DISPLAY_NAMES:
        assert skill_name in skill_text, (
            f"master-chef SKILL.md missing reference to {skill_name}"
        )
    _check_master_chef_consolidation(package_root)


def validate_generated_openclaw_builder_skills(repo_root: Path) -> None:
    """Validate the generated OpenClaw Builder variants built from skills/.

    Structural-only: name, description present, user-invocable flag, no
    disable-model-invocation flag (generated variants are model-visible), and
    the canonical wrapper line. No prose matching on the body.
    """
    generator = repo_root / "scripts" / "build_runtime_builder_skills.py"
    assert generator.exists(), f"missing {generator}"

    skills_root = repo_root / "skills"
    canonical_names = sorted(
        path.name for path in skills_root.iterdir() if path.is_dir()
    )
    assert canonical_names, f"no canonical Builder skills found in {skills_root}"

    with tempfile.TemporaryDirectory(prefix="cdd-openclaw-builder-") as tmp_dir:
        output_root = Path(tmp_dir) / "generated"
        subprocess.run(
            [
                sys.executable,
                str(generator),
                "--runtime",
                "openclaw",
                "--output",
                str(output_root),
            ],
            check=True,
            capture_output=True,
            text=True,
        )

        for skill_name in canonical_names:
            generated_dir = output_root / skill_name
            skill_md = generated_dir / "SKILL.md"
            assert skill_md.exists(), f"missing generated {skill_md}"
            meta = frontmatter(skill_md)
            require_field(
                meta,
                rf"^name:\s*{re.escape(skill_name)}\s*$",
                skill_md,
                "name",
            )
            require_field(meta, r"^description:\s*.+", skill_md, "description")
            require_field(
                meta,
                r"^user-invocable:\s*false\b",
                skill_md,
                "user-invocable: false",
            )
            assert "disable-model-invocation:" not in meta, (
                f"generated skill should be model-visible in {skill_md}"
            )
            skill_text = skill_md.read_text(encoding="utf-8")
            assert "Internal OpenClaw Builder variant" in skill_text, (
                f"canonical generated wrapper line missing in {skill_md}"
            )


def main(argv: list[str] | None = None) -> int:
    repo_root = Path(__file__).resolve().parent.parent
    skills_root = repo_root / "skills"
    assert skills_root.exists(), f"missing {skills_root}"
    skill_dirs = sorted(path for path in skills_root.iterdir() if path.is_dir())
    assert skill_dirs, f"no Builder skill directories found in {skills_root}"

    for skill_dir in skill_dirs:
        validate_skill(skill_dir)

    validate_master_chef(repo_root)
    validate_generated_openclaw_builder_skills(repo_root)

    print("skill structure checks passed (structural)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
