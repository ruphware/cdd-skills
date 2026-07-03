"""Structural validation for CDD skills and the shared master-chef contract.

This validator is intentionally narrow. It asserts:
  - file presence (skill SKILL.md and openai.yaml per skill; full master-chef
    contract file set; generated openclaw builder skills)
  - frontmatter shape (name regex, description present, leaf skills are
    model-invocable i.e. carry no disable-model-invocation flag, user-invocable
    flag for generated variants)
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


# The cdd-master-chef package lives under skills/ alongside the other cdd-*
# skills but is the user-facing orchestrator, not a Builder skill. The loops
# that produce or check Builder skills exclude this name. Bash scripts that
# need the same exclusion keep an inline literal cross-referenced to this
# constant.
ORCHESTRATOR_SKILL_NAME = "cdd-master-chef"


CDD_DISPLAY_NAMES = {
    "cdd-boot": "[CDD-0] Boot",
    "cdd-init-project": "[CDD-1] Init Project",
    "cdd-plan": "[CDD-2] Plan",
    "cdd-implement": "[CDD-3] Implement",
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
        "## Default boot set",
        "## Deepening triggers",
        "## Graceful fallback rules",
        "## External source handling",
        "## Boot intent routing",
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
        "## External source handling",
        "## Runnable TODO step contract",
        "## Audit-input normalization",
        "## Clarification floor and architecture options",
        "## Edge-case review",
        "## Intent and assumption checkpoint",
        "## Open decisions queue",
        "## Interactive planning contract",
        "## Question economy",
        "## Planning anti-patterns",
        "## Flow",
    ),
    "cdd-implement": (
        "## Supported task sources",
        "## Task normalization and escalation",
        "## Interaction contract",
        "## Completion semantics",
        "## Flow",
    ),
    "cdd-audit": (
        "## Sources of truth",
        "## External source handling",
        "## Audit framing",
        "## Scope resolution",
        "## Audit shapes",
        "## Step-scoped TODO contract audit",
        "## Enhancement-proposal audit",
        "## Review depth and proportionality",
        "## As-built model",
        "## Core audit dimensions",
        "## Optional lenses",
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
    # Leaf skills are model-invocable so audit->plan->implement handoffs work on
    # Claude (where disable-model-invocation is a hard tool-level block, unlike
    # Codex). Asserting absence locks the ungated state in. The Codex surface
    # (openai.yaml allow_implicit_invocation: false, checked below) is unchanged.
    assert "disable-model-invocation:" not in meta, (
        f"leaf skill should be model-invocable (no disable-model-invocation) in {skill_md}"
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

# Each forbidden pattern is detected after stripping fenced code blocks so JSON
# examples and shell snippets in satellite docs do not produce false positives.
# The threshold detector pairs `(5|10|20|30) minutes?` with policy vocabulary
# inside one sentence (no period crossed).
MASTER_CHEF_FENCED_CODE_RE = re.compile(r"```.*?```", re.S)
MASTER_CHEF_FORBIDDEN_PATTERNS = (
    (
        re.compile(
            r"\b(5|10|20|30)\s*minutes?\b[^.\n]*"
            r"\b(cadence|boot|suspect|silence|replace|replacement|probe)\b",
            re.IGNORECASE,
        ),
        "restates Builder threshold (this lives in CONTRACT.md §7 only)",
    ),
    (
        re.compile(
            r"5\s*/\s*10\s*/\s*20[\w-]*\s*/\s*30[\w-]*\s*(?:monitoring\s+)?ladder",
            re.IGNORECASE,
        ),
        "restates the 5/10/20-soft/30-hard monitoring ladder",
    ),
    (
        re.compile(
            r"2\s+consecutive\s+unanswered\s+explicit\s+(?:status\s+)?probes",
            re.IGNORECASE,
        ),
        "restates `2 consecutive unanswered explicit probes`",
    ),
)
MASTER_CHEF_TIMING_SUMMARY_RE = re.compile(
    r"(?mi)^\s*(?:#+\s*)?Builder timing summary\b"
)


def _check_master_chef_consolidation(package_root: Path) -> None:
    """Step 59: enforce single-canonical-surface Builder lifecycle policy.

    Asserts: CONTRACT.md §7 carries the canonical-surface anchor; each
    satellite contains a `CONTRACT.md §7` pointer; no satellite restates the
    5/10/20/30-minute thresholds, the `5/10/20-soft/30-hard` legacy ladder, or
    `2 consecutive unanswered explicit probes`; the OpenClaw runbook no
    longer carries a `Builder timing summary` heading or bullet group.
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
        for pattern, label in MASTER_CHEF_FORBIDDEN_PATTERNS:
            hit = pattern.search(scan)
            assert hit is None, f"{doc_path} {label}: {hit.group(0)!r}"

    openclaw_runbook = package_root / "openclaw" / "MASTER-CHEF-RUNBOOK.md"
    openclaw_text = openclaw_runbook.read_text(encoding="utf-8")
    assert MASTER_CHEF_TIMING_SUMMARY_RE.search(openclaw_text) is None, (
        f"{openclaw_runbook} retains a `Builder timing summary` heading"
    )


MASTER_CHEF_INVESTIGATION_SUBSECTION = "### Builder-stop investigation"
MASTER_CHEF_CLEAR_STOP_PHRASE = "clear stop signal"
MASTER_CHEF_STOP_CLASSIFICATIONS = (
    "missing_requirements",
    "solvable_blocker",
    "route_drift",
    "unrecoverable",
    "pending",
)
MASTER_CHEF_STOP_EVENTS = (
    "BUILDER_STOPPED",
    "BUILDER_INVESTIGATION_RESOLVED",
    "BUILDER_INVESTIGATION_ESCALATED",
)
MASTER_CHEF_STOP_FIELDS = (
    "builder_stop_reason",
    "builder_stop_classification",
    "builder_stop_evidence_summary",
)

# Step 60 negative anchors. The 30-minute total-silence and 2-probe replacement
# triggers must not return as replacement rules. Match each forbidden phrase
# only when it co-occurs with `replace` / `replacement` in the same sentence so
# legitimate non-replacement narrative (boot timeouts, observation cadence) is
# not false-flagged.
MASTER_CHEF_FORBIDDEN_REPLACEMENT_PHRASES = (
    "30 minutes of total running silence",
    "2 consecutive unanswered explicit status probes",
    "2 consecutive unanswered explicit probes",
)

# Locate the body of `## N) Title` sections so we can require the
# investigation-stage anchors land in the right place rather than just
# somewhere in CONTRACT.md.
_CONTRACT_SECTION_RE = re.compile(r"^##\s+(\d+)\)\s.*?$", re.MULTILINE)


def _extract_contract_section(text: str, section_number: int) -> str:
    matches = list(_CONTRACT_SECTION_RE.finditer(text))
    for idx, match in enumerate(matches):
        if int(match.group(1)) != section_number:
            continue
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        return text[start:end]
    raise AssertionError(
        f"CONTRACT.md missing `## {section_number})` section heading"
    )


def _check_master_chef_clear_stop_policy(package_root: Path) -> None:
    """Step 60: enforce clear-stop-signal replacement policy and the
    Builder-stop investigation stage.

    Asserts:
      - CONTRACT.md §7 contains the literal phrase `clear stop signal`, the
        `### Builder-stop investigation` subsection heading, and all four
        classification names.
      - CONTRACT.md §9 lists all three Builder-stop JSONL event names.
      - CONTRACT.md §3 lists all three Builder-stop runtime-state field names.
      - Neither `30 minutes of total running silence` nor
        `2 consecutive unanswered explicit (status )?probes` appears in a
        sentence that also contains `replace` or `replacement`.
    """
    contract_path = package_root / "CONTRACT.md"
    contract_text = contract_path.read_text(encoding="utf-8")

    section_3 = _extract_contract_section(contract_text, 3)
    section_7 = _extract_contract_section(contract_text, 7)
    section_9 = _extract_contract_section(contract_text, 9)

    assert MASTER_CHEF_CLEAR_STOP_PHRASE in section_7, (
        f"CONTRACT.md §7 missing literal phrase '{MASTER_CHEF_CLEAR_STOP_PHRASE}'"
    )
    assert MASTER_CHEF_INVESTIGATION_SUBSECTION in section_7, (
        f"CONTRACT.md §7 missing '{MASTER_CHEF_INVESTIGATION_SUBSECTION}' subsection heading"
    )
    for name in MASTER_CHEF_STOP_CLASSIFICATIONS:
        assert name in section_7, (
            f"CONTRACT.md §7 missing Builder-stop classification `{name}`"
        )
    for event in MASTER_CHEF_STOP_EVENTS:
        assert event in section_9, (
            f"CONTRACT.md §9 missing Builder-stop JSONL event `{event}`"
        )
    for field in MASTER_CHEF_STOP_FIELDS:
        assert field in section_3, (
            f"CONTRACT.md §3 missing Builder-stop runtime-state field `{field}`"
        )

    # Sentence-segment the contract (strip fenced code blocks first) so the
    # forbidden replacement-trigger phrases only fail when they co-occur with
    # `replace` / `replacement` in the same sentence.
    scan = MASTER_CHEF_FENCED_CODE_RE.sub("", contract_text)
    for sentence in re.split(r"(?<=[.\n])\s+", scan):
        lowered = sentence.lower()
        if "replace" not in lowered and "replacement" not in lowered:
            continue
        for forbidden in MASTER_CHEF_FORBIDDEN_REPLACEMENT_PHRASES:
            assert forbidden.lower() not in lowered, (
                f"CONTRACT.md reintroduces silence-based replacement trigger "
                f"({forbidden!r}); replacement requires a clear stop signal"
            )


def validate_master_chef(repo_root: Path) -> None:
    package_root = repo_root / "skills" / "cdd-master-chef"
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
    _check_master_chef_clear_stop_policy(package_root)


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
        path.name
        for path in skills_root.iterdir()
        if path.is_dir() and path.name != ORCHESTRATOR_SKILL_NAME
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
    skill_dirs = sorted(
        path
        for path in skills_root.iterdir()
        if path.is_dir() and path.name != ORCHESTRATOR_SKILL_NAME
    )
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
