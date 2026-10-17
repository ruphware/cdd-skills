---
name: cdd-plan
description: "Plan change requests or external audit findings into implementation-ready TODO steps by asking one key clarification first and reviewing audit remediation options (interactive, approval-gated)."
---

# CDD Plan (interactive, approval-gated)

Source of truth: the target repo's CDD contract files `AGENTS.md`, `README.md`, `TODO*.md`, `docs/specs/prd.md`, `docs/specs/blueprint.md`, and, when present, `docs/INDEX.md` and `docs/index/**`.

## Interactive planning contract

- Use the runtime's read-only or plan mode if any; otherwise stay read-only until the user approves applying, then apply only repo-local plan and TODO edits.
- Ask at most one substantive question per message. After each answer, re-rank what remains and ask the next highest-leverage question; never list several open questions as a checklist.
- End every decision message with repo-local `NEXT` when `AGENTS.md` defines one, otherwise `**Options**`: question, any reply hint, then choices; nothing follows the final choice.
- Label every choice with a lettered selector, also in native option UIs (`A.`, `B.`, …; nested `A1.`, `A2.`); put the recommended choice first and mark it; say the user may reply with the selector alone. The selected option is the approval; never append a separate approval question.
- Offer 2-4 short, action-oriented, repo-grounded choices; open-ended only when a free-form value is required. With a clear next execution step use exactly these three, otherwise apply, revise, or stop choices:
  - `A. apply now and continue with the recommended next step`
  - `B. apply now only`
  - `C. keep the plan read-only and revise before applying`
- After applying, hand the next approved step to `$cdd-implement` (model-invocable); return here only for plan-shaping deltas newly found in implementation, validation, or audit.
- Ground the plan in code, docs, tests, entrypoints, configs, manifests, and TODO surfaces, reviewed before and during planning. Before the intent frame, read only enough to stabilize intent, the existing contract, and the affected surfaces.
- Name affected boundaries, risks, dependency order, assumptions, validation surfaces, and write locations; update them after each answer or finding.
- Ambiguous, multi-surface, audit-driven, or multi-step requests go coarse first: a lightweight dependency-ordered decomposition that checks boundaries, order, coverage, reviewed artifacts, open major decisions, and validation surfaces. Once it is accepted or the next step is clear, refine only that step into runnable steps. A single bounded step is refined directly. Offer 2-3 plan shapes only for a real grouping, sequencing, scope, or write-location choice.
- During coarse planning, expand user-provided contract, content, or implementation-driving artifacts into the plan, keeping only confirmed requirements that fit the repo. When an artifact mixes product and implementation detail, the implementation detail goes into `TODO.md` with a follow-up step for the spec or doc update, unless a durable spec delta is drafted now.
- Visible plan sections, when applicable: `Frame`, `Recommended shape`, `Intent and assumptions`, `Confirmed requirements coverage` (confirmed and excluded requirements, where each lives), `Reviewed contract artifacts` (each `copied as-is`, `corrected`, `expanded`, `removed`, or `left intentionally unspecified`, with reason for material change and write location), `Audit normalization`, `Architecture / implementation options` (audit-derived, when remediation shapes compete or the choice moves boundaries, sequencing, or validation), `Edge-case review`, `Open decisions`, `Coarse dependency-ordered steps`, `Material assumptions`; coverage and artifacts come before approval.

## Clarification floor and architecture options

- Every `cdd-plan` run must ask one substantive clarification or decision question before emitting a finished runnable TODO step or applying plan edits.
- The first question targets the highest-leverage unresolved direction, boundary, architecture, sequencing, or validation choice; rhetorical summaries, pure apply approval, and yes/no restatements of settled facts do not satisfy the floor.
- For audit-derived planning, default the first question to remediation shape after repo review and audit normalization: compare 2-3 concrete implementation options, recommend one, and explain what changes if the user picks differently; for architecture-touching or cross-boundary findings, cover affected boundaries, trade-offs, and each option's stop point.
- Rank options toward the simplest shape with correct ownership: reuse existing seams and prior art before a new layer, registry, or wrapper; keep an abstraction only if it owns policy or state, isolates a real dependency, or removes proven repetition.
- A single viable architecture is still a user choice: accept it, narrow scope, or defer.

## Intent and assumption checkpoint

- Before detailed implementation questions, TODO drafting, or plan-shape selection, build an intent frame from the request, contract files, and reviewed repo evidence.
- Frame fields: `Requested change`, `Suspected intent`, `Deliverable`, `Hardest constraint`, `Success signal`, `Non-goals`, `Material assumptions`, `Recommended direction` (one of `feature`, `bugfix`, `audit_fix`, `spec_delta`, `refactor`, `maintenance`, `investigation`, `defer`), `Unstable points`.
- If intent is unclear, including when repo evidence suggests another reading of the user's first wording, ask one intent-level clarification first, not implementation-detail questions.
- Challenge a material assumption that could change the problem, user-visible outcome, product/architecture boundaries, scope, sequencing, whether to implement, defer, audit, or convert to a spec or TODO delta, validation/UAT, or risk/rollback/migration/privacy/security/permission behavior.
- With intent stable, classify each remaining material assumption as `confirmed`, `repo-inferred`, `recommended default`, `risky`, or `excluded`; only `risky` blocks planning by itself. A `recommended default` goes straight into the step only if a different choice would not create a live `Open decisions` item; otherwise keep the choice visible with the default recommended.
- Expand scope only once the expansion is confirmed to serve the intent, however obvious the path.
- `Intent-qualifying` requests (behavior-changing, ambiguous, multi-surface, audit-driven, or likely multi-step) show a compact `Intent and assumptions` section: the frame fields, assumptions by status, and any blocking intent question.

## Open decisions queue

- After the intent frame and repo review stabilize the request, surface unresolved plan-shaping choices in a visible `Open decisions` section before emitting a finished runnable TODO step.
- Queue only choices where a different answer would materially change product/architecture boundaries, storage/contract shape, permission posture, rollout/compatibility posture, validation strategy, or the step's exact stop point.
- A repo-backed recommendation is not closure: `repo-inferred` and `recommended default` justify the recommended option but never close a live decision alone.
- Close a decision only by explicit user instruction, a hard repo constraint, or a remaining difference that is a true minor default leaving plan shape unchanged.
- Record per decision, collapsing duplicates into the smallest root decision: short label, affected boundary, why it matters, recommended option, status:
  - `asking now` = the single highest-leverage open decision for this message
  - `queued` = still unresolved, visible to the user, but not asked yet
- Visibility is broader than questioning: show every remaining decision, mark one `asking now`, leave the rest `queued`.
- Do not emit a finished runnable TODO step while a plan-shaping `Open decisions` item remains unresolved unless the user explicitly resolves or accepts it, or the clarification budget is exhausted and the plan keeps it visible instead of pretending the step is decision-complete.
- If none remain, say so briefly and continue.

## Question economy

- Rank open decisions privately on this ladder; never ask a lower-level question while a higher-level one could still invalidate it:
  1. intent and outcome
  2. material assumptions and non-goals
  3. planning direction
  4. product and architecture boundaries
  5. data/state/contracts/APIs
  6. sequencing, rollout, migration, rollback, validation
  7. implementation details
- Ask only when the answer would materially change product/architecture boundaries, data/state, contracts/APIs, file/write location, sequencing, approval safety, migration/rollback/rollout, security/privacy/permissions, validation, or an unresolved `major` edge case.
- Never ask about reversible implementation details, naming/copy polish, convention-implied file placement, defaults safely documentable in the step, preferences that leave plan shape unchanged, or anything already answered by the user, repo evidence, or an accepted default.
- Prefer the fewest questions that remove the most uncertainty; one hard direction question beats many detail ones.
- Budget: small/local change 1 question; multi-surface 1-2; audit, migration, security, external contract, or destructive change 1-3.
- Safety override, regardless of ladder or budget: when a remaining material assumption would invalidate the plan, enable unsafe or destructive work, or materially change boundaries, sequencing, contracts, data/state, rollout, or validation, ask one highest-leverage clarification first.
- Past 3 needed clarifications, stop expanding: present the best bounded plan so far, mark unresolved major decisions, and recommend the next single decision.

## Edge-case review

- For behavior-changing or audit-derived planning, run a repo-grounded edge-case review after the repo review and before detailed TODO drafting; keep its section concise, limited to cases that materially affect plan shape, interfaces, data/state, rollout, or validation.
- Record per edge case: affected boundary, why it matters, and `major` (could change subsystem boundaries, APIs/contracts, data/state model, user-visible behavior, rollout/migration, or validation strategy) or `minor` (handled by a recommended implementation default without changing plan shape). Collapse duplicate or related cases into the smallest root decision.
- Ask about unresolved `major` edges through the one-question loop; each question states the recommended direction and which part of the plan changes if the answer differs.
- Carry each `minor` edge's recommended default into assumptions, constraints, implementation notes, automated checks, or UAT instead of asking.
- If none exist, say so briefly and continue.

## Audit-input normalization

- Never convert raw audit bullets directly into TODO tasks. Normalize each item into one or more of `spec_delta`, `implementation_delta`, `verification_delta`, `defer`, naming its user-visible symptom, likely root cause, affected boundary, intended outcome, and proof needed.
- Collapse duplicate symptoms into the smallest root-cause work package that can be implemented and validated cleanly.
- Preserve dependency order: prerequisite contract or plumbing changes precede downstream UI, storage, export, or cleanup work.
- Check each finding against the relevant docs (`README.md`, `docs/specs/*`) and tests or validation surfaces; never audit code alone when doc or test drift is part of the finding.
- Offer the write location in the same option set when practical: default, update an existing TODO file; alternative, `TODO-audit-<tag>.md` (ask for the tag only if chosen).

## External source handling

- Resolve user-named issues, tickets, PRs, RFCs, docs, or tracker references read-only, via connectors, CLIs, local remotes, pasted URLs, or identifiers.
- Before intent framing, the first substantive clarification, audit normalization, edge-case review, or plan options, read each in-scope artifact's complete thread: body, all comments, review comments, directly referenced artifacts; do not crawl unrelated links. The latest authoritative comment is current intent; flag superseded body requirements.
- Ask one clarifying question when the reference or source of truth is ambiguous enough to change the plan shape, write target, or validation strategy.
- When a surface cannot be fetched after a reasonable read-only attempt, mark coverage partial, name the unread surfaces, and do not promote unread requirements as confirmed.
- Never post, update, label, assign, or otherwise mutate external systems.

## Runnable TODO step contract

Every step is decision-complete: the implementer never reopens PRD/Blueprint or chat to find missing product, architecture, sequencing, or validation decisions. Plans are also `rough` (reversible details left open) and `bounded` (scope, non-scope, and stop point stated).

- Keep the repo's Step template, adding sections only where it would leave the step underspecified; preferred set for non-trivial work: `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, `UAT`.
- Each `Tasks` bullet names the target boundary or subsystem, the exact change, the resulting artifact/contract/behavior, and any must-preserve invariant or evidence requirement.
- `Implementation notes` carry file/symbol hints, interface or schema changes, ordering constraints, migration notes, snapshot/audit requirements, and other coding-critical detail; essential detail never lives only in chat.
- Write no new cap, truncation, timeout, retry, or config knob into a step without a proven trust, resource, external-deadline, or liveness risk, a named owner, and a defined reached behavior; prefer explicit failure, streaming, pagination, or backpressure over speculative caps — most values stay unbounded.
- Split a step when it crosses distinct hard gates, migration boundaries, rollback surfaces, or independently testable subsystems, or when its `points:` would exceed 8.

## Step annotations

Every emitted TODO step carries grep-friendly lines directly under its `## Step N` heading, before the first H3.

- `points: <1 | 2 | 3 | 5 | 8 | 13 | 21 | >21>` on every step: complexity points on the Fibonacci story-point scale, never time, sized by the planner without asking the user.
- `touches: <comma-separated path globs or boundary names>` on every step of a multi-step plan: the files, globs, or boundaries the step is expected to write.
- `deps: <comma-separated step ids>` only when a hard ordering edge exists, to step ids in the same TODO file; a step without the line has no edge, so never write `deps: none`. Cross-file dependencies are out of scope and force serial execution.
- Two steps are disjoint only when neither lists the other in `deps:` and their `touches:` sets share no file, glob overlap, or named boundary. A step with no `touches:` line is a serial barrier: it is treated as touching everything.
- Unannotated TODO files always run serial; annotations are additive and never change the meaning of an existing serial run.

Points measure four dimensions: shape (how many owners change and whether one is new), contract (none, private, additive, or a new port or durable format), proof (what evidence closes the step), and unknowns (what is still open when the step is written). A step takes the highest level any dimension reaches.

| Points | Shape | Contract | Proof | Unknowns |
|---|---|---|---|---|
| 1 | one site | none | existing test or one assertion | none |
| 2 | one owner, a few sites | private shape | one focused test | none |
| 3 | one path through existing seams, or one doc family | internal shape | focused tests in one or two scopes | decisions taken |
| 5 | one path with regenerated artifacts, or several paths in one subsystem | additive change to an existing contract | several test scopes | shape known, many sites |
| 8 | a new owner or mechanism | new port or behavior, or a durable format with a rollback path | acceptance beyond unit tests | design decisions remain |
| 13 | several new mechanisms, or one behavior across runtimes or surfaces | new durable records | acceptance across surfaces | several open decisions |
| 21 | a program phase | several of the above | acceptance matrix | the design is still being settled |
| >21 | a program | not sized | not sized | plan it into phases before delegating any of it |

- 13 and 21 size phases, not steps: split before delegation unless a hard gate makes the work indivisible. Never write a number above 21.
- Count consumers, not lines: a deletion behind one seam is small however large the file.
- Docs-only work tops out at 3: width does not raise it, judgment per section does.
- An investigate-first gate that may close the step without code does not raise the size; one that decides which owner or contract moves does.
- Points are spent at implementation: a step left with only UAT boxes has 0 remaining; its `points:` line is not edited.
- A repo calibrates this scale in its TODO family or a repo-local skill with anchor steps per level and corrections to a dimension; that calibration wins over this table, while the levels and the line format never change.

## Plan output style

Plans are high-entropy: every sentence must carry decisions, constraints, or evidence.

- Lead with facts and instructions; no decorative prose, restated context, or filler transitions.
- Prefer compact structures: tables for option comparisons, short bullets for rules, fenced blocks for exact step text.
- Use ASCII diagrams when structure helps (dependency order, data/control flow, boundary maps, ladders), not for linear or trivial shapes.
- Apply it to chat plans and `TODO*.md` step text alike, never weakening the `Runnable TODO step contract`: compress wording, never decisions.
- Plans may be long when scope requires it; never over-compress to stay minimal. Keep messages scannable: light Markdown emphasis (`**bold**`, `*italics*`) when helpful, no reliance on color.

## Flow

1. Frame intent — `Intent and assumption checkpoint`
2. Shape direction — `Edge-case review`, `Audit-input normalization`, `Clarification floor and architecture options`
3. Bisect uncertainty — `Question economy`, `Open decisions queue`
4. Coarse plan — `Interactive planning contract`
5. Refine one step — `Runnable TODO step contract`, `Step annotations`
6. Apply and hand off — `Interactive planning contract`
