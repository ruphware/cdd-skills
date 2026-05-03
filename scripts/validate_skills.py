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
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." in skill_text, (
        f"TODO-next journal rule missing in {skill_md}"
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
    assert "If no active implementation `TODO-<area>.md` exists, treat the repo as single-journal mode and archive `docs/JOURNAL.md` only according to the rules defined there." in skill_text, (
        f"single-journal archive rule missing in {skill_md}"
    )
    assert "When any active implementation `TODO-<area>.md` exists, treat split-journal mode as active and keep it active; do not propose collapsing back to a single hot journal." in skill_text, (
        f"split-journal activation rule missing in {skill_md}"
    )
    assert "In split-journal mode, review `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes, matching `docs/journal/JOURNAL-<area>.md` files for active workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches when present." in skill_text, (
        f"split-journal review coverage missing in {skill_md}"
    )
    assert "`TODO-next.md` is backlog and does not require `JOURNAL-next.md`." in skill_text, (
        f"TODO-next backlog rule missing in {skill_md}"
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
    assert "## Contract-surface taxonomy and drift rules" in skill_text, (
        f"contract-surface taxonomy heading missing in {skill_md}"
    )
    assert (
        "- Treat these files as methodology-stable contract surfaces that should be materialized from `cdd-boilerplate` and kept aligned with its CDD workflow language:"
    ) in skill_text, f"stable contract taxonomy missing in {skill_md}"
    assert (
        "- Treat these files as repo-specific contract surfaces that must be filled from the actual target repo rather than copied verbatim:"
    ) in skill_text, f"repo-specific contract taxonomy missing in {skill_md}"
    assert (
        "- `AGENTS.md`: start from the boilerplate `AGENTS.md` and preserve the CDD methodology, rule numbering, method structure, and output contract. Limited repo-fit edits are allowed only for project facts such as language, framework, repo layout, runbook entrypoints, or a short repo note; do not rewrite the methodology."
    ) in skill_text, f"bounded AGENTS drift rule missing in {skill_md}"
    assert (
        "- `TODO.md`: start from the boilerplate `TODO.md` and preserve its header, Step 00, and Step template. Add repo-specific work only as Step 01+ or `TODO-*.md`; do not replace Step 00 with a repo-specific adoption format."
    ) in skill_text, f"TODO Step 00 preservation rule missing in {skill_md}"
    assert (
        "- `docs/JOURNAL.md`: start from the boilerplate journal and preserve its rules, entry format, and archive or summarize mechanics. Repo-specific content belongs in entries and summaries only."
    ) in skill_text, f"JOURNAL preservation rule missing in {skill_md}"
    assert (
        "- `docs/prompts/PROMPT-INDEX.md`: start from the boilerplate prompt and preserve its role, analysis and generation workflow, quality bar, and template structure. Do not replace it with a repo-specific docs-index prompt."
    ) in skill_text, f"PROMPT-INDEX preservation rule missing in {skill_md}"
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
            "keep `docs/JOURNAL.md` and `docs/prompts/PROMPT-INDEX.md` aligned with their boilerplate methodology scaffolds instead of rewriting them"
        )
        >= 3
    ), f"JOURNAL/PROMPT-INDEX flow preservation missing in {skill_md}"
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
    assert "a Step 00-style “CDD adoption” step" not in skill_text, (
        f"old repo-specific Step 00 adoption wording should not appear in {skill_md}"
    )
    assert "Add an adoption plan to `TODO.md`:" not in skill_text, (
        f"old TODO adoption-plan wording should not appear in {skill_md}"
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


def validate_openclaw_skill(repo_root: Path) -> None:
    """Validate the OpenClaw-only skill package."""
    skill_md = repo_root / "openclaw" / "SKILL.md"
    assert skill_md.exists(), f"missing {skill_md}"
    skill_text = skill_md.read_text(encoding="utf-8")
    runbook_md = repo_root / "openclaw" / "MASTER-CHEF-RUNBOOK.md"
    readme_md = repo_root / "openclaw" / "README.md"
    harness_md = repo_root / "openclaw" / "MASTER-CHEF-TEST-HARNESS.md"
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
    assert "if QA rejects the Builder result, either push concrete findings to a fresh Builder run for the same step or fix the issue directly in Master Chef, then re-run QA before the step can pass" in skill_text, (
        f"Master Chef QA remediation contract missing in {skill_md}"
    )
    assert "advertise `STEP_PASS` with the full result, evidence, and decision trail in the current Master Chef session" in skill_text, (
        f"session-native STEP_PASS advertising missing in {skill_md}"
    )
    assert "re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains" in skill_text, (
        f"automatic TODO continuation contract missing in {skill_md}"
    )
    assert "When Master Chef rejects Builder output during QA" in runbook_text, (
        f"QA rejection procedure missing in {runbook_md}"
    )
    assert "cannot be passed, committed, pushed, or advertised as `STEP_PASS`" in runbook_text, (
        f"pre-remediation pass guardrail missing in {runbook_md}"
    )
    assert "then re-run QA and UAT before the normal commit, push, `STEP_PASS`, TODO re-inspection, and automatic continuation path resumes" in runbook_text, (
        f"QA remediation continuation path missing in {runbook_md}"
    )
    assert "Passed steps are advertised as `STEP_PASS` in the current Master Chef session before automatic continuation" in readme_text, (
        f"user-facing STEP_PASS advertising missing in {readme_md}"
    )
    assert "Prompt J - QA reject remediation" in harness_text, (
        f"QA reject remediation harness case missing in {harness_md}"
    )
    assert "QA-rejected Builder output was remediated and rechecked before `STEP_PASS`, commit, push, and automatic continuation." in harness_text, (
        f"QA remediation pass criterion missing in {harness_md}"
    )
    assert "If a TODO step is blocked by a hard blocker, ambiguous scope, or repeated failed Builder replacements:" in skill_text, (
        f"blocked-step recovery contract missing in {skill_md}"
    )
    assert "decompose the blocked work into smaller decision-complete TODO steps through Master-Chef-direct planning or TODO repair" in skill_text, (
        f"blocked-step TODO decomposition contract missing in {skill_md}"
    )
    assert "restart only from the next smaller actionable TODO step; do not retry the same broad blocked step unchanged" in skill_text, (
        f"smaller-step restart contract missing in {skill_md}"
    )
    assert "When a step is blocked by a hard gate, ambiguous scope, missing implementation decisions, or repeated failed Builder replacements" in runbook_text, (
        f"blocked-step recovery procedure missing in {runbook_md}"
    )
    assert "Clean only stale runtime or build artifacts required for a coherent retry; do not revert unrelated user work or discard useful failure evidence." in runbook_text, (
        f"blocked-step cleanup guardrail missing in {runbook_md}"
    )
    assert "if a step is blocked, Master Chef stops the autonomous loop, reports the blocker in-session, decomposes the work into smaller TODO steps when possible, cleans only stale retry artifacts, and restarts from the next smaller actionable step" in readme_text, (
        f"user-facing blocked-step behavior missing in {readme_md}"
    )
    assert "Prompt L - Blocked-step decomposition" in harness_text, (
        f"blocked-step decomposition harness case missing in {harness_md}"
    )
    assert "Blocked broad or underspecified steps stopped the autonomous loop, were decomposed into smaller TODO steps, and restarted only from a smaller actionable step." in harness_text, (
        f"blocked-step decomposition pass criterion missing in {harness_md}"
    )
    assert ".cdd-runtime/master-chef/context-summary.md" in skill_text, (
        f"Master Chef context checkpoint file missing in {skill_md}"
    )
    assert "before Master Chef compaction, write `run.json`, `run.lock.json`, JSONL evidence, and `.cdd-runtime/master-chef/context-summary.md`" in skill_text, (
        f"pre-compaction checkpoint contract missing in {skill_md}"
    )
    assert "do not compact while QA, commit, push, blocker strategy, or next-action decisions exist only in the live transcript" in skill_text, (
        f"unsafe compaction guardrail missing in {skill_md}"
    )
    assert "after compaction, resume from runtime files, `context-summary.md`, active TODO, and git state before continuing" in skill_text, (
        f"post-compaction resume contract missing in {skill_md}"
    )
    assert "### 4.4 `context-summary.md`" in runbook_text, (
        f"context-summary section missing in {runbook_md}"
    )
    assert "Use `context-summary.md` as the durable Master Chef checkpoint for long runs and context compaction." in runbook_text, (
        f"context-summary purpose missing in {runbook_md}"
    )
    assert "## 8) Master Chef context compaction" in runbook_text, (
        f"context compaction procedure missing in {runbook_md}"
    )
    assert "Master Chef may compact only after durable state is written to `run.json`, `run.lock.json` when applicable, `master-chef.jsonl`, `builder.jsonl`, and `context-summary.md`." in runbook_text, (
        f"safe compaction boundary missing in {runbook_md}"
    )
    assert "Do not compact:" in runbook_text and "while QA findings or UAT decisions are only in the live transcript" in runbook_text, (
        f"unsafe compaction windows missing in {runbook_md}"
    )
    assert "After compaction, Master Chef must reconstruct state from durable sources instead of trusting transcript memory:" in runbook_text, (
        f"compaction resume procedure missing in {runbook_md}"
    )
    assert "Master Chef checkpoints long-run memory in `.cdd-runtime/master-chef/context-summary.md` before deliberate compaction." in readme_text, (
        f"user-facing context checkpoint behavior missing in {readme_md}"
    )
    assert "Prompt N - Context compaction and resume" in harness_text, (
        f"context compaction harness case missing in {harness_md}"
    )
    assert "`context-summary.md` records run, state, recent decisions, current diff, pending proof, and next action" in harness_text, (
        f"context summary harness expectation missing in {harness_md}"
    )
    assert "Master Chef compaction happened only after a durable checkpoint and resume used runtime files, active TODO, and git state." in harness_text, (
        f"context compaction pass criterion missing in {harness_md}"
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
