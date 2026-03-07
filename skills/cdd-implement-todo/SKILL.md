---
name: cdd-implement-todo
description: "Implement exactly one TODO step, run its checks, and return a UAT checklist (explicit-only)."
disable-model-invocation: true
---

# CDD Implement TODO (explicit-only)

Implement exactly one TODO step in the target repo, then run that step’s `Automated checks`, and return a UAT checklist.

## Flow
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, and any files needed for the chosen step.
2) Resolve the requested step before asking anything:
   - If the user explicitly names a step (for example `step 8`, `step 08`, `step 008`, or an exact step heading), search `TODO.md` and `TODO-*.md` and normalize numeric step identifiers so `8`, `08`, and `008` are equivalent.
   - If exactly one step matches, treat that step as authoritative and continue immediately without asking for confirmation.
   - Ask only when the step is ambiguous (for example the same step number exists in multiple TODO files) or cannot be resolved from the user’s request.
   - If the user did not specify a step at all, ask for the exact step to implement.
3) If the step is underspecified (missing Tasks / Automated checks / UAT), draft a minimal TODO patch and ask approval before implementing.
4) Implement the step with minimal diffs.
5) Run the step’s listed `Automated checks` (or the repo’s stricter standard checks if they exist).
6) Update `docs/JOURNAL.md` only when changes are non-trivial, per `AGENTS.md`.
7) Final report format: follow the target repo’s `AGENTS.md` “Output Format Per Turn”.

## Resolution examples
- `$cdd-implement-todo step 008` + one matching Step 08 in the repo: implement immediately, no reconfirmation.
- `$cdd-implement-todo step 008` + matches in `TODO.md` and `TODO-foo.md`: ask which TODO file or exact heading to use.
- `$cdd-implement-todo` with no step argument: ask which step to implement.
- A matched step missing `Tasks`, `Automated checks`, or `UAT`: ask approval only for the minimal TODO patch needed to make the step executable.
