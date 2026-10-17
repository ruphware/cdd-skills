# Mode A — Doc drift + upkeep

Own both support-doc drift and repo upkeep: TODO archive review, stale adjacent TODO review, journal archive review, and repo-local runtime cleanup review. Apply the TODO archive rules, stale adjacent `TODO*.md` rules, journal archive rules, and local runtime cleanup review rules below only in this mode unless another selected mode explicitly needs one of those surfaces as proof.

## Contents
- `## Read list`: everything this mode reads
- `## Canonical support docs`: canonical docs, navigation surfaces, workflow-skill surfaces
- `## Drift review and classification`: comparison, doc-role rules, labels, drift edits
- `## Codebase-comparison checks`: bounded claim checks and the orphaned-topic check
- `## Subsystem doc clusters`: cluster detection and scope
- `## Ad-hoc support docs`: the ad-hoc scope walked on every run
- `## TODO archive rules`: contiguous top trim and archive filenames
- `## Stale adjacent TODO file handling`: age check and grouped deletion
- `## Journal archive rules`: single- and split-journal archival
- `## Ad-hoc support doc archive rules`: triggers and mirrored archive layout
- `## Local runtime cleanup review`: `.cdd-runtime/` classification and removal limits
- `## Approval surfaces`: the four approvals this mode raises

## Read list
- Always: `README.md`; `TODO.md` and adjacent `TODO*.md`; `docs/JOURNAL.md` as the stable journal entrypoint; `docs/specs/prd.md` and `docs/specs/blueprint.md`; every detected subsystem doc cluster (`## Subsystem doc clusters`); every ad-hoc support doc (`## Ad-hoc support docs`); the manifests, entrypoints, or scripts needed to verify drift or upkeep decisions.
- When split-journal mode is active: `docs/journal/JOURNAL.md`, matching `docs/journal/JOURNAL-<area>.md` files, `docs/journal/SUMMARY.md`, `docs/journal/archive/`.
- When INDEX split is active: `docs/index/**` siblings.
- When present: `docs/INDEX.md`, connected `docs/specs/*-definition.md` files, `docs/prompts/PROMPT-INDEX.md`, repo-root `RUNBOOK.md` and `docs/runbooks/*.md`, repo-local `.agents/skills/*/SKILL.md`, repo-local `.cdd-runtime/`.

## Canonical support docs
- Treat `README.md`, repo-root `RUNBOOK.md` and `docs/runbooks/*.md` when present, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and connected `docs/specs/*-definition.md` files as canonical support docs.
- Also review `docs/INDEX.md`, `docs/index/**` siblings when INDEX split is active, and `docs/prompts/PROMPT-INDEX.md` when present as support-doc navigation surfaces.
- Treat repo-local `.agents/skills/*/SKILL.md` files when present as workflow/governance drift surfaces tied to the repo's documented workflow.
- For `docs/specs/prd.md`: treat it as the product-manager view.
- For `docs/specs/blueprint.md` and connected `*-definition.md` files: treat `blueprint.md` as the anchor technical spec.

## Drift review and classification
- Compare each support doc against the current repo state or clearly intended future-state contract using manifests, entrypoints, scripts, active TODO/JOURNAL context, and the other support docs. Use the bounded checks and orphaned-topic check defined in `## Codebase-comparison checks`. When repo-local `.agents/skills/*/SKILL.md` files are present, compare them against the current repo structure, documentation topology, `AGENTS.md`, and the current support-doc contract.
- Check whether setup/dev/test/build instructions, documented workflows, active features, future plans, architecture notes, referenced doc paths, doc-role boundaries, journal topology, and workflow-skill expectations still match the repo.
- Repo history is not justification for stale support-doc content; drift review is about current repo truth or clearly intended future-state docs.
- For `README.md`: keep it as the runbook entrypoint. It may include current features, use cases, and future plans, but not historical project narration — step-by-step development summaries, "implemented X in commit Y" stories, retired roadmap entries — or CDD/TODO step progression; that history belongs in journal/changelog. If it includes a CDD contract note, keep it as a low-visibility bottom footer.
- For `docs/runbooks/*.md` and repo-root `RUNBOOK.md`, flag procedures or commands for decommissioned, renamed, or removed services, scripts, or entrypoints; the runbook is for current operations, not archaeology.
- If `README.md` is long and substantially duplicates content already maintained in other support docs such as `TODO.md` or `docs/specs/*`, propose a user-approved compaction rather than silently condensing it.
- Classify each support doc as `current`, `drifted`, `stale-candidate`, `missing`, or `unclear`. The `stale-candidate` label applies only to ad-hoc support docs and is populated only by the orphaned-topic check in `## Codebase-comparison checks`; classifying a doc as `stale-candidate` does not by itself archive anything.
- Classify each repo-local skill surface reviewed under `.agents/skills/*/SKILL.md` as `current`, `drifted`, `missing`, or `unclear`.
- If a support doc is missing, report it explicitly and do not fabricate it automatically as part of maintenance.
- If `README.md`, `docs/specs/*`, connected `*-definition.md` files, `docs/INDEX.md`, `docs/index/**` siblings when INDEX split is active, `docs/prompts/PROMPT-INDEX.md`, or repo-local `.agents/skills/*/SKILL.md` files have drifted, prepare the needed edits and show them to the user before applying anything; never silently refresh any of these files.
- If the user approves, apply only the approved support-doc edits and then report them.
- If the user does not approve, leave support docs unchanged and report the remaining drift clearly.

## Codebase-comparison checks
- Run these bounded checks against canonical support docs and ad-hoc support docs. Use repo-native search only; no full static analysis or symbol-graph traversal.
- A failed bounded check produces a `drifted` classification with the specific claim cited.
- **Script-name claims** (`npm run <name>`, `pnpm <name>`, `yarn <name>`, `make <target>`, `pdm run <name>`, `cargo <command>`, `go run <path>`, `python -m <module>`, or any quoted command pointing at a repo script): verify the target resolves to an entry in the relevant manifest (`package.json`, `pyproject.toml`, `Makefile`, `scripts/`, `Cargo.toml`, `go.mod`, `mix.exs`, etc.).
- **File-path claims** (any repo-relative path or backticked path in a doc): verify the path exists in the current tree.
- **Symbol claims** (function, class, module, or CLI command name in a doc): best-effort repo-grep. Report `unclear` if not found rather than auto-`drifted`.
- **Entrypoint claims** (a main / CLI / service / handler in a doc): verify the named entrypoint file exists and is referenced from the relevant manifest.
- **Skill-reference claims** (`$cdd-<x>` or `skills/<x>` in a doc): verify the skill directory and `SKILL.md` exist.
- **Manifest-field claims** (package name, version range, or dependency in a doc): verify the field is present in the relevant manifest.
- **Lifecycle-mismatch claims** (narrative content that talks about work as future, in-progress, current, or past): cross-check against current code, active TODO surfaces, and recent journal or commit activity. Future-tense work that already shipped, in-progress narration ("currently implementing", "we are migrating") of completed work, present-tense documentation of removed or renamed surfaces, deprecated paths still presented as the primary recommendation, and retired roadmap or "coming soon" items still presented as future are all `drifted` findings — cite the specific phrase and the evidence that contradicts it.
- Orphaned-topic check (ad-hoc support docs only):
  - Extract the doc's primary subject from filename, H1 heading, and first-paragraph keywords.
  - Grep the subject across (a) the codebase, (b) the active TODO step list (`TODO.md` + adjacent `TODO-*.md`), (c) the active specs and blueprint (`docs/specs/*`), and (d) the last 30 days of journal activity. Locate journal sources per the existing single-vs-split rules in `## Journal archive rules`.
  - Map hit count to label: 0 hits across all four surfaces → `stale-candidate`; 1-2 weak hits → `unclear`; 3+ hits → `current`.

## Subsystem doc clusters
- Detect a subsystem doc cluster when a directory contains `README.md` and at least one of `RUNBOOK.md`, `CONTRACT.md`, or `SKILL.md`. Treat the cluster's `README.md`, `RUNBOOK.md`, `CONTRACT.md`, and `SKILL.md` files as canonical for that subsystem only.
- Root `README.md` stays the repo runbook entrypoint; a subsystem `README.md` is canonical only for its subsystem — both scopes coexist.
- Treat every other `*.md` inside a detected cluster as a subsystem-internal ad-hoc support doc per `## Ad-hoc support docs`.

## Ad-hoc support docs
- Treat the following as ad-hoc support docs and walk them on every Mode A invocation:
  - every `*.md` under `docs/` not in a canonical-role subdirectory (`docs/specs/`, `docs/prompts/`, `docs/runbooks/`, `docs/archive/`, `docs/journal/`, `docs/index/`, `docs/INDEX.md`, `docs/JOURNAL.md`)
  - every non-canonical `*.md` at repo root (excluding the protected names `README.md`, `AGENTS.md`, `CLAUDE.md`, `TODO.md`, `TODO-*.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`)
  - every subsystem-internal non-canonical `*.md` file inside a detected subsystem doc cluster
- This covers mockups, scratch RFCs, design notes, retired drafts, source mockups, and similar exploratory artifacts. RFCs are one example of an ad-hoc support doc, not a privileged class.
- Non-`.md` files (images, JSON, binaries) are out of scope for Mode A.
- Classify each ad-hoc support doc using `## Drift review and classification` and report them under `Support documentation status`. Archive proposals follow `## Ad-hoc support doc archive rules`.

## TODO archive rules
- Check `TODO.md` and adjacent `TODO*.md` files.
- Treat a step as archiveable only when its task list is fully complete under the repo's current TODO style. If step completion is ambiguous, leave that step in place and report it.
- Preserve top-to-bottom TODO history: archive only from the oldest contiguous archiveable block near the top of the active step list. Never archive a step from the middle or tail of the active TODO file. Do not leapfrog an older incomplete or ambiguous step in order to archive later completed steps below it.
- Retain the newest 3 step headings in each active TODO file. Archive older completed steps when a TODO file is long enough to need trimming. Treat a TODO file as long when it has more than 6 step headings or clearly accumulated completed historical steps beyond the retained active window.
- Move archived sections into `docs/archive/`.
- Use archive filenames:
  - `TODO.md` -> `docs/archive/TODO_YYYY-MM-DD.md`
  - `TODO-foo.md` -> `docs/archive/TODO-foo_YYYY-MM-DD.md`
- If the same-day archive file already exists, append the newly archived sections instead of overwriting it.
- If older incomplete or ambiguous steps block a clean top trim, do not archive later completed steps; report archival as blocked by non-contiguous active history. After archiving, keep the active TODO file focused on the retained newest 3 step headings plus any older incomplete or ambiguous steps that could not be archived safely.

## Stale adjacent TODO file handling
- For adjacent `TODO*.md` files, check last activity using `git log -1` timestamp when available.
- If git history is unavailable, fall back to filesystem mtime.
- An adjacent TODO file older than 14 days with no remaining active work after safe archiving is a stale-TODO deletion candidate.
- Group all such stale-file deletions into one approval request.

## Journal archive rules
- Read the journal layout plus archive or rotation guidance at the top of `docs/JOURNAL.md` first. Treat `docs/JOURNAL.md` as the stable journal entrypoint in all repos.
- In split-journal mode, expect the top of `docs/JOURNAL.md` to remain a short, clear current-state index/header for the active journal layout; if it no longer clearly routes readers to `docs/journal/*`, report it as drift.
- If no active implementation `TODO-<area>.md` exists, treat the repo as single-journal mode and archive `docs/JOURNAL.md` only according to the rules defined there.
- When any active implementation `TODO-<area>.md` exists, treat split-journal mode as active and keep it active; do not propose collapsing back to a single hot journal. In split-journal mode, review `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes, matching `docs/journal/JOURNAL-<area>.md` files for active workstreams, `docs/journal/SUMMARY.md` for condensed archive history, and `docs/journal/archive/` for raw archived batches when present.
- Do not precreate split-journal files before split-journal mode is active.
- In split-journal mode, archive hot journals only according to the rules defined in the active journal files or entrypoint guidance, and route condensed/archive review through `docs/journal/SUMMARY.md` and `docs/journal/archive/` when present. If the relevant journal entrypoint or active hot journal files have no clear archive or routing rule, do not invent one; skip journal archival for that unclear surface and report it.

## Ad-hoc support doc archive rules
- Primary trigger is an ad-hoc support doc classified as `stale-candidate` by the orphaned-topic check in `## Codebase-comparison checks`. Cite which evidence surfaces returned no hits when proposing archive.
- Secondary trigger is an explicit retirement marker in the doc — frontmatter `Deprecated:`, frontmatter `Superseded by:`, or frontmatter `Status:` with value `Superseded`, `Rejected`, or `Withdrawn`. Strong signals when present but not required; judgement-based `stale-candidate` proposals are also valid.
- The destination layout mirrors the source location:
  - `docs/foo.md` → `docs/archive/foo_YYYY-MM-DD.md`
  - `docs/<sub>/bar.md` → `docs/archive/<sub>/bar_YYYY-MM-DD.md`
  - Repo-root non-canonical `*.md` such as `NOTES.md` → `docs/archive/NOTES_YYYY-MM-DD.md`
  - Subsystem-internal `<subsystem>/scratch.md` → `<subsystem>/_archive/scratch_YYYY-MM-DD.md` (local archive so the subsystem stays self-contained)
- Same-day archive append: if the destination archive file already exists for the same date, append the newly archived sections to that file rather than overwriting it.

## Local runtime cleanup review
- Inspect repo-local `.cdd-runtime/` when present, especially `.cdd-runtime/master-chef/`.
- If the repo is Git-backed, use local worktree state to classify runtime artifacts as `live`, `stale`, or `unclear`.
- Treat currently linked worktrees, clearly active runtime locks, and current run state as `live`.
- Treat abandoned managed worktree directories, orphaned runtime logs, stale context snapshots, and old run directories not tied to live worktrees as `stale`.
- If runtime state is unclear, leave it in place and report it as `unclear`.
- On approval, remove only `stale` repo-local runtime artifacts and managed worktrees.
- Never remove the current worktree, the current run state, or any runtime surface still tied to a `live` linked worktree.

## Approval surfaces
- Documentation: the edits prepared for drifted files in `## Drift review and classification`.
- Stale-TODO deletion: the grouped request from `## Stale adjacent TODO file handling`.
- Ad-hoc archive: the moves from `## Ad-hoc support doc archive rules`, a documentation approval taken per file or batched — user picks granularity.
- Runtime cleanup: the `stale` artifacts from `## Local runtime cleanup review`.
