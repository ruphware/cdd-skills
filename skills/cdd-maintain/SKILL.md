---
name: cdd-maintain
description: "Maintain a CDD repo by archiving long TODO and journal files, auditing support-doc drift, proposing approval-gated doc refreshes, and doctoring the codebase for refactor and dead-code signals (explicit-only)."
disable-model-invocation: true
---

# CDD Maintain (explicit-only)

Use this skill for explicit codebase maintenance: archive long CDD files, audit support-doc drift, propose approval-gated documentation refreshes, and doctor the repo for refactor and dead-code signals.

## Sources of truth
Read:
- `AGENTS.md`
- `README.md`
- `TODO.md` and adjacent `TODO*.md`
- `docs/JOURNAL.md` as the stable journal entrypoint
- `docs/journal/JOURNAL.md`, matching `docs/journal/JOURNAL-<area>.md` files, `docs/journal/SUMMARY.md`, and `docs/journal/archive/` when split-journal mode is active
- `docs/INDEX.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- connected `docs/specs/*-definition.md` files when present
- `docs/prompts/PROMPT-INDEX.md` if present
- repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces
- repo manifests, entrypoints, and test/lint/typecheck config as needed for code-health checks

## Safe archive behavior
- Apply safe archive moves immediately.
- Ask before deleting stale adjacent `TODO*.md` files.
- Do not delete or rewrite application code as part of maintenance.
- Do not silently rewrite support docs as part of maintenance.

## TODO archive rules
- Check `TODO.md` and adjacent `TODO*.md` files.
- Treat a step as archiveable only when its task list is fully complete under the repo's current TODO style.
- If step completion is ambiguous, leave that step in place and report it.
- Preserve top-to-bottom TODO history: archive only from the oldest contiguous archiveable block near the top of the active step list.
- Never archive a step from the middle or tail of the active TODO file.
- Do not leapfrog an older incomplete or ambiguous step in order to archive later completed steps below it.
- Retain the newest 3 step headings in each active TODO file.
- Archive older completed steps when a TODO file is long enough to need trimming.
- Treat a TODO file as long when it has more than 6 step headings or clearly accumulated completed historical steps beyond the retained active window.
- Move archived sections into `docs/archive/`.
- Use archive filenames:
  - `TODO.md` -> `docs/archive/TODO_YYYY-MM-DD.md`
  - `TODO-foo.md` -> `docs/archive/TODO-foo_YYYY-MM-DD.md`
- If the same-day archive file already exists, append the newly archived sections instead of overwriting it.
- If older incomplete or ambiguous steps block a clean top trim, do not archive later completed steps; report archival as blocked by non-contiguous active history.
- After archiving, keep the active TODO file focused on the retained newest 3 step headings plus any older incomplete or ambiguous steps that could not be archived safely.

## Stale adjacent TODO file handling
- For adjacent `TODO*.md` files, check last activity using `git log -1` timestamp when available.
- If git history is unavailable, fall back to filesystem mtime.
- If an adjacent TODO file is older than 14 days and has no remaining active work after safe archiving, ask the user once for approval before deleting those stale files.
- Group all such stale-file deletions into one approval request.

## Journal archive rules
- Read the journal layout plus archive or rotation guidance at the top of `docs/JOURNAL.md` first.
- Treat `docs/JOURNAL.md` as the stable journal entrypoint in all repos.
- In split-journal mode, expect the top of `docs/JOURNAL.md` to remain a short, clear current-state index/header for the active journal layout; if it no longer clearly routes readers to `docs/journal/*`, report it as drift.
- If no active implementation `TODO-<area>.md` exists, treat the repo as single-journal mode and archive `docs/JOURNAL.md` only according to the rules defined there.
- When any active implementation `TODO-<area>.md` exists, treat split-journal mode as active and keep it active; do not propose collapsing back to a single hot journal.
- In split-journal mode, review `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes, matching `docs/journal/JOURNAL-<area>.md` files for active workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches when present.
- Do not precreate split-journal files before split-journal mode is active.
- In split-journal mode, archive hot journals only according to the rules defined in the active journal files or entrypoint guidance, and route condensed/archive review through `docs/journal/SUMMARY.md` and `docs/journal/archive/` when present.
- If the relevant journal entrypoint or active hot journal files have no clear archive or routing rule, do not invent one; skip journal archival for that unclear surface and report it.

## Support documentation drift review
- Treat `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and connected `docs/specs/*-definition.md` files as canonical support docs.
- Also review `docs/INDEX.md` and `docs/prompts/PROMPT-INDEX.md` when present as support-doc navigation surfaces.
- Treat repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces tied to the repo's documented workflow.
- Compare each support doc against the current repo state or clearly intended future-state contract using manifests, entrypoints, scripts, active TODO/JOURNAL context, and the other support docs.
- When repo-local `.agents/skills/*/SKILL.md` files are present, compare them against the current repo structure, documentation topology, `AGENTS.md`, and the current support-doc contract.
- Check whether setup/dev/test/build instructions, documented workflows, active features, future plans, architecture notes, referenced doc paths, doc-role boundaries, journal topology, and workflow-skill expectations still match the repo.
- For `README.md`: keep it as the runbook entrypoint. It may include current features, use cases, and future plans, but it must not include historical project narration or CDD/TODO step progression.
- If `README.md` includes a CDD contract note, keep it as a low-visibility bottom footer, such as the repo-standard `___` + badges + `<sup>` footnote, rather than a top-of-file banner.
- If `README.md` is long and substantially duplicates content already maintained in other support docs such as `TODO.md` or `docs/specs/*`, propose a user-approved compaction rather than silently condensing it.
- For `docs/specs/prd.md`: treat it as the product-manager view; it may include product vision, use cases, JTBD, and feature lists.
- For `docs/specs/blueprint.md` and connected `*-definition.md` files: treat `blueprint.md` as the anchor technical spec and use connected definition files for technical architecture, data structures, interfaces, technical reasoning, and implementation detail.
- Do not treat repo history as justification for stale support-doc content; drift review is about current repo truth or clearly intended future-state docs.
- Classify each support doc as `current`, `drifted`, `missing`, or `unclear`.
- Classify each repo-local skill surface reviewed under `.agents/skills/*/SKILL.md` as `current`, `drifted`, `missing`, or `unclear` when that surface exists or is expected by the repo.
- If a support doc is missing, report it explicitly and do not fabricate it automatically as part of maintenance.
- If `README.md`, `docs/specs/*`, or connected `*-definition.md` files have drifted, prepare the needed edits and show them to the user before applying anything.
- If repo-local `.agents/skills/*/SKILL.md` files drift from the current repo structure, documentation topology, or workflow contract, prepare the needed edits and show them to the user before applying anything.
- Do not silently refresh `README.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, connected `*-definition.md` files, `docs/INDEX.md`, `docs/prompts/PROMPT-INDEX.md`, or repo-local `.agents/skills/*/SKILL.md` files.
- Ask once for documentation approval using a single grouped confirmation such as: `Approve and apply these documentation updates?`
- Keep documentation approval separate from stale TODO deletion approval so the user can approve doc updates without approving file deletions.
- If the user approves, apply only the approved support-doc edits and then report them.
- If the user does not approve, leave support docs unchanged and report the remaining drift clearly.
- Report repo-local skill-surface drift together with support-doc drift when present.

## INDEX freshness
- Check how old `docs/INDEX.md` is using the last git change when available, otherwise filesystem mtime.
- Report the exact age in days.
- Classify freshness as:
  - `fresh` for 0-14 days
  - `stale` for 15-30 days
  - `very stale` for over 30 days or clearly older than current TODO or journal activity

## Codebase doctoring
- Check the severity of files and areas that appear to need refactoring.
- Use repo-native lint, typecheck, or unused-code tooling when present.
- Otherwise use conservative heuristic scans for:
  - orphaned files or modules
  - dead or unreachable code paths
  - unused exports or duplicate retired implementation paths
  - stale feature code that no longer appears wired into entrypoints
- Report findings with both:
  - `severity`: `high`, `medium`, or `low`
  - `confidence`: `confirmed`, `probable`, or `possible`
- Never auto-delete code.
- Do not create TODO or refactor files automatically.

## Output
Return a maintenance report that includes:
- `Archive actions applied`
- `Deletion approval needed`
- `Journal archive status`
- `Support documentation status`
- `Documentation updates proposed` or `Documentation updates applied`
- `Documentation approval needed`
- `INDEX freshness`
- `Refactor severity summary`
- `Dead/orphan code findings`
- `Recommended next action`

Recommend follow-up such as `cdd-index`, `cdd-refactor`, `cdd-plan`, or direct cleanup work when supported by the findings, but do not create those artifacts automatically.
