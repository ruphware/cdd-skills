# TODO


## Step 49 — Make cdd-plan enumerate edge cases and escalate only major clarifications

### Goal

Make `cdd-plan` explicitly review repo-grounded edge cases for behavior-changing or audit-derived implementation planning, list them in the plan, and turn only unresolved major edge cases into one clarifying question at a time before drafting final TODO edits.

### Constraints

- Keep this contract in `cdd-plan` only; do not widen `cdd-implementation-audit` in this step.
- Trigger the edge-case pass only for behavior-changing or audit-derived implementation plans, not simple docs, upkeep, or narrow mechanical refactors.
- `Major` means an edge case that could materially change subsystem boundaries, APIs/contracts, data/state model, user-visible behavior, rollout/migration path, or validation strategy.
- `Minor` edge cases must not block planning; carry them forward as recommended defaults, implementation notes, assumptions, constraints, automated checks, or UAT where appropriate.
- Preserve the existing one-substantive-question-per-message rule and selector-based decision flow.
- If no unresolved major edge cases remain after review, continue planning without extra clarification questions.

### Tasks

- [x] Update `skills/cdd-plan/SKILL.md` so the Interactive planning contract and Flow add an explicit planning-time edge-case review pass for behavior-changing or audit-derived implementation requests after codebase review and before detailed TODO drafting.
- [x] Require `skills/cdd-plan/SKILL.md` to produce a visible `Edge-case review` section in qualifying plans that lists repo-grounded edge cases, names the affected boundary, states why each case matters, and classifies each item as `major` or `minor`.
- [x] Require `skills/cdd-plan/SKILL.md` to escalate unresolved `major` edge cases into one clarifying question at a time before finalizing the plan, with each question grounded in actual codebase findings and framed as a real plan-shaping decision rather than a preference poll.
- [x] Require `skills/cdd-plan/SKILL.md` to keep `minor` edge cases non-blocking: state the recommended default handling in the plan itself and record it in assumptions, constraints, implementation notes, automated checks, or UAT instead of asking a clarification question.
- [x] Extend `scripts/validate_skills.py` so validation fails if the plan skill no longer requires the qualifying-request trigger, visible `Edge-case review` section, major-edge-case escalation rule, or non-blocking minor-default handling.

### Implementation notes

- Keep the edge-case pass codebase-grounded: derive edge cases from reviewed code, docs, tests, entrypoints, configs, manifests, and current TODO surfaces rather than generic brainstorming.
- Keep the classification compact: `major` versus `minor` is enough here; do not introduce audit-style severity buckets.
- Make the major-edge threshold explicit in the skill text:
  - `major` if it can materially change boundaries, contracts, data/state model, user-visible behavior, rollout/migration, or validation strategy
  - `minor` if it can be handled by a recommended implementation default without changing the plan shape
- Keep selector-based clarifying questions and the “selected option itself is the approval” rule unchanged.
- Prefer validator coverage in the default path where practical instead of hiding this contract only behind `--include-legacy-prose`.
- Touch only `skills/cdd-plan/SKILL.md` and `scripts/validate_skills.py` unless a failing check proves another surface is required.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `cdd-plan` skill and confirm behavior-changing or audit-derived implementation requests now require an explicit edge-case review before detailed TODO drafting.
- Confirm qualifying plan output requires a visible `Edge-case review` section with repo-grounded items classified as `major` or `minor`.
- Confirm unresolved `major` edge cases become one clarifying question at a time and only when they could materially change boundaries, contracts, data/state model, user-visible behavior, rollout/migration, or validation strategy.
- Confirm `minor` edge cases stay non-blocking and are carried into the plan as recommended defaults or implementation notes rather than becoming clarification questions.
- Confirm the validator fails if the qualifying-request trigger, `Edge-case review` section, major-edge escalation rule, or non-blocking minor-default rule is removed.

## Step 50 — Make cdd-implementation-audit ask only the highest-yield major audit questions

### Goal

Make `cdd-implementation-audit` surface edge-case and failure-path gaps in an audit-native way, collapse related ambiguities into root decisions, and ask only the highest-yield unresolved major audit question at a time before finalizing findings.

### Constraints

- Keep `cdd-implementation-audit` read-only and audit-only; do not drift into planning or TODO drafting.
- Do not add a planning-style standalone `Edge-case review` section.
- `Major` audit ambiguity means it could materially change whether a finding is real, its severity, its root-cause grouping, the affected boundary, or the recommended `cdd-plan` follow-up.
- Minor ambiguities should stay report-only unless they materially change the recommended follow-up.
- Preserve the existing one-substantive-question-per-message and selector-based decision flow.
- Do not re-ask a question already answered by the user, already resolved by repo evidence, or already covered by an accepted audit assumption.

### Tasks

- [x] Update `skills/cdd-implementation-audit/SKILL.md` so the Interaction contract and Flow require audit-time review of relevant edge-case and failure-path gaps when they materially affect audit conclusions, without introducing a separate planning-style section.
- [x] Require `skills/cdd-implementation-audit/SKILL.md` to collapse duplicate or closely related audit ambiguities into the smallest root decision that can be discussed cleanly before surfacing a question.
- [x] Require `skills/cdd-implementation-audit/SKILL.md` to ask the highest-leverage unresolved `major` audit question first, meaning the one whose answer resolves the most uncertainty about finding validity, severity, grouping, affected boundary, or recommended next path.
- [x] Require `skills/cdd-implementation-audit/SKILL.md` to keep major audit questions efficient:
  - combine multiple related ambiguities into one clarification when they share the same root decision
  - state the current recommended finding direction
  - state what audit conclusion would change if the answer differs
  - avoid preference polls
- [x] Require `skills/cdd-implementation-audit/SKILL.md` to keep minor ambiguities report-only by default and record them directly in findings, proof gaps, or follow-up notes instead of turning them into user questions.
- [x] Extend `scripts/validate_skills.py` so validation fails if the audit skill no longer requires root-decision collapse, highest-yield major-question ordering, non-repetition, or report-only handling for minor ambiguities.

### Implementation notes

- Keep this audit-native rather than planning-native:
  - `cdd-plan` asks plan-shaping questions
  - `cdd-implementation-audit` asks only when unresolved ambiguity would materially change the audit conclusion
- Acceptable audit ambiguity sources include:
  - missing or ambiguous failure-path intent
  - unclear contract expectations in docs or TODO steps
  - uncertainty about whether behavior is intentional versus a defect
  - uncertainty that changes severity or whether multiple symptoms are one root cause
- Keep the output compact: the skill does not need a standalone edge-case section as long as those gaps are folded into normalized findings and question selection.
- Touch only `skills/cdd-implementation-audit/SKILL.md` and `scripts/validate_skills.py` unless a failing check proves another surface is required.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated audit skill and confirm it stays read-only and audit-only while explicitly handling major edge-case and failure-path ambiguities.
- Confirm the updated audit skill collapses related ambiguities into root decisions instead of asking repetitive adjacent questions.
- Confirm the first audit clarification question is the highest-leverage unresolved major ambiguity rather than the first issue discovered.
- Confirm each major audit question states the current recommended finding direction and what audit conclusion would change if answered differently.
- Confirm minor ambiguities stay report-only unless they materially change the recommended follow-up.
- Confirm the validator fails if root-decision collapse, highest-yield question ordering, non-repetition, or report-only minor handling is removed.

## Step 51 — Make `cdd-maintain` index mode fully rebuild `docs/INDEX.md` from repo signals

### Goal

Make `cdd-maintain` `C. index` always regenerate `docs/INDEX.md` from a fresh repo scan that enumerates source files, counts LOC, extracts per-file keywords and meaning, combines those signals with docs/specs and framework-aware project metadata, and derives the index diagrams from that rebuilt model.

### Constraints

- Keep `index` mode write-scoped to `docs/INDEX.md` only.
- Full rebuild means `docs/INDEX.md` is output-only in this mode; do not reuse prior index prose or diagrams as semantic input.
- Require repo-local tool use to enumerate tracked source files and compute LOC, but do not freeze one specific command shape in the skill text.
- Treat `README.md`, `TODO*.md`, `docs/specs/*`, and project metadata files such as `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `mix.exs`, and `requirements*.txt` as supporting inputs when present.
- If docs/specs or project metadata are missing, continue with available repo signals and report the missing inputs rather than failing or inventing content.
- Validation must fail if the maintain contract regresses to incremental refresh or drops file enumeration, LOC counting, keyword extraction, metadata intake, or evidence-grounded diagram synthesis.

### Tasks

- [x] Update `skills/cdd-maintain/SKILL.md` Mode C so it explicitly requires a fresh, tool-driven scan of relevant tracked source files, tests, configs, manifests, and support-doc signals before generating `docs/INDEX.md`.
- [x] Require Mode C to build LOC plus per-file keyword/meaning inventory data and to synthesize the 2-4 GitHub-safe mermaid diagrams from the rebuilt repo model rather than stale `docs/INDEX.md` content.
- [x] Update `skills/cdd-maintain/agents/openai.yaml` if needed so the default maintain prompt reflects the new full-rebuild index contract instead of a generic refresh summary.
- [x] Extend `scripts/validate_skills.py` so validation fails if `cdd-maintain` index mode no longer requires full rebuild, repo-tool file enumeration, LOC counting, keyword/meaning extraction, manifest/spec-aware synthesis, graceful missing-input handling, and evidence-grounded diagram generation.

### Implementation notes

- Keep this step confined to the maintain contract and its proof surfaces; do not add a new standalone indexer unless a failing proof shows the skill text cannot carry the behavior cleanly.
- Preserve the existing `docs/INDEX.md` section/output contract unless a narrow validator update is required to support the stronger rebuild semantics.
- Because this repo currently has no `docs/` tree, the resulting contract should allow creating `docs/INDEX.md` from scratch during an approved index pass.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `skills/cdd-maintain/SKILL.md` and confirm Mode C now says `docs/INDEX.md` is fully rebuilt from current repo signals rather than refreshed from prior index content.
- Confirm Mode C now requires tool-driven source enumeration, LOC counting, and per-file keyword/meaning extraction.
- Confirm Mode C now uses docs/specs and framework-aware project metadata as diagram and architecture inputs when present.
- Confirm the validator fails if the full-rebuild, LOC, keyword, metadata, or diagram-synthesis rules are removed.

## Step 52 — Make cdd-plan frame requests, bisect uncertainty, and budget clarifications

### Goal

Make `cdd-plan` explicitly frame each request, follow an approval-gated bounded-bisection planning lifecycle, minimize clarification loops through a visible question-economy contract, and ask only one highest-leverage remaining clarification when a wrong assumption would invalidate or materially reshape the plan.

### Constraints

- Touch only `skills/cdd-plan/SKILL.md` and `scripts/validate_skills.py` unless a failing proof shows another surface is required.
- Preserve `cdd-plan` as read-only until approval, the one-substantive-question-per-message rule, and the existing selector-based final apply options.
- Replace the current “material assumptions...confirm or correct” gate rather than adding a second assumption-confirmation step.
- Do not force coarse decomposition for every request; the updated flow must still allow direct refinement of the next clear bounded step when the work is single-surface or otherwise obviously one-step.
- Keep the canonical editable source in `skills/cdd-plan/SKILL.md`; do not patch installed runtime copies under `~/.agents/`.

### Tasks

- [x] Update `skills/cdd-plan/SKILL.md` to rename the flow section to `## Flow (approval-gated, bounded-bisection)` and encode the six planning phases from the approved request: frame the request, shape the plan, bisect uncertainty, produce the coarse plan, refine one coarse step, and apply/hand off/audit.
- [x] Add a `## Question economy` section to `skills/cdd-plan/SKILL.md` that ranks unresolved decisions by uncertainty removed, limits clarifications to boundary/architecture/data-state/contract/sequencing/approval/rollout/security/validation or unresolved `major` edge cases, forbids questions about reversible details or safe defaults, sets the default clarification budgets, and requires surfacing the best bounded plan plus one next decision when more than three clarifications would otherwise be needed.
- [x] Replace the current material-assumption rule in `skills/cdd-plan/SKILL.md` so the skill asks one highest-leverage clarification only when a remaining assumption would invalidate the plan, create unsafe or destructive work, or materially change boundaries, sequencing, contracts, data/state, rollout, or validation; otherwise the assumption must be disclosed in the plan and carried into the resulting TODO step.
- [x] Extend `scripts/validate_skills.py` so validation requires the new bounded-bisection flow, question-economy contract, and replacement assumption logic, and fails if the old `confirm or correct them before continuing` loop or equivalent wording returns.

### Implementation notes

- Keep the existing Step 49 edge-case review contract and integrate the new question-economy rules around it instead of creating a competing clarification path.
- Prefer validator coverage in the default path (`python3 scripts/validate_skills.py`) rather than hiding the new rules behind `--include-legacy-prose` only.
- The new flow should make the coarse-plan trigger explicit for multi-surface, ambiguous, audit-driven, or likely multi-step requests, while also stating that a single clearly bounded next step can be refined directly.
- Leave `skills/cdd-plan/agents/openai.yaml` unchanged unless the validator or repo review proves the short description is now materially misleading.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `skills/cdd-plan/SKILL.md` and confirm the flow heading is now `Flow (approval-gated, bounded-bisection)` with all six lifecycle phases present.
- Confirm the updated skill includes a visible `Question economy` section with clarification priorities, prohibited low-value question types, and the default clarification budgets.
- Confirm the old material-assumption confirmation rule is replaced by the new “ask only when the remaining assumption would invalidate or materially reshape the plan” rule.
- Confirm the validator fails if the bounded-bisection flow, question-economy contract, or replacement assumption logic is removed, or if the old `confirm or correct them before continuing` wording returns.

## Step 53 — Restore per-finding approval in cdd-implementation-audit and sharpen audit closeout

### Goal

Make `cdd-implementation-audit` explicitly triage major findings for planning inclusion one at a time again, improve the code-audit signal so findings stay concrete and evidence-backed, and end audit runs with selector-labeled next actions that route approved findings into `cdd-plan`.

### Constraints

- Keep `cdd-implementation-audit` read-only and audit-only; do not drift into planning or implementation.
- Preserve the Step 50 ambiguity-handling improvements, but separate `ambiguity resolution` from `finding approval`: even when a major finding is already proven, it must still be surfaced to the user if it recommends planning follow-up.
- Preserve the existing root-cause collapse rule: when multiple symptoms or ambiguities clearly collapse into one root-cause finding, one combined approval decision is enough.
- Keep minor findings report-only by default unless they materially change the recommended follow-up.
- Preserve letter selectors as the canonical interaction surface across the skill pack.
- When approved findings exist, the final next-action bundle must make `A. run cdd-plan on the approved findings` the recommended first option.
- If no approved findings exist, do not recommend an empty `cdd-plan` invocation; offer non-planning selector options instead.
- Touch only `skills/cdd-implementation-audit/SKILL.md` and `scripts/validate_skills.py` unless a failing proof shows another surface is required.

### Tasks

- [x] Update `skills/cdd-implementation-audit/SKILL.md` so the Interaction contract and Flow clearly separate `major ambiguity clarification` from `major finding approval`, restoring the requirement that each major finding or collapsed root-cause finding that recommends follow-up is surfaced to the user one at a time with selector-based options that decide whether it enters the approved planning set.
- [x] Update `skills/cdd-implementation-audit/SKILL.md` so the code audit stays higher-signal: require code-quality and test-quality findings to be concrete, evidence-backed, and behavior-relevant; cite the file/symbol/diff or proof surface for non-trivial findings; prioritize correctness, contract drift, missing validation, missing failure-path coverage, and accidental complexity with real cost; and avoid style-only or vague refactor advice without a stated risk or payoff.
- [x] Update `skills/cdd-implementation-audit/SKILL.md` so the final audit summary ends with selector-labeled next actions using the repo-local `NEXT` section when `AGENTS.md` defines one or a final `**Options**` section otherwise; when approved findings exist, require `A. run cdd-plan on the approved findings` first, followed by concrete backlog/stop/re-audit alternatives.
- [x] Extend `scripts/validate_skills.py` so validation fails if `cdd-implementation-audit` again allows proven major findings to bypass user approval, drops the evidence-first code-audit rules, or loses the lettered final closeout options with the `A. run cdd-plan on the approved findings` handoff when applicable.

### Implementation notes

- The repo-grounded drift source is commit `78a432c`, which replaced the old flow sentence `Report concise minor findings and surface major findings one at a time with **Options**` with an ambiguity-only question gate while leaving the older “major findings must be checked with the user one at a time” rule in place.
- Fix that contradiction by restoring a two-stage audit decision flow:
  1. resolve only material major ambiguities when needed
  2. triage each major finding for planning inclusion even when no ambiguity remains
- Keep the existing per-finding option family separate from the final next-action bundle. Per-finding triage decides whether a finding is approved, deferred, accepted, or rejected; the final next-action bundle decides what to do with the approved set.
- Prefer proof surfaces keyed to behavior and capability boundaries rather than one exact sentence, but keep a small canonical phrase family for the final closeout selector so the skill pack stays grep-friendly.
- `skills/cdd-implementation-audit/agents/openai.yaml` can remain unchanged unless the revised contract makes its short description materially misleading.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `skills/cdd-implementation-audit/SKILL.md` and confirm major ambiguity resolution and major finding approval are separate stages.
- Confirm a proven major finding that recommends follow-up is still surfaced to the user one at a time for approval even when no ambiguity remains.
- Confirm code-quality and test-quality findings now require concrete evidence or proof surfaces and explicitly avoid style-only low-signal findings.
- Confirm the final closeout now uses selector-labeled next actions and makes `A. run cdd-plan on the approved findings` the first option when approved findings exist.
- Confirm the validator fails if the flow regresses to ambiguity-only questioning, if evidence-first code-audit rules are removed, or if the final closeout loses its lettered `cdd-plan` handoff options.

## Step 54 — Standardize active Builder monitoring across Master Chef adapters

### Goal

Make `cdd-master-chef` use one shared active-monitoring policy across OpenClaw, Codex, and Claude: while Builder is active, Master Chef checks it at least every 5 minutes, times out boot after 10 minutes without readiness, treats 20 minutes without direct running proof of life as a soft stale threshold that triggers escalation rather than immediate closure, and replaces Builder only after the harder no-signal boundary is crossed.

### Constraints

- Keep the current one-control-loop architecture: do not add a watchdog cron, timer-based heartbeat loop, second supervising session, or background heartbeat actor.
- Standardize timing semantics across the shared contract and all adapter docs; runtime-specific files may differ only in probe mechanics, direct-status surfaces, and session-close behavior.
- Preserve the current spawn/readiness boundary: a returned `builder_session_key` or spawned-agent line is spawn evidence only, not readiness proof.
- Preserve the current proof-of-life rule: any coherent Builder status, readiness ACK, discovery note, progress reply, runtime child-status signal, or Builder-authored readiness/progress record resets the relevant silence timer.
- Treat `10 minutes without readiness` as a boot-timeout boundary for the current Builder attempt.
- Treat `20 minutes without direct proof of life while running` as a soft stale threshold: Master Chef must mark the Builder as suspect and perform an explicit status probe rather than closing or replacing it immediately.
- Add one harder replacement boundary for running silence: replace or block only after either `30 minutes total running silence` or `2 consecutive unanswered explicit probes` after the soft stale threshold, whichever comes first.
- Keep replacement and deadlock handling inside the existing recovery path; do not reinterpret the new thresholds as an automatic whole-run abort on first miss.
- Prefer existing runtime-state timestamps where possible, but add narrow runtime-state fields when needed to prove cadence and escalation cleanly.

### Tasks

- [x] Update `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, and `cdd-master-chef/RUNTIME-CAPABILITIES.md` so the shared Builder lifecycle defines one monitoring ladder:
  - active Builder checks at least every 5 minutes while Master Chef is waiting
  - boot timeout after 10 minutes without readiness evidence, with one final explicit boot-status probe before replacement or blocked classification
  - running soft-stale threshold after 20 minutes without direct proof of life, which triggers suspect classification plus an explicit status probe
  - running hard-stale threshold after 30 minutes of total running silence or 2 consecutive unanswered explicit probes after the soft threshold, which enters the existing replacement-or-stop recovery path
- [x] Extend the shared runtime-state contract so timing evidence is explicit and grep-friendly. Add `builder_last_probe_at_utc`, `builder_last_probe_result`, `builder_suspect_since_utc`, and `builder_missed_probe_count` to the documented runtime state, and describe how they interact with existing fields such as `builder_spawn_requested_at_utc`, `builder_ready_at_utc`, `last_builder_direct_signal_at_utc`, and `last_progress_at_utc`.
- [x] Update `cdd-master-chef/CODEX-ADAPTER.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-ADAPTER.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, `cdd-master-chef/openclaw/README.md`, and `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md` so all adapters share the same cadence and escalation semantics, while differing only in:
  - how Master Chef performs a probe in that runtime
  - what counts as direct runtime status there
  - how a superseded or failed Builder session is closed or marked inactive there
- [x] Update `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `scripts/test_master_chef_artifacts.sh`, and `scripts/validate_skills.py` so proof surfaces fail if docs regress to:
  - no shared 5-minute active-check cadence
  - passive stale checks only during ad hoc status requests
  - immediate replacement at the first 20-minute running silence threshold
  - Codex/Claude-only quiet-work semantics without the shared soft/hard stale ladder
  - watchdog, cron, or timer-heartbeat supervision
- [x] Append this step to `TODO.md` using the existing step template and keep the timing model explicit enough that a later implementer does not need surrounding chat to recover the intended behavior.

### Implementation notes

- Follow the official long-running-operation pattern rather than ad hoc silence guesses:
  - active polling with bounded cadence
  - explicit last-update/proof-of-life evidence
  - separate short liveness threshold from a longer hard timeout
- Boot and running should use different clocks:
  - boot is anchored to `builder_spawn_requested_at_utc` until readiness is proven
  - running silence is anchored to the latest direct Builder signal after `builder_phase` becomes `running`
- Keep `20 minutes` as a soft stale threshold, not a kill switch. The first action there is probe-and-classify, not immediate replacement.
- Keep `30 minutes` or `2 missed probes` as the harder replacement boundary so Master Chef remains patient on real long-running work without drifting into indefinite silence.
- Do not add synthetic “still alive” chatter to logs or the session. Active monitoring means periodic evidence-based checks, not heartbeat spam.
- Preserve the existing replacement budget and deadlock logic unless implementation review shows they must move into the same shared section for consistency.

### Automated checks

- `bash scripts/test_master_chef_artifacts.sh`
- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the shared Master Chef docs and confirm they now require active Builder checks at least every 5 minutes while waiting.
- Confirm the docs still forbid watchdog cron, timer-based heartbeat loops, and second control loops.
- Confirm `10 minutes without readiness` is a boot-timeout boundary.
- Confirm `20 minutes without direct running proof of life` triggers suspect classification plus an explicit probe, not immediate replacement.
- Confirm `30 minutes total running silence` or `2 consecutive unanswered explicit probes` is the harder replacement boundary.
- Confirm Codex, Claude, and OpenClaw adapter docs all use the same timing semantics and differ only in runtime-specific probe mechanics.
- Confirm the validator and artifact script fail if docs regress to passive OpenClaw-only stale checks, Codex/Claude-only quiet-work windows, or watchdog-style supervision.

## Step 55 — Add intent-first framing to cdd-plan bounded-bisection planning

### Goal

Make `cdd-plan` resolve intent, material assumptions, and planning direction before it asks lower-level implementation questions or drafts runnable TODO edits.

### Constraints

- Layer this change onto the existing `Question economy` and `Flow (approval-gated, bounded-bisection)` contract; do not replace the upstream bounded-bisection lifecycle.
- Preserve the Step 49 edge-case review, Step 52 clarification-budget and single-step-refinement rules, the approval-gated read-only model, and selector-based final apply options.
- Do not reintroduce a blanket “confirm or correct all material assumptions before continuing” loop. Keep the Step 52 rule that only invalidating or materially plan-shaping assumptions block progress.
- Keep the visible intent output lightweight and require it only when the request is behavior-changing, ambiguous, multi-surface, audit-driven, or likely to produce more than one TODO step.
- Touch only `skills/cdd-plan/SKILL.md` and `scripts/validate_skills.py` unless a failing proof shows another surface is required.

### Tasks

- [x] Add an `## Intent and assumption checkpoint` section to `skills/cdd-plan/SKILL.md` that requires an intent frame before detailed implementation questions, TODO drafting, or plan-shape selection.
- [x] Extend `skills/cdd-plan/SKILL.md` so `Question economy` ranks unresolved decisions from intent and assumptions down to implementation details and forbids lower-level questions while higher-level direction is still unstable.
- [x] Require intent-qualifying plans to show a compact visible `Intent and assumptions` section with requested change, suspected intent, success signal, recommended direction, material assumptions by status, non-goals, and any blocking intent question.
- [x] Add a `## Planning anti-patterns` section to `skills/cdd-plan/SKILL.md` that forbids premature implementation-detail questioning, unchallenged assumptions, and premature TODO drafting.
- [x] Extend `scripts/validate_skills.py` so the default path keeps the upstream bounded-bisection and audit-normalization checks while also enforcing the new intent-checkpoint structure, and `--include-legacy-prose` covers the assumption taxonomy, direction taxonomy, anti-patterns, and visible intent-output contract.

### Implementation notes

- Reuse the existing `Interactive planning contract`, `Question economy`, and `Flow (approval-gated, bounded-bisection)` sections instead of creating a second competing planning framework.
- Keep the visible `Intent and assumptions` trigger separate from the coarse-plan trigger: behavior-changing requests may need intent framing without forcing a coarse decomposition unless they are also ambiguous, multi-surface, audit-driven, or likely multi-step.
- Preserve the repo’s validator strategy from Step 20: keep structural and order-sensitive checks in the default path, and put deeper topic-bundle coverage under `--include-legacy-prose` where exact structure is less machine-checkable.
- Keep canonical `cdd-plan` validation additive: intent-checkpoint coverage must sit alongside the upstream audit-mode and bounded-bisection checks, not replace them.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `cdd-plan` skill and confirm it resolves intent and material assumptions before lower-level implementation questions.
- Confirm `Question economy` now orders unresolved decisions from intent and assumptions down to implementation details and still preserves the upstream clarification-budget contract.
- Confirm intent-qualifying plans now include a compact visible `Intent and assumptions` section without forcing coarse decomposition for every behavior change.
- Confirm the validator fails if the intent checkpoint, decision-order hierarchy, anti-pattern section, or visible intent-output contract is removed, or if the Step 52 bounded-bisection checks are displaced.

## Step 56 — Rename `cdd-implementation-audit` skill to `cdd-audit` (slug + label)

### Goal

Rename the `cdd-implementation-audit` skill to `cdd-audit` across folder, frontmatter, slash-command slug, user-facing label `[CDD-4] Implementation Audit` → `[CDD-4] Audit`, validator, installer, test harness, and all in-repo cross-references; retire the old folder on upgrade; keep the help/description text and audit behavior unchanged.

### Constraints

- Slug change: `cdd-implementation-audit` → `cdd-audit`. Label change: `[CDD-4] Implementation Audit` → `[CDD-4] Audit`. The skill's description/help one-liner stays the same.
- Audit behavior, contract, approval flow, finding format, and the Step 50/53 contracts remain unchanged.
- Do not edit historical TODO step bodies (Steps 49–55); they are an immutable record of what was planned at the time.
- The installer must retire the old folder on upgrade by adding it to `delete_retired_skill_artifacts_in_target()` in `scripts/install.sh`, mirroring the precedent for `cdd-audit-and-implement` at `scripts/install.sh:227-241`.
- Validator regex patterns must anchor on `cdd-audit` or the bracketed label `[CDD-4] Audit` — never bare `Audit` — to avoid false matches.
- Replace `Implementation Audit` (proper-noun, refers to the skill) with `Audit` everywhere except inside `TODO.md` history; leave lowercase generic prose unchanged where it describes a generic activity rather than the skill.
- Touch only the surfaces listed in the file plan unless a failing check proves another surface is required.

### Tasks

- [x] Rename `skills/cdd-implementation-audit/` to `skills/cdd-audit/` using `git mv` so folder history is preserved.
- [x] Update `skills/cdd-audit/SKILL.md` frontmatter `name: cdd-implementation-audit` → `name: cdd-audit`, the H1 `# CDD Implementation Audit (explicit-only)` → `# CDD Audit (explicit-only)`, and any in-body proper-noun "Implementation Audit" references to the skill; preserve the `description:` text and all other body content.
- [x] Update `scripts/install.sh delete_retired_skill_artifacts_in_target()` (around lines 227-241) to include `"$dest_root"/cdd-implementation-audit` and `"$dest_root"/cdd-implementation-audit.pruned.*`, alongside the existing retirements for `cdd-audit-and-implement`, `cdd-index`, and `cdd-refactor`.
- [x] Update `scripts/validate_skills.py`: change the title-map entry at line 34 to `"cdd-audit": "[CDD-4] Audit"`; rewrite the regex at line 102 so it anchors on `cdd-audit` / `[CDD-4] Audit`; rename all dict keys and skill-name list entries (lines 818, 907, 931, 959, 2157, 2200) from `cdd-implementation-audit` to `cdd-audit`; rename internal Python function names matching `_check_implementation_audit_*` to `_check_audit_*` and identifier strings like `"implementation-audit topics"` to `"audit topics"` so the validator remains readable. Keep all assertion semantics unchanged.
- [x] Update `scripts/test_installers.sh` so every fixture path, expected output string, and assertion that references `cdd-implementation-audit` switches to `cdd-audit`; add or extend a case that asserts an upgrade from a fixture containing `cdd-implementation-audit/` prunes that folder via the new retirement entry.
- [x] Update `README.md` Skill Map and Typical Workflows so `[CDD-4] Implementation Audit` becomes `[CDD-4] Audit` and `cdd-implementation-audit` becomes `cdd-audit`; preserve the descriptive one-liner.
- [x] Update Master Chef package docs — `cdd-master-chef/SKILL.md`, `CONTRACT.md`, `RUNBOOK.md`, `CODEX-TEST-HARNESS.md`, `CLAUDE-TEST-HARNESS.md`, `openclaw/README.md`, `openclaw/MASTER-CHEF-RUNBOOK.md`, `openclaw/MASTER-CHEF-TEST-HARNESS.md` — so every proper-noun `[CDD-4] Implementation Audit` and slug `cdd-implementation-audit` switches to `[CDD-4] Audit` and `cdd-audit`. Include the harness fixture assertion `ls ~/.openclaw/skills/cdd-implementation-audit/SKILL.md` at `MASTER-CHEF-TEST-HARNESS.md:17`. Leave lowercase generic phrases ("implementation audit") only where they describe an activity rather than the skill.
- [x] Update `skills/cdd-init-project/SKILL.md:55` so the scaffolded `<sup>` help line names `$cdd-audit` instead of `$cdd-implementation-audit`; do not touch any other scaffolded text.

### Implementation notes

- File plan:
  - Renamed: `skills/cdd-implementation-audit/` → `skills/cdd-audit/` (`git mv`).
  - Edited: `skills/cdd-audit/SKILL.md` (post-rename), `scripts/install.sh`, `scripts/validate_skills.py`, `scripts/test_installers.sh`, `README.md`, `cdd-master-chef/SKILL.md`, `cdd-master-chef/CONTRACT.md`, `cdd-master-chef/RUNBOOK.md`, `cdd-master-chef/CODEX-TEST-HARNESS.md`, `cdd-master-chef/CLAUDE-TEST-HARNESS.md`, `cdd-master-chef/openclaw/README.md`, `cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md`, `cdd-master-chef/openclaw/MASTER-CHEF-TEST-HARNESS.md`, `skills/cdd-init-project/SKILL.md`.
- Order:
  1. `git mv` the folder.
  2. Update `skills/cdd-audit/SKILL.md` name/heading.
  3. Update validator (`validate_skills.py`) and installer (`install.sh`, `test_installers.sh`) — these are the gates.
  4. Sweep `README.md`, Master Chef package, `cdd-init-project/SKILL.md`.
- Validator regex (line 102): the long alternation must read `(?:cdd-audit|\[CDD-4\] Audit)` (or equivalent precise form), not bare `Audit`. The full regex covers post-run recommendation bundle phrasing — its semantics stay identical.
- Master Chef proper-noun vs. generic: in `MASTER-CHEF-RUNBOOK.md:151` the phrase "when the repo needs setup, planning, implementation audit, doc drift review …" describes activities; rewrite to "audit" (it pairs with the renamed skill) but keep the surrounding list grammatical. Where the phrase is unambiguously a skill reference (`[CDD-4] Implementation Audit`), rename strictly.
- No `TODO.md` edits to closed steps (Steps 49–55). This Step 56 entry is the only `TODO.md` mention of the new slug.
- History preservation: prefer `git mv skills/cdd-implementation-audit skills/cdd-audit` so the folder rename shows up as a rename in `git log --follow`.
- Two-pass safety: after the sweep, run `grep -rn 'cdd-implementation-audit\|\[CDD-4\] Implementation Audit' . --exclude-dir=.git --exclude-dir=.cdd-runtime --exclude=TODO.md` and confirm zero hits.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`
- `bash scripts/test_installers.sh`
- `grep -rn 'cdd-implementation-audit\|\[CDD-4\] Implementation Audit' . --exclude-dir=.git --exclude-dir=.cdd-runtime --exclude=TODO.md` returns no matches.

### UAT

- `skills/cdd-audit/SKILL.md` exists, has frontmatter `name: cdd-audit`, heading `# CDD Audit (explicit-only)`, and the original `description:` text intact.
- `skills/cdd-implementation-audit/` no longer exists.
- `README.md` Skill Map shows `[CDD-4] Audit` paired with `cdd-audit` and a description equivalent to the previous one.
- Master Chef package docs reference `[CDD-4] Audit` and `cdd-audit`; no proper-noun `Implementation Audit` strings remain outside `TODO.md` history.
- `scripts/install.sh delete_retired_skill_artifacts_in_target()` contains `cdd-implementation-audit` and its `.pruned.*` glob.
- `python3 scripts/validate_skills.py` and `--include-legacy-prose` both pass.
- `scripts/test_installers.sh` passes, including an upgrade-cleanup case that removes a pre-existing `cdd-implementation-audit/` fixture.
- `skills/cdd-init-project/SKILL.md:55` references `$cdd-audit`.
- Closed historical steps in `TODO.md` (Steps 49–55) are unchanged.

## Step 57 — Broaden `cdd-maintain` Mode A surface + codebase-comparison rigor (runbooks + subsystem clusters + ad-hoc support docs + bounded checks + orphaned-topic detection)

### Goal

Make `cdd-maintain` Mode A:
1. Read, classify, and report drift on canonical docs (README + specs + runbooks + INDEX + PROMPT-INDEX + repo-local skill manifests), detected subsystem doc clusters, AND every ad-hoc support doc under `docs/`, at repo root, and inside subsystem clusters — using a five-label classification (`current` / `drifted` / `stale-candidate` / `missing` / `unclear`).
2. Run concrete bounded codebase-comparison checks against canonical docs (script-name / file-path / symbol / entrypoint / skill-reference / manifest-field), plus orphaned-topic detection for ad-hoc support docs (subject grep against codebase + active TODO + active specs + recent journal), so the runner does not invent rules.

### Constraints

- Touch only `skills/cdd-maintain/SKILL.md` and `scripts/validate_skills.py` unless a failing proof shows another surface is required.
- Do not remove any existing Mode A rule; only add new doc classes, the new classification label, the new subsections, and the new checks subsection.
- **Ad-hoc support doc** is defined as: any `*.md` under `docs/` not in a canonical-role subdir (`docs/specs/`, `docs/prompts/`, `docs/runbooks/`, `docs/archive/`, `docs/journal/`, `docs/INDEX.md`, `docs/JOURNAL.md`); plus any non-canonical `*.md` at repo root (excluding the protected names: `README.md`, `AGENTS.md`, `CLAUDE.md`, `TODO.md`, `TODO-*.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`); plus subsystem-internal non-canonical `*.md` files inside detected subsystem clusters (i.e., not the cluster's `README.md` / `RUNBOOK.md` / `CONTRACT.md` / `SKILL.md`).
- Non-`.md` files (images, JSON, binaries) are out of scope for Mode A.
- Subsystem-cluster detection: a directory qualifies when it contains `README.md` and at least one of `RUNBOOK.md` / `CONTRACT.md` / `SKILL.md`.
- Classification labels expand to `current` / `drifted` / `stale-candidate` / `missing` / `unclear`. `stale-candidate` is ad-hoc-doc-only and is populated only by the orphaned-topic check; classifying a doc as `stale-candidate` does not by itself archive anything — Step 58's approval-gated contract handles that.
- Bounded checks: language-agnostic; repo-native search only; no full static analysis; no symbol-graph traversal. A failed bounded check → `drifted` with the specific claim cited.
- Orphaned-topic check applies only to ad-hoc support docs. Result map: 0 evidence hits across all four surfaces → `stale-candidate`; 1-2 weak hits → `unclear`; 3+ hits → `current`.
- Root `README.md` remains the repo runbook entrypoint; subsystem `README.md` is canonical for its subsystem only — both hold the canonical label without conflict.
- **Journal archive rules are unchanged** (lines 90–96 of current `skills/cdd-maintain/SKILL.md`). They already correctly implement the single-vs-split policy from `cdd-boilerplate/.agents/skills/cdd-drift-guard/SKILL.md`: single-journal mode → `docs/archive/`; split-journal mode → `docs/journal/SUMMARY.md` (condensed) + `docs/journal/archive/` (raw batches). This step does not touch journal archive behavior. Orphaned-topic detection respects the existing single-vs-split rules when locating recent journal entries.
- Preserve existing Mode A TODO archive rules, stale-adjacent-TODO handling, journal archive rules, `Safe write behavior`, `Approval contract`, and `Output` schema. The new ad-hoc archive contract arrives in Step 58.

### Tasks

- [x] Extend `## Mode-scoped read discipline` row `A. doc drift + upkeep` in `skills/cdd-maintain/SKILL.md` to additionally read: repo-root `RUNBOOK.md`, `docs/runbooks/*.md`, every `*.md` under `docs/` not in a canonical-role subdir, every non-canonical `*.md` at repo root, and every detected subsystem doc-cluster file (`<subsystem>/README.md`, `<subsystem>/RUNBOOK.md`, `<subsystem>/CONTRACT.md`, `<subsystem>/SKILL.md`, plus every other `*.md` adjacent in the same `<subsystem>/` directory).
- [x] Extend the canonical-support-docs paragraph at the top of `## Mode A — Doc drift + upkeep` so `RUNBOOK.md`, `docs/runbooks/*.md`, and detected-subsystem README/RUNBOOK/CONTRACT/SKILL files are listed as canonical alongside README and specs.
- [x] Add a `### Mode A — Subsystem doc clusters` subsection defining: detection rule (`README.md` + at least one of `RUNBOOK.md` / `CONTRACT.md` / `SKILL.md`); routing rule (root README = repo entrypoint, subsystem README = canonical for that subsystem only); and that subsystem-internal non-canonical `*.md` files are subsystem-internal ad-hoc support docs.
- [x] Add a `### Mode A — Ad-hoc support docs` subsection defining the ad-hoc scope and stating that Mode A walks every ad-hoc doc on every invocation, classifies each, and reports them under `Support documentation status`. State explicitly that this covers mockups, scratch RFCs, design notes, retired drafts, and similar exploratory artifacts — RFCs are one example, not a privileged class.
- [x] Add the `stale-candidate` classification label to Mode A. Update the classification line so the full label set reads `current` / `drifted` / `stale-candidate` / `missing` / `unclear`. State that `stale-candidate` applies only to ad-hoc support docs and is populated only by the orphaned-topic check, and that classifying a doc as `stale-candidate` does not by itself archive anything.
- [x] Add a `### Mode A — Codebase-comparison checks` subsection enumerating the bounded checks: **script-name claims** (`npm run X` / `pnpm X` / `yarn X` / `make X` / `pdm run X` / `cargo X` / `go run X` / `python -m X` etc. resolve to the relevant manifest); **file-path claims** (path exists in the current tree); **symbol claims** (function / class / module / CLI name best-effort repo-grep; `unclear` if not found rather than auto-`drifted`); **entrypoint claims** (file exists + referenced from the relevant manifest); **skill-reference claims** (`$cdd-<x>` or `skills/<x>` resolves to a real skill dir with `SKILL.md`); **manifest-field claims** (package / version named in a doc still present in the relevant manifest). For each, a failed check → `drifted` with the specific claim cited.
- [x] Add the orphaned-topic check to the same `### Mode A — Codebase-comparison checks` subsection, scoped to ad-hoc docs only: extract the doc's primary subject (filename + H1 + first-paragraph keywords); grep across (a) the codebase, (b) the active TODO step list (`TODO.md` + adjacent `TODO-*.md`), (c) the active specs / blueprint (`docs/specs/*`), (d) the last 30 days of journal activity (locate journal sources per the existing single-vs-split rules in the journal-archive subsection). Map hit count to label: 0 → `stale-candidate`; 1-2 weak → `unclear`; 3+ → `current`.
- [x] Cross-reference: in the existing "compare each support doc against the current repo state" paragraph (around line 57), link/reference the new `### Mode A — Codebase-comparison checks` subsection.
- [x] Extend `scripts/validate_skills.py` so validation fails if Mode A no longer requires: runbooks (root + `docs/runbooks/*`) in canonical set; subsystem-doc-cluster detection rule; `Ad-hoc support docs` subsection with scope + walk-and-classify; `stale-candidate` classification label; `Codebase-comparison checks` subsection with the bounded check list + orphaned-topic check.

### Implementation notes

- Touch points in `skills/cdd-maintain/SKILL.md`:
  - Line 17 area (`Mode-scoped read discipline` row `A`) — extend the read list.
  - Lines 54–58 (`Mode A — Doc drift + upkeep` canonical-doc paragraph) — add runbooks.
  - Insert new `### Mode A — Subsystem doc clusters` subsection.
  - Insert new `### Mode A — Ad-hoc support docs` subsection. Place after the canonical-doc paragraph and before the existing TODO archive rules.
  - Line 64 (`Classify each support doc`) — generalize to the five-label set with `stale-candidate` documented as ad-hoc-only.
  - Insert new `### Mode A — Codebase-comparison checks` subsection (bounded checks + orphaned-topic check). Place adjacent to the existing comparison paragraph; the existing paragraph links/references the new subsection.
- Do not introduce a new approval gate; reuse the existing documentation-approval flow when Step 58 adds the archive contract.
- Do not touch Mode B / C / D, the `Approval contract`, `Safe write behavior` (other than what Step 58 adds), or the `Output` section schema. `Support documentation status` already covers the new doc classes implicitly.
- Do not touch the existing journal archive rules (lines 90–96) — they already correctly implement the single-vs-split policy from `cdd-boilerplate/.agents/skills/cdd-drift-guard/SKILL.md`.
- Validator coverage (`scripts/validate_skills.py`): add a `_check_maintain_*` function matching the existing naming pattern (precedent: Step 51's Mode C validator). Assert: read-discipline row mentions runbooks + ad-hoc patterns + subsystem clusters; canonical-doc paragraph names runbooks; subsystem-cluster detection rule is present; ad-hoc-support-docs subsection exists with the per-file walk; `stale-candidate` label is in the classification line; codebase-comparison-checks subsection exists with the bounded check list and orphaned-topic check.
- Keep validator regexes anchored on stable phrasing (e.g., `runbook`, `docs/runbooks/`, `subsystem doc cluster`, `ad-hoc support doc`, `stale-candidate`, `orphaned-topic`, `codebase-comparison checks`) rather than full sentence matches.
- After editing SKILL.md, run the validator both default and with `--include-legacy-prose`.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`

### UAT

- Read the updated `skills/cdd-maintain/SKILL.md` Mode A section and confirm runbooks (root + `docs/runbooks/*`) are now canonical alongside README and specs.
- Confirm `Mode-scoped read discipline` row `A` enumerates runbook paths, every `*.md` under `docs/` not in a canonical-role subdir, every non-canonical `*.md` at repo root, and subsystem-cluster paths.
- Confirm the subsystem-doc-cluster detection rule is present: `README.md` + at least one of `RUNBOOK.md` / `CONTRACT.md` / `SKILL.md`.
- Confirm Mode A has an `Ad-hoc support docs` subsection with the scope definition and walk-and-classify rule, with mockups / scratch RFCs / design notes / retired drafts called out as examples (RFCs not privileged).
- Confirm the classification line now uses the five-label set with `stale-candidate` documented as ad-hoc-only.
- Confirm Mode A has a `Codebase-comparison checks` subsection listing the bounded checks (script-name / file-path / symbol / entrypoint / skill-reference / manifest-field) and the orphaned-topic check for ad-hoc docs with the 0 / 1-2 / 3+ threshold map across codebase + active TODO + active specs + last 30 days of journal.
- Confirm the existing Journal archive rules (single-vs-split pattern from `cdd-drift-guard`) are unchanged.
- Confirm `python3 scripts/validate_skills.py` and `--include-legacy-prose` both pass.
- Confirm the validator fails if any of the following are removed: runbook coverage, subsystem-cluster detection rule, ad-hoc-support-docs subsection, `stale-candidate` label, codebase-comparison-checks subsection (bounded check list or orphaned-topic check).

## Step 58 — Add `cdd-maintain` Mode A ad-hoc-doc archive contract (coarse — refine before implementation)

### Goal

Define a judgement-based, evidence-backed, approval-gated archive contract for ad-hoc support docs (mockups, scratch RFCs, design notes, retired drafts, and similar exploratory artifacts) — without changing TODO or journal archive rules.

### Constraints

- Touch only `skills/cdd-maintain/SKILL.md` and `scripts/validate_skills.py` unless a failing proof shows another surface is required.
- Never silent. Every archive move requires documentation approval.
- Primary trigger: Step 57's `stale-candidate` classification with orphaned-topic evidence. Explicit frontmatter markers (`Deprecated:`, `Superseded by:`, `Status: Superseded` / `Rejected` / `Withdrawn`) are strong signals when present but not required.
- Archive destination mirrors source location:
  - `docs/foo.md` → `docs/archive/foo_YYYY-MM-DD.md`
  - `docs/<sub>/bar.md` → `docs/archive/<sub>/bar_YYYY-MM-DD.md`
  - Repo-root non-canonical `*.md` (e.g., `NOTES.md`) → `docs/archive/<name>_YYYY-MM-DD.md`
  - Subsystem-internal `<subsystem>/scratch.md` → `<subsystem>/_archive/scratch_YYYY-MM-DD.md` (local archive so the subsystem stays self-contained)
- Same-day archive files append rather than overwrite.
- Per-file or batched approval via selector options; user picks granularity.
- **Journal archive rules unchanged.** They already correctly implement the single-vs-split policy from `cdd-boilerplate/.agents/skills/cdd-drift-guard/SKILL.md` (single mode → `docs/archive/`; split mode → `docs/journal/SUMMARY.md` + `docs/journal/archive/`). The new ad-hoc archive contract is parallel and additive; it does not override journal rules.
- TODO archive rules (current lines 72–82 of `skills/cdd-maintain/SKILL.md`) and journal archive rules (current lines 90–96) are untouched.
- `## Safe write behavior` gains one new bullet: `Apply ad-hoc-doc archive moves only after documentation approval.`
- Depends on Step 57.

### Tasks

- [ ] Coarse — refine into a runnable step via `$cdd-plan` before implementation. Initial spec from `/Users/ruph/.claude/plans/happy-stirring-bunny.md` Step 2. Add a `### Mode A — Ad-hoc support doc archive rules` subsection after the existing journal archive rules; spell out trigger model (primary: `stale-candidate` classification + orphaned-topic evidence; secondary: frontmatter markers); destination layout (mirror under `docs/archive/` for repo-level docs and repo-root scratch; under `<subsystem>/_archive/` for subsystem-internal docs); same-day append rule; per-file or batched approval rule. Add the new `Safe write behavior` bullet. Validator must fail if the subsection is missing, the trigger model is silent-only, the destination layout omits the subsystem-local case, the same-day-append rule is removed, or the new `Safe write behavior` bullet is removed.

### Automated checks

- `python3 scripts/validate_skills.py`
- `python3 scripts/validate_skills.py --include-legacy-prose`
