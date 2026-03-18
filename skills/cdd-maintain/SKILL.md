---
name: cdd-maintain
description: "Maintain a CDD repo by archiving long TODO and journal files, checking docs freshness, and doctoring the codebase for refactor and dead-code signals (explicit-only)."
disable-model-invocation: true
---

# CDD Maintain (explicit-only)

Use this skill for explicit codebase maintenance: archive long CDD files, check stale docs, and doctor the repo for refactor and dead-code signals.

## Sources of truth
Read:
- `AGENTS.md`
- `README.md`
- `TODO.md` and adjacent `TODO*.md`
- `docs/JOURNAL.md`
- `docs/INDEX.md`
- repo manifests, entrypoints, and test/lint/typecheck config as needed for code-health checks

## Safe archive behavior
- Apply safe archive moves immediately.
- Ask before deleting stale adjacent `TODO*.md` files.
- Do not delete or rewrite application code as part of maintenance.

## TODO archive rules
- Check `TODO.md` and adjacent `TODO*.md` files.
- Treat a step as archiveable only when its task list is fully complete under the repo's current TODO style.
- If step completion is ambiguous, leave that step in place and report it.
- Retain the newest 3 step headings in each active TODO file.
- Archive older completed steps when a TODO file is long enough to need trimming.
- Treat a TODO file as long when it has more than 6 step headings or clearly accumulated completed historical steps beyond the retained active window.
- Move archived sections into `docs/archive/`.
- Use archive filenames:
  - `TODO.md` -> `docs/archive/TODO_YYYY-MM-DD.md`
  - `TODO-foo.md` -> `docs/archive/TODO-foo_YYYY-MM-DD.md`
- If the same-day archive file already exists, append the newly archived sections instead of overwriting it.
- After archiving, keep the active TODO file focused on the retained newest 3 step headings plus any older incomplete or ambiguous steps that could not be archived safely.

## Stale adjacent TODO file handling
- For adjacent `TODO*.md` files, check last activity using `git log -1` timestamp when available.
- If git history is unavailable, fall back to filesystem mtime.
- If an adjacent TODO file is older than 14 days and has no remaining active work after safe archiving, ask the user once for approval before deleting those stale files.
- Group all such stale-file deletions into one approval request.

## Journal archive rules
- Read the archive or rotation guidance at the top of `docs/JOURNAL.md`.
- Archive `docs/JOURNAL.md` only according to the rules defined there.
- If `docs/JOURNAL.md` has no clear archive rule near the top, do not invent one; skip journal archival and report that it was skipped.

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
- `INDEX freshness`
- `Refactor severity summary`
- `Dead/orphan code findings`
- `Recommended next action`

Recommend follow-up such as `cdd-index`, `cdd-refactor`, `cdd-plan`, or direct cleanup work when supported by the findings, but do not create those artifacts automatically.
