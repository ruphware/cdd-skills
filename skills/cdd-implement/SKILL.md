---
name: cdd-implement
description: "Implement exactly one bounded task under the repo's AGENTS.md rules, revise the delta for overlap and residue, run its checks, close out in TODO-backed or direct mode, and hand off a UAT checklist tagged by who can cover each item (interactive)."
---

# CDD Implement (interactive)

Implement exactly one bounded task in the target repo per invocation: a TODO step when one exists, otherwise one explicit non-TODO task. Runtime loops such as `/goal` or `/workflows` may re-invoke the skill once per step; the skill itself never batches.

Never invent product, architecture, sequencing, or validation decisions while implementing. A task that is not decision-complete after minimal normalization goes to `cdd-plan` first.

## Supported task sources
- One TODO step in `TODO.md` or `TODO-*.md`; the preferred path.
- One approved audit finding package small and bounded enough to skip a planning pass.
- One pasted task item, issue text, or ticket text already present in the prompt or repo.
- Never fetch live tracker content or integrate with external task managers here.

## Task normalization and escalation
- A TODO step is underspecified only when it lacks `Tasks`; other sections such as `Automated checks` and `UAT` are optional. Patch only the selected step, and only as far as a minimal clarification makes its tasks runnable.
- For a non-TODO task, extract a compact implementation frame: target boundary, expected behavior or contract, key constraints, validation evidence.
- Normalize only small local gaps in place: tighten wording, make validation concrete, or write a runnable TODO step when the user picks the TODO-backed path.
- Escalate to `cdd-plan` when minimal normalization still leaves multiple hard gates, migration or rollback boundaries, distinct subsystems, or unresolved product, architecture, sequencing, or validation decisions.
- For `add to TODO and implement`, write the normalized task into the active TODO surface as one runnable step in the repo's step template, adding only what makes it decision-complete, before any code edit; the run then closes out in TODO-backed mode. Default to `TODO.md` unless several TODO files are plausible targets or none exists.

## Interaction contract
- End every decision message with repo-local `NEXT` when defined, otherwise `**Options**`: question, any reply hint, then choices. All other content comes before this block; nothing follows the final choice.
- Start every option label with a lettered selector, including in native UIs (`A.`, `B.`, …); nested selectors retain the parent letter (`A1.`, `A2.`, `B1.`). Examples do not set the option count. When practical, say the user can reply with just the selector.
- The selected option itself is the approval; never append a separate free-form approval question.
- Source-appropriate option sets:
  - bounded non-TODO task: `A. implement directly`, `B. add to TODO and implement`, `C. run cdd-plan first`, `D. keep it read-only and revise first`
  - underspecified TODO step: `A. apply the minimal TODO patch and implement`, `B. apply the minimal TODO patch only`, `C. run cdd-plan first`, `D. keep the task read-only and revise first`
  - UAT handoff after closeout: `run the self-coverable UATs now`, `hand every UAT to the user`, lettered after any commit suggestion the repo's `NEXT` format places first

## Implementation rules
- Before any code edit, read the target repo's `AGENTS.md` and internalize its implementation rules as binding for the run: role and scope, core rules, KISS guardrails, code-structuring rules, logging conventions, Definition of Done, and per-turn output format.
- Restate under `CONSTRAINTS` only the rules that shape this task, such as a file LOC target, the log line template, or the ban on stripping debug lines; never echo the whole document.
- Where `AGENTS.md` is missing or silent, follow the repo's observable conventions (tooling, formatters, test framework, naming, layout), then CDD defaults: KISS, single responsibility per file, composition over inheritance, one-line docstring plus minimal example per public interface. Never remove tests or logs unless the task says so.
- Keep the diff minimal: touch only files the task names or clearly requires. Add no caps, guards, retries, or abstraction layers the task does not call for; a new limit needs a proven risk named in the task.
- Anything noticed outside the task boundary goes under `OPINION` in the final report, never into the diff.

## Revision pass
- Once the main implementation is done and before the final check run, review the working-tree diff plus the code it touches as a reviewer would, for four things:
  - `overlap`: new code duplicating a helper, utility, type, or path the repo already has. Use the existing one; extend it only when the task needs a small generalization.
  - `net complexity`: abstractions, parameters, branches, or files beyond what the task needed. Remove forward-only indirection, flatten single-use layers, fold special cases into one path.
  - `duplicated paths`: two paths now doing one job, old and new or two new variants. Keep the one general path that covers the task's cases; retire the other.
  - `residue`: unrequested debug output, dead branches, unused imports or parameters, stale comments or docstrings, orphaned tests, configs, fixtures, or temp files.
- Revise towards smaller, more general code: fewer lines and fewer special cases for the same behavior. Generalize only across cases the task actually has.
- Stay inside the task boundary: the delta and the code it directly touches. Pre-existing overlap or residue elsewhere goes under `OPINION`.
- One pass, then stop. Stop earlier when a further cut would change behavior the task did not ask for or needs a decision the task did not make; record what was left and why.
- Report under `EXECUTION` what was merged, flattened, or deleted with approximate LOC removed, or `revision pass: no change` plus one sentence of evidence.

## Completion semantics
- TODO-backed mode, on success: mark the selected step's `Tasks` done and nothing else. Flip `[ ]` to `[x]`; rewrite plain bullets into checked checkboxes, preserving text and order. Add no `Status:` field or other completion marker. Never touch other steps.
- Never mark a step done after failed implementation or checks.
- Direct mode: no TODO writeback and no fabricated TODO artifact or completion record; the final report is the closeout.
- Journal, only for non-trivial changes per `AGENTS.md`: `docs/JOURNAL.md` in single-journal mode; in split-journal mode the `docs/journal/JOURNAL-<area>.md` matching the step's `TODO-<area>.md`, with `docs/journal/JOURNAL.md` reserved for repo-wide or cross-cutting notes. Write each entry in exactly one file.

## UAT handoff
- After closeout, list every UAT item as a checklist in original wording and order: the step's `UAT` section when it has one, otherwise the validation its tasks imply; in direct mode, the frame's validation evidence. Add an item only for behavior the implementation introduced that the list misses, and say so.
- Tag each item: `self` when repo-local tools can produce the evidence (run a command or test, read a file or output, diff a rendered artifact, exercise a CLI or API locally); `user` when it needs human judgment or access the agent lacks (visual or UX acceptance, product fit, external systems, credentials, real devices, production data); `partial` when the agent can do the mechanical half and the user must judge the rest, naming the split.
- For each `self` item name the exact command, check, or read, so one reply approves the batch. Cite evidence the checks already produced where it covers an item; run the rest only after the user selects that option.
- Agent-covered items are evidence, not acceptance: the user still confirms acceptance tests per the Definition of Done. Report each covered item with what ran and what was observed; never mark a `user` item done.

## Flow
1) Read `AGENTS.md` first and internalize its implementation guidance; then `README.md`, active `TODO*.md` files, and whatever the task source needs.
2) Find the task: the named TODO step (`8`, `08`, and `008` are the same step) or the one pasted item. One match: proceed without reconfirmation. Several matches or several items: ask the user to pick one.
3) Normalize small gaps or escalate to `cdd-plan`; present the source-appropriate options before any edit.
4) Implement all of the step's tasks with minimal diffs.
5) Revise the delta for overlap, net complexity, duplicated paths, and residue.
6) Run the step's automated checks or the repo-native checks and meet the DoD. Any edit after a green run re-runs the checks. Fix failures inside the task boundary and re-run; when a failure needs a decision the task did not make, stop, mark nothing, and report the failing output and the decision needed.
7) Close out: mark the step's tasks done in TODO-backed mode, report only in direct mode, journal when non-trivial.
8) List the UATs tagged `self`, `user`, or `partial`, with the evidence you would produce for each `self` item.
9) Report in the `AGENTS.md` output format: source task, files changed, checks run, and revision outcome under `EXECUTION`; which `TODO*.md` step was updated, or that direct mode had no writeback; the UAT checklist and its options under `NEXT`.

## Resolution examples
- `$cdd-implement` with one pasted, already bounded ticket: offer `implement directly`, `add to TODO and implement`, `run cdd-plan first`, or `revise first`.
- `$cdd-implement` with an approved audit finding package spanning several boundaries: offer `cdd-plan` instead.
- Revision pass finds the new parser duplicates an existing `parse_step_id` helper: delete the copy, call the helper, report the LOC removed, note the helper's own quirks under `OPINION`.
- A step whose UAT says "run the validator" and "confirm the rendered diagram reads well": tag the first `self` with the exact command, the second `user`, and offer to run the first.
