---
name: cdd-implement-todo
description: "Implement exactly one TODO step, run its checks, mark that step's tasks done in TODO on success, and return a UAT checklist (explicit-only)."
disable-model-invocation: true
---

# CDD Implement TODO (explicit-only)

Implement exactly one TODO step in the target repo, run that step's `Automated checks`, update the active TODO file to mark that step's tasks done on success, and return a UAT checklist.

Do not invent missing product, architecture, sequencing, or validation decisions during implementation. If the selected step is not decision-complete, patch the TODO step first.

## Flow
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, and any files needed for the chosen step.
2) Resolve the requested step before asking anything:
   - If the user explicitly names a step (for example `step 8`, `step 08`, `step 008`, or an exact step heading), search `TODO.md` and `TODO-*.md` and normalize numeric step identifiers so `8`, `08`, and `008` are equivalent.
   - If exactly one step matches, treat that step as authoritative and continue immediately without asking for confirmation.
   - Ask only when the step is ambiguous (for example the same step number exists in multiple TODO files) or cannot be resolved from the user’s request.
   - If the user did not specify a step at all, ask for the exact step to implement.
3) If the step is underspecified, draft a minimal TODO patch and ask approval before implementing.
   - Treat the step as underspecified when it is missing `Tasks`, `Automated checks`, or `UAT`.
   - Also treat it as underspecified when the task list does not identify the concrete target boundary or subsystem, the contract/interface/behavior change to make, the sequencing needed across multiple surfaces, or the validation evidence required by the goal.
   - If the step implies migration, snapshot/audit retention, compatibility, or must-preserve behavior, treat those omissions as underspecification unless the step captures them in `Constraints`, `Implementation notes`, or equivalent local sections.
   - Preserve the repo's step template when possible, but add `Constraints`, `Implementation notes`, or equivalent detail when that is the smallest change that makes the step decision-complete.
4) Implement the step with minimal diffs.
5) Run the step’s listed `Automated checks` (or the repo’s stricter standard checks if they exist).
6) If implementation and checks pass, update only the selected step in the active `TODO*.md` file to show its Tasks are done:
   - If the step's `Tasks` section already uses markdown checkboxes, change unchecked task items from `[ ]` to `[x]`.
   - If the step's `Tasks` section uses plain bullets, rewrite only those task bullets into checked markdown checkboxes while preserving the task text and order.
   - Do not add a new step-level `Status:` field or any other completion marker.
   - Do not mark the TODO step done if implementation or checks failed.
   - Do not modify future or unrelated steps.
7) Update the matching journal file only when changes are non-trivial, per `AGENTS.md`.
   - In single-journal mode, update `docs/JOURNAL.md`.
   - If the selected step is in `TODO-<area>.md`, treat matching `docs/journal/JOURNAL-<area>.md` as the default hot journal in split-journal mode.
   - In split-journal mode, use `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes.
   - Do not duplicate the same journal entry across multiple journal files.
   - `TODO-next.md` is backlog and does not require `JOURNAL-next.md`.
8) Final report format: follow the target repo’s `AGENTS.md` “Output Format Per Turn”.
   - Explicitly state which `TODO*.md` file and step were updated to mark the completed tasks done.

## Resolution examples
- `$cdd-implement-todo step 008` + one matching Step 08 in the repo: implement immediately, no reconfirmation.
- `$cdd-implement-todo step 008` + matches in `TODO.md` and `TODO-foo.md`: ask which TODO file or exact heading to use.
- `$cdd-implement-todo` with no step argument: ask which step to implement.
- A matched step missing `Tasks`, `Automated checks`, or `UAT`: ask approval only for the minimal TODO patch needed to make the step executable.
- A matched step with vague tasks such as "support DOCX export" or "simplify the report" but no concrete boundaries, sequencing, or proof: ask approval for the minimal TODO patch needed to make the step decision-complete before implementing.
- A matched step that passes implementation and checks: mark only that step's task items done in the active TODO file before the final report.
