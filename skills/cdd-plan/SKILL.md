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

## Edge-case review
For behavior-changing or audit-derived implementation planning, do not move from codebase review straight to TODO drafting.

- Run an explicit repo-grounded edge-case review after inspecting the relevant code, docs, tests, entrypoints, configs, manifests, and current TODO surfaces.
- Keep a visible `Edge-case review` section in qualifying plans, but keep it concise and limited to repo-grounded cases that materially affect plan shape, interfaces, data/state, rollout, or validation.
- Collapse duplicate or closely related edge cases into the smallest root decision that can be planned cleanly.
- For each edge case, record:
  - the affected boundary
  - why it matters
  - whether it is `major` or `minor`
- `Major` means the edge case could materially change subsystem boundaries, APIs/contracts, data/state model, user-visible behavior, rollout/migration path, or validation strategy.
- `Minor` means the edge case can be handled by a recommended implementation default without changing the plan shape.
- If a `major` edge case remains unresolved after review, ask one clarifying question about it at a time before finalizing the plan.
- Keep major-edge clarifying questions grounded in actual codebase findings and framed as real plan-shaping decisions rather than preference polls.
- When several unresolved `major` edge cases remain, ask the highest-leverage question first: prefer the one whose answer resolves the most downstream plan, boundary, sequencing, or validation uncertainty.
- When multiple `major` edge cases collapse to one underlying decision, ask one combined clarification instead of separate repetitive questions.
- Each major-edge clarification should state the current recommended direction and what part of the plan would change if the answer differs.
- Do not re-ask a question already answered by the user, already resolved by codebase evidence, or already covered by an accepted plan default.
- If only `minor` edge cases remain, keep them non-blocking and carry the recommended default into assumptions, constraints, implementation notes, automated checks, or UAT instead of asking a clarification question.
- If the review finds no meaningful repo-grounded edge cases, say so briefly and continue without inventing generic ones.

## Interactive planning contract
Planning in this skill is interactive, review-driven, and continuously refined.

- Start in planning mode when the runtime supports a native read-only or plan mode. If it does not, emulate that behavior by staying read-only until the user approves applying the plan.
- Review the codebase before and during planning. Audit the relevant code, docs, tests, entrypoints, configs, and current TODO surfaces so the plan is grounded in the actual implementation, not just the docs or user prompt.
- For behavior-changing or audit-derived implementation requests, run the repo-grounded edge-case review before detailed TODO drafting.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths. Do not ask preference questions that do not materially affect the plan.
- Ask at most one substantive clarification or decision question per message.
- Prefer the fewest clarification questions that resolve the most plan-shaping uncertainty.
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

## Question economy
Minimize clarification loops.

- Before asking any clarification, rank unresolved decisions by how much downstream uncertainty they remove.
- Prefer questions that affect boundaries, sequencing, interfaces, data/state, rollout, validation, or approval safety.
- Do not ask about reversible implementation details, naming/copy polish, file placement already implied by repo conventions, defaults that can be safely documented in the TODO step, preferences that do not change plan shape, or questions already answered by the user, repo evidence, or an accepted default.
- Default clarification budget:
  - small/local change: 0-1 questions
  - multi-surface change: 1-2 questions
  - audit, migration, security, external contract, or destructive change: up to 3 questions
- If more than 3 clarifications appear necessary, stop expanding the question list. Present the best bounded plan so far, mark unresolved major decisions, recommend the next single decision, and proceed only through selector-based options.

## Flow (approval-gated, bounded-bisection)
1) Frame the request.
   - Read the repo contract files plus the relevant docs/specs, TODO surfaces, affected code, tests, entrypoints, configs, and manifests.
   - Reduce the request to one concise frame:
     - deliverable
     - hardest constraint
     - success signal
   - If the change request or audit finding is not clear enough to frame, ask one clarification before continuing.
   - Do not draft TODO edits before the request has a concrete frame.
2) Shape the plan.
   - Create a plan that is rough, solved, and bounded:
     - `rough`: do not over-specify reversible implementation details
     - `solved`: remove ambiguity that would force the implementer to invent product, architecture, sequencing, or validation decisions
     - `bounded`: state what is in scope, what is out of scope, and where the work stops
   - Identify affected boundaries, risks, dependency order, validation surfaces, and likely write locations.
   - For behavior-changing or audit-derived requests, run the repo-grounded edge-case review before detailed TODO drafting.
   - For audit-driven requests, normalize audit items before drafting TODO steps.
3) Bisect uncertainty.
   - List unresolved plan-shaping decisions privately before asking the user anything.
   - Ask only the highest-leverage unresolved decision first.
   - A clarification is allowed only when the answer would materially change product or architecture boundaries, data/state, contracts or APIs, file/write location, sequencing, approval boundaries, migration/rollback/rollout, security/privacy/permission behavior, validation strategy, or an unresolved `major` edge case.
   - Collapse related open questions into the fewest root decisions possible.
   - If only minor defaults or `minor` edge cases remain, disclose them briefly and carry them into assumptions, constraints, implementation notes, automated checks, or UAT.
   - If a remaining material assumption would invalidate the plan, create unsafe or destructive work, or materially change boundaries, sequencing, contracts, data/state, rollout, or validation, ask one highest-leverage clarification. Otherwise, disclose it in the plan and carry it into the relevant TODO step.
4) Produce the coarse plan.
   - For requests that are multi-surface, ambiguous, audit-driven, or likely to produce more than one TODO step, produce a coarse dependency-ordered decomposition before detailed TODO drafting.
   - Keep the coarse pass lightweight but concrete enough to validate:
     - boundaries
     - dependency order
     - coverage
     - reviewed artifacts
     - unresolved major decisions
     - validation surfaces
   - Include visible sections when applicable:
     - `Frame`
     - `Recommended shape`
     - `Confirmed requirements coverage`
     - `Reviewed contract artifacts`
     - `Audit normalization`
     - `Edge-case review`
     - `Coarse dependency-ordered steps`
     - `Material assumptions`
   - When those sections apply, show `Confirmed requirements coverage` and `Reviewed contract artifacts` before approval.
   - Before drafting TODO edits, present 2-3 plan shapes only when there is a real grouping, sequencing, scope, or write-location decision to make.
   - For audit-driven requests, include the write-location choice in the same option set when practical:
     - default: update an existing TODO file
     - alternative: create `TODO-audit-<tag>.md`
   - Ask for a short tag only if the user chose the new-file option.
5) Refine one coarse step.
   - After the coarse plan is accepted or the next step is clear, refine only the next coarse step into one or more runnable TODO steps.
   - Do not jump straight to a full mixed-surface detailed plan when the work is multi-step.
   - When the work is already a single clearly bounded next step, refine that step directly without forcing a coarse decomposition pass.
   - For each new or revised execution step, produce an implementation-ready TODO contract using the repo’s existing Step template when possible.
   - Each runnable TODO step must include enough product, architecture, sequencing, and validation detail that the implementer does not need to reopen PRD/Blueprint or surrounding chat to fill gaps.
   - Keep exact implementation-driving detail in `TODO.md` or the selected TODO file.
6) Apply, hand off, and audit.
   - Present final selector-based apply options instead of a second approval question.
   - When a clear next execution step exists, prefer exactly three selectors:
     - `A. apply now and continue with the recommended next step`
     - `B. apply now only`
     - `C. keep the plan read-only and revise before applying`
   - If no immediate follow-on step is clear, still use 2-4 selector-based apply/revise/stop options.
   - The selected option itself is the approval.
   - After applying, suggest implementing the next approved TODO step via `$cdd-implement-todo`.
   - After implementation, validation, or audit reveals new evidence, return to this planning flow only for newly discovered plan-shaping deltas.
