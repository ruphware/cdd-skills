---
name: cdd-plan
description: "Plan change requests or external audit findings into implementation-ready TODO steps (approval-gated, explicit-only)."
disable-model-invocation: true
---

# CDD Plan (explicit-only)

Use this skill for change requests and externally supplied audit findings that should become implementation-ready TODO steps before implementation begins.

Treat the target repo’s CDD contract files as the source of truth:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/INDEX.md` (if present)

## Runnable TODO step contract
For any new or rewritten execution step, produce an implementation-ready step rather than a placeholder summary.

- Preserve the repo's existing Step template when possible, but add missing sections when the current template would leave the step underspecified.
- Preferred section set for non-trivial work:
  - `Goal`
  - `Constraints`
  - `Tasks`
  - `Implementation notes`
  - `Automated checks`
  - `UAT`
- A runnable step is decision-complete: the implementer can execute it without reopening PRD/Blueprint to discover missing product, architecture, sequencing, or validation decisions.
- Each `Tasks` bullet must name:
  - the target boundary or subsystem
  - the exact change to make
  - the output artifact, contract, or behavior that must result
  - any must-preserve invariant or evidence requirement when relevant
- Use `Implementation notes` for file/symbol hints, interface or schema changes, ordering constraints, migration notes, snapshot/audit requirements, and other coding-critical detail that would otherwise be lost in a short task list.
- Do not leave essential implementation detail only in the surrounding chat. Put it in the TODO step.
- Split work into separate steps when it crosses distinct hard gates, migration boundaries, rollback surfaces, or independently testable subsystems.

## Audit-input normalization
Do not convert raw audit bullets directly into TODO tasks.

- For audit-driven requests, normalize each audit item into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- Identify the user-visible symptom, likely root cause, affected boundary, and proof needed for each normalized item.
- Collapse duplicate symptoms into the smallest root-cause work package that can be implemented and validated cleanly.
- Preserve dependency order: prerequisite contract or plumbing changes should appear before downstream UI, storage, export, or cleanup work.
- Inspect the relevant docs (`README.md`, `docs/specs/*`) and the corresponding tests or validation surfaces; do not audit code in isolation when doc or test drift is part of the finding.
- Keep audit-derived execution steps at the same implementation-ready standard as any other `cdd-plan` output.

## Interactive planning contract
Planning in this skill is interactive, review-driven, and continuously refined.

- Start in planning mode when the runtime supports a native read-only or plan mode. If it does not, emulate that behavior by staying read-only until the user approves applying the plan.
- Review the codebase before and during planning. Audit the relevant code, docs, tests, entrypoints, configs, and current TODO surfaces so the plan is grounded in the actual implementation, not just the docs or user prompt.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths. Do not ask preference questions that do not materially affect the plan.
- Ask at most one substantive clarification or decision question per message.
- Keep refining the execution plan as new evidence appears. After each user answer or new repo finding, update boundaries, sequencing, assumptions, and validation requirements before continuing.
- For qualifying requests that are multi-surface, ambiguous, or likely to produce more than one TODO step, first produce a coarse dependency-ordered step decomposition before detailed TODO drafting.
- For those qualifying requests, refine one coarse step at a time into runnable TODO steps rather than jumping straight to a full mixed-surface detailed plan.
- During the coarse planning phase, review any user-provided contract details, content details, and other implementation-driving artifacts, expand them into the plan, and keep exact implementation-driving detail in `TODO.md` rather than leaving it only in surrounding chat.
- If a reviewed artifact is a mixed product and implementation detail surface, keep the exact implementation-driving detail in `TODO.md` and add explicit `TODO.md` follow-up for the relevant spec/doc update unless a durable spec delta is intentionally being drafted now.
- Add a visible `Confirmed requirements coverage` section that records which user requirements were confirmed, which were excluded by user decision or repo fit, and where each confirmed requirement is represented in the plan.
- Add a visible `Reviewed contract artifacts` section that identifies the user-provided artifacts, marks each as `copied as-is`, `corrected`, `expanded`, `removed`, or `left intentionally unspecified`, gives a short reason for each material change, and records where each artifact was written.
- Only carry forward confirmed requirements that make sense for the repo.
- Plans may be long and include many steps when the confirmed scope requires it. Do not over-compress the plan just to stay minimal.
- Keep messages easy to scan: concise, no fluff, and use lightweight Markdown emphasis such as `**bold**` and `*italics*` when helpful. Do not depend on color.
- For every clarification or decision message, put the choices at the bottom under a final `**Options**` section:
  - offer 2-4 concrete options grounded in the repo context
  - put the recommended option first and mark it clearly
  - prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key
  - default to letters: `A.`, `B.`, `C.`
  - use numbers only when the surrounding context is already numeric and that would be clearer
  - keep each option short and action-oriented
  - avoid open-ended options unless a free-form value is truly required
  - when practical, tell the user they can reply with just the selector
- When a draft plan is ready for application, use the final repo-local `NEXT` section when `AGENTS.md` defines one; otherwise use a final `**Options**` section.
- The selected option itself is the approval; do not append a separate free-form approval question after selector options.
- When a clear next execution step exists, prefer exactly three final options:
  - `A. apply now and continue with the recommended next step`
  - `B. apply now only`
  - `C. keep the plan read-only and revise before applying`

## Flow (approval-gated)
1) Read the contract files above, any linked sub-specs, and the relevant codebase surfaces.
   - Review the current implementation before planning: affected modules, entrypoints, tests, manifests, configs, relevant README/spec surfaces, and existing TODO steps.
   - Identify the likely boundaries, risks, and validation surfaces for the requested change.
2) Ask for the change request or audit items only if they are not already clear from the user prompt.
3) Before drafting edits, identify only the blocking or plan-shaping clarifications that would materially change assumptions, goals, implementation paths, file placement, sequencing, or approval boundaries.
4) Ask clarifying questions one at a time using the interaction contract above.
5) If any material assumption would remain after the answers, list only those material assumptions and ask the user to confirm or correct them before continuing.
6) If only minor defaults remain, disclose them briefly in the plan and proceed without blocking.
7) If the request is audit-driven, normalize the audit items before drafting TODO steps.
   - identify the user-visible symptom, likely root cause, affected boundary, and proof needed for each item
   - tag each item as `spec_delta`, `implementation_delta`, `verification_delta`, or `defer`
   - merge duplicates and split mixed-surface findings before detailed TODO drafting
8) For qualifying requests, first produce a coarse dependency-ordered step decomposition before detailed TODO drafting.
   - Use this mode only when the request is multi-surface, ambiguous, audit-driven, or likely to produce more than one TODO step.
   - Keep the coarse pass lightweight but concrete enough to validate boundaries, dependency order, coverage, and reviewed artifacts before detailed TODO drafting begins.
   - Include visible `Confirmed requirements coverage` and `Reviewed contract artifacts` sections before asking for approval.
9) Before drafting TODO edits, present 2-3 plan shapes when there is a real grouping, sequencing, or write-location decision to make.
   - Recommend one option based on the codebase review.
   - For audit-driven requests, include the write-location choice in the same option set when possible:
     - default: update an existing TODO file
     - alternative: create `TODO-audit-<tag>.md`
   - Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
   - Ask for a short tag only if the user chose the new-file option.
10) Draft proposed edits (grouped by file):
   - PRD/Blueprint deltas only if required
   - TODO step updates using the repo’s existing Step template
   - translate spec deltas into implementation deltas instead of restating product intent
   - for each new or revised execution step, include exact boundaries, interface or contract changes, sequencing notes, and validation evidence
   - for audit-driven requests, keep the normalized root-cause grouping, any required README/spec updates, corresponding tests, and proof surfaces explicit in the resulting TODO steps
   - keep exact implementation-driving detail in `TODO.md` and use explicit `TODO.md` follow-up for later spec/doc updates when mixed product/implementation artifacts are not becoming durable spec deltas now
   - add `Implementation notes` when the step would otherwise force the implementer to make decisions
   - for qualifying requests, refine one coarse step at a time into runnable TODO steps rather than drafting a single mixed-surface detailed plan in one jump
   - split oversized mixed-surface work into dependency-ordered steps
   - plans may be long and include many steps when the confirmed scope requires it
11) Present final selector-based apply options instead of a second approval question.
   - When a clear next execution step exists, prefer exactly three selectors: `A. apply now and continue with the recommended next step`, `B. apply now only`, `C. keep the plan read-only and revise before applying`.
   - If no immediate follow-on step is clear, still use 2-4 selector-based apply/revise/stop options.
12) After applying, suggest implementing the next step via `$cdd-implement-todo`.
