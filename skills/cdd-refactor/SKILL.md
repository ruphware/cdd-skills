---
name: cdd-refactor
description: "Turn refactor candidates in docs/INDEX.md into a TODO refactor plan (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Refactor (explicit-only)

Turn refactor candidates in `docs/INDEX.md` into a small, checkable TODO plan.

## Candidate sources
- `docs/INDEX.md` file inventory rows tagged `refactor-candidate` (when present)
- Any explicit refactor notes already in `docs/INDEX.md` or `TODO*.md`

## Refactor step contract
For any new or rewritten refactor step, produce an implementation-ready step rather than a placeholder cleanup note.

- Preserve the repo's existing Step template when possible, but add missing sections when the current template would leave the step underspecified.
- Preferred section set for non-trivial work:
  - `Goal`
  - `Constraints`
  - `Tasks`
  - `Implementation notes`
  - `Automated checks`
  - `UAT`
- Each step should identify the exact boundary to refactor, the intended code health outcome, the must-preserve behavior, and the evidence needed to prove the refactor is safe.
- Split refactor work into separate steps when it crosses distinct boundaries, compatibility surfaces, migration risk, or independently testable subsystems.
- Keep the plan KISS: minimal steps, minimal diffs, no speculative cleanup.

## Interactive planning contract
Planning in this skill is interactive, review-driven, and continuously refined.

- Start in planning mode when the runtime supports a native read-only or plan mode. If it does not, emulate that behavior by staying read-only until the user approves applying the plan.
- Review the codebase before and during planning. Audit the relevant code, tests, entrypoints, configs, and current TODO surfaces so the refactor plan reflects the real implementation state.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths. Do not ask preference questions that do not materially affect the plan.
- Ask at most one substantive clarification or decision question per message.
- Keep refining the execution plan as new evidence appears. After each user answer or new repo finding, update boundaries, sequencing, assumptions, and proof requirements before continuing.
- Keep messages easy to scan: concise, no fluff, and use lightweight Markdown emphasis such as `**bold**` and `*italics*` when helpful. Do not depend on color.
- For every clarification or decision message, put the choices at the bottom under a final `**Options**` section:
  - offer 2-4 concrete options grounded in the repo context
  - put the recommended option first and mark it clearly
  - keep each option short and action-oriented
  - avoid open-ended options unless a free-form value is truly required

## Flow (approval-gated)
1) Read `AGENTS.md`, `README.md`, `docs/INDEX.md`, the active `TODO*.md`, relevant specs, and the relevant codebase surfaces.
   - Review the current implementation before planning: affected modules, entrypoints, tests, manifests, configs, and existing TODO context.
   - Confirm whether each refactor candidate still appears current, reachable, and worth planning.
2) Extract and normalize candidate items:
   - identify the affected boundary, likely code smell or risk, must-preserve behavior, and proof surface for each candidate
   - merge duplicates and drop stale or unsupported candidates rather than planning speculative work
3) Before drafting TODO steps, identify only the blocking or plan-shaping clarifications that would materially change assumptions, goals, implementation paths, grouping, file placement, sequencing, or approval boundaries.
4) Ask clarifying questions one at a time using the interaction contract above.
5) If any material assumption would remain after the answers, list only those material assumptions and ask the user to confirm or correct them before continuing.
6) If only minor defaults remain, disclose them briefly in the plan and proceed without blocking.
7) Before drafting TODO edits, present 2-3 plan shapes when there is a real grouping, sequencing, or write-location decision to make.
   - Recommend one option based on the codebase review and normalized refactor candidates.
   - Include the write-location choice in the same option set when possible:
     - default: create `TODO-refactor-<tag>.md`
     - alternative: update an existing TODO file
   - Keep the options at the bottom of the message under `**Options**`.
   - Ask for a short tag only if the user chose the new-file option.
8) Draft a small, implementation-ready step plan using the repo’s existing Step template.
9) Ask: **Approve and apply these changes?**
10) Apply the approved plan and, if applicable, link it from `TODO.md` if the repo maintains an index section.
