"""Validate CDD skill, generator, and contract structure for this repo.

Example:
  python3 scripts/validate_skills.py

Validation layers:
  - Structural checks: default. Frontmatter, required files, generated artifact
    shape, markdown headings, installer/runtime file references.
  - Generated-artifact checks: default. Runtime Builder generation and package
    layout invariants.
  - Legacy prose checks: opt-in with ``--include-legacy-prose``. These add
    extra topic-coverage checks for canonical skill bodies, but they are not
    the primary contract gate.
"""

from __future__ import annotations

import argparse
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
    "cdd-implementation-audit": "[CDD-4] Implementation Audit",
    "cdd-maintain": "[CDD-5] Maintain",
}
CDD_CORE_LABELS = tuple(CDD_DISPLAY_NAMES.values())
MASTER_CHEF_LABEL = "[CDD-6] Master Chef"
OPENCLAW_ROUTING_LABELS = (
    "[CDD-0] Boot",
    "[CDD-1] Init Project",
    "[CDD-2] Plan",
    "[CDD-3] Implement TODO",
    "[CDD-4] Implementation Audit",
    "[CDD-5] Maintain",
)
MASTER_CHEF_RUN_CONFIG_OPTION_REGEXES = (
    r"`A\.\s*use this Run config`",
    r"`B\.\s*edit this Run config`",
    r"`C\.\s*stop before kickoff`",
)
MASTER_CHEF_KICKOFF_OPTION_STRINGS = (
    "`A. approve kickoff and start the autonomous run now`",
    "`B. approve kickoff but do not spawn Builder yet`",
    "`C. revise the next action, Run config, or step budget before kickoff`",
)
MASTER_CHEF_KICKOFF_OPTION_REGEXES = (
    r"`A\.\s*approve kickoff and start the autonomous run now`",
    r"`B\.\s*approve kickoff but do not spawn Builder yet`",
    r"`C\.\s*revise the next action, Run config, or step budget before kickoff`",
)
MASTER_CHEF_KICKOFF_HARNESS_SUMMARY = (
    "Kickoff approval used selector-based options and asked for a run step budget plus whether to spawn Builder now."
)
MASTER_CHEF_KICKOFF_HARNESS_REGEXES = (
    r"selector-based options rather than a free-form approval question",
    r"replying with just `A`, `B`, or `C` would be enough",
)


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


def require_substrings(
    text: str, patterns: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that every expected token exists in the given text."""
    missing = [pattern for pattern in patterns if pattern not in text]
    assert not missing, f"missing {label} in {path}: {', '.join(missing)}"


def require_regexes(
    text: str, patterns: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that every expected regex matches somewhere in the given text."""
    missing = [pattern for pattern in patterns if not re.search(pattern, text, re.M | re.S)]
    assert not missing, f"missing {label} in {path}: {', '.join(missing)}"


def require_topic_bundle(
    text: str, patterns: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that a document still covers a topic bundle without exact prose."""
    require_regexes(text, patterns, path, label)


def forbid_substrings(
    text: str, patterns: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that none of the forbidden tokens exist in the given text."""
    present = [pattern for pattern in patterns if pattern in text]
    assert not present, f"unexpected {label} in {path}: {', '.join(present)}"


def require_headings(
    text: str, headings: tuple[str, ...], path: Path, label: str
) -> None:
    """Assert that the markdown text contains the required headings."""
    require_substrings(text, headings, path, label)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse CLI args for structural versus legacy validation modes."""
    parser = argparse.ArgumentParser(
        description=(
            "Validate repo-local CDD skills, generators, and Master Chef contract "
            "artifacts. Default mode is structural/generated only."
        )
    )
    parser.add_argument(
        "--include-legacy-prose",
        action="store_true",
        help=(
            "Also run extra topic-coverage checks for canonical skill bodies. "
            "These are retained for spot-checking, but are not the primary gate."
        ),
    )
    return parser.parse_args(argv)


def validate_coarse_step_planning(skill_text: str, skill_md: Path) -> None:
    """Assert planning skills decompose coarse work and track confirmed coverage."""
    require_topic_bundle(
        skill_text,
        (
            r"multi-surface.*ambiguous.*more than one TODO step",
            r"coarse (dependency-ordered step decomposition|root-cause work packages).*before detailed TODO drafting",
            r"refine one coarse (step|root-cause work package) at a time.*runnable TODO steps",
            r"Confirmed requirements coverage",
            r"confirmed.*excluded.*repo fit.*represented in the plan",
            r"carry forward confirmed requirements.*make sense for the repo",
            r"Do not over-compress the plan just to stay minimal",
        ),
        skill_md,
        "coarse planning topics",
    )


def validate_reviewed_contract_artifacts(skill_text: str, skill_md: Path) -> None:
    """Assert planning skills preserve reviewed artifacts in TODO-focused output."""
    require_topic_bundle(
        skill_text,
        (
            r"coarse (planning|root-cause planning) phase.*user-provided contract.*implementation-driving artifacts.*TODO\.md",
            r"mixed product.*implementation detail.*TODO\.md.*follow-up",
            r"Reviewed contract artifacts",
            r"copied as-is.*corrected.*expanded.*removed.*left intentionally unspecified",
            r"reason for each material change.*records where each artifact was written",
            r"Confirmed requirements coverage.*Reviewed contract artifacts.*before asking for approval",
            r"keep exact implementation-driving detail in `TODO\.md`.*follow-up.*spec/doc",
        ),
        skill_md,
        "reviewed artifact topics",
    )


def validate_plan_audit_mode_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the plan skill absorbs audit-input normalization cleanly."""
    require_topic_bundle(
        skill_text,
        (
            r"Ask clarifying questions one at a time",
            r"material assumptions.*confirm or correct",
            r"minor defaults.*proceed without blocking",
            r"change requests and audits|change requests and for audit findings|change requests and externally supplied audit findings|change requests or external audit findings",
            r"Do not convert raw audit bullets directly into TODO tasks",
            r"`spec_delta`.*`implementation_delta`.*`verification_delta`.*`defer`",
            r"user-visible symptom.*likely root cause.*affected boundary.*proof needed",
            r"Collapse duplicate symptoms.*root-cause work package",
            r"relevant docs.*README\.md.*docs/specs.*corresponding tests|corresponding tests.*README\.md.*docs/specs",
            r"Use this mode only when the request is multi-surface, ambiguous, audit-driven, or likely to produce more than one TODO step",
            r"write-location choice.*update an existing TODO file.*TODO-audit-<tag>\.md",
            r"After applying, suggest implementing the next step via `\$?cdd-implement-todo`\.",
        ),
        skill_md,
        "plan audit-mode topics",
    )
    assert "implement that step immediately" not in skill_text, (
        f"plan skill should not implement directly in {skill_md}"
    )


def validate_implementation_audit_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the implementation-audit skill keeps its audit-only contract."""
    require_topic_bundle(
        skill_text,
        (
            r"explicit implementation or codebase audits",
            r"findings plus approved follow-up, not code changes",
            r"Supported audit scopes:.*last commit.*uncommitted changes.*one TODO step.*multiple TODO steps.*one TODO file.*whole codebase",
            r"missing docs, specs, or tests as findings",
            r"`spec compliance`",
            r"`code quality`",
            r"`test quality`",
            r"`accidental complexity`",
            r"`documentation`",
            r"KISS.*YAGNI.*SRP|YAGNI.*KISS.*SRP|SRP.*KISS.*YAGNI",
            r"validate untrusted input early.*syntactic.*semantic",
            r"confidence over coverage",
            r"mostly integration",
            r"narrower unit tests.*fewer high-level tests|fewer high-level tests.*narrower unit tests",
            r"implementation details.*broad unrelated object equality.*mock choreography.*fragile snapshots|fragile snapshots.*mock choreography.*broad unrelated object equality.*implementation details",
            r"useless tests.*duplicate lower-level coverage|duplicate lower-level coverage.*useless tests",
            r"speculative abstraction.*wrapper indirection.*generic APIs with one concrete use.*parameterization without real consumers",
            r"compact and optimized for reading",
            r"Normalize each finding into a root-cause item",
            r"user-visible symptom",
            r"likely root cause",
            r"affected boundary",
            r"evidence or proof surface",
            r"Collapse duplicate symptoms|Collapse duplicate findings",
            r"Major findings.*one at a time|one at a time unless multiple findings clearly collapse into one root-cause decision",
            r"`A\.\s*Plan fix now in cdd-plan`",
            r"`B\.\s*Postpone or backlog`",
            r"`C\.\s*Accept current state`",
            r"`D\.\s*Reject finding or ask for more evidence`",
            r"Stay read-only during the audit",
            r"Do not patch code, docs, or TODO files",
            r"recommend `\$?cdd-plan`",
        ),
        skill_md,
        "implementation-audit topics",
    )
    assert "implement directly from this skill" not in skill_text, (
        f"implementation-audit skill should stay audit-only in {skill_md}"
    )


def validate_selector_labeled_options(skill_text: str, skill_md: Path) -> None:
    """Assert interactive planning skills require visible option selectors."""
    require_topic_bundle(
        skill_text,
        (
            r"visible selector.*label itself.*selectable key",
            r"[Dd]efault to letters:\s*`A\.`, `B\.`, `C\.`",
            r"[Uu]se numbers only when the surrounding context is already numeric",
            r"reply with just the selector",
        ),
        skill_md,
        "selector option topics",
    )


def validate_option_driven_approval(skill_text: str, skill_md: Path) -> None:
    """Assert approval decisions are made through selector options, not a second prompt."""
    require_topic_bundle(
        skill_text,
        (
            r"selected option itself is the approval",
            r"[Dd]o not append a separate free-form approval question after selector options",
        ),
        skill_md,
        "option-driven approval topics",
    )


def validate_plan_final_apply_options(skill_text: str, skill_md: Path) -> None:
    """Assert the plan skill uses one selector-driven final approval surface."""
    require_topic_bundle(
        skill_text,
        (
            r"AGENTS\.md.*`NEXT`.*otherwise.*`\*\*Options\*\*`",
            r"clear next execution step.*exactly three final options",
            r"`A\.\s*apply now and continue with the recommended next step`",
            r"`B\.\s*apply now only`",
            r"`C\.\s*keep the plan read-only and revise before applying`",
        ),
        skill_md,
        "plan final apply option topics",
    )
    assert "Approve and apply these changes?" not in skill_text, (
        f"plan skill should not add a second free-form approval prompt in {skill_md}"
    )


def validate_boot_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the boot skill keeps its graceful vanilla boot contract."""
    require_topic_bundle(
        skill_text,
        (
            r"If `AGENTS\.md` is missing.*stop.*not CDD-ready",
            r"Read `AGENTS\.md` first.*source of truth",
            r"Continue gracefully when `README\.md`, `docs/INDEX\.md`, `docs/specs/blueprint\.md`, or `docs/JOURNAL\.md` are missing",
            r"top of `docs/JOURNAL\.md`.*stable journal entrypoint",
            r"`docs/JOURNAL\.md`.*split-journal mode.*`docs/journal/JOURNAL-<area>\.md`.*`docs/journal/SUMMARY\.md`",
            r"split-journal mode is active.*cross-cutting notes.*older condensed context",
            r"top of `docs/JOURNAL\.md`.*do not ingest full history unless the user explicitly asks",
            r"repo is Git-backed.*main worktree or a linked worktree",
            r"current checkout is already a linked worktree.*recommend staying in that worktree",
            r"current checkout is the main worktree.*recommend moving feature development into a worktree",
            r"recommends moving feature development into a worktree.*`Next action`.*offer creating a worktree and continuing development there as one of the options",
            r"staying in the main folder is acceptable|Otherwise.*staying in the main folder is acceptable",
            r"Do not create, switch, remove, or clean worktrees during boot",
            r"`Worktree`.*stay in the main folder or move into a worktree",
            r"`Next action`.*worktree migration is recommended.*creating a worktree and continuing there one of them",
            r"Do not write or modify repo files",
            r"recommend continuing in vanilla AGENTS-driven mode",
        ),
        skill_md,
        "boot skill topics",
    )


def validate_implement_todo_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the implement-todo skill routes non-trivial journaling correctly."""
    require_topic_bundle(
        skill_text,
        (
            r"Resolve ambiguity and approval boundaries with selector-based options under a final `\*\*Options\*\*` section",
            r"`A\.\s*apply the minimal TODO patch and implement the step`",
            r"`B\.\s*apply the minimal TODO patch only`",
            r"`C\.\s*keep the step read-only and revise first`",
            r"multiple matches remain.*matching file or heading choices.*`\*\*Options\*\*`",
            r"matching journal file.*non-trivial.*AGENTS\.md",
            r"single-journal mode.*`docs/JOURNAL\.md`",
            r"selected step.*`TODO-<area>\.md`.*`docs/journal/JOURNAL-<area>\.md`.*default hot journal",
            r"split-journal mode.*`docs/journal/JOURNAL\.md`.*cross-cutting",
            r"Do not duplicate the same journal entry across multiple journal files",
        ),
        skill_md,
        "implement-todo journal topics",
    )
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." not in skill_text, (
        f"stale TODO-next journal rule should not appear in {skill_md}"
    )
    assert "Update `docs/JOURNAL.md` only when changes are non-trivial, per `AGENTS.md`." not in skill_text, (
        f"old root-journal-only rule should not appear in {skill_md}"
    )


def validate_maintain_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the maintain skill keeps its archive and doctoring contract."""
    require_topic_bundle(
        skill_text,
        (
            r"Mode selection",
            r"`A\. doc drift`.*`B\. codebase cleanup`.*`C\. index`.*`D\. refactor`.*`do all`",
            r"Allow selecting more than one option",
            r"`do all`.*fixed order `A -> B -> C -> D`",
            r"Keep the mode-specific write scope tight",
            r"Apply safe archive moves immediately",
            r"Ask before deleting stale adjacent `TODO\*\.md` files",
            r"In `index` mode, write only `docs/INDEX\.md`",
            r"In `codebase cleanup` mode, remove only clearly approved dead or obsolete code and artifacts",
            r"In `refactor` mode, do not rewrite implementation directly.*architecture audit.*refactor options.*recommendation to use `cdd-plan`",
            r"Retain the newest 3 step headings",
            r"oldest contiguous archiveable block near the top",
            r"Never archive a step from the middle or tail",
            r"Do not leapfrog an older incomplete or ambiguous step",
            r"same-day archive file.*append",
            r"non-contiguous active history",
            r"`docs/JOURNAL\.md`.*stable journal entrypoint",
            r"`docs/journal/JOURNAL\.md`.*`docs/journal/JOURNAL-<area>\.md`.*`docs/journal/SUMMARY\.md`.*`docs/journal/archive/`",
            r"repo-local `\.agents/skills/\*/SKILL\.md`.*workflow/governance drift surfaces",
            r"split-journal mode.*do not propose collapsing back to a single hot journal",
            r"Do not precreate split-journal files before split-journal mode is active",
            r"no clear archive or routing rule.*do not invent one",
            r"README\.md.*runbook entrypoint",
            r"README\.md.*low-visibility bottom footer",
            r"README\.md.*user-approved compaction",
            r"selected option itself is the approval",
            r"[Dd]o not append a separate free-form approval question after selector options",
            r"`A\.\s*apply now`.*`B\.\s*keep the report only`.*`C\.\s*revise scope first`",
            r"`docs/specs/prd\.md`.*product-manager view",
            r"`docs/specs/blueprint\.md`.*anchor technical spec",
            r"documentation approval using selector-based options",
            r"documentation approval separate from stale TODO deletion approval.*runtime-cleanup approval",
            r"Write only `docs/INDEX\.md` in this mode",
            r"selector-based apply options for the single-file `docs/INDEX\.md` update",
            r"[Ss]elf-grade.*0-12.*11\.5",
            r"refactor-candidate",
            r"repo-local `\.cdd-runtime/`.*`\.cdd-runtime/master-chef/`",
            r"Git-backed.*local worktree state.*`live`, `stale`, or `unclear`",
            r"currently linked worktrees.*current run state as `live`",
            r"abandoned managed worktree directories.*orphaned runtime logs.*`stale`",
            r"Do not silently delete `\.cdd-runtime/` content",
            r"runtime state is unclear.*report it as `unclear`",
            r"runtime-cleanup approval using selector-based options",
            r"runtime-cleanup approval separate from support-document approval.*stale TODO deletion approval",
            r"remove only `stale` repo-local runtime artifacts and managed worktrees",
            r"Never remove the current worktree.*current run state.*`live` linked worktree",
            r"confirmed_cleanup.*probable_cleanup.*unclear",
            r"Do not remove anything classified as `unclear`",
            r"Group approved removals into one cleanup patch.*selector-based options",
            r"[Rr]epo history.*not justification for stale support-doc content",
            r"Classify each support doc as `current`, `drifted`, `missing`, or `unclear`",
            r"Do not silently refresh `README\.md`.*`docs/prompts/PROMPT-INDEX\.md`.*`\.agents/skills/\*/SKILL\.md`",
            r"Refactor mode requires a fresh `docs/INDEX\.md`",
            r"If `docs/INDEX\.md` is missing, `stale`, or `very stale`.*add `C\. index`",
            r"TODO-refactor-<tag>\.md",
            r"Present 2-3 context-specific refactor options.*`A\.`, `B\.`, and `C\.` selectors",
            r"Each option should identify the target boundary.*intended design direction.*key benefits.*main risks.*validation evidence",
            r"Finish with an architecture audit report and recommend `cdd-plan`",
            r"Report the exact age in days",
            r"`Mode`",
            r"`Index update status`",
            r"`Codebase cleanup status`",
            r"`Cleanup approval needed`",
            r"`Refactor audit status`",
            r"`Refactor options proposed`",
            r"`Local runtime cleanup status`",
            r"`Runtime cleanup approval needed`",
        ),
        skill_md,
        "maintain skill topics",
    )
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." not in skill_text, (
        f"stale TODO-next backlog rule should not appear in {skill_md}"
    )


def validate_init_project_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the init skill keeps the canonical boilerplate source guardrails."""
    require_topic_bundle(
        skill_text,
        (
            r"https://github\.com/ruphware/cdd-boilerplate.*canonical bootstrap source",
            r"do not copy.*download.*clone.*materialize boilerplate.*separate explicit confirmation",
            r"local path to an existing `cdd-boilerplate` checkout.*fallback bootstrap source",
            r"README\.md.*footer block near the bottom.*runbook stays primary.*low-visibility",
            r"\[!\[CDD Project\]",
            r"\[!\[CDD Skills\]",
            r"This repo follows the \[`CDD Project`\].*\[`AGENTS\.md`\]",
            r"Start with .*cdd-boot.*cdd-implementation-audit.*cdd-plan.*cdd-implement-todo.*cdd-maintain.*doc drift.*codebase cleanup.*index refresh.*refactor architecture audit",
            r"existing-repo adoption.*explicit confirmation.*README\.md edit",
            r"Avoid duplicating the block if it or its badges already exist",
            r"source of truth for the CDD contract.*existing repo",
            r"migration.*separate explicit confirmation",
            r"methodology-stable contract surfaces.*preserve the CDD workflow language",
            r"Contract-surface taxonomy and drift rules",
            r"methodology-stable contract surfaces",
            r"optional scaled workflow surfaces",
            r"optional repo-local workflow surfaces",
            r"repo-specific contract surfaces",
            r"`AGENTS\.md`.*preserve the CDD methodology",
            r"`TODO\.md`.*preserve its header, Step 00, and Step template",
            r"`docs/JOURNAL\.md`.*stable journal entrypoint/index",
            r"`docs/journal/\*`.*only when split-journal mode is active",
            r"`docs/prompts/PROMPT-INDEX\.md`.*preserve its role",
            r"`\.agents/skills/\*/SKILL\.md`.*preserve repo-local project skills when present",
            r"`\.gitignore`: preserve existing repo-specific ignore rules and ensure repo-local `\.cdd-runtime/` is ignored",
            r"`README\.md`, `docs/specs/prd\.md`, and `docs/specs/blueprint\.md` are repo-specific outputs",
            r"Ignore non-substantive paths.*`\.cdd-runtime/`",
            r"Inventory existing docs.*repo-local `\.agents/skills/\*/SKILL\.md`",
            r"repo-specific planning to `TODO\.md`",
            r"preserve the boilerplate header, Step 00, and Step template",
            r"append repo-specific Step 01\+ work.*docs/INDEX\.md.*PROMPT-INDEX.*cdd-maintain.*`index` mode",
            r"`TODO\.md`, `docs/JOURNAL\.md`, and `docs/prompts/PROMPT-INDEX\.md`.*materialize from `https://github\.com/ruphware/cdd-boilerplate`",
            r"`\.agents/skills/\*/SKILL\.md`: when present.*do not import user-home skills",
            r"update `\.gitignore` if needed so repo-local `\.cdd-runtime/` is ignored without dropping existing ignore rules",
            r"AGENTS\.md.*`NEXT`.*otherwise.*`\*\*Options\*\*`",
            r"selected option itself is the approval",
            r"[Dd]o not append a separate free-form approval question after selector options",
            r"`A\.\s*apply now`.*`B\.\s*revise first`.*`C\.\s*stop read-only`",
        ),
        skill_md,
        "init-project topics",
    )
    assert "a Step 00-style “CDD adoption” step" not in skill_text, (
        f"old repo-specific Step 00 adoption wording should not appear in {skill_md}"
    )
    assert "Add an adoption plan to `TODO.md`:" not in skill_text, (
        f"old TODO adoption-plan wording should not appear in {skill_md}"
    )
    assert "ask for a local path to a `cdd-boilerplate` checkout (preferred)" not in skill_text, (
        f"local checkout should not be preferred in {skill_md}"
    )
    assert "bottom `## Footnote` section" not in skill_text, (
        f"old README footnote-section rule should not appear in {skill_md}"
    )
    assert (
        "For fresh/bootstrap repos, require this exact `README.md` block under the title and short project description, before the rest of the runbook content:"
        not in skill_text
    ), f"old README header placement rule should not appear in {skill_md}"
    assert "Approve and apply these changes?" not in skill_text, (
        f"init-project skill should not add a second free-form approval prompt in {skill_md}"
    )
    assert "Approve and apply this migration plan?" not in skill_text, (
        f"init-project migration flow should use selector options in {skill_md}"
    )


def validate_builder_skill(skill_dir: Path, include_legacy_prose: bool) -> None:
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
    expected_display_name = CDD_DISPLAY_NAMES.get(skill_dir.name)
    assert expected_display_name, f"missing display-name mapping for {skill_dir.name}"
    assert f'display_name: "{expected_display_name}"' in yaml_text, (
        f"unexpected display name in {openai_yaml}"
    )
    assert "allow_implicit_invocation: false" in yaml_text, (
        f"implicit invocation not disabled in {openai_yaml}"
    )

    if skill_dir.name in {
        "cdd-plan",
        "cdd-implementation-audit",
        "cdd-init-project",
        "cdd-maintain",
        "cdd-implement-todo",
    }:
        validate_selector_labeled_options(skill_text, skill_md)
    if skill_dir.name in {
        "cdd-plan",
        "cdd-init-project",
        "cdd-maintain",
        "cdd-implement-todo",
    }:
        validate_option_driven_approval(skill_text, skill_md)
    if skill_dir.name == "cdd-plan":
        validate_plan_final_apply_options(skill_text, skill_md)

    if include_legacy_prose:
        if skill_dir.name == "cdd-implement-todo":
            require_topic_bundle(
                skill_text,
                (
                    r"update only the selected step in the active `TODO\*\.md` file",
                    r"Do not add a new step-level `Status:` field",
                ),
                skill_md,
                "implement-todo legacy topics",
            )
            validate_implement_todo_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-boot":
            validate_boot_skill_text(skill_text, skill_md)
            require_regexes(
                yaml_text,
                (
                    r"worktree boot",
                    r"docs/JOURNAL\.md.*journal entrypoint.*split-journal files",
                    r"worktree status.*stay in the main folder or move into a worktree",
                    r"[Nn]ext action.*creat.*worktree.*continu.*there",
                ),
                openai_yaml,
                "boot YAML topics",
            )
        if skill_dir.name == "cdd-maintain":
            validate_maintain_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-init-project":
            validate_init_project_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-plan":
            validate_coarse_step_planning(skill_text, skill_md)
            validate_reviewed_contract_artifacts(skill_text, skill_md)
            validate_plan_audit_mode_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-implementation-audit":
            validate_implementation_audit_skill_text(skill_text, skill_md)


def validate_master_chef_shared_contract(repo_root: Path) -> None:
    """Validate shared Master Chef contract artifacts structurally."""
    shared_root = repo_root / "cdd-master-chef"
    readme_md = shared_root / "README.md"
    skill_md = shared_root / "SKILL.md"
    contract_md = shared_root / "CONTRACT.md"
    runbook_md = shared_root / "RUNBOOK.md"
    matrix_md = shared_root / "RUNTIME-CAPABILITIES.md"
    root_readme_md = repo_root / "README.md"
    gitignore_md = repo_root / ".gitignore"
    install_sh = repo_root / "scripts" / "install.sh"

    for path in (readme_md, skill_md, contract_md, runbook_md, matrix_md, root_readme_md, gitignore_md, install_sh):
        assert path.exists(), f"missing {path}"

    assert not (repo_root / "master-chef").exists(), "legacy top-level master-chef stub should be removed"
    assert not (repo_root / "openclaw").exists(), "legacy top-level openclaw stub should be removed"

    readme_text = readme_md.read_text(encoding="utf-8")
    skill_text = skill_md.read_text(encoding="utf-8")
    contract_text = contract_md.read_text(encoding="utf-8")
    runbook_text = runbook_md.read_text(encoding="utf-8")
    matrix_text = matrix_md.read_text(encoding="utf-8")
    root_readme_text = root_readme_md.read_text(encoding="utf-8")
    gitignore_text = gitignore_md.read_text(encoding="utf-8")
    install_text = install_sh.read_text(encoding="utf-8")

    require_substrings(
        readme_text,
        (
            MASTER_CHEF_LABEL,
            "`SKILL.md`",
            "`CONTRACT.md`",
            "`RUNBOOK.md`",
            "`RUNTIME-CAPABILITIES.md`",
            "`CODEX-ADAPTER.md`",
            "`CLAUDE-ADAPTER.md`",
            "`openclaw/`",
        ),
        readme_md,
        "shared contract index entries",
    )
    require_regexes(
        readme_text,
        (
            r"`skills/`.*canonical Builder workflow source.*`\[CDD-0\]`.*`\[CDD-5\]`.*`cdd-\*` skills",
            r"Current concrete adapters in this package:",
            r"OpenClaw.*packaged runtime adapter.*generated Builder install flow",
            r"Codex.*subagent-backed adapter docs",
            r"Claude Code.*subagent-backed adapter docs",
            r"No Hermes adapter ships in this package today\.",
        ),
        readme_md,
        "shared package adapter coverage",
    )
    forbid_substrings(
        readme_text,
        (
            "only packaged Master Chef runtime today",
            "very experimental",
            "docs-only surrogate",
        ),
        readme_md,
        "outdated shared package wording",
    )
    require_substrings(
        skill_text,
        (
            ".cdd-runtime/worktrees/<run-id>/",
            ".cdd-runtime/master-chef/",
        ),
        skill_md,
        "shared package worktree contract",
    )
    forbid_substrings(
        skill_text,
        (".cdd-runtime/master-chef/worktrees/<run-id>/",),
        skill_md,
        "old shared package worktree root",
    )
    require_substrings(
        gitignore_text,
        (".cdd-runtime/",),
        gitignore_md,
        "repo-local runtime ignore rule",
    )

    require_headings(
        contract_text,
        (
            "## 3) Durable runtime state",
            "## 6) Managed worktree lifecycle",
            "## 11) Runtime adapter obligations",
        ),
        contract_md,
        "shared contract headings",
    )
    require_substrings(
        contract_text,
        (
            ".cdd-runtime/master-chef/run.json",
            ".cdd-runtime/worktrees/<run-id>/",
            "The full Run config must be resolved and approved before kickoff.",
            "- the per-run step budget",
            "unfinished top-level TODO step-heading count",
            "oversized for one Builder run",
            "descriptive feature branch",
            "default/max run step budget",
            "`until_blocked_or_complete`",
            "`run_step_budget`",
            "`steps_completed_this_run`",
            "`builder_phase`",
            "`builder_spawn_requested_at_utc`",
            "`builder_ready_at_utc`",
            "`last_builder_direct_signal_at_utc`",
            "\"event\":\"BUILDER_READY\"",
            "\"tool_access\":\"ready|blocked|unknown\"",
            "\"mcp_access\":\"ready|blocked|unknown\"",
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
            "- `BUILDER_READY`",
            "- `builder_restart_count`",
            "- `current_blocker`",
            "- `STEP_PASS`",
            "- `RUN_COMPLETE`",
        ),
        contract_md,
        "shared contract runtime-state fields",
    )
    forbid_substrings(
        contract_text,
        (".cdd-runtime/master-chef/worktrees/<run-id>/",),
        contract_md,
        "old shared contract worktree root",
    )
    require_regexes(
        contract_text,
        (
            r"recommended candidate.*current session model and thinking",
            r"selector-based choices.*free-form approval question",
            r"selected option itself (?:is|count(?:s)? as) the approval",
            *MASTER_CHEF_RUN_CONFIG_OPTION_REGEXES,
            r"selected option itself (?:is|count(?:s)? as) the kickoff approval",
            *MASTER_CHEF_KICKOFF_OPTION_REGEXES,
            r"fresh run from a long-lived branch.*descriptive feature branch",
            r"unfinished top-level TODO step headings only.*nested checkboxes or sub-tasks",
            r"default/max run step budget.*all remaining steps",
            r"oversized for one Builder run.*split.*smaller decision-complete TODO steps",
            r"Builder monitoring.*live status.*partial output.*direct reasoning visibility",
            r"runtime cannot expose live Builder reasoning.*streaming partial output",
            r"two phases:.*boot/readiness.*quiet-work",
            r"spawn evidence only",
            r"Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>",
            r"timed-out wait.*no agent completed yet.*inconclusive",
            r"missing diff.*empty `builder\.jsonl`.*proof",
            r"boot window.*boot-status probe",
            r"(long-thinking|high-latency).*quiet-work window",
            r"10 minutes.*quiet-work window.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`",
            r"coherent Builder reply.*proof of life",
        ),
        contract_md,
        "shared contract monitoring topics",
    )

    require_headings(
        runbook_text,
        (
            "## 1) Managed worktree policy",
            "## 2) Runtime-state additions",
            "## 3) Continuation decision rule",
            "## 4) Active worktree behavior",
            "## 5) Cleanup",
        ),
        runbook_md,
        "shared runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            "<source-repo>/.cdd-runtime/worktrees/<run-id>/",
            "master-chef/<run-id>",
            "### Fresh-start feature branch suggestion",
            "unfinished top-level TODO step-heading count",
            "oversized for one Builder run",
            "default/max `run_step_budget`",
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
            "- `builder_phase`",
            "- `builder_spawn_requested_at_utc`",
            "- `builder_ready_at_utc`",
            "- `last_builder_direct_signal_at_utc`",
            "- `run_step_budget`",
            "- `steps_completed_this_run`",
            "`builder_phase` is `not_started`, `booting`, `running`, `blocked`, `completed`, `failed`, or `closed`",
            "`tool_access`",
            "`mcp_access`",
            "reply with just the selector",
        ),
        runbook_md,
        "shared runbook worktree fields",
    )
    forbid_substrings(
        runbook_text,
        (".cdd-runtime/master-chef/worktrees/<run-id>/",),
        runbook_md,
        "old shared runbook worktree root",
    )
    require_regexes(
        runbook_text,
        (
            r"fresh run.*long-lived branch.*descriptive feature branch",
            r"oversized for one Builder run.*split it first",
            r"unfinished top-level TODO step-heading count",
            r"default/max `run_step_budget`.*all remaining steps",
            r"does not expose live Builder reasoning.*do not pretend",
            r"Codex- or Claude-style adapters.*completion/failure.*progress replies.*closure/errors",
            r"two phases:.*boot/readiness.*quiet-work",
            r"returned Builder handle.*not enough to prove",
            r"Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>",
            r"timed-out wait.*no agent completed yet.*inconclusive",
            r"boot window.*2 minutes",
            r"(long-thinking|high-latency).*quiet-work window",
            r"10 minutes.*quiet-work window.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`",
            r"coherent discovery note.*proof of life",
        ),
        runbook_md,
        "shared runbook monitoring topics",
    )

    require_substrings(
        matrix_text,
        (
            "| OpenClaw |",
            "| Codex |",
            "| Claude Code |",
            ".codex/agents/*.toml",
            ".claude/agents/",
            "~/.claude/agents/",
            "`CODEX-ADAPTER.md`",
            "`CLAUDE-ADAPTER.md`",
        ),
        matrix_md,
        "runtime capability matrix entries",
    )

    require_substrings(
        root_readme_text,
        CDD_CORE_LABELS
        + (
            MASTER_CHEF_LABEL,
            "npx skills add https://github.com/ruphware/cdd-skills/",
            "./scripts/install.sh --all",
            "install-remote.sh",
            "uninstall-remote.sh",
            "cdd-master-chef/RUNBOOK.md",
            "cdd-master-chef/CODEX-ADAPTER.md",
            "cdd-master-chef/CLAUDE-ADAPTER.md",
            "cdd-master-chef/RUNTIME-CAPABILITIES.md",
            "./scripts/install.sh --runtime claude",
            "./scripts/install.sh --runtime openclaw",
        ),
        root_readme_md,
        "root README stable Master Chef references",
    )
    require_regexes(
        root_readme_text,
        (
            r"Use the core .*cdd-\*.*single coding agent",
            r"Use .*(cdd-master-chef|\[CDD-6\] Master Chef).*kickoff approval",
            r"For `\[CDD-6\] Master Chef`:",
            r"remaining unfinished top-level step-heading count.*default/max step budget",
            r"fresh run from a long-lived branch.*descriptive feature branch",
            r"split an oversized top-level step before (?:Builder handoff|delegation)",
            r"start `(?:\$|/)?cdd-master-chef`.*main session.*runtime you want to control",
            r"Run config block.*current session model.*thinking.*approve or edit",
            r"how many TODO steps this run should cover",
            r"whether (?:Master Chef|it) should spawn Builder now",
            r"No-clone upgrade path:",
            r"managed prune semantics",
            r"Adapter docs.*maintainers.*debugging.*runtime support",
            r"Current concrete adapters in this repo:",
            r"OpenClaw.*packaged adapter.*install\.sh --runtime openclaw",
            r"Codex.*CODEX-ADAPTER\.md.*CODEX-RUNBOOK\.md",
            r"Claude Code.*CLAUDE-ADAPTER\.md.*CLAUDE-RUNBOOK\.md",
            r"No Hermes adapter ships in this repo today\.",
        ),
        root_readme_md,
        "root README topic coverage",
    )
    forbid_substrings(
        root_readme_text,
        (
            "wrong `npx skills add` entrypoint",
            "docs-only surrogate",
            "very experimental",
            "the current OpenClaw adapter fits your runtime",
            "only packaged Master Chef runtime",
            "For current Codex or Claude Code `[CDD-6] Master Chef` adapter work:",
            "treat those as the current subagent-backed adapter paths in development",
        ),
        root_readme_md,
        "outdated root README drift",
    )
    require_substrings(
        install_text,
        (
            'MASTER_CHEF_SRC_ROOT="$ROOT_DIR/cdd-master-chef"',
            'OPENCLAW_SRC_ROOT="$MASTER_CHEF_SRC_ROOT/openclaw"',
            'SOURCE_PACKAGES+=("$MASTER_CHEF_SRC_ROOT")',
            "--all           Install, update, or uninstall across every existing default runtime home",
            'echo "Skipping $runtime (missing runtime home: $runtime_home)" >&2',
            'echo "No existing runtime homes found under $HOME/.agents, $HOME/.claude, or $HOME/.openclaw." >&2',
            "Generated runtime Builder skills are still copied.",
        ),
        install_sh,
        "installer Master Chef taxonomy",
    )
    forbid_substrings(
        install_text,
        (
            'MASTER_CHEF_SRC_ROOT="$ROOT_DIR/master-chef"',
            "emit_generic_master_chef_package",
        ),
        install_sh,
        "legacy installer packaging",
    )


def validate_codex_adapter(repo_root: Path) -> None:
    """Validate the Codex adapter artifacts structurally."""
    adapter_md = repo_root / "cdd-master-chef" / "CODEX-ADAPTER.md"
    runbook_md = repo_root / "cdd-master-chef" / "CODEX-RUNBOOK.md"
    harness_md = repo_root / "cdd-master-chef" / "CODEX-TEST-HARNESS.md"

    for path in (adapter_md, runbook_md, harness_md):
        assert path.exists(), f"missing {path}"

    adapter_text = adapter_md.read_text(encoding="utf-8")
    runbook_text = runbook_md.read_text(encoding="utf-8")
    harness_text = harness_md.read_text(encoding="utf-8")

    require_headings(
        adapter_text,
        (
            "## 1) Delegation model",
            "## 2) Built-in vs custom agents",
            "## 4) Run config mapping",
            "## 6) Worktree handling",
            "## 7) Unsupported or blocked patterns",
        ),
        adapter_md,
        "Codex adapter headings",
    )
    require_substrings(
        adapter_text,
        (
            "`worker`",
            "`explorer`",
            ".codex/agents/*.toml",
            "Startup-only application",
        ),
        adapter_md,
        "Codex adapter runtime tokens",
    )
    require_regexes(
        adapter_text,
        (
            r"does not guarantee live access to Builder chain-of-thought|does not guarantee .*streaming partial output",
            r"Codex accepted the spawn request",
            r"readiness ACK",
            r"empty `builder\.jsonl`.*prove.*died",
            r"runtime-reported completion/failure.*status replies.*closure/error",
            r"inconclusive unless Codex also reports closure or failure",
            r"proof of life rather than proof of death",
        ),
        adapter_md,
        "Codex adapter monitoring topics",
    )

    require_headings(
        runbook_text,
        (
            "## 1) Session shape",
            "## 2) Builder selection",
            "## 3) Run config handling",
            "## 4) Kickoff approval and run budget",
            "## 6) Worktree hand-off",
            "## 7) Builder monitoring",
        ),
        runbook_md,
        "Codex runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            "`1` or `3`, or `until_blocked_or_complete`",
            "shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget",
            "oversized next top-level TODO step",
            "whether to spawn Builder now and start the autonomous run",
            "Do not treat \"here is a `codex -C ...` command for you to run\" as the normal Builder-start path.",
            ".codex/agents/*.toml",
            "`exact support`, `inherited-model fallback`, `startup-only application`, or `constrained behavior`",
            "Follow the shared selector contract.",
        )
        + MASTER_CHEF_KICKOFF_OPTION_STRINGS,
        runbook_md,
        "Codex runbook structural tokens",
    )
    require_regexes(
        runbook_text,
        (
            r"selector-driven kickoff approval",
            r"should not claim live access to Builder thinking.*streaming partial output",
            r"completion/failure notifications.*status replies.*closure/errors",
            r"two phases:.*boot/readiness.*quiet-work",
            r"spawn evidence only",
            r"`builder_phase: booting`.*runtime child-started signal.*readiness ACK.*`BUILDER_READY`",
            r"Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>",
            r"no agent has completed yet.*`running`.*`unknown`.*`dead`",
            r"inconclusive unless Codex also reports closure or failure",
            r"2 minutes.*boot-status probe",
            r"(long-thinking|high-latency).*quiet-work window",
            r"10 minutes.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`",
            r"coherent status or discovery reply.*proof of life",
        ),
        runbook_md,
        "Codex runbook monitoring topics",
    )

    require_substrings(
        harness_text,
        (
            "### Prompt C - Kickoff approval and run budget",
            "### Prompt F - Unsupported patterns",
            "### Prompt G - Worktree continuation",
            "### Prompt H - Long-thinking Builder monitoring",
            "### Prompt I - Builder boot readiness",
            "remaining top-level-step count is stated when finite",
            "feature-branch suggestion is surfaced when applicable",
            "oversized top-level step is split in Master Chef before Builder handoff",
            "exact remaining top-level-step count when that count is finite",
            MASTER_CHEF_KICKOFF_HARNESS_SUMMARY,
            "Recursive default fan-out was rejected.",
        ),
        harness_md,
        "Codex harness coverage",
    )
    require_regexes(
        harness_text,
        MASTER_CHEF_KICKOFF_HARNESS_REGEXES
        + (
            r"direct evidence instead of guessing",
            r"spawn evidence, not readiness proof",
            r"(long-thinking|high-latency).*quiet-work window|quiet-work window.*(long-thinking|high-latency)",
            r"10 minutes.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`.*`builder_ready_at_utc`",
            r"inconclusive unless Codex also reports closure or failure",
            r"proof of life.*step is not finished yet",
            r"`Hi\. You are Builder`",
            r"`READY`.*`BLOCKED: <reason>`",
            r"ACK or runtime-ready signal rather than only a spawn handle",
        ),
        harness_md,
        "Codex harness monitoring topics",
    )


def validate_claude_adapter(repo_root: Path) -> None:
    """Validate the Claude Code adapter artifacts structurally."""
    adapter_md = repo_root / "cdd-master-chef" / "CLAUDE-ADAPTER.md"
    runbook_md = repo_root / "cdd-master-chef" / "CLAUDE-RUNBOOK.md"
    harness_md = repo_root / "cdd-master-chef" / "CLAUDE-TEST-HARNESS.md"

    for path in (adapter_md, runbook_md, harness_md):
        assert path.exists(), f"missing {path}"

    adapter_text = adapter_md.read_text(encoding="utf-8")
    runbook_text = runbook_md.read_text(encoding="utf-8")
    harness_text = harness_md.read_text(encoding="utf-8")

    require_headings(
        adapter_text,
        (
            "## 1) Delegation model",
            "## 2) Agent surfaces",
            "## 3) Foreground vs background policy",
            "## 4) Non-nesting and tool inheritance",
            "## 5) Run config mapping",
            "## 6) Worktree handling",
        ),
        adapter_md,
        "Claude adapter headings",
    )
    require_substrings(
        adapter_text,
        (
            "--agents <json>",
            "--agent <name>",
            ".claude/agents/",
            "~/.claude/agents/",
            "Subagents cannot spawn other subagents.",
            "Startup-only application",
        ),
        adapter_md,
        "Claude adapter runtime tokens",
    )
    require_regexes(
        adapter_text,
        (
            r"does not guarantee live access to Builder chain-of-thought|does not guarantee .*streaming partial output",
            r"Claude accepted the spawn request",
            r"readiness ACK",
            r"empty `builder\.jsonl`.*prove.*died",
            r"runtime-reported completion/failure.*status replies.*closure/error",
            r"inconclusive unless Claude also reports closure or failure",
            r"proof of life rather than proof of death",
        ),
        adapter_md,
        "Claude adapter monitoring topics",
    )

    require_headings(
        runbook_text,
        (
            "## 1) Session shape",
            "## 2) Builder selection",
            "## 3) Run config handling",
            "## 4) Kickoff approval and run budget",
            "## 5) Foreground and background policy",
            "## 6) Tool and MCP policy",
            "## 7) Worktree hand-off",
            "## 8) Builder monitoring",
        ),
        runbook_md,
        "Claude runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            "--effort <master_thinking>",
            "`1` or `3`, or `until_blocked_or_complete`",
            "shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget",
            "oversized next top-level TODO step",
            "whether to spawn Builder now and start the autonomous run",
            "Do not treat \"here is a `claude --worktree ...` command for you to run\" as the normal Builder-start path.",
            "Subagents cannot spawn other subagents",
            "Do not rely on background Builder work for MCP-dependent or approval-heavy tasks.",
            "Treat `--worktree` as a startup-time or relaunch-time tool when the current Claude surface cannot continue safely in-session.",
            "Follow the shared selector contract.",
        )
        + MASTER_CHEF_KICKOFF_OPTION_STRINGS,
        runbook_md,
        "Claude runbook structural tokens",
    )
    require_regexes(
        runbook_text,
        (
            r"selector-driven kickoff approval",
            r"should not claim live access to Builder thinking.*streaming partial output",
            r"completion/failure notifications.*status replies.*closure/errors",
            r"two phases:.*boot/readiness.*quiet-work",
            r"spawn evidence only",
            r"`builder_phase: booting`.*runtime child-started signal.*readiness ACK.*`BUILDER_READY`",
            r"Builder <builder_session_key>.*run <run_id>.*step <active_step>.*worktree <active_worktree_path>.*READY.*BLOCKED: <reason>",
            r"quiet wait with no completion.*`running`.*`unknown`.*`dead`",
            r"inconclusive unless Claude also reports closure or failure",
            r"2 minutes.*boot-status probe",
            r"(long-thinking|high-latency).*quiet-work window",
            r"10 minutes.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`",
            r"coherent status or discovery reply.*proof of life",
        ),
        runbook_md,
        "Claude runbook monitoring topics",
    )

    require_substrings(
        harness_text,
        (
            "### Prompt C - Kickoff approval and run budget",
            "### Prompt F - Non-nesting rule",
            "### Prompt G - Worktree continuation",
            "### Prompt H - Long-thinking Builder monitoring",
            "### Prompt I - Builder boot readiness",
            "remaining top-level-step count is stated when finite",
            "feature-branch suggestion is surfaced when applicable",
            "oversized top-level step is split in Master Chef before Builder handoff",
            "exact remaining top-level-step count when that count is finite",
            MASTER_CHEF_KICKOFF_HARNESS_SUMMARY,
            "Permission-heavy Builder work stayed foreground.",
            "Nested subagent spawning was rejected.",
        ),
        harness_md,
        "Claude harness coverage",
    )
    require_regexes(
        harness_text,
        MASTER_CHEF_KICKOFF_HARNESS_REGEXES
        + (
            r"direct evidence instead of guessing",
            r"spawn evidence, not readiness proof",
            r"(long-thinking|high-latency).*quiet-work window|quiet-work window.*(long-thinking|high-latency)",
            r"10 minutes.*high-latency",
            r"quiet-work window.*`builder_phase`.*`running`.*`builder_ready_at_utc`",
            r"inconclusive unless Claude also reports closure or failure",
            r"proof of life.*step is not finished yet",
            r"`Hi\. You are Builder`",
            r"`READY`.*`BLOCKED: <reason>`",
            r"ACK or runtime-ready signal rather than only a spawn handle",
        ),
        harness_md,
        "Claude harness monitoring topics",
    )


def validate_openclaw_adapter(repo_root: Path) -> None:
    """Validate the OpenClaw adapter package structurally."""
    skill_md = repo_root / "cdd-master-chef" / "SKILL.md"
    openai_yaml = repo_root / "cdd-master-chef" / "agents" / "openai.yaml"
    assert skill_md.exists(), f"missing {skill_md}"
    assert openai_yaml.exists(), f"missing {openai_yaml}"
    skill_text = skill_md.read_text(encoding="utf-8")
    yaml_text = openai_yaml.read_text(encoding="utf-8")
    runbook_md = repo_root / "cdd-master-chef" / "openclaw" / "MASTER-CHEF-RUNBOOK.md"
    readme_md = repo_root / "cdd-master-chef" / "openclaw" / "README.md"
    harness_md = repo_root / "cdd-master-chef" / "openclaw" / "MASTER-CHEF-TEST-HARNESS.md"
    runbook_text = runbook_md.read_text(encoding="utf-8")
    readme_text = readme_md.read_text(encoding="utf-8")
    harness_text = harness_md.read_text(encoding="utf-8")
    meta = frontmatter(skill_md)
    require_field(meta, r"^name:\s*cdd-master-chef\s*$", skill_md, "name")
    require_field(meta, r"^description:\s*.+", skill_md, "description")
    require_field(meta, r"^user-invocable:\s*true\b", skill_md, "user-invocable: true")
    assert "disable-model-invocation:" not in meta, (
        f"cdd-master-chef should stay model-visible for implicit invocation in {skill_md}"
    )
    require_field(meta, r"^metadata:\s*\{.+\}\s*$", skill_md, "metadata")
    assert 'display_name: "[CDD-6] Master Chef"' in yaml_text, (
        f"unexpected display name in {openai_yaml}"
    )
    assert "allow_implicit_invocation: true" in yaml_text, (
        f"implicit invocation should stay enabled in {openai_yaml}"
    )
    require_headings(
        skill_text,
        (
            "# [CDD-6] Master Chef",
            "Canonical `run.json` fields:",
            "Report events:",
            "Reporting surface:",
        ),
        skill_md,
        "OpenClaw skill headings",
    )
    require_substrings(
        skill_text,
        (
            ".cdd-runtime/master-chef/run.json",
            "the approved run step budget",
            "unfinished top-level TODO step-heading count",
            "oversized for one Builder run",
            "descriptive feature branch",
            "whether to spawn Builder now and start the autonomous run",
            "`run_step_budget`",
            "`steps_completed_this_run`",
            "`builder_phase`",
            "`builder_spawn_requested_at_utc`",
            "`builder_ready_at_utc`",
            "`last_builder_direct_signal_at_utc`",
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
            "- `BUILDER_READY`",
            "- `STEP_PASS`",
            "- `DEADLOCK_STOPPED`",
        )
        + OPENCLAW_ROUTING_LABELS,
        skill_md,
        "OpenClaw skill runtime tokens",
    )
    require_regexes(
        skill_text,
        (
            r"current session model.*current session thinking.*recommend.*`Run config`",
            r"approves or edits it",
            r"selector-based options.*`A\.`, `B\.`, `C\.`",
            r"selected option itself should count as the approval",
            MASTER_CHEF_KICKOFF_OPTION_REGEXES[0],
            r"fresh run from a long-lived branch.*descriptive feature branch",
            r"oversized for one Builder run.*split.*smaller decision-complete TODO steps",
            r"default/max run step-budget recommendation",
            r"direct Builder status or progress surfaces",
            r"`builder_phase: booting`.*spawn request succeeds",
            r"Hi\. You are Builder <builder_session_key>.*READY.*BLOCKED: <reason>",
            r"preferred readiness ACK.*active worktree path.*active TODO step.*tool or MCP surfaces",
            r"does not expose live Builder thinking.*`running` or `unknown`.*rather than guessing",
            r"missing diff.*empty `builder\.jsonl`.*proof",
            r"(long-thinking|high-latency).*quiet-work window",
            r"10 minutes.*quiet-work window.*high-latency",
            r"coherent Builder reply.*proof of life rather than proof of death",
        ),
        skill_md,
        "OpenClaw skill monitoring topics",
    )

    require_headings(
        runbook_text,
        (
            "## 3) Kickoff flow",
            "### 3.1 Managed worktree kickoff",
            "### 4.4 `context-summary.md`",
            "## 8) Master Chef context compaction",
        ),
        runbook_md,
        "OpenClaw runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            MASTER_CHEF_LABEL,
            "~/.openclaw/skills/cdd-master-chef",
            "./scripts/install.sh --runtime openclaw",
            "The full Run config must be resolved and approved before kickoff.",
            "the approved run step budget",
            "unfinished top-level TODO step-heading count",
            "oversized for one Builder run",
            "shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget",
            "whether to spawn Builder now and start the autonomous run",
            "\"run_step_budget\": 1",
            "\"steps_completed_this_run\": 0",
            "worktree_continue_mode",
            "context-summary.md",
        )
        + OPENCLAW_ROUTING_LABELS,
        runbook_md,
        "OpenClaw runbook runtime tokens",
    )
    require_regexes(
        runbook_text,
        (
            r"recommend it from the current session model and thinking",
            r"shared selector contract",
            *MASTER_CHEF_RUN_CONFIG_OPTION_REGEXES,
            *MASTER_CHEF_KICKOFF_OPTION_REGEXES,
            r"oversized for one Builder run.*split.*smaller decision-complete TODO steps",
        ),
        runbook_md,
        "OpenClaw runbook config topics",
    )

    require_substrings(
        readme_text,
        (
            MASTER_CHEF_LABEL,
            "~/.openclaw/skills/cdd-master-chef",
            "./scripts/install.sh --runtime openclaw",
            "how many TODO steps this run should cover",
            "top-level TODO step-heading count",
            "descriptive feature branch",
            "oversized for one Builder run",
            "default/max step budget",
            "whether to spawn Builder now",
            ".cdd-runtime/master-chef/context-summary.md",
            "STEP_PASS",
        )
        + OPENCLAW_ROUTING_LABELS,
        readme_md,
        "OpenClaw README runtime references",
    )
    require_regexes(
        readme_text,
        (
            r"recommend a candidate Run config from the current session model and current session thinking",
            r"selector-based `A\.`, `B\.`, `C\.` options for approval or edits before kickoff",
            r"replying with just `A`, `B`, or `C` is enough",
            r"present selector-driven kickoff options before creating runtime state or spawning the Builder",
            r"split an oversized one first",
        ),
        readme_md,
        "OpenClaw README config topics",
    )

    require_substrings(
        harness_text,
        (
            MASTER_CHEF_LABEL,
            "Prompt A0 - Recommendation path",
            "Prompt A1 - Oversized-step split before Builder handoff",
            "Prompt B - Selector-driven kickoff approval",
            "Prompt J - QA reject remediation",
            "Prompt L - Blocked-step decomposition",
            "Prompt N - Context compaction and resume",
            "Dirty checkout refusal",
            "The run step budget is prepared as either a positive integer step count or `until_blocked_or_complete`.",
            "remaining unfinished top-level TODO step-heading count is stated when finite",
            "fresh-start feature-branch suggestion",
            "remaining top-level-step count is recomputed after the split",
            "exact remaining top-level-step count when that count is finite",
            "replying with just `A`, `B`, or `C` would be enough to approve, edit, or stop before kickoff",
        )
        + OPENCLAW_ROUTING_LABELS,
        harness_md,
        "OpenClaw harness coverage",
    )
    require_regexes(
        harness_text,
        (
            r"(selector-based|visible) `A\.`, `B\.`, `C\.` options for approval or edits before kickoff",
            r"pending selector-based approval or edits",
            r"replying with just `A`, `B`, or `C` would be enough",
            r"selector-driven kickoff options",
            r"selected option itself should count as the approval",
        ),
        harness_md,
        "OpenClaw harness selector topics",
    )


def validate_generated_openclaw_builder_skills(
    repo_root: Path, include_legacy_prose: bool
) -> None:
    """Validate the generated OpenClaw Builder variants built from skills/."""
    generator = repo_root / "scripts" / "build_runtime_builder_skills.py"
    assert generator.exists(), f"missing {generator}"

    skills_root = repo_root / "skills"
    canonical_names = sorted(path.name for path in skills_root.iterdir() if path.is_dir())
    assert canonical_names, f"no canonical Builder skills found in {skills_root}"

    with tempfile.TemporaryDirectory(prefix="cdd-openclaw-builder-") as tmp_dir:
        output_root = Path(tmp_dir) / "generated"
        subprocess.run(
            [sys.executable, str(generator), "--runtime", "openclaw", "--output", str(output_root)],
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
            require_regexes(
                skill_text,
                (
                    r"Internal OpenClaw Builder variant.*canonical `skills/` pack",
                    r"return that request to Master Chef",
                ),
                skill_md,
                "generated Builder wrapper topics",
            )
            if skill_name in {
                "cdd-plan",
                "cdd-implementation-audit",
                "cdd-init-project",
                "cdd-maintain",
                "cdd-implement-todo",
            }:
                validate_selector_labeled_options(skill_text, skill_md)
            if skill_name in {
                "cdd-plan",
                "cdd-init-project",
                "cdd-maintain",
                "cdd-implement-todo",
            }:
                validate_option_driven_approval(skill_text, skill_md)
            if skill_name == "cdd-plan":
                validate_plan_final_apply_options(skill_text, skill_md)

            if include_legacy_prose:
                if skill_name == "cdd-implement-todo":
                    require_topic_bundle(
                        skill_text,
                        (
                            r"update only the selected step in the active `TODO\*\.md` file",
                            r"Do not add a new step-level `Status:` field",
                        ),
                        skill_md,
                        "generated implement-todo legacy topics",
                    )
                    validate_implement_todo_skill_text(skill_text, skill_md)
                if skill_name == "cdd-boot":
                    validate_boot_skill_text(skill_text, skill_md)
                if skill_name == "cdd-maintain":
                    validate_maintain_skill_text(skill_text, skill_md)
                if skill_name == "cdd-init-project":
                    validate_init_project_skill_text(skill_text, skill_md)
                if skill_name == "cdd-plan":
                    validate_coarse_step_planning(skill_text, skill_md)
                    validate_reviewed_contract_artifacts(skill_text, skill_md)
                    validate_plan_audit_mode_skill_text(skill_text, skill_md)
                if skill_name == "cdd-implementation-audit":
                    validate_implementation_audit_skill_text(skill_text, skill_md)

def main(argv: list[str] | None = None) -> int:
    """Validate the current repository layout and print a success marker."""
    args = parse_args(argv)
    repo_root = Path(__file__).resolve().parent.parent
    skills_root = repo_root / "skills"
    assert skills_root.exists(), f"missing {skills_root}"

    skill_dirs = sorted(path for path in skills_root.iterdir() if path.is_dir())
    assert skill_dirs, f"no Builder skill directories found in {skills_root}"

    for skill_dir in skill_dirs:
        validate_builder_skill(skill_dir, args.include_legacy_prose)

    validate_generated_openclaw_builder_skills(repo_root, args.include_legacy_prose)
    validate_master_chef_shared_contract(repo_root)
    validate_codex_adapter(repo_root)
    validate_claude_adapter(repo_root)
    validate_openclaw_adapter(repo_root)
    if args.include_legacy_prose:
        print("skill structure checks passed (structural + legacy prose)")
    else:
        print("skill structure checks passed (structural)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
