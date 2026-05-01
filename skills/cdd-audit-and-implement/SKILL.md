---
name: cdd-audit-and-implement
description: "Convert audit bullets into implementation-ready TODO steps, then implement the first dependency-ordered step (two approvals, explicit-only)."
disable-model-invocation: true
---

# CDD Audit + Implement (explicit-only)

Turn an audit list into small TODO steps, apply them, then immediately implement the first chosen step.

## Interactive planning contract
Planning in this skill is interactive, review-driven, and continuously refined.

- Start in planning mode when the runtime supports a native read-only or plan mode. If it does not, emulate that behavior by staying read-only until the user approves applying the plan.
- Review the codebase before and during planning. Audit the relevant code, tests, entrypoints, configs, and current TODO surfaces so the TODO plan reflects the real implementation state.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths. Do not ask preference questions that do not materially affect the plan.
- Ask at most one substantive clarification or decision question per message.
- Keep refining the execution plan as new evidence appears. After each user answer or new repo finding, update boundaries, sequencing, assumptions, and proof requirements before continuing.
- For qualifying requests that are multi-surface, ambiguous, or likely to produce more than one TODO step, first produce coarse dependency-ordered root-cause work packages before detailed TODO drafting.
- For those qualifying requests, refine one coarse root-cause work package at a time into runnable TODO steps rather than jumping straight from normalized audit bullets to a full mixed-surface detailed plan.
- Add a visible `Confirmed requirements coverage` section that records which user requirements were confirmed, which were excluded by user decision or repo fit, and where each confirmed requirement is represented in the plan.
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

## Audit normalization rules
Do not convert raw audit bullets directly into TODO tasks.

- Normalize each audit item into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- Collapse duplicate symptoms into the smallest root-cause work package that can be implemented and validated cleanly.
- Preserve dependency order: prerequisite contract or plumbing changes should appear before downstream UI, storage, export, or cleanup work.
- Generated execution steps must satisfy the same implementation-ready standard as `cdd-plan`: `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, and `UAT` for non-trivial work, or equivalent sections if the repo already uses a richer local template.

## Flow (two approvals)

### A) Plan
1) Read `AGENTS.md`, `README.md`, the active `TODO*.md`, the relevant specs, and the relevant codebase surfaces.
   - Review the current implementation before planning: affected modules, entrypoints, tests, manifests, configs, and recent TODO context.
   - Identify likely root causes, impacted boundaries, and proof surfaces for the audit items.
2) Ask for the audit items (inline bullets or a file path + section).
3) Before drafting TODO steps, identify only the blocking or plan-shaping clarifications that would materially change assumptions, goals, implementation paths, grouping, file placement, sequencing, or approval boundaries.
4) Ask clarifying questions one at a time using the interaction contract above.
5) If any material assumption would remain after the answers, list only those material assumptions and ask the user to confirm or correct them before continuing.
6) If only minor defaults remain, disclose them briefly in the plan and proceed without blocking.
7) Normalize the audit items:
   - identify the user-visible symptom, likely root cause, affected boundary, and proof needed for each item
   - tag each item as `spec_delta`, `implementation_delta`, `verification_delta`, or `defer`
   - merge duplicates and split mixed-surface findings before drafting steps
8) For qualifying requests, first produce coarse dependency-ordered root-cause work packages before detailed TODO drafting.
   - Use this mode only when the request is multi-surface, ambiguous, or likely to produce more than one TODO step.
   - Keep audit normalization and duplicate-collapsing intact; the coarse pass should organize normalized root-cause work, not bypass that analysis.
   - Include a visible `Confirmed requirements coverage` section before asking for approval.
9) Before drafting TODO edits, present 2-3 plan shapes when there is a real grouping, sequencing, or write-location decision to make.
   - Recommend one option based on the codebase review and normalized audit results.
   - Include the write-location choice in the same option set when possible:
     - default: update an existing TODO file
     - alternative: create `TODO-audit-<tag>.md`
   - Keep the options at the bottom of the message under `**Options**`, with selector-prefixed labels such as `A.`, `B.`, `C.`.
   - Ask for a short tag only if the user chose the new-file option.
10) Group the normalized items into 1–N implementation-ready TODO steps using the repo’s existing Step template.
    - For qualifying requests, refine one coarse root-cause work package at a time into runnable TODO steps rather than jumping straight from normalized audit bullets to a full mixed-surface detailed plan.
    - Keep the plan KISS and CDD-style: minimal diffs, no invented structure, and as many dependency-ordered steps as the confirmed scope requires.
11) Ask: **Approve and apply the TODO plan?**
12) Apply the approved plan.

### B) Implement
13) Ask which newly created step should be implemented now using the same bottom-positioned, selector-prefixed guided options; recommend the first runnable new step by default.
    Prefer dependency order and prerequisite work when choosing that recommendation.
    The selected implementation option serves as the explicit approval to start that step immediately.
    Include a clear stop-after-plan option.
14) If the user chooses the stop-after-plan option, stop and report the next recommended step.
15) If the user chooses a step, implement that step immediately using the same workflow as `$cdd-implement-todo`.
