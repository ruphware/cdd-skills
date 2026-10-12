---
name: cdd-plan
description: "Plan change requests or external audit findings into implementation-ready TODO steps by asking one key clarification first and reviewing audit remediation options (interactive, approval-gated)."
---

# CDD Plan (interactive, approval-gated)

Use this skill for change requests and externally supplied audit findings that should become implementation-ready TODO steps before implementation begins.

Treat the target repo's CDD contract files as the source of truth:
- `AGENTS.md`
- `README.md`
- `TODO.md` (and/or `TODO-*.md`)
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/INDEX.md` (if present; also `docs/index/**` siblings when INDEX split is active)

## External source handling
- Resolve user-named external issues, tickets, PRs, RFCs, docs, or tracker references via available read-only surfaces: connectors, CLIs, local remotes, pasted URLs, and identifiers.
- Before intent framing, the first substantive clarification, audit normalization, edge-case review, or plan options, read each in-scope external artifact's complete thread: title/body/description, all comments, review comments when present, and material directly referenced artifacts. Do not recursively crawl unrelated links.
- Treat the latest authoritative comment or decision as current intent; flag superseded body requirements.
- If the reference or source of truth is ambiguous enough to change the plan shape, write target, or validation strategy, ask one clarifying question.
- If the artifact, comments, or material references cannot be fetched after a reasonable read-only attempt, mark plan coverage partial, name the unread surfaces, and do not promote uncovered requirements as confirmed.
- Never post, update, label, assign, or otherwise mutate external systems during planning; apply only repo-local plan/TODO edits after user approval.

## Runnable TODO step contract

A runnable step is decision-complete: the implementer can execute it without reopening PRD/Blueprint or surrounding chat to discover missing product, architecture, sequencing, or validation decisions.

- Preserve the repo's existing Step template when possible; add missing sections only when the current template would leave the step underspecified.
- Preferred section set for non-trivial work: `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, `UAT`.
- Each `Tasks` bullet must name the target boundary or subsystem, the exact change to make, the output artifact/contract/behavior that must result, and any must-preserve invariant or evidence requirement when relevant.
- Use `Implementation notes` for file/symbol hints, interface or schema changes, ordering constraints, migration notes, snapshot/audit requirements, and other coding-critical detail that would otherwise be lost in a short task list.
- Do not leave essential implementation detail only in the surrounding chat — put it in the TODO step.
- Do not write new caps, truncations, timeouts, retries, or config knobs into a step without a proven trust, resource, external-deadline, or liveness risk with a named owner and defined reached behavior; prefer explicit failure, streaming, pagination, or backpressure over speculative caps — most values stay unbounded.
- Split work into separate steps when it crosses distinct hard gates, migration boundaries, rollback surfaces, or independently testable subsystems, or when its `points:` would exceed 8.

## Plan output style

Plans are high-entropy: every sentence must carry decisions, constraints, or evidence.

- Lead with facts and instructions; cut decorative prose, restated context, and filler transitions.
- Prefer compact structures over paragraphs: tables for option comparisons, short bullets for rules, fenced blocks for exact step text.
- Use ASCII diagrams when structure helps — dependency order, data/control flow, boundary maps, ladders. Skip diagrams for linear or trivial shapes.
- Apply this style to both chat-visible plan output and written `TODO*.md` step text.
- Style must not weaken decision-completeness: the `Runnable TODO step contract` section set and detail requirements stay unchanged; compress wording, never decisions.
- Scannability rules from `Interactive planning contract` still apply; plans may stay long when scope requires it.

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

## Audit-input normalization

Do not convert raw audit bullets directly into TODO tasks.

- Normalize each audit item into one or more of: `spec_delta`, `implementation_delta`, `verification_delta`, `defer`.
- Identify the user-visible symptom, likely root cause, affected boundary, and proof needed for each normalized item.
- Collapse duplicate symptoms into the smallest root-cause work package that can be implemented and validated cleanly.
- Preserve dependency order: prerequisite contract or plumbing changes appear before downstream UI, storage, export, or cleanup work.
- Inspect the relevant docs (`README.md`, `docs/specs/*`) and corresponding tests or validation surfaces; do not audit code in isolation when doc or test drift is part of the finding.
- Keep audit-derived steps at the same implementation-ready standard as any other `cdd-plan` output.

## Clarification floor and architecture options

Do not let `cdd-plan` go straight from repo review to TODO drafting.

- Every `cdd-plan` run must ask one substantive clarification or decision question before emitting a finished runnable TODO step or applying plan edits.
- That first question must target the highest-leverage unresolved direction, boundary, architecture, sequencing, or validation choice, not wording polish, repo-implied file placement, or another reversible detail.
- For audit-derived planning, default the first question to remediation shape after repo review and audit normalization: compare 2-3 concrete implementation options, recommend one, and explain what changes if the user picks differently.
- When audit findings touch architecture or cross multiple boundaries, review the likely affected boundaries, main trade-offs, and where each option would stop before proposing TODO edits.
- Rank options toward the simplest shape that preserves correct ownership: reuse existing seams and repo prior art before adding a new layer, registry, or wrapper; keep an abstraction only when it owns policy or state, isolates a real dependency, or removes proven repetition.
- If repo constraints leave only one viable architecture, still surface it as a real user choice: accept the recommended path, narrow scope, or defer. Repo evidence alone is not user approval.
- The clarification floor is satisfied only by a question that could materially change the plan. A rhetorical summary, pure apply approval, or yes/no restatement of settled facts does not count.

## Edge-case review

For behavior-changing or audit-derived planning, do not move from codebase review straight to TODO drafting.

- Run an explicit repo-grounded edge-case review after inspecting relevant code, docs, tests, entrypoints, configs, manifests, and current TODO surfaces.
- Keep a visible `Edge-case review` section in qualifying plans — concise, limited to repo-grounded cases that materially affect plan shape, interfaces, data/state, rollout, or validation.
- For each edge case, record: affected boundary, why it matters, `major` or `minor`.
  - `Major` = could change subsystem boundaries, APIs/contracts, data/state model, user-visible behavior, rollout/migration, or validation strategy.
  - `Minor` = handled by a recommended implementation default without changing plan shape.
- Collapse duplicate or closely related edge cases into the smallest root decision.
- For unresolved `major` edges, apply the loop rule from `Interactive planning contract`, highest-leverage edge first; each clarification states the current recommended direction and what part of the plan would change if the answer differs.
- If only `minor` edges remain, carry the recommended default into assumptions, constraints, implementation notes, automated checks, or UAT instead of asking.
- If no meaningful repo-grounded edges exist, say so briefly and continue.

## Intent and assumption checkpoint

Resolve intent and material assumptions before detailed implementation planning.

- Before detailed implementation questions, TODO drafting, or plan-shape selection, build an intent frame from the user request, repo contract files, and reviewed repo evidence.
- Intent frame fields: `Requested change`, `Suspected intent`, `Deliverable`, `Hardest constraint`, `Success signal`, `Non-goals`, `Material assumptions`, `Recommended direction`, `Unstable points`.
- Challenge a material assumption when it could change the actual problem being solved, the user-visible outcome, product/architecture boundaries, what is in scope or out of scope, the sequencing of work, whether the work should be implemented/deferred/audited/converted into a spec or TODO delta, validation or UAT requirements, or risk/rollback/migration/privacy/security/permission behavior.
- If intent is unclear, ask one intent-level clarification first. Do not use implementation-detail questions to substitute for intent resolution.
- If intent is stable but assumptions remain, classify each material assumption as `confirmed`, `repo-inferred`, `recommended default`, `risky`, or `excluded`. Only `risky` assumptions block planning by themselves. A `recommended default` may be written straight into the TODO step only when choosing differently would not create a live `Open decisions` item; otherwise keep the choice visible and present the repo-backed default as the recommended option.

## Open decisions queue

Make remaining plan-shaping choices visible before final TODO drafting.

- After the intent frame and repo-grounded review stabilize the request, surface unresolved plan-shaping choices in a visible `Open decisions` section before emitting a finished runnable TODO step.
- Use this queue only for unresolved choices where a different answer would materially change product or architecture boundaries, storage or contract shape, permission posture, rollout or compatibility posture, validation strategy, or the exact stop point of the step.
- A repo-backed recommendation is not closure. `repo-inferred` and `recommended default` justify the recommended option, but they do not close a live plan-shaping decision by themselves.
- Close a decision only by explicit user instruction, a hard repo constraint, or because the remaining difference is a true minor default that does not change plan shape.
- For each open decision, record: short label, affected boundary, why it matters, current recommended option, and status.
- Status values:
  - `asking now` = the single highest-leverage open decision for this message
  - `queued` = still unresolved, visible to the user, but not asked yet
- Keep the queue compact. Collapse duplicates into the smallest root decision and exclude reversible implementation details, naming, copy, or file-placement questions implied by repo conventions.
- If no plan-shaping open decisions remain, say so briefly and continue.

## Interactive planning contract

- Start in planning mode when the runtime supports a native read-only or plan mode. Otherwise stay read-only until the user approves applying the plan.
- Review the codebase before and during planning. Audit relevant code, docs, tests, entrypoints, configs, and current TODO surfaces so the plan is grounded in the actual implementation, not just docs or user prompt.
- Follow the intent and assumption checkpoint before detailed implementation questions, TODO drafting, or plan-shape selection.
- For behavior-changing or audit-derived requests, run the repo-grounded edge-case review before detailed TODO drafting.
- Treat clarification as a way to resolve the right assumptions, goals, and implementation paths; satisfy `## Clarification floor and architecture options` before drafting a finished runnable TODO step or applying plan edits.
- **One question per message, in a loop.** Ask at most one substantive clarification per message. After each user answer, re-rank remaining unresolved decisions and ask the next single highest-leverage question, then wait again. Never list multiple open questions in one message as a checklist for the user to answer at once.
- Visibility is broader than questioning. When multiple plan-shaping decisions remain, show them in `Open decisions`, mark one `asking now`, and leave the rest `queued`; do not ask them all at once.
- Prefer the fewest clarifications that resolve the most plan-shaping uncertainty.
- Keep refining as new evidence appears. After each answer or new finding, update boundaries, sequencing, assumptions, and validation requirements before continuing.
- Treat a request as `intent-qualifying` when it is behavior-changing, ambiguous, multi-surface, audit-driven, or likely to need more than one TODO step. For these, add a compact visible `Intent and assumptions` section covering requested change, suspected intent, success signal, recommended direction, material assumptions by status, non-goals, and any blocking intent question.
- For audit-derived requests, include a visible `Architecture / implementation options` section before final TODO drafting whenever multiple viable remediation shapes exist or the choice changes boundaries, sequencing, or validation.
- For ambiguous, multi-surface, audit-driven, or multi-step requests, start with a coarse dependency-ordered decomposition, then refine one coarse step at a time. Do not jump straight to a full mixed-surface detailed plan.
- During coarse planning, review user-provided contract/content/implementation-driving artifacts and expand them into the plan. Apply `External source handling` to external issues, tickets, PRs, RFCs, docs, or tracker references before treating them as confirmed planning input. Keep exact implementation-driving detail in `TODO.md`, not in surrounding chat. If a reviewed artifact mixes product and implementation detail, keep implementation detail in `TODO.md` and add explicit `TODO.md` follow-up for the spec/doc update unless a durable spec delta is intentionally being drafted now.
- Add visible `Confirmed requirements coverage` (which requirements were confirmed, which were excluded, where each lives in the plan) and `Reviewed contract artifacts` (each artifact marked `copied as-is`, `corrected`, `expanded`, `removed`, or `left intentionally unspecified`, short reason for material change, write location) sections when applicable.
- Only carry forward confirmed requirements that fit the repo.
- Plans may be long when scope requires it. Do not over-compress just to stay minimal. Keep messages scannable: concise, no fluff, lightweight Markdown emphasis such as `**bold**` and `*italics*` when helpful. Do not depend on color.

### Options block

End every decision message with repo-local `NEXT` when defined, otherwise `**Options**`: question, any reply hint, then choices. All other content comes before this block; nothing follows the final choice.

- 2-4 concrete options grounded in repo context; recommended first and marked.
- Start every option label with a lettered selector, including in native UIs (`A.`, `B.`, …); nested selectors retain the parent letter (`A1.`, `A2.`, `B1.`). Examples do not set the option count.
- Keep options short and action-oriented. Avoid open-ended options unless a free-form value is truly required.
- When practical, tell the user they can reply with just the selector.
- The selected option itself is the approval; do not append a separate free-form approval question.
- When a clear next execution step exists, prefer exactly three final options:
  - `A. apply now and continue with the recommended next step`
  - `B. apply now only`
  - `C. keep the plan read-only and revise before applying`

## Question economy

- Decision-ranking ladder (ask higher first):
  1. intent and outcome
  2. material assumptions and non-goals
  3. planning direction
  4. product and architecture boundaries
  5. data/state/contracts/APIs
  6. sequencing, rollout, migration, rollback, validation
  7. implementation details
- Do not ask a lower-level question while a higher-level unresolved decision could still invalidate it.
- A clarification is allowed only when the answer would materially change product/architecture boundaries, data/state, contracts/APIs, file/write location, sequencing, approval safety, migration/rollback/rollout, security/privacy/permission behavior, validation strategy, or an unresolved `major` edge case.
- Do not ask about reversible implementation details, naming/copy polish, file placement implied by repo conventions, defaults that can be safely documented in the TODO step, preferences that do not change plan shape, or questions already answered by the user, repo evidence, or an accepted default.
- Default clarification budget: every `cdd-plan` run asks 1 substantive question minimum; small/local change 1 question; multi-surface change 1-2 questions; audit, migration, security, external contract, or destructive change 1-3 questions.
- If more than 3 clarifications appear necessary, stop expanding. Present the best bounded plan so far, keep the remaining `Open decisions` visible, mark unresolved major decisions, recommend the next single decision, and proceed only through selector-based options.

## Planning anti-patterns

- Asking implementation-detail questions before the intent is clear.
- Treating the user's first wording as the confirmed intent when repo evidence suggests another interpretation.
- Converting an audit bullet directly into implementation work before identifying symptom, root cause, proof needed, and intended outcome.
- Letting audit-derived planning skip architecture review or the first substantive decision question because a repo-backed default looks plausible.
- Asking about file placement, naming, UI copy, endpoint shape, schema fields, or test mechanics before resolving whether the work is a feature, bugfix, refactor, audit fix, spec delta, investigation, or defer.
- Producing a detailed TODO step that encodes an unchallenged assumption as fact.
- Emitting a finished TODO step while plan-shaping `Open decisions` remain hidden or unresolved.
- Expanding scope because an implementation path is obvious before confirming the expansion serves the intent.
- Using many small detail questions to avoid asking one hard direction question.
- Listing multiple open clarification questions in one message instead of following the one-question loop.
- Planning speculative caps, guards, wrappers, or abstraction layers "just in case" instead of tying each to a proven risk or a real consumer.

## Flow (approval-gated, bounded-bisection)

1) Frame intent before details.
   - Read repo contract files plus relevant docs/specs, TODO surfaces, code, tests, entrypoints, configs, and manifests — only far enough to stabilize intent, the existing contract, and the likely affected surfaces.
   - Do not deep-dive into reversible implementation choices before intent is stable.
   - Build the intent frame per `Intent and assumption checkpoint`. If it cannot yet be built, ask one intent-level clarification first.
   - Do not draft TODO edits until the request has a concrete frame.

2) Shape the planning direction.
   - Aim for a plan that is `rough` (do not over-specify reversible details), `solved` (remove ambiguity that would force the implementer to invent product/architecture/sequencing/validation decisions), and `bounded` (state what is in scope, out of scope, where work stops).
   - Choose the primary planning direction: `feature`, `bugfix`, `audit_fix`, `spec_delta`, `refactor`, `maintenance`, `investigation`, or `defer`. If ambiguous and the choice would change boundaries, sequencing, or validation, ask one direction-level clarification.
   - Identify affected boundaries, risks, dependency order, validation surfaces, and likely write locations.
   - Run the edge-case review (behavior-changing or audit-derived requests) and audit normalization (audit-driven requests) before detailed TODO drafting.
   - Before moving on, prepare the first required clarification. For audit-derived requests, prefer an architecture or remediation-shape question with concrete options and a recommended path.

3) Bisect uncertainty before detailed drafting.
   - List unresolved plan-shaping decisions privately, tagging each as `intent`, `assumption`, `direction`, `boundary`, `implementation`, or `validation`.
   - Resolve `intent`, `assumption`, and `direction` uncertainty before `boundary`, `implementation`, or detailed `validation` questions unless a safety constraint forces otherwise.
   - Turn remaining plan-shaping decisions into a visible `Open decisions` queue per `## Open decisions queue` before final TODO drafting.
   - Apply the loop rule from `Interactive planning contract` and the ladder/budget from `Question economy`.
   - The first asked decision must satisfy the clarification floor. For audit-derived requests with more than one viable remediation shape, that first asked decision should usually be the architecture or implementation-shape choice, with 2-3 concrete options and a recommended default.
   - Safety override: if a remaining material assumption would invalidate the plan, enable unsafe or destructive work, or materially change boundaries/sequencing/contracts/data-state/rollout/validation, ask one highest-leverage clarification before moving on, regardless of the question budget.
   - If only minor defaults or `minor` edge cases remain, disclose them briefly and carry them into assumptions, constraints, implementation notes, automated checks, or UAT.
   - When clarifications complete (no blocking decisions left or budget exhausted), move to step 4 and disclose any remaining unresolved items in the plan.

4) Produce the coarse plan.
   - For ambiguous, multi-surface, audit-driven, or multi-step requests, produce a coarse dependency-ordered decomposition. Keep it lightweight but concrete enough to validate boundaries, dependency order, coverage, reviewed artifacts, unresolved major decisions, and validation surfaces.
   - Include visible sections when applicable: `Frame`, `Recommended shape`, `Intent and assumptions`, `Confirmed requirements coverage`, `Reviewed contract artifacts`, `Audit normalization`, `Architecture / implementation options`, `Edge-case review`, `Open decisions`, `Coarse dependency-ordered steps`, `Material assumptions`. Show `Confirmed requirements coverage` and `Reviewed contract artifacts` before approval when present.
   - Present 2-3 plan shapes only when there is a real grouping, sequencing, scope, or write-location decision.
   - For audit-driven requests, include the write-location choice in the same option set when practical: default — update an existing TODO file; alternative — create `TODO-audit-<tag>.md` (ask for the tag only if the new-file option is chosen).

5) Refine one coarse step.
   - After the coarse plan is accepted or the next step is clear, refine only the next coarse step into one or more runnable TODO steps. Do not jump straight to a full mixed-surface detailed plan when the work is multi-step.
   - When the work is already a single clearly bounded next step, refine that step directly without forcing a coarse decomposition pass.
   - Do not emit a finished runnable TODO step while a plan-shaping `Open decisions` item remains unresolved unless the user explicitly resolves or accepts it, or the clarification budget is exhausted and the plan keeps that unresolved item visible instead of pretending the step is decision-complete.
   - For each new or revised execution step, produce an implementation-ready TODO contract per `Runnable TODO step contract`.

6) Apply, hand off, and audit.
   - Present final selector-based apply options per the `Options block` subsection of `Interactive planning contract`; when no immediate follow-on step is clear, still use 2-4 selector-based apply/revise/stop options.
   - After applying, hand off to `$cdd-implement` (model-invocable) to implement the next approved TODO step.
   - Return to this planning flow only for newly discovered plan-shaping deltas after implementation, validation, or audit.
