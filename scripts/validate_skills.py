"""Validate CDD skill, generator, and contract structure for this repo.

Example:
  python3 scripts/validate_skills.py

Validation layers:
  - Structural checks: default. Frontmatter, required files, generated artifact
    shape, markdown headings, installer/runtime file references.
  - Generated-artifact checks: default. Runtime Builder generation and package
    layout invariants.
  - Legacy prose checks: opt-in with ``--include-legacy-prose``. These preserve
    older exact-sentence contract assertions for canonical skill bodies, but
    they are no longer the primary contract gate.
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
    "cdd-audit-and-implement": "[CDD-4] Audit + Implement",
    "cdd-refactor": "[CDD-5] Refactor",
    "cdd-index": "[CDD-6] Index",
    "cdd-maintain": "[CDD-7] Maintain",
}
CDD_CORE_LABELS = tuple(CDD_DISPLAY_NAMES.values())
MASTER_CHEF_LABEL = "[CDD-8] Master Chef"
OPENCLAW_ROUTING_LABELS = (
    "[CDD-0] Boot",
    "[CDD-1] Init Project",
    "[CDD-2] Plan",
    "[CDD-3] Implement TODO",
    "[CDD-4] Audit + Implement",
    "[CDD-5] Refactor",
    "[CDD-6] Index",
    "[CDD-7] Maintain",
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
            "Also run older exact-sentence contract assertions for canonical skill "
            "bodies. These are retained for spot-checking, but are not the primary "
            "gate."
        ),
    )
    return parser.parse_args(argv)


def validate_coarse_step_planning(skill_text: str, skill_md: Path) -> None:
    """Assert planning skills decompose coarse work and track confirmed coverage."""
    assert (
        "multi-surface, ambiguous, or likely to produce more than one TODO step"
    ) in skill_text, f"qualifying-request trigger missing in {skill_md}"
    require_any_substring(
        skill_text,
        (
            "first produce a coarse dependency-ordered step decomposition before detailed TODO drafting.",
            "first produce coarse dependency-ordered root-cause work packages before detailed TODO drafting.",
        ),
        skill_md,
        "coarse-step-first planning rule",
    )
    require_any_substring(
        skill_text,
        (
            "refine one coarse step at a time into runnable TODO steps",
            "refine one coarse root-cause work package at a time into runnable TODO steps",
        ),
        skill_md,
        "one-by-one coarse refinement rule",
    )
    assert "Confirmed requirements coverage" in skill_text, (
        f"confirmed requirements coverage section missing in {skill_md}"
    )
    assert (
        "which user requirements were confirmed, which were excluded by user decision "
        "or repo fit, and where each confirmed requirement is represented in the plan."
    ) in skill_text, f"confirmed requirements mapping rule missing in {skill_md}"
    assert (
        "Only carry forward confirmed requirements that make sense for the repo."
    ) in skill_text, f"repo-fit requirement filter missing in {skill_md}"
    assert (
        "Plans may be long and include many steps when the confirmed scope requires it. "
        "Do not over-compress the plan just to stay minimal."
    ) in skill_text, f"broad-plan allowance missing in {skill_md}"


def validate_reviewed_contract_artifacts(skill_text: str, skill_md: Path) -> None:
    """Assert planning skills preserve reviewed artifacts in TODO-focused output."""
    require_any_substring(
        skill_text,
        (
            "During the coarse planning phase, review any user-provided contract details, content details, and other implementation-driving artifacts, expand them into the plan, and keep exact implementation-driving detail in `TODO.md` rather than leaving it only in surrounding chat.",
            "During the coarse root-cause planning phase, review any user-provided contract details, content details, and other implementation-driving artifacts, expand them into the plan, and keep exact implementation-driving detail in `TODO.md` rather than leaving it only in surrounding chat.",
        ),
        skill_md,
        "coarse artifact-review rule",
    )
    assert (
        "If a reviewed artifact affects both product behavior and implementation detail, "
        "keep the exact implementation-driving detail in `TODO.md` and add explicit "
        "`TODO.md` follow-up for the relevant spec/doc update unless a durable spec "
        "delta is intentionally being drafted now."
    ) in skill_text, f"mixed-surface TODO placement rule missing in {skill_md}"
    assert "Reviewed contract artifacts" in skill_text, (
        f"reviewed contract artifacts section missing in {skill_md}"
    )
    assert (
        "identifies the user-provided artifacts, marks each as `copied as-is`, "
        "`corrected`, `expanded`, `removed`, or `left intentionally unspecified`, "
        "gives a short reason for each material change, and records where each "
        "artifact was written."
    ) in skill_text, f"reviewed artifact disposition rule missing in {skill_md}"
    assert (
        "Include visible `Confirmed requirements coverage` and `Reviewed contract artifacts` sections before asking for approval."
    ) in skill_text, f"pre-approval reviewed-artifacts rule missing in {skill_md}"
    require_any_substring(
        skill_text,
        (
            "keep exact implementation-driving detail in `TODO.md` and use explicit `TODO.md` follow-up for later spec/doc updates when mixed product/implementation artifacts are not becoming durable spec deltas now",
            "Keep exact implementation-driving detail in `TODO.md` and use explicit `TODO.md` follow-up for later spec/doc updates when mixed product/implementation artifacts are not becoming durable spec deltas now.",
        ),
        skill_md,
        "TODO follow-up drafting rule",
    )


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
    assert (
        "Keep the plan KISS and CDD-style: minimal diffs, no invented structure, and "
        "as many dependency-ordered steps as the confirmed scope requires."
    ) in skill_text, (
        f"KISS/CDD planning guardrail missing in {skill_md}"
    )
    require_any_substring(
        skill_text,
        (
            "Ask which of the newly created steps to implement first using guided options; recommend the first runnable new step by default.",
            "Ask which of the newly created steps to implement first using the same bottom-positioned guided options; recommend the first runnable new step by default.",
            "Ask which of the newly created steps to implement first using the same bottom-positioned, selector-prefixed guided options; recommend the first runnable new step by default.",
            "Ask which newly created step should be implemented now using the same bottom-positioned, selector-prefixed guided options; recommend the first runnable new step by default.",
        ),
        skill_md,
        "guided implementation-step selection",
    )
    assert (
        "The selected implementation option serves as the explicit approval to start that step immediately."
    ) in skill_text, f"combined implementation approval guidance missing in {skill_md}"
    assert "Include a clear stop-after-plan option." in skill_text, (
        f"stop-after-plan option guidance missing in {skill_md}"
    )
    assert (
        "If the user chooses the stop-after-plan option, stop and report the next recommended step."
    ) in skill_text, f"stop-after-plan handling missing in {skill_md}"
    require_any_substring(
        skill_text,
        (
            "If the user chooses a step, implement that step immediately using the same workflow as `$cdd-implement-todo`.",
            "If the user chooses a step, implement that step immediately using the same workflow as `cdd-implement-todo`.",
        ),
        skill_md,
        "immediate implementation handoff",
    )
    assert "Ask: **Approve starting implementation now?**" not in skill_text, (
        f"repetitive implementation confirmation should not appear in {skill_md}"
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
        "top of `docs/JOURNAL.md` as the stable journal entrypoint"
    ) in skill_text, f"journal entrypoint preferred input missing in {skill_md}"
    assert (
        "matching `docs/journal/JOURNAL-<area>.md` files and `docs/journal/SUMMARY.md` when `docs/JOURNAL.md` indicates split-journal mode"
    ) in skill_text, f"split-journal preferred inputs missing in {skill_md}"
    assert (
        "Use `docs/JOURNAL.md` to detect journal layout first. If it indicates split-journal mode, continue with the matching `docs/journal/JOURNAL-<area>.md` files and `docs/journal/SUMMARY.md` as needed."
    ) in skill_text, f"split-journal detection rule missing in {skill_md}"
    assert (
        "If split-journal mode is active but no matching area journal is clear, prefer `docs/journal/JOURNAL.md` for cross-cutting notes and `docs/journal/SUMMARY.md` for older condensed context before falling back to non-journal docs."
    ) in skill_text, f"split-journal fallback preference missing in {skill_md}"
    assert (
        "Use only the top of `docs/JOURNAL.md`, matching split-journal files, or development fallback files; do not ingest full history unless the user explicitly asks."
    ) in skill_text, f"top-of-journal guardrail missing in {skill_md}"
    assert (
        "Use docs/JOURNAL.md as the journal entrypoint and continue with matching split-journal files when it points to them."
    ) in skill_text, f"boot example prompt split-journal rule missing in {skill_md}"
    assert "Do not write or modify repo files." in skill_text, (
        f"read-only boot contract missing in {skill_md}"
    )
    assert "On success, recommend continuing in vanilla AGENTS-driven mode." in skill_text, (
        f"vanilla next-step guidance missing in {skill_md}"
    )


def validate_implement_todo_skill_text(skill_text: str, skill_md: Path) -> None:
    """Assert the implement-todo skill routes non-trivial journaling correctly."""
    assert "Update the matching journal file only when changes are non-trivial, per `AGENTS.md`." in skill_text, (
        f"matching-journal update rule missing in {skill_md}"
    )
    assert "In single-journal mode, update `docs/JOURNAL.md`." in skill_text, (
        f"single-journal update rule missing in {skill_md}"
    )
    assert "If the selected step is in `TODO-<area>.md`, treat matching `docs/journal/JOURNAL-<area>.md` as the default hot journal in split-journal mode." in skill_text, (
        f"area journal routing rule missing in {skill_md}"
    )
    assert "In split-journal mode, use `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes." in skill_text, (
        f"cross-cutting journal routing rule missing in {skill_md}"
    )
    assert "Do not duplicate the same journal entry across multiple journal files." in skill_text, (
        f"journal dedupe guardrail missing in {skill_md}"
    )
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." not in skill_text, (
        f"stale TODO-next journal rule should not appear in {skill_md}"
    )
    assert "Update `docs/JOURNAL.md` only when changes are non-trivial, per `AGENTS.md`." not in skill_text, (
        f"old root-journal-only rule should not appear in {skill_md}"
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
    assert "`docs/JOURNAL.md` as the stable journal entrypoint" in skill_text, (
        f"stable journal entrypoint source missing in {skill_md}"
    )
    assert "docs/journal/JOURNAL.md`, matching `docs/journal/JOURNAL-<area>.md` files, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when split-journal mode is active" in skill_text, (
        f"split-journal source coverage missing in {skill_md}"
    )
    assert "repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces" in skill_text, (
        f"repo-local skill source coverage missing in {skill_md}"
    )
    assert "Treat `docs/JOURNAL.md` as the stable journal entrypoint in all repos." in skill_text, (
        f"stable journal entrypoint rule missing in {skill_md}"
    )
    assert "In split-journal mode, expect the top of `docs/JOURNAL.md` to remain a short, clear current-state index/header for the active journal layout; if it no longer clearly routes readers to `docs/journal/*`, report it as drift." in skill_text, (
        f"post-split journal entrypoint quality rule missing in {skill_md}"
    )
    assert "If no active implementation `TODO-<area>.md` exists, treat the repo as single-journal mode and archive `docs/JOURNAL.md` only according to the rules defined there." in skill_text, (
        f"single-journal archive rule missing in {skill_md}"
    )
    assert "When any active implementation `TODO-<area>.md` exists, treat split-journal mode as active and keep it active; do not propose collapsing back to a single hot journal." in skill_text, (
        f"split-journal activation rule missing in {skill_md}"
    )
    assert "In split-journal mode, review `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes, matching `docs/journal/JOURNAL-<area>.md` files for active workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches when present." in skill_text, (
        f"split-journal review coverage missing in {skill_md}"
    )
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." not in skill_text, (
        f"stale TODO-next backlog rule should not appear in {skill_md}"
    )
    assert "Do not precreate split-journal files before split-journal mode is active." in skill_text, (
        f"split-journal precreation guardrail missing in {skill_md}"
    )
    assert "In split-journal mode, archive hot journals only according to the rules defined in the active journal files or entrypoint guidance, and route condensed/archive review through `docs/journal/SUMMARY.md` and `docs/journal/archive/` when present." in skill_text, (
        f"split-journal archive routing missing in {skill_md}"
    )
    assert "If the relevant journal entrypoint or active hot journal files have no clear archive or routing rule, do not invent one; skip journal archival for that unclear surface and report it." in skill_text, (
        f"journal unclear-surface skip rule missing in {skill_md}"
    )
    assert "Treat repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces tied to the repo's documented workflow." in skill_text, (
        f"repo-local skill drift-surface rule missing in {skill_md}"
    )
    assert "When repo-local `.agents/skills/*/SKILL.md` files are present, compare them against the current repo structure, documentation topology, `AGENTS.md`, and the current support-doc contract." in skill_text, (
        f"repo-local skill comparison rule missing in {skill_md}"
    )
    assert "Check whether setup/dev/test/build instructions, documented workflows, active features, future plans, architecture notes, referenced doc paths, doc-role boundaries, journal topology, and workflow-skill expectations still match the repo." in skill_text, (
        f"support-doc topology and workflow-skill review missing in {skill_md}"
    )
    assert "Classify each repo-local skill surface reviewed under `.agents/skills/*/SKILL.md` as `current`, `drifted`, `missing`, or `unclear` when that surface exists or is expected by the repo." in skill_text, (
        f"repo-local skill classification rule missing in {skill_md}"
    )
    assert "If repo-local `.agents/skills/*/SKILL.md` files drift from the current repo structure, documentation topology, or workflow contract, prepare the needed edits and show them to the user before applying anything." in skill_text, (
        f"repo-local skill drift prep rule missing in {skill_md}"
    )
    assert "Report repo-local skill-surface drift together with support-doc drift when present." in skill_text, (
        f"repo-local skill reporting rule missing in {skill_md}"
    )
    assert "connected `docs/specs/*-definition.md` files when present" in skill_text, (
        f"definition sources-of-truth scope missing in {skill_md}"
    )
    assert "Treat `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and connected `docs/specs/*-definition.md` files as canonical support docs." in skill_text, (
        f"support-doc scope missing in {skill_md}"
    )
    assert "Compare each support doc against the current repo state or clearly intended future-state contract using manifests, entrypoints, scripts, active TODO/JOURNAL context, and the other support docs." in skill_text, (
        f"support-doc current-or-future contract missing in {skill_md}"
    )
    assert "For `README.md`: keep it as the runbook entrypoint. It may include current features, use cases, and future plans, but it must not include historical project narration or CDD/TODO step progression." in skill_text, (
        f"README doc-role rule missing in {skill_md}"
    )
    assert "If `README.md` includes a CDD contract note, keep it as a low-visibility bottom footer, such as the repo-standard `___` + badges + `<sup>` footnote, rather than a top-of-file banner." in skill_text, (
        f"README CDD footer rule missing in {skill_md}"
    )
    assert "If `README.md` is long and substantially duplicates content already maintained in other support docs such as `TODO.md` or `docs/specs/*`, propose a user-approved compaction rather than silently condensing it." in skill_text, (
        f"README compaction approval rule missing in {skill_md}"
    )
    assert "For `docs/specs/prd.md`: treat it as the product-manager view; it may include product vision, use cases, JTBD, and feature lists." in skill_text, (
        f"PRD role rule missing in {skill_md}"
    )
    assert "For `docs/specs/blueprint.md` and connected `*-definition.md` files: treat `blueprint.md` as the anchor technical spec and use connected definition files for technical architecture, data structures, interfaces, technical reasoning, and implementation detail." in skill_text, (
        f"blueprint/definition role rule missing in {skill_md}"
    )
    assert "Do not treat repo history as justification for stale support-doc content; drift review is about current repo truth or clearly intended future-state docs." in skill_text, (
        f"support-doc anti-history rule missing in {skill_md}"
    )
    assert "Classify each support doc as `current`, `drifted`, `missing`, or `unclear`." in skill_text, (
        f"support-doc classification rule missing in {skill_md}"
    )
    assert "If `README.md`, `docs/specs/*`, or connected `*-definition.md` files have drifted, prepare the needed edits and show them to the user before applying anything." in skill_text, (
        f"support-doc drift prep rule missing in {skill_md}"
    )
    assert "Do not silently refresh `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, connected `*-definition.md` files, `docs/INDEX.md`, `docs/prompts/PROMPT-INDEX.md`, or repo-local `.agents/skills/*/SKILL.md` files." in skill_text, (
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
    assert (
        "For fresh/bootstrap repos, require this exact `README.md` footer block near the bottom of the file so the runbook stays primary and the CDD contract remains present but low-visibility:"
    ) in skill_text, f"README footer placement rule missing in {skill_md}"
    assert "bottom `## Footnote` section" not in skill_text, (
        f"old README footnote-section rule should not appear in {skill_md}"
    )
    assert (
        "For fresh/bootstrap repos, require this exact `README.md` block under the title and short project description, before the rest of the runbook content:"
        not in skill_text
    ), f"old README header placement rule should not appear in {skill_md}"
    assert "___" in skill_text, f"README footer separator missing in {skill_md}"
    assert (
        "[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)"
    ) in skill_text, f"CDD project badge rule missing in {skill_md}"
    assert (
        "[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)"
    ) in skill_text, f"CDD skills badge rule missing in {skill_md}"
    assert (
        "<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>"
    ) in skill_text, f"CDD workflow note missing in {skill_md}"
    require_any_substring(
        skill_text,
        (
            "<sup>Start with `$cdd-boot`. Use `$cdd-plan` + `$cdd-implement-todo` for feature work, `$cdd-maintain` for upkeep and drift control, and `$cdd-refactor` for structured refactors.</sup>",
            "<sup>Start with `cdd-boot`. Use `cdd-plan` + `cdd-implement-todo` for feature work, `cdd-maintain` for upkeep and drift control, and `cdd-refactor` for structured refactors.</sup>",
        ),
        skill_md,
        "CDD command note",
    )
    assert (
        "For existing-repo adoption, consider adding or moving that full CDD footnote footer near the bottom of the current `README.md`, but ask the user for explicit confirmation before proposing or applying that README edit."
    ) in skill_text, f"existing README footer confirmation rule missing in {skill_md}"
    assert "Avoid duplicating the block if it or its badges already exist." in skill_text, (
        f"README duplication guardrail missing in {skill_md}"
    )
    assert (
        "Use `https://github.com/ruphware/cdd-boilerplate` as the source of truth for the CDD contract when migrating an existing repo."
    ) in skill_text, f"existing repo migration source-of-truth rule missing in {skill_md}"
    assert (
        "If migration requires copying, downloading, cloning, or otherwise materializing contract files from that source, ask for separate explicit confirmation before doing so."
    ) in skill_text, f"existing repo migration approval gate missing in {skill_md}"
    assert (
        "If the user explicitly prefers a local checkout or network access is unavailable, you may use a local `cdd-boilerplate` checkout as the migration fallback source."
    ) in skill_text, f"existing repo migration fallback rule missing in {skill_md}"
    assert (
        "For methodology-stable contract surfaces, materialize from `cdd-boilerplate` and preserve the CDD workflow language under the drift rules below instead of freehand rewriting."
    ) in skill_text, f"methodology-stable contract preface missing in {skill_md}"
    assert (
        "- `docs/journal/JOURNAL.md`, `docs/journal/JOURNAL-<area>.md`, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when split-journal mode is active"
    ) in skill_text, f"split-journal canonical contract listing missing in {skill_md}"
    assert (
        "- repo-local `.agents/skills/*/SKILL.md` files when present as project workflow surfaces"
    ) in skill_text, f"repo-local skill canonical contract listing missing in {skill_md}"
    assert "## Contract-surface taxonomy and drift rules" in skill_text, (
        f"contract-surface taxonomy heading missing in {skill_md}"
    )
    assert (
        "- Treat these files as methodology-stable contract surfaces that should be materialized from `cdd-boilerplate` and kept aligned with its CDD workflow language:"
    ) in skill_text, f"stable contract taxonomy missing in {skill_md}"
    assert (
        "- Treat these optional scaled workflow surfaces as boilerplate-aligned only when the repo shape activates them:"
    ) in skill_text, f"scaled workflow taxonomy missing in {skill_md}"
    assert (
        "- Treat these optional repo-local workflow surfaces as project-level contract files to preserve when present:"
    ) in skill_text, f"repo-local workflow taxonomy missing in {skill_md}"
    assert (
        "- Treat these files as repo-specific contract surfaces that must be filled from the actual target repo rather than copied verbatim:"
    ) in skill_text, f"repo-specific contract taxonomy missing in {skill_md}"
    assert (
        "- `AGENTS.md`: start from the boilerplate `AGENTS.md` and preserve the CDD methodology, rule numbering, method structure, and output contract. Limited repo-fit edits are allowed only for project facts such as language, framework, repo layout, runbook entrypoints, or a short repo note; do not rewrite the methodology."
    ) in skill_text, f"bounded AGENTS drift rule missing in {skill_md}"
    assert (
        "- `TODO.md`: start from the boilerplate `TODO.md` and preserve its header, Step 00, and Step template. Add repo-specific work only as Step 01+ in root `TODO.md` or split `TODO-<area>.md` files; do not replace Step 00 with a repo-specific adoption format."
    ) in skill_text, f"TODO Step 00 preservation rule missing in {skill_md}"
    assert (
        "- `docs/JOURNAL.md`: start from the boilerplate journal and preserve its rules, entry format, compact header guidance, and transition-to-split mechanics. In unsplit repos it remains the live journal; once active implementation work branches into `TODO-<area>.md`, keep `docs/JOURNAL.md` as the stable journal entrypoint/index, rewrite it as a short current-state index after split activation, and keep it compact and high-signal. Repo-specific content belongs in entries and summaries only."
    ) in skill_text, f"JOURNAL preservation rule missing in {skill_md}"
    assert (
        "- `docs/journal/*`: create or preserve these only when split-journal mode is active. Keep `docs/journal/JOURNAL.md` for cross-cutting notes, `docs/journal/JOURNAL-<area>.md` for matching active `TODO-<area>.md` workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches. Do not precreate split-journal files before active `TODO-<area>.md` work exists, and keep split-journal mode once it starts."
    ) in skill_text, f"split-journal topology rule missing in {skill_md}"
    assert (
        "- `docs/prompts/PROMPT-INDEX.md`: start from the boilerplate prompt and preserve its role, analysis and generation workflow, quality bar, and template structure. Do not replace it with a repo-specific docs-index prompt."
    ) in skill_text, f"PROMPT-INDEX preservation rule missing in {skill_md}"
    assert (
        "- `.agents/skills/*/SKILL.md`: preserve repo-local project skills when present. Treat them as project-level workflow surfaces tied to the repo's documented process. Preserve them during bootstrap or adoption; do not require them when absent and do not pull user-home skills into the repo."
    ) in skill_text, f"repo-local skill preservation rule missing in {skill_md}"
    assert (
        "- `README.md`, `docs/specs/prd.md`, and `docs/specs/blueprint.md` are repo-specific outputs and should be written from the target repo's actual product, architecture, and runbook reality."
    ) in skill_text, f"repo-specific output boundary missing in {skill_md}"
    assert (
        skill_text.count(
            "if needed, add only bounded repo-detail edits to `AGENTS.md` under the drift rules above"
        )
        >= 3
    ), f"bounded AGENTS flow guidance missing in {skill_md}"
    assert (
        skill_text.count(
            "extend `TODO.md` with Step 01+ if needed, preserving the boilerplate header, Step 00, and Step template already in `TODO.md`"
        )
        >= 3
    ), f"TODO Step 00 flow preservation missing in {skill_md}"
    assert (
        skill_text.count(
            "keep `docs/JOURNAL.md` as the stable journal entrypoint/index, preserve split-journal topology only when active, keep post-split `docs/JOURNAL.md` as a short current-state index, keep `docs/prompts/PROMPT-INDEX.md` aligned with its boilerplate methodology scaffold, and preserve repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present"
        )
        >= 3
    ), f"JOURNAL/PROMPT-INDEX/local-skill flow preservation missing in {skill_md}"
    assert (
        "A repo-local `.agents/skills/` folder may also be present in fresh boilerplate state; treat it as compatible boilerplate workflow surface, not as evidence of existing-repo adoption."
    ) in skill_text, f"fresh-boilerplate local-skill compatibility note missing in {skill_md}"
    assert (
        "2) Inventory existing docs (e.g., `docs/`, `design/`, `adr/`, root markdown files) and repo-local `.agents/skills/*/SKILL.md` workflow surfaces when present."
    ) in skill_text, f"existing-repo audit local-skill inventory rule missing in {skill_md}"
    assert "Add repo-specific planning to `TODO.md`:" in skill_text, (
        f"existing-repo TODO planning rule missing in {skill_md}"
    )
    assert "- preserve the boilerplate header, Step 00, and Step template" in skill_text, (
        f"existing-repo TODO scaffold preservation missing in {skill_md}"
    )
    require_any_substring(
        skill_text,
        (
            "- append repo-specific Step 01+ work, including a step to generate or refresh `docs/INDEX.md` via `docs/prompts/PROMPT-INDEX.md` (or `$cdd-index`)",
            "- append repo-specific Step 01+ work, including a step to generate or refresh `docs/INDEX.md` via `docs/prompts/PROMPT-INDEX.md` (or `cdd-index`)",
        ),
        skill_md,
        "existing-repo Step 01+ append rule",
    )
    assert (
        "- `TODO.md`, `docs/JOURNAL.md`, and `docs/prompts/PROMPT-INDEX.md`: materialize from `https://github.com/ruphware/cdd-boilerplate` and preserve their methodology scaffolds, with `docs/JOURNAL.md` kept as the stable journal entrypoint/index, rewritten as a short current-state index after split activation, and split-journal `docs/journal/*` topology preserved only when active"
    ) in skill_text, f"existing-repo split-journal materialization rule missing in {skill_md}"
    assert (
        "- `.agents/skills/*/SKILL.md`: when present in the source or target repo, preserve them as repo-local workflow surfaces tied to the repo's documented process; do not require them when absent and do not import user-home skills"
    ) in skill_text, f"existing-repo repo-local skill preservation rule missing in {skill_md}"
    assert "a Step 00-style “CDD adoption” step" not in skill_text, (
        f"old repo-specific Step 00 adoption wording should not appear in {skill_md}"
    )
    assert "Add an adoption plan to `TODO.md`:" not in skill_text, (
        f"old TODO adoption-plan wording should not appear in {skill_md}"
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

    if include_legacy_prose:
        if skill_dir.name == "cdd-implement-todo":
            assert "update only the selected step in the active `TODO*.md` file" in skill_text, (
                f"TODO completion writeback missing in {skill_md}"
            )
            assert "Do not add a new step-level `Status:` field" in skill_text, (
                f"TODO completion guardrail missing in {skill_md}"
            )
            validate_implement_todo_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-boot":
            validate_boot_skill_text(skill_text, skill_md)
            assert "development (journal entrypoint + split journals) boot" in yaml_text, (
                f"boot prompt short description missing split-journal wording in {openai_yaml}"
            )
            assert "Use docs/JOURNAL.md as the journal entrypoint and continue with matching split-journal files when it points to them." in yaml_text, (
                f"boot default prompt missing split-journal wording in {openai_yaml}"
            )
        if skill_dir.name == "cdd-maintain":
            validate_maintain_skill_text(skill_text, skill_md)
        if skill_dir.name == "cdd-init-project":
            validate_init_project_skill_text(skill_text, skill_md)
        if skill_dir.name in {"cdd-plan", "cdd-audit-and-implement"}:
            validate_coarse_step_planning(skill_text, skill_md)
            validate_reviewed_contract_artifacts(skill_text, skill_md)
        if skill_dir.name == "cdd-audit-and-implement":
            validate_audit_and_implement_skill_text(skill_text, skill_md)
        if skill_dir.name in {
            "cdd-plan",
            "cdd-init-project",
            "cdd-refactor",
            "cdd-audit-and-implement",
        }:
            validate_selector_labeled_options(skill_text, skill_md)


def validate_master_chef_shared_contract(repo_root: Path) -> None:
    """Validate shared Master Chef contract artifacts structurally."""
    shared_root = repo_root / "cdd-master-chef"
    legacy_shared_root = repo_root / "master-chef"
    legacy_openclaw_root = repo_root / "openclaw"
    readme_md = shared_root / "README.md"
    contract_md = shared_root / "CONTRACT.md"
    runbook_md = shared_root / "RUNBOOK.md"
    matrix_md = shared_root / "RUNTIME-CAPABILITIES.md"
    root_readme_md = repo_root / "README.md"
    install_sh = repo_root / "scripts" / "install.sh"

    for path in (readme_md, contract_md, runbook_md, matrix_md, root_readme_md, install_sh):
        assert path.exists(), f"missing {path}"

    assert (shared_root / "SKILL.md").exists(), f"missing {shared_root / 'SKILL.md'}"
    assert legacy_shared_root.exists(), f"missing {legacy_shared_root}"
    assert legacy_openclaw_root.exists(), f"missing {legacy_openclaw_root}"
    assert (legacy_shared_root / "README.md").exists(), f"missing {legacy_shared_root / 'README.md'}"
    assert not (legacy_shared_root / "CONTRACT.md").exists(), (
        f"legacy shared root should not remain canonical: {legacy_shared_root / 'CONTRACT.md'}"
    )
    assert (legacy_openclaw_root / "README.md").exists(), (
        f"missing {legacy_openclaw_root / 'README.md'}"
    )
    assert not (legacy_openclaw_root / "SKILL.md").exists(), (
        f"legacy OpenClaw root should not remain a skill package: {legacy_openclaw_root / 'SKILL.md'}"
    )

    readme_text = readme_md.read_text(encoding="utf-8")
    contract_text = contract_md.read_text(encoding="utf-8")
    runbook_text = runbook_md.read_text(encoding="utf-8")
    matrix_text = matrix_md.read_text(encoding="utf-8")
    root_readme_text = root_readme_md.read_text(encoding="utf-8")
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
            "`skills/` remains the canonical Builder workflow source for the core `[CDD-0]` through `[CDD-7]` `cdd-*` skills.",
        ),
        readme_md,
        "shared contract index entries",
    )
    require_regexes(
        readme_text,
        (
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
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
            "- `builder_restart_count`",
            "- `current_blocker`",
            "- `STEP_PASS`",
            "- `RUN_COMPLETE`",
        ),
        contract_md,
        "shared contract runtime-state fields",
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
            ".cdd-runtime/master-chef/worktrees/<run-id>/",
            "master-chef/<run-id>",
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
        ),
        runbook_md,
        "shared runbook worktree fields",
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
            r"Use .*(cdd-master-chef|\[CDD-8\] Master Chef).*kickoff approval",
            r"For `\[CDD-8\] Master Chef`:",
            r"start `(?:\$|/)?cdd-master-chef`.*main session.*runtime you want to control",
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
            "For current Codex or Claude Code `[CDD-8] Master Chef` adapter work:",
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

    require_headings(
        runbook_text,
        (
            "## 1) Session shape",
            "## 2) Builder selection",
            "## 3) Run config handling",
            "## 5) Worktree hand-off",
        ),
        runbook_md,
        "Codex runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            "-C <active_worktree_path>",
            ".codex/agents/*.toml",
            "`exact support`, `inherited-model fallback`, `startup-only application`, or `constrained behavior`",
        ),
        runbook_md,
        "Codex runbook structural tokens",
    )

    require_substrings(
        harness_text,
        (
            "### Prompt E - Unsupported patterns",
            "### Prompt F - Worktree continuation",
            "Recursive default fan-out was rejected.",
        ),
        harness_md,
        "Codex harness coverage",
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

    require_headings(
        runbook_text,
        (
            "## 1) Session shape",
            "## 2) Builder selection",
            "## 3) Run config handling",
            "## 4) Foreground and background policy",
            "## 5) Tool and MCP policy",
            "## 6) Worktree hand-off",
        ),
        runbook_md,
        "Claude runbook headings",
    )
    require_substrings(
        runbook_text,
        (
            "--effort <master_thinking>",
            "Subagents cannot spawn other subagents",
            "Do not rely on background Builder work for MCP-dependent or approval-heavy tasks.",
            "Treat `--worktree` as a startup-time or relaunch-time tool",
        ),
        runbook_md,
        "Claude runbook structural tokens",
    )

    require_substrings(
        harness_text,
        (
            "### Prompt E - Non-nesting rule",
            "### Prompt F - Worktree continuation",
            "Permission-heavy Builder work stayed foreground.",
            "Nested subagent spawning was rejected.",
        ),
        harness_md,
        "Claude harness coverage",
    )


def validate_openclaw_adapter(repo_root: Path) -> None:
    """Validate the OpenClaw adapter package structurally."""
    skill_md = repo_root / "cdd-master-chef" / "SKILL.md"
    assert skill_md.exists(), f"missing {skill_md}"
    skill_text = skill_md.read_text(encoding="utf-8")
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
    require_headings(
        skill_text,
        (
            "# [CDD-8] Master Chef",
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
            "- `source_repo`",
            "- `active_worktree_path`",
            "- `worktree_continue_mode`",
            "- `STEP_PASS`",
            "- `DEADLOCK_STOPPED`",
        )
        + OPENCLAW_ROUTING_LABELS,
        skill_md,
        "OpenClaw skill runtime tokens",
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
            "worktree_continue_mode",
            "context-summary.md",
        )
        + OPENCLAW_ROUTING_LABELS,
        runbook_md,
        "OpenClaw runbook runtime tokens",
    )

    require_substrings(
        readme_text,
        (
            MASTER_CHEF_LABEL,
            "~/.openclaw/skills/cdd-master-chef",
            "./scripts/install.sh --runtime openclaw",
            ".cdd-runtime/master-chef/context-summary.md",
            "STEP_PASS",
        )
        + OPENCLAW_ROUTING_LABELS,
        readme_md,
        "OpenClaw README runtime references",
    )

    require_substrings(
        harness_text,
        (
            MASTER_CHEF_LABEL,
            "Prompt J - QA reject remediation",
            "Prompt L - Blocked-step decomposition",
            "Prompt N - Context compaction and resume",
            "Dirty checkout refusal",
        )
        + OPENCLAW_ROUTING_LABELS,
        harness_md,
        "OpenClaw harness coverage",
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
            assert "Internal OpenClaw Builder variant generated from the canonical `skills/` pack." in skill_text, (
                f"internal-use wrapper missing in {skill_md}"
            )
            assert "return that request to Master Chef" in skill_text, (
                f"Master Chef approval routing missing in {skill_md}"
            )

            if include_legacy_prose:
                if skill_name == "cdd-implement-todo":
                    assert "update only the selected step in the active `TODO*.md` file" in skill_text, (
                        f"generated TODO completion writeback missing in {skill_md}"
                    )
                    assert "Do not add a new step-level `Status:` field" in skill_text, (
                        f"generated TODO completion guardrail missing in {skill_md}"
                    )
                    validate_implement_todo_skill_text(skill_text, skill_md)
                if skill_name == "cdd-boot":
                    validate_boot_skill_text(skill_text, skill_md)
                if skill_name == "cdd-maintain":
                    validate_maintain_skill_text(skill_text, skill_md)
                if skill_name == "cdd-init-project":
                    validate_init_project_skill_text(skill_text, skill_md)
                if skill_name in {"cdd-plan", "cdd-audit-and-implement"}:
                    validate_coarse_step_planning(skill_text, skill_md)
                if skill_name == "cdd-audit-and-implement":
                    validate_audit_and_implement_skill_text(skill_text, skill_md)
                if skill_name in {
                    "cdd-plan",
                    "cdd-init-project",
                    "cdd-refactor",
                    "cdd-audit-and-implement",
                }:
                    validate_selector_labeled_options(skill_text, skill_md)

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
