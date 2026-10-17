---
name: cdd-audit
description: "Audit implemented work or proposed enhancements against stated intent and the simplest boundary-respecting solution using proportional proof; model as-built behavior, detect over-engineering, over-defensive limits, and legacy-on-arrival code, explain each finding's problem and fix in simple English, and route approved follow-up to cdd-plan, direct implementation, or backlog (interactive, read-only)."
---

# CDD Audit (interactive, read-only)

Use this skill for explicit implementation or codebase audits. Output findings plus approved follow-up, not code changes.

## Interaction contract

- Stay read-only: never patch code, docs, or TODO files.
- Ask only when the answer could materially change the audit conclusion (type, goal, or primary question; finding validity, severity, root-cause grouping, affected boundary, or next path), or when scope is missing or ambiguous; then ask only for the smallest missing decision, otherwise report directly.
- Ask framing and proof-sufficiency questions before local implementation detail, and merge ambiguities that share one root decision into one question.
- Ask at most one substantive question per message. After each answer, re-rank what remains and ask the next highest-leverage question; never list several open questions as a checklist.
- Each question states the recommended direction and what conclusion changes if the answer differs; never re-ask what the user, repo evidence, or an accepted assumption settled.
- Keep baseline confirmation (Stage 3), ambiguity clarification, and finding approval in separate messages. Resolving an ambiguity approves no finding; a framing, model, or baseline correction re-anchors the audit without consuming a finding approval.
- Surface one proven finding at a time, collapsing only symptoms with one root cause; after each decision, refresh the remaining list and show the next; never batch findings into one approval checklist. Minor findings and ambiguities may stay report-only unless they change the recommended follow-up.
- Write simple English that a capable reader new to the repo's terms understands on first read: main point first; the concrete behavior or action and its effect; common words, one idea per short sentence; a needed technical term explained once. Never coin a term in a finding: define a truly needed name in one plain phrase at first use, else describe the behavior.
- End every decision message with repo-local `NEXT` when `AGENTS.md` defines one, otherwise `**Options**`: question, any reply hint, then choices; nothing follows the final choice.
- Label every choice with a lettered selector, also in native option UIs (`A.`, `B.`, …; nested `A1.`, `A2.`); put the recommended choice first and mark it; say the user may reply with the selector alone. The selected option is the approval; never append a separate approval question.
- Each option is one decision on one short line, `<selector>. <action> — <immediate result>; <main trade-off>`, whose concrete action stands alone; omit a trade-off that does not matter; split choices with different outcomes. Examples do not set the option count.
- Single-path triage, adapted to the finding (routes come in Stage 6): `A.` approve the follow-up, `B.` backlog it, `C.` keep current behavior, `D.` request evidence, `E.` reject the finding; e.g. `A. Approve the session-expiry follow-up — include handler and regression-test work; no code changes yet`.
- Variant mode, for several credible approval paths: `A. Choose the recommended path — same as A1`, then `A1.`-`A3.` as option lines, then `B.`-`E.`; variants must differ in implementation, spec, verification, or sequence, else collapse into one recommendation.
- Accept compact replies (`A`, `A1`, `A 1`, `A3`, `A 3`, `B`, `C`, `D`, `E`); in variant mode plain `A` selects `A1`.

## Stage 1 — Frame

Read `AGENTS.md`, then the contract docs and likely proof surfaces from Stage 2 (in-scope external artifacts first), only far enough to stabilize framing, scope, and risk. Then classify the question the audit must settle before any detailed review.

- Audit types are the six Stage 2 shapes. Choose one primary type; cover cross-cutting concerns with optional lenses (Stage 4), never by mixing types.
- Fields: `Audit type`, `Requested audit question`, `Expected behavior or intended goal`, `Primary proof surface`, `Read strategy` (`implementation-only`, `plan-only`, or `plan-vs-implementation`; ordering in Stage 3), `Affected boundaries`, `Hardest constraint`, `Recommended review depth`, `Out of scope`, `Artifact authority`.
- `Artifact authority`: design detail mixed into an in-scope problem statement is `binding contract` or `illustrative guidance` (the `bug_report` default). Illustrative guidance is direction the implementation may deviate from, not a contract to audit against; misread authority re-anchors the framing and never yields findings against the misread contract.
- Audit a proposal for unbuilt capability (issue, RFC, or spec draft) as `enhancement_proposal`, never as a retrospective shape. Readiness review of unimplemented TODO steps, Master Chef readiness included, stays with the step-scoped and `master_chef_multi_step` shapes.
- Always classify. Emit the visible `Audit framing` block for behavior-changing, branch-sized, step-scoped, or multi-step audits; narrow local audits classify in one line.

## Stage 2 — Scope and shape

- Scopes: last commit, uncommitted changes, one TODO step, multiple TODO steps, one TODO file, one proposal artifact (issue, RFC, or spec draft), whole codebase.
- Resolve TODO steps as `cdd-implement` does (normalize numeric ids, ask only if several matches remain) and record the selected step ids.
- Scope answers where to audit; shape answers how, what matters most, which proof surfaces deserve deep review, which findings stay suppressed or report-only, and what a successful audit must answer. Never widen a bounded `small_change` into a whole-codebase drift sweep unless the evidence or audit question requires it.

| shape | primary question | proof surfaces | default depth | as-built model and checkpoint | suppress |
|---|---|---|---|---|---|
| `bug_report` | Is the bug real, its root cause understood, and the reported path closed, not just nearby code changed? Weigh expected vs actual, failure handling, regression risk. | repro steps, failing behavior, error traces, boundary validation, regression tests, nearby state transitions | `standard` | model; no checkpoint | broad architecture critique, unless a systemic flaw changes the conclusion or next path |
| `functionality` | Does it satisfy the intended capability and contract? Weigh goal match, user-visible behavior, edge cases, declared non-goals, code/test/doc drift. | specs, README, selected TODO contract, observable behavior, tests, user-facing docs | `standard` | model; checkpoint | generic cleanup that leaves the capability verdict unchanged |
| `small_change` (small fixes, new functions, config, docs) | Did the bounded change do the intended thing without adjacent regressions or proof gaps? Weigh local correctness, proof quality, nearby contract drift. | changed files plus adjacent tests, docs, configs, manifests, entrypoints | `quick` when bounded | model; checkpoint only if the delta changes behavior, contract, or user-visible scope | unrelated drift, speculative refactors, branch-scale architecture fishing, unless they directly change the conclusion |
| `big_branch` | Which boundaries changed, where are the top risks, does the branch cohere as one shape? Weigh boundary interactions, migration and compatibility risk, validation blind spots, needed specialist review or lenses. | diff inventory, affected-boundary map, contract artifacts, representative validation evidence, declared rollout or migration surfaces; inventory changed boundaries, top risks, review order, and depth before deep findings | `deep` | model; checkpoint | line-level nits, unless they imply real behavior risk or materially weaken the proof |
| `master_chef_multi_step` | Were the steps correctly decomposed, executed, evidenced, and closed out? | step contracts, implementation deltas, automated checks, UAT evidence, run summaries, continuation artifacts, final mission or stop-state evidence; inventory boundaries or review order first | `deep` | model; checkpoint | replanning inside the audit; route approved findings outward |
| `enhancement_proposal` | Is the proposal sound, non-duplicative, and ready to plan: what exists, how does it fit, which integration shape is best? | the full proposal thread; `Existing-capability inventory` (first) across code, specs, docs, skills, tools, tests; in-repo prior art; declared acceptance criteria | `standard` | exempt: the inventory plays the model's role; no checkpoint | absence-of-the-artifact findings; missing implementation, tests, or TODO normalization is the premise |

- Depth: start with the lightest depth that answers the audit question confidently; deepen only when risk, weak proof, or boundary count justifies it; never impose branch-scale expectations on `quick`.
  - `quick`: changed files plus the smallest adjacent proof surface that answers the question.
  - `standard`: the changed surface plus adjacent contracts, tests, docs, configs, and entrypoints that materially affect the verdict; also the step-scoped default.
  - `deep`: by boundary cluster and risk order, not raw diff order; also the default for security-sensitive, migration-heavy, or otherwise multi-boundary audits.
- Unrelated repo drift stays report-only unless it materially changes the goal-match verdict, finding severity, root-cause grouping, affected boundary, or recommended next path.
- Candidate proof surfaces after `AGENTS.md`, chosen per shape and depth: `README.md`; `TODO.md` and adjacent `TODO*.md`; `docs/specs/prd.md`, `docs/specs/blueprint.md`, connected `docs/specs/*-definition.md`; when present, `docs/INDEX.md` (plus `docs/index/**` when split), `docs/runbooks/*.md`, repo-root `RUNBOOK.md`, and the current-state header of `docs/JOURNAL.md` (plus split-journal index) for recent activity; the scope's code, tests, configs, manifests, entrypoints, and validation surfaces; in-scope external references.
- Missing docs, specs, tests, or other proof surfaces the chosen shape depends on, unreadable in-scope external surfaces included, are findings; never invent missing contract surfaces during the audit.
- For `enhancement_proposal`, step-scoped, or multi-step shapes, read `references/shapes.md` now.

### External sources

- Resolve user-named issues, tickets, PRs, RFCs, docs, or tracker references read-only, via connectors, CLIs, local remotes, pasted URLs, or identifiers.
- Before framing, scope resolution, proposal-fit verdicts, or findings, read each in-scope artifact's complete thread: body, all comments, review comments, directly referenced artifacts; do not crawl unrelated links. The latest authoritative comment is current intent; flag superseded body requirements.
- Ask one clarifying question when the reference or source of truth is ambiguous enough to change the audit question, scope, or conclusion.
- When a surface cannot be fetched after a reasonable read-only attempt, mark coverage partial, name the unread surfaces, and do not promote unread requirements as confirmed.
- Never post, update, label, assign, or otherwise mutate external systems.

## Stage 3 — Model the as-built

- Model trigger: the Stage 2 column, for a retrospective shape with an implemented surface. First inspect one concrete delta (the branch diff, selected commits, or another repo-local changed-file surface fitting the scope), then emit the model visibly.
- Exemptions: the Stage 2 column, plus readiness audits of unbuilt TODO steps, which skip the model with a one-line reason.
- Read `references/as-built-model.md` now; an exempt audit reads only its `## Limits and assumptions`, which Stage 4 applies to every solution.

### Core direction checkpoint

- Trigger: the Stage 2 column, plus every step-scoped retrospective audit, when an implemented delta exists.
- Map the smallest useful in-scope requirements set to implementation evidence; emit one visible `Core direction checkpoint` block:
  - `Recent delta reviewed`: the commit, diff, changed-file, or step-scoped surface inspected, plus affected boundaries
  - `Intent provenance`: intent sources by priority (TODO step, spec, issue or PR thread, README, commit message, journal note), weak or missing ones marked
  - `As-built model`: reuse the emitted model; restate it only if compact reuse would be unclear
  - `Requirements coverage`: that set, grouped when practical, each `implemented`, `partial`, `missing`, `unclear`, `deferred by contract`, or `out of scope`, with one evidence cite
  - `Direction verdict`: `aligned`, `aligned with gaps`, `misaligned`, or `unclear`
  - `Open assumptions / proof gaps`: inference, missing proof, or contract weakness still limiting confidence
- `missing` means reviewed in-scope intent requires it and the reviewed implementation lacks it or leaves it materially incomplete. Materially conflicting intent sources make the requirement or overall direction `unclear`; re-anchor instead of guessing.
- Pause exactly once: no missing-item analysis, normalized findings, or planning-oriented recommendations until the user confirms or corrects the baseline; refresh the checkpoint when a correction materially changes it.
  - `A. Continue — the baseline is correct; review gaps and findings`
  - `B. Correct the baseline — update the intended behavior or requirements before findings`
  - `C. Change scope — review a smaller or different surface`
  - `D. Stop — end after the baseline review; do not produce findings`
- Confirmation validates the auditor's reading of product direction, requirements (any missing-requirement claim included), implementation shape, and scope; it approves no finding and authorizes no follow-up.

## Stage 4 — Judge

- Read `references/boundary-and-dimensions.md` now.
- Order: the boundary and simplicity check, then the six core dimensions together, then triggered optional lenses. Never audit code in isolation when the contract, proof surface, or tests are part of the issue.
- Emit `Solution shape` and `Deletion opportunities` together: at `quick`, one overall `Verdict` plus one evidence sentence; at `standard` or `deep`, one evidence-backed line per field in the reference. No deletion candidates: `none` plus one evidence sentence.
- Then emit a compact `Goal match` or the shape's equivalent: is the goal understood; does the implementation match, partially match, or miss it; is the proof strong enough for that verdict? Build it on the model's `Perceived intent vs stated intent` diff when emitted, and on the confirmed baseline, not the draft, after a checkpoint.

## Stage 5 — Findings and triage

- Never emit raw audit bullets as final output. Findings explain why the goal-match verdict is justified or weak: anchor each to the audit type and that verdict; skip side findings that leave the audit question unchanged.
- Ground every finding in observed evidence from the audited surface (code, tests, configs, artifact text, observable behavior); solution-shape, complexity, and verification findings cite a file, symbol, diff, failing or missing test, or equivalent concrete, behavior-relevant proof. Never derive a finding from an imagined implementation, architecture, or contract; what an in-scope artifact leaves unspecified is at most a gap note or a clarification, never a defect.
- Four blocks per finding; `Problem` and `Solution` default to one sentence each, a second only when needed:
  - `Problem`: current behavior, cause, affected user or system, impact.
  - `Solution`: the smallest safe change, where it belongs, and how to prove it worked; with insufficient evidence, what must be learned first instead of guessing.
  - `Assumptions`: each load-bearing assumption, tagged `evidence-backed <cite>`, `user-confirmed`, or `unconfirmed`; `none` when observed evidence alone carries the finding. Assumptions inform, never gate: an `unconfirmed` one never suppresses the finding, blocks triage, or turns it into a clarification; it stays visible for the user to strike.
  - `Details`: audit dimension; severity (`high`, `medium`, `low`); affected boundary; exact evidence; recommended next path; approval recommendation. Exact evidence and technical labels live here, never repeated in prose or used in place of explaining the problem or fix.
- State what approval authorizes as `<action> in <place> so <result>`, translating planner labels into concrete work: `Check session expiry in the login handler and add a regression test so expired users are signed out.`
- Collapse duplicate symptoms into the smallest root-cause finding that can be discussed and planned cleanly.
- Fold material edge-case and failure-path gaps into findings, never a separate planning-style section, only when they could change the conclusion and have an observed trigger path (code path, test, config, or repro) in the audited surface; a "could happen" case without one stays report-only, labeled speculative.
- Prioritize correctness, contract drift, missing validation, missing failure-path coverage, and accidental complexity with real cost; skip style-only notes and vague refactor advice without a real behavior risk, confidence gap, or maintenance payoff.
- Findings routed to `cdd-plan` map into one or more of `spec_delta`, `implementation_delta`, `verification_delta`, `defer`.

Example finding:

```text
Problem: Expired sessions remain active because the login handler does not check their expiry time.
Solution: Check expiry in the login handler and add a test that signs out expired sessions.
Assumptions: evidence-backed auth/session.ex:validate/1 — expiry is stored but never read at login; unconfirmed — no other layer is expected to enforce expiry.
Details: high correctness risk; boundary: session validation; evidence: auth/session.ex:validate/1; next: implementation_delta + verification_delta; approval: handler and regression-test follow-up.
```

- Triage each proven major finding with the single-path or variant options; keep a running list of findings approved for follow-up, backlogged, accepted as-is, needing more evidence, and rejected.

## Stage 6 — Close out

- Final summary: framing (audit type, scope, depth); checkpoint summary when emitted; `Solution shape` fields; goal-match verdict; the reviewed delta, changed-file, or commit surface; `Delta stats` and `Deletion opportunities` outcome for a measurable delta; findings by dimension; for step-scoped audits, selected step ids and step-completion judgments; full triage state, approved findings mapped to `cdd-plan` types when planning is the recommended route; notable missing proof surfaces, docs, specs, or tests; recommended next action.
- With approved findings, offer three routes:
  - `A. Prepare implementation steps (recommended) — send approved findings to cdd-plan before changing code`
  - `B. Implement approved findings now — make a short plan here, then run cdd-implement`
  - `C. Stop here — leave approved findings for later; make no repo changes`
- `A` asks one substantive planning question, compares fixes, and writes runnable TODO steps; for `enhancement_proposal` it hands `cdd-plan` the chosen integration option as the pre-selected architecture option, mapped to `spec_delta` and/or `implementation_delta`; TODO normalization happens there. `B` makes a short plan ordered by dependency, boundary, and validation, then invokes `$cdd-implement` on existing TODO steps when available, otherwise on bounded direct tasks.
- Without approved findings, never recommend an empty `$cdd-plan` or direct implementation; offer concrete non-planning actions such as backlog, stop, or rerun on a narrower audit slice.
- Never let a large scope erase the audit question: order a broad audit around the chosen shape and primary proof surfaces, and propose a smaller first slice when one sane pass cannot cover it.
- If docs or specs are intentionally future-state, say so and audit for clarity rather than forcing current-state wording onto planned behavior.
