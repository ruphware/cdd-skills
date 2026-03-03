---
name: cdd-implement-todo
description: "Implement exactly one TODO step, run its checks, and return a UAT checklist (explicit-only)."
disable-model-invocation: true
---

# CDD Implement TODO (explicit-only)

Implement exactly one TODO step in the target repo, then run that step’s `Automated checks`, and return a UAT checklist.

## Flow
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, and any files needed for the chosen step.
2) Ask the user to confirm:
   - which TODO file to use (if multiple)
   - the exact step heading to implement
3) If the step is underspecified (missing Tasks / Automated checks / UAT), draft a minimal TODO patch and ask approval before implementing.
4) Implement the step with minimal diffs.
5) Run the step’s listed `Automated checks` (or the repo’s stricter standard checks if they exist).
6) Update `docs/JOURNAL.md` only when changes are non-trivial, per `AGENTS.md`.
7) Final report format: follow the target repo’s `AGENTS.md` “Output Format Per Turn”.
