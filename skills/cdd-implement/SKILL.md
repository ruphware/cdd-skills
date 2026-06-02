---
name: cdd-implement
description: "Implement exactly one bounded task, run its checks, close it out through TODO-backed or direct mode as appropriate, and return a UAT checklist (interactive)."
---

# CDD Implement (interactive)

Implement exactly one bounded task in the target repo. Prefer a TODO-backed step when one exists, but support one explicit non-TODO task when that task is already available in the prompt or repo.

Do not invent missing product, architecture, sequencing, or validation decisions during implementation. If the selected task is not decision-complete and cannot be normalized locally into one bounded unit, route it through `cdd-plan` first.

## Supported task sources
- One TODO step in `TODO.md` or `TODO-*.md` files. This is the preferred path.
- One approved audit finding package that is already small and bounded enough to implement without a planning pass.
- One pasted task list item, issue text, or ticket text that is already available in the prompt or repo.
- If multiple candidate items remain, stop and ask the user to pick exactly one bounded task.
- Do not fetch live tracker content or integrate with external task managers in this skill.

## Task normalization and escalation
- Resolve the task source before asking anything else.
- For TODO-backed tasks, preserve the repo's existing step-resolution behavior and patch only the selected step when a minimal clarification makes it runnable.
- For non-TODO tasks, extract a compact implementation frame: target boundary, expected behavior or contract, key constraints, and validation evidence.
- Normalize only small local gaps in place. Acceptable normalization includes tightening wording, making validation concrete, or writing a runnable TODO step when the user chooses the TODO-backed path.
- If minimal normalization still leaves multiple hard gates, migration or rollback boundaries, distinct subsystems, or unresolved product, architecture, sequencing, or validation decisions, stop and offer `cdd-plan`.
- When a non-TODO task is already bounded and decision-complete after normalization, present selector-based options for:
  - `A. implement directly`
  - `B. add to TODO and implement`
  - `C. run cdd-plan first`
  - `D. keep it read-only and revise first`
- For `add to TODO and implement`, write the normalized task into the active TODO surface first as one runnable TODO step that matches the repo's step contract before any code edits begin. Reuse the repo's step template when possible and add only the missing sections or detail needed to make that step decision-complete. Default to the active `TODO.md` unless multiple TODO files are plausible targets or no TODO surface exists yet.

## Interaction contract
- Resolve ambiguity and approval boundaries with selector-based options under a final `**Options**` section.
- Prefix every option label with a visible selector so plan-mode UIs still expose a selectable key. Default to `A.`, `B.`, `C.`; use numbers only when surrounding context is already numeric.
- When practical, tell the user they can reply with just the selector.
- When a minimal normalization patch is required before implementation, the selected option itself is the approval; do not append a separate free-form approval question.
- Prefer source-appropriate options:
  - for a bounded non-TODO task: `A. implement directly`, `B. add to TODO and implement`, `C. run cdd-plan first`, `D. keep it read-only and revise first`
  - for an underspecified TODO step: `A. apply the minimal TODO patch and implement`, `B. apply the minimal TODO patch only`, `C. run cdd-plan first`, `D. keep the task read-only and revise first`

## Completion semantics
- TODO-backed mode:
  - If implementation and checks pass, update only the selected step in the active `TODO*.md` file to show its Tasks are done.
  - If the step's `Tasks` section already uses markdown checkboxes, change unchecked task items from `[ ]` to `[x]`.
  - If the step's `Tasks` section uses plain bullets, rewrite only those task bullets into checked markdown checkboxes while preserving the task text and order.
  - Do not add a new step-level `Status:` field or any other completion marker.
  - Do not mark the TODO step done if implementation or checks failed.
  - Do not modify future or unrelated steps.
- Direct mode:
  - Do not fabricate a TODO artifact or synthetic completion record on success.
  - The final report must name the exact source task, the files changed, the checks run, and the UAT evidence.
  - If the user chose `add to TODO and implement`, that run switches into TODO-backed mode only after the normalized task is written into the TODO surface as a runnable TODO step.
- Update the matching journal file only when changes are non-trivial, per `AGENTS.md`.
  - In single-journal mode, update `docs/JOURNAL.md`.
  - If the selected task is in `TODO-<area>.md`, treat matching `docs/journal/JOURNAL-<area>.md` as the default hot journal in split-journal mode.
  - In split-journal mode, use `docs/journal/JOURNAL.md` only for repo-wide or cross-cutting notes.
  - Do not duplicate the same journal entry across multiple journal files.

## Flow
1) Read `AGENTS.md`, `README.md`, active `TODO*.md` files when present, and any files needed for the chosen task source.
2) Resolve the requested task before asking anything:
   - If the user explicitly names a TODO step (for example `step 8`, `step 08`, `step 008`, or an exact step heading), search `TODO.md` and `TODO-*.md` and normalize numeric step identifiers so `8`, `08`, and `008` are equivalent.
   - If exactly one TODO step matches, treat that step as authoritative and continue immediately without asking for confirmation.
   - If the source text contains multiple candidate findings or task items, ask the user to choose exactly one bounded item before continuing.
   - Ask only when the task source is ambiguous or cannot be resolved from the user's request.
3) Normalize or escalate before implementing:
   - Treat a TODO step as underspecified when it is missing `Tasks`, `Automated checks`, or `UAT`, or when those sections still omit the concrete target boundary, required behavior change, cross-surface sequencing, or validation proof.
   - For non-TODO tasks, normalize only enough to make one bounded implementation frame. If that frame still needs planning-shaped decisions, offer `cdd-plan` instead of coding.
   - If the user chooses `add to TODO and implement`, materialize that frame as one runnable TODO step before any code edits begin.
   - When a non-TODO task is bounded and decision-complete, present the direct-vs-TODO-vs-plan selector options before implementing.
4) Implement the selected task with minimal diffs.
5) Run the task's listed `Automated checks`, repo-native checks, or other concrete validation promised by the normalized task frame.
   - Follow the repo's `AGENTS.md` DoD before closing the task out.
6) Apply the appropriate completion semantics:
   - TODO-backed mode updates only the selected TODO step on success.
   - Direct mode closes out through the final report only.
7) Final report format: follow the target repo's `AGENTS.md` "Output Format Per Turn".
   - Explicitly state which `TODO*.md` file and step were updated, or explicitly state that the task completed in direct mode with no TODO writeback.

## Resolution examples
- `$cdd-implement step 008` + one matching Step 08 in the repo: implement immediately, no reconfirmation.
- `$cdd-implement step 008` + matches in `TODO.md` and `TODO-foo.md`: present selector-based choices for the matching TODO file or exact heading.
- `$cdd-implement` with one pasted ticket that is already bounded: offer `implement directly`, `add to TODO and implement`, `run cdd-plan first`, or `revise first`.
- `$cdd-implement` with an approved audit finding package that still spans multiple boundaries: offer `cdd-plan` instead of direct implementation.
- A matched TODO step missing `Tasks`, `Automated checks`, or `UAT`: present selector-based options for the minimal TODO patch needed to make the step executable.
- A direct task that passes implementation and checks: close it out in the final report without fabricating TODO completion state.
