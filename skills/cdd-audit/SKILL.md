---
name: cdd-audit
description: "Audit implemented work or proposed enhancements against stated intent and the simplest boundary-respecting solution using proportional proof; model as-built behavior, detect over-engineering, over-defensive limits, and legacy-on-arrival code, explain every finding's problem and practical solution in simple English, then route approved follow-up into cdd-plan, direct implementation, or backlog (interactive, read-only)."
---

# CDD Audit (interactive, read-only)

Use this skill for explicit implementation or codebase audits. Output findings plus approved follow-up, not code changes.

## Sources of truth
Read:
- `AGENTS.md`
- `README.md`
- `TODO.md` and adjacent `TODO*.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md` and connected `docs/specs/*-definition.md` leaf specs when present
- `docs/INDEX.md` when present (also `docs/index/**` siblings when INDEX split is active)
- `docs/runbooks/*.md` and repo-root `RUNBOOK.md` when present
- the current-state header of `docs/JOURNAL.md` (and split-journal index when active) for recent activity context
- relevant code, tests, configs, manifests, entrypoints, and validation surfaces for the chosen scope
- any user-named external issue, ticket, PR, RFC, doc, or tracker reference in scope, per `## External source handling`

## External source handling
- Resolve user-named external issues, tickets, PRs, RFCs, docs, or tracker references via available read-only surfaces: connectors, CLIs, local remotes, pasted URLs, and identifiers.
- Before audit framing, scope resolution, proposal-fit verdicts, or findings, read each in-scope external artifact's complete thread: title/body/description, all comments, review comments when present, and material directly referenced artifacts. Do not recursively crawl unrelated links.
- Treat the latest authoritative comment or decision as current intent; flag superseded body requirements.
- If the reference or source of truth is ambiguous enough to change the audit question, scope, or conclusion, ask one framing clarification.
- If the artifact, comments, or material references cannot be fetched after a reasonable read-only attempt, declare the assessment partial, name the unread surfaces, and record the gap as a missing proof surface.
- Never post, update, label, assign, or otherwise mutate external systems during the audit.

Treat missing docs, specs, tests, or other proof surfaces that the chosen audit shape depends on as findings. Do not invent missing contract surfaces during the audit.

## Audit framing

Before detailed review, classify what question this audit is actually trying to settle.

- Supported audit types:
  - `bug_report`
  - `functionality`
  - `small_change`
  - `big_branch`
  - `master_chef_multi_step`
  - `enhancement_proposal`
- Choose one primary audit type. Use `Optional lenses` for cross-cutting concerns instead of mixing multiple primary audit types.
- For every audit, classify:
  - `Audit type`
  - `Requested audit question`
  - `Expected behavior or intended goal`
  - `Primary proof surface`
  - `Read strategy` — `implementation-only`, `plan-only`, or `plan-vs-implementation`, per `## As-built model`
  - `Affected boundaries`
  - `Hardest constraint`
  - `Recommended review depth`
  - `Out of scope`
  - `Artifact authority` — when an in-scope artifact mixes a problem statement with design detail, classify that design detail as `binding contract` or `illustrative guidance`; `bug_report` artifacts default to `illustrative guidance`
- Design detail classified as `illustrative guidance` is direction the implementation may deviate from, not a contract to audit against. Misreading artifact authority re-anchors the audit framing; it never produces findings against the misread contract.
- Audit a proposal for unbuilt capability (issue, RFC, or spec draft) as `enhancement_proposal`; never force a retrospective shape onto unbuilt work. Readiness review of unimplemented TODO steps (including Master Chef readiness) stays with the step-scoped and `master_chef_multi_step` shapes.
- If the audit type, intended goal, or primary review question is ambiguous enough to materially change the audit conclusion, ask one framing clarification first.
- Produce a compact visible `Audit framing` summary for behavior-changing, branch-sized, step-scoped, or multi-step audits. For narrow local audits, keep the framing compact but still classify it before findings.

## Scope resolution
- Supported audit scopes:
  - last commit
  - uncommitted changes
  - one TODO step
  - multiple TODO steps
  - one TODO file
  - one proposal artifact (issue, RFC, or spec draft)
  - whole codebase
- Resolve scope after the audit framing stabilizes.
- Ask only when the scope is missing or ambiguous, and keep the question scoped to the smallest missing decision.
- If the scope references TODO steps, resolve them the same way `cdd-implement` would: normalize numeric step identifiers and ask only if multiple matches remain.
- If the scope resolves to one or more TODO steps, record the selected step ids explicitly and audit each selected step against its own step contract rather than only the broader TODO topic.
- Let audit type and scope work together. Do not widen a bounded `small_change` audit into a whole-codebase drift sweep unless the evidence or requested audit question requires it.
- Scope answers where to audit. Audit shape answers how to audit and what matters most.

## Audit shapes

Choose one audit shape before reviewing dimensions. The shape determines which proof surfaces deserve deep review, which findings should stay suppressed or report-only, and what a successful audit must be able to answer.

- `bug_report`
  - Primary question: is the reported bug real, is the root cause understood, and does the implementation actually close it?
  - Preferred proof surfaces: repro steps, failing behavior, error traces, boundary validation, regression tests, and nearby state transitions.
  - Prioritize expected-versus-actual behavior, failure handling, regression risk, and whether the change closes the reported path instead of merely changing nearby code.
  - Suppress broad architecture critique unless the bug clearly comes from a systemic design flaw that changes the audit conclusion or recommended next path.
- `functionality`
  - Primary question: does the implementation satisfy the intended capability and contract?
  - Preferred proof surfaces: specs, README, selected TODO contract, observable behavior, tests, and user-facing docs.
  - Prioritize goal match, user-visible behavior, edge cases, declared non-goals, and drift between code, tests, and documentation.
  - Suppress generic cleanup findings that do not change the capability verdict.
- `small_change`
  - Covers small bug fixes, new functions, config changes, and doc updates.
  - Primary question: did this bounded change do the intended thing without creating adjacent regressions or proof gaps?
  - Preferred proof surfaces: changed files plus adjacent tests, docs, configs, manifests, or entrypoints.
  - Prioritize local correctness, proof quality, and nearby contract drift that weakens confidence in the change.
  - Suppress unrelated repo drift, speculative refactor advice, and branch-scale architecture fishing unless they directly change the audit conclusion.
- `big_branch`
  - Primary question: which boundaries changed, where are the highest risks, and does the branch still cohere as one implementation shape?
  - Preferred proof surfaces: diff inventory, affected-boundary map, contract artifacts, representative validation evidence, and any declared rollout or migration surfaces.
  - Before deep findings, inventory changed boundaries, highest-risk areas, recommended review order, and declared review depth.
  - Prioritize boundary interactions, migration and compatibility risk, validation blind spots, and places where specialist review or optional lenses are required.
  - Suppress line-level nits unless they imply real behavior risk or materially weaken the proof surface.
- `master_chef_multi_step`
  - Primary question: were the steps correctly decomposed, executed, evidenced, and closed out?
  - Preferred proof surfaces: selected TODO step contracts, implementation deltas, automated checks, UAT evidence, run summaries, continuation artifacts, and final mission or stop-state evidence when present.
  - Prioritize step sizing, dependency order, completion evidence, proof quality, and whether the run stopped at the right boundary for the evidence available.
  - Suppress planning-style replanning inside the audit itself; route approved findings outward instead.
- `enhancement_proposal`
  - Primary question: is the proposal sound, non-duplicative, and ready to plan — what already exists, how does it fit, and which integration shape is best?
  - Preferred proof surfaces: the full proposal thread (per `## Sources of truth`), an existing-capability inventory across code, specs, docs, skills, tools, and tests, in-repo prior art, and the proposal's declared acceptance criteria.
  - Prioritize duplication with shipped surfaces, architectural conflicts, unstated decisions and gaps in the proposal itself, acceptance-criteria quality, and integration seams.
  - Suppress absence-of-the-artifact findings — missing implementation, tests, or TODO normalization is the premise, not a finding (see `## Enhancement-proposal audit`).

## Step-scoped TODO contract audit

When the chosen scope resolves to one or more TODO steps, explicitly audit each selected step against its own step contract.

- Review each selected step's:
  - `Goal`
  - `Constraints`
  - `Tasks`
  - `Implementation notes`
  - `Automated checks`
  - `UAT`
- Inspect one concrete implementation delta for that scope: current branch diff, selected commits, or another repo-local changed-file surface.
- Judge whether that delta actually satisfies the step contract, not just the surrounding TODO theme.
- Treat unchecked TODO tasks, missing completion evidence, weak automated-check or UAT proof, or implementation that misses the step goal as first-class findings.
- If a selected TODO step lacks one of the preferred sections, treat that as a contract weakness or missing proof surface rather than silently skipping it.
- Keep this step-scoped audit additive to the broader README, spec, code, test, config, manifest, and entrypoint review; do not narrow the audit into TODO-only review.
- For `master_chef_multi_step`, audit both the per-step contract and the run-level execution evidence: step sizing, dependency order, completion evidence, continuation quality, and whether checks plus UAT actually prove completion.

## Enhancement-proposal audit

When the chosen audit type is `enhancement_proposal`, audit the proposal against the current codebase instead of judging an implementation delta.

- Before findings, produce a visible `Existing-capability inventory`: each entry names an existing surface, tags it `overlaps`, `duplicates`, `depends on`, or `conflicts`, and cites a file or symbol.
- Emit a `Proposal fit` verdict as this shape's `Goal match` equivalent: `fits as proposed`, `fits with adjustments`, `needs reshaping`, `mostly already exists`, or `conflicts with current architecture`.
- Produce a visible `Integration options` block with 2-4 materially different integration shapes — approach, affected boundaries, reuse versus new surface, trade-offs — recommended option first, surfaced through the existing approval-variant mode (`A1`, `A2`, `A3`). Collapse to one justified option when alternatives would be cosmetic.
- Apply `## Boundary and simplicity check` to the recommended integration shape and use it to rank materially different alternatives; do not invent implementation details that the proposal or current architecture cannot support.
- Keep findings about the proposal itself: duplication, conflicts, unstated decisions, gaps, and acceptance-criteria weaknesses — never the absence of the proposed artifact, its tests, or its TODO normalization.
- In per-finding triage, `C. Accept current state` means keeping the proposal as written, with no repo change.
- At closeout, hand the chosen integration option to `cdd-plan` as the pre-selected architecture option, mapped to `spec_delta` and/or `implementation_delta`; that handoff is where TODO normalization happens.

## Review depth and proportionality

Choose a review depth before detailed findings:

- Start with the lightest depth that can answer the audit question confidently. Deepen only when risk, weak proof, or boundary count justifies it.
- `quick`
  - Default for bounded `small_change` audits.
  - Review changed files plus the smallest adjacent proof surface needed to answer the audit question confidently.
- `standard`
  - Default for most `bug_report`, `functionality`, `enhancement_proposal`, and step-scoped audits.
  - Review the changed surface plus the adjacent contracts, tests, docs, configs, and entrypoints that materially affect the verdict.
- `deep`
  - Default for `big_branch`, `master_chef_multi_step`, security-sensitive, migration-heavy, or otherwise multi-boundary audits.
  - Review by boundary cluster and risk order, not just by raw diff order.
- Apply deep review only where the audit type, risk, or evidence warrants it. Do not impose branch-scale expectations on a `quick` audit.
- Unrelated repo drift stays report-only unless it materially changes the goal-match verdict, finding severity, root-cause grouping, affected boundary, or recommended next path.

## As-built model

For retrospective audit shapes (`bug_report`, `functionality`, `small_change`, `big_branch`, `master_chef_multi_step`) with an implemented surface, emit a visible as-built model before the `Goal match` verdict. The model commits the auditor to a reading of what the implementation actually is before any verdict compares it against what it should be.

- Model parts:
  - `Diagram` — compact ASCII: components, data/control flow, boundary crossings.
  - `Gist` — 2-4 sentences: what the audited surface actually does as built.
  - `Delta stats` — the audited delta's measured size: files changed, LOC added/deleted, net — tool output (`git diff --numstat`-style), never estimated. Report generated, vendored, and lockfile churn separately so it cannot distort the counts. No measurable delta (whole-codebase scope, no diff surface): one line naming why, no numbers.
  - `Perceived intent vs stated intent` — the implementation's apparent design goal, stated independently, then marked `matches` or `diverges at <point>` against the stated contract.
  - `Limits & assumptions` — every encoded bound in the audited surface (string lengths, collection caps, numeric ranges, timeouts, retries, concurrency caps, enum sets, truncations, defaults) as `limit | value | location/owner | behavior when reached | verdict`, where the verdict is an action plus its reason:
    - `keep — <reason>` — required by an external or public contract, or a minimum necessary guard at the owner of a proven trust, resource, external deadline, or liveness risk; being contractual is provenance, not proof the bound is well designed
    - `too restrictive — <reason>` — the risk may be real, but the value or placement rejects valid production work, silently truncates truth, duplicates another owner, or adds defense at every layer; name what to relax
    - `remove — <reason>` — nothing breaks without it: the bound is arbitrary (no consumer or rationale found) or over-defensive where deleting beats relaxing
    - `add bound — <reason>` — reserved for a proven trust, resource, external-deadline, or liveness risk with a named owner; most values should stay unbounded, and a missing bound without such proof is not a defect
  - `Prior art` — existing similar solutions or established repo patterns the audited surface overlaps, each marked `standardizable onto <surface>` or `novel`.
- A `keep` verdict needs a strong reason: the contract or proven risk, the value, the owner, and the reached behavior all justified — otherwise the verdict is `remove` or `too restrictive`. An implementation may need to honor a fixed external contract; when the contract itself is in scope, flag an unsupported cap as a contract weakness. Prefer one canonical bound at the risk owner plus streaming, pagination, backpressure, cancellation, or explicit failure over cascading caps and silent truncation. Do not turn an arbitrary bound into configuration unless operators have a real tuning need.
- Evidence: the model cites only code, tests, configs, manifests, and observable behavior — never plan or spec wording.
- Blind window: when `Read strategy` is `plan-vs-implementation`, the stated contract is locator-only until `Gist`, `Perceived intent`, and the limits inventory are drafted. Locator use answers where the audited surface is (scope, shape, files, step ids, boundaries); semantic use answers what it should do. Deep-read the stated claims only after drafting, then emit the diff.
- No stated contract (`implementation-only`): the diff line reads `no stated contract`, perceived intent stands as the audit baseline, and the missing contract surface stays a finding per the missing-proof-surface rule.
- Depth scaling: `quick` = `Gist` + `Delta stats` + limits inventory, diagram and `Prior art` optional; `standard`/`deep` = the full model including `Prior art`.
- Soft checkpoint: intent divergence or a load-bearing ambiguous limit routes through the existing one-framing-clarification rule — no second question gate. User corrections re-anchor the audit without consuming a finding approval.
- Scope: one model per audited scope. Multi-step and branch scopes model the composed result, not per-step; bound the limits inventory to the audited delta plus directly touched surfaces.
- Exemptions: `enhancement_proposal` — the `Existing-capability inventory` plays this role per `## Enhancement-proposal audit`; readiness audits of unbuilt TODO steps skip the model with a one-line reason.
- Findings map into existing dimensions: intent divergence → `goal / contract match`; `add bound` verdicts → `correctness / failure handling`; `remove` and `too restrictive` verdicts → `complexity / maintainability` and, when production behavior changes, `correctness / failure handling`; deletion opportunities, duplicate logic, and obscured values → `complexity / maintainability`; test-cost findings → `verification quality`.

Example shape:

```
As-built model — import pipeline

  file ──▶ parse() ──▶ validate() ──▶ apply()
              │             │
              ▼             ▼
         defaults.py   limits.py (MAX_ROWS=500)

Gist: streams rows from CSV, validates per-row, applies in one transaction.
Delta stats: 6 files, +412 / -38 LOC (net +374); package-lock.json churn
(+1,120) reported separately.
Perceived intent: bulk-import with all-or-nothing semantics.
Stated intent (Step 42): "import user CSVs" -> diverges: contract is silent
on atomicity; implementation chose all-or-nothing.
Prior art: jobs/bulk_load.py batch importer -> standardizable onto its
chunked-apply path instead of a second import pipeline.

Limits & assumptions:
| limit          | value     | location/owner   | behavior when reached    | verdict                                      |
| max rows       | 500       | limits.py:import | rejects row 501          | remove — no consumer found                   |
| upload timeout | 5s        | http.py:upload   | valid large uploads fail | too restrictive — p95 is 8s; raise or stream |
| email length   | unbounded | parse.py:email   | memory grows with input  | add bound — proven memory risk; owner parse() |
```

## Core direction checkpoint

For qualifying retrospective audits with an implemented delta, stop after the as-built model and confirm the audit baseline with the user before moving into gap analysis.

- Trigger for:
  - `functionality`
  - `big_branch`
  - `master_chef_multi_step`
  - step-scoped retrospective audits
  - `small_change` only when the delta changes behavior, contract, or user-visible scope
- Emit one visible `Core direction checkpoint` block with:
  - `Recent delta reviewed` — the concrete commit, diff, changed-file, or step-scoped implementation surface inspected, plus the affected boundaries
  - `Intent provenance` — the intent sources used to judge direction, in priority order, such as selected TODO step, spec, issue or PR thread, README, commit message, or journal note; mark weak or missing sources explicitly
  - `As-built model` — reuse the model emitted per `## As-built model`; do not restate it in full unless compact reuse would be unclear
  - `Requirements coverage` — the smallest useful set of in-scope required behaviors or capabilities, grouped when practical; mark each `implemented`, `partial`, `missing`, `unclear`, `deferred by contract`, or `out of scope`, with one concrete evidence cite
  - `Direction verdict` — `aligned`, `aligned with gaps`, `misaligned`, or `unclear`
  - `Open assumptions / proof gaps` — remaining inference, missing proof surface, or unresolved contract weakness that still limits confidence
- Treat a capability as `missing` only when it is required by the reviewed in-scope intent surfaces and absent or materially incomplete in the implementation reviewed.
- If the intent sources conflict materially, mark the affected requirement or the overall direction `unclear` and use the checkpoint to re-anchor the audit instead of guessing.
- Do not continue into missing-item analysis, normalized findings, or planning-oriented recommendations until the user confirms or corrects this baseline.
- Default checkpoint options:
  - `A. Continue — the baseline is correct; review gaps and findings`
  - `B. Correct the baseline — update the intended behavior or requirements before findings`
  - `C. Change scope — review a smaller or different surface`
  - `D. Stop — end after the baseline review; do not produce findings`
- Baseline confirmation validates the auditor's reading of product direction, requirements understanding (including any missing-requirement claim), implementation shape, and audit scope. It neither approves findings nor authorizes follow-up work. Major-finding approval still happens later per `## Interaction contract`.

## Boundary and simplicity check

For every implemented or proposed solution, judge the audited delta against the simplest shape that preserves correct ownership and fits the real capability family. Reuse the `As-built model` (diagram, `Delta stats`, `Prior art`, limits inventory) when emitted; for proposals, reuse the `Existing-capability inventory` and `Integration options` rather than creating another model.

Trace one representative path: entrypoint → validation/authority → state or durable effect → projection/adapter. Judge:

- `Boundaries` — Give truth, policy, validation, persistence, orchestration, and presentation one appropriate owner; point dependencies toward it. Flag duplicated truth or reversed dependencies, but do not collapse a necessary boundary to reduce layers.
- `Simplicity / elegance` — Try deletion, standardization onto the model's `Prior art`, an existing seam, or direct composition first. Keep an abstraction only when it owns policy/state, isolates a real dependency, or removes proven repetition. Flag indirection hiding a plain value — a getter, factory, or config layer over one fixed value, a single-variant wrapper or enum, a resolution chain returning a literal, a pass-through parameter that never varies: keep such values readable at the use site unless the indirection owns real variation, policy, or state. The main and failure paths should remain locally explainable; tie every concern to concrete cost or risk.
- `Limit discipline` — Keep only contractual and minimum necessary defensive bounds, judged per the limits rules in `## As-built model`; missing protection at a real trust/resource boundary remains a correctness issue.
- `Reusable generality` — Use the narrowest contract serving current consumers or an established extension seam. Flag duplicated shared concerns and generic APIs for hypothetical consumers; system-wide reuse is not maximum abstraction.
- `Duplication` — Detect logic repeated within the delta and delta code reimplementing an existing repo surface, anchored to the model's `Prior art`. Cite both locations; prefer standardizing onto the existing owner over parallel copies.
- `Legacy load` — Require compatibility aliases, deprecated dependencies, superseded paths, old-format writes, or parallel truth to have a live caller, durable-data, or public-contract reason, regression proof, and a permanence or retirement decision. Proposals name the evidence and proof plan. Do not confuse retry, failover, or recovery with compatibility.

Practical example: if two adapters need the same normalization, prefer one small function at their existing shared boundary; add a registry or strategy layer only when runtime selection is real. Reading stored v1 rows can be justified compatibility, while adding a new v1 write path without a live consumer is legacy-on-arrival. A provider timeout backed by its SLA and real cancellation can be defensive; a 100-row scan that silently hides valid results is over-defensive.

Emit `Solution shape` and `Deletion opportunities` together before normalized findings. For `quick`, give one overall verdict plus one evidence sentence. For `standard` or `deep`, give one evidence-backed line for each field:

- `Boundary integrity`: `respected` | `strained` | `violated` | `unclear`
- `Simplicity / elegance`: `simplest` | `justified complexity` | `over-engineered` | `unclear`
- `Limit posture`: `minimal` | `justified` | `over-defensive` | `under-defensive` | `unclear`
- `Reusable generality`: `right-sized` | `under-generalized` | `over-generalized` | `unclear`
- `Legacy load`: `none` | `justified compatibility` | `legacy-on-arrival` | `unclear`
- `Duplication`: `none` | `within-delta` | `vs-repo` | `both` | `unclear`
- `Deletion opportunities`: `none` | `found (<n> cited)` | `unclear`
- `Verdict`: `KISS and boundary-aligned` | `aligned with justified complexity` | `works but over-engineered` | `boundary-breaking` | `unclear`

`Deletion opportunities` lists every cited candidate: what to delete, why it is safe, the evidence — a dead or unreachable path, a superseded caller, a duplicate of named `Prior art` or an existing seam, or a limits-table `remove` / `too restrictive` verdict — and approximate LOC recoverable when measurable. With no candidates, state `none` plus one evidence sentence. A net-additive delta is never a finding by itself; an uncited candidate stays report-only, labeled speculative.

Expand only non-green or unclear judgments into findings, and only when they create concrete behavior risk or maintenance cost; still cite concrete evidence for a green verdict.

## Core audit dimensions

Every audit uses these core dimensions. Treat them as questions the audit must answer, phrased relative to the chosen audit type and intended goal.

- `solution shape / boundaries`
  - Apply `## Boundary and simplicity check` to the actual implementation or recommended proposal integration shape, not only its names or file count; its expansion rule decides which judgments become findings.

- `goal / contract match`
  - Compare implementation against the requested audit question, intended goal, `README.md`, `docs/specs/*`, the selected `TODO*.md` scope, and observable current behavior.
  - For one-step or multi-step TODO audits, compare each selected step's contract sections per `## Step-scoped TODO contract audit` against the concrete implementation delta reviewed for that scope, not only the final filesystem state.
  - Treat drift between code, tests, and docs as a real finding.
  - Before listing normalized findings, emit a compact `Goal match` or equivalent summary stating whether the intended goal is understood, whether the implementation matches, partially matches, or misses it, and whether the proof surface is strong enough to justify that verdict. When an as-built model was emitted, build this verdict on the model's `Perceived intent vs stated intent` diff. When a `Core direction checkpoint` was emitted, build the verdict on the confirmed baseline, not the pre-confirmation draft.
- `correctness / failure handling`
  - Check happy paths, edge cases, failure paths, boundary validation, and state or data invariants.
  - Validate untrusted input early, separate syntactic from semantic validation when both matter, and keep invariants explicit where they protect real behavior.
  - Require only the bounds justified per `## As-built model`; verify cancellation, partial-work, retry, and user-visible behavior when each is reached.
  - For `bug_report`, treat missing repro closure or new adjacent regression risk as first-class findings.
- `verification quality`
  - Prioritize confidence over coverage theater.
  - Prefer a layered suite with mostly integration where it buys meaningful confidence, plus narrower unit tests and fewer high-level tests.
  - Flag brittle tests that assert implementation details, broad unrelated object equality, mock choreography, fragile snapshots, or other harmless-refactor breakpoints.
  - Flag useless tests that duplicate lower-level coverage without adding confidence, or that mainly check framework behavior instead of product behavior.
  - Flag needlessly costly tests: real sleeps or waits instead of controllable time, heavyweight fixtures or broad integration setup where a narrower test buys the same confidence, redundant per-test rebuilding of shared state, duplicated parameterization. Judge cost against confidence bought; a test-cost finding needs observable evidence (test code, measured runtime, or a CI signal) and targets the tests' own runtime cost, never missing benchmark coverage.
  - Check whether tests, automated checks, and UAT cover the real contract, edge cases, and failure paths instead of only the happy path.
- `complexity / maintainability`
  - Default to KISS: prefer simpler, clearer solutions over clever indirection.
  - Apply YAGNI: flag speculative abstraction, nested wrapper indirection, value-obscuring indirection (a plain value behind a getter, factory, config layer, or wrapper that owns no real variation), generic APIs with one concrete use, parameterization or extension points without real consumers, and ceremony that does not protect a real boundary.
  - Apply SOLID pragmatically, with SRP first: use "one reason to change" as the first pressure test before broader rewrites.
- `documentation / operability`
  - Audit `README.md`, `docs/specs/*` (PRD, blueprint, and connected `*-definition.md` leaf specs), `docs/INDEX.md` (with `docs/index/**` siblings when INDEX split is active), `docs/runbooks/*.md`, repo-root `RUNBOOK.md`, and the current-state header of `docs/JOURNAL.md` when present when they materially affect the audit verdict.
  - Documentation should stay compact and optimized for reading.
  - Specs should match the current codebase or clearly intended future implementation. Specs for removed features are `drifted` findings; major implementation areas without spec coverage are `missing` findings.
  - For `docs/INDEX.md`: verify the entrypoint layout matches the actual mode per the boilerplate INDEX-split scaling rules — single-file mode should not carry a Layout pointer block; split mode should carry Layout pointers and keep diagram or inventory bodies in `docs/index/**` siblings rather than inline. A single-file INDEX exceeding ~300 lines or with unbounded-growth sections is a structural drift finding — recommend INDEX split via `cdd-maintain` index mode. Stale INDEX (clearly older than current TODO or journal activity) is also a `documentation` finding.
  - For mermaid diagrams (inline in `docs/INDEX.md` for single-file mode, or in `docs/index/DIAGRAMS.md` for split mode): verify each diagram still matches the current supervision tree, flow shape, module boundaries, or component layout it claims to represent. Diagrams referencing removed components, missing newly-added ones, or showing structurally outdated edges are `drifted` findings — cite the specific node or edge.
  - For `docs/runbooks/*.md` and repo-root `RUNBOOK.md`: verify each documented procedure or command still resolves to a live entrypoint, service, or script. Procedures for decommissioned, renamed, or removed surfaces are `drifted` findings.

## Optional lenses

Activate optional lenses only when the scope, audit type, or evidence warrants them. A lens may deepen the audit, raise the review depth, or indicate specialist review is needed, but it should never become mandatory noise in every audit.

- `security / privacy`
  - Review trust boundaries, sensitive data handling, authorization, secrets, logging, privacy-sensitive flows, and places where failure-path behavior could expose data or privilege.
- `dependency / provenance / supply chain`
  - Review new or upgraded third-party components in the context of their expected use.
  - Check secure configuration, dependency diffs, provenance or SBOM signals when available, and unresolved trust or vulnerability gaps that materially affect the audit.
- `reliability / availability / performance / scalability`
  - Review concurrency, retries, recovery, load-sensitive code paths, data volume assumptions, and operational behavior under failure or growth.
- `migration / compatibility / rollout / rollback`
  - Review schema, config, manifest, or API changes for deployment order, backward compatibility, state transitions, rollout safety, and rollback posture.
- `ux / accessibility / i18n / concurrency`
  - Activate the relevant subset when the change affects user interaction, accessibility guarantees, localization behavior, or concurrency-sensitive flows that need specialist review or deeper proof.
- If you are not qualified to judge a triggered lens confidently, say so and record that specialist review or stronger proof is required instead of pretending the audit is complete.

## Plain-English output
Use simple English for every user-facing explanation and option. A capable reader who does not know the repo's internal terms should understand it on the first read.

- Lead with the main point. Name the concrete behavior or action and its effect. Use common words and one idea per short sentence. Explain any necessary technical term once.
- Never coin a new term inside a finding. When a concept truly needs a name, define it in one plain phrase at first use; otherwise describe the concrete behavior or action instead of naming a concept.
- Default `Problem` and `Solution` to one sentence each; add a second only when needed. Keep exact evidence and internal labels in `Details` instead of repeating them in prose.
- Write each option as one decision on one short line: `<selector>. <action> — <immediate result>; <main trade-off>`. Omit the trade-off when none matters. Split choices that lead to different outcomes.

## Finding normalization
Do not emit raw audit bullets as the final output.

- The compact `Goal match` verdict answers the audit question. Normalized findings explain why that verdict is justified or weak.
- Ground every finding in observed evidence from the audited surface: code, tests, configs, artifact text, or observable behavior. Never derive a finding from an implementation, architecture, or contract the auditor imagined. Anything an in-scope artifact leaves unspecified is at most a gap note or a clarification, never a defect finding.
- Normalize each finding into four blocks:
  - `Problem` — state the current behavior, cause, affected user or system, and impact.
  - `Solution` — state the smallest safe change, where it belongs, and how to prove it worked. If evidence is insufficient, state what must be learned first instead of guessing.
  - `Assumptions` — every load-bearing assumption the finding rests on, each tagged `evidence-backed <cite>`, `user-confirmed`, or `unconfirmed`; write `none` when the finding rests on observed evidence alone. Assumptions are communicated, never gating: an `unconfirmed` assumption never suppresses the finding, blocks its triage, or auto-converts it into a clarification — it stays visible so the user can strike it.
  - `Details` — audit dimension; severity (`high`, `medium`, or `low`); affected boundary; exact evidence; recommended next path; and approval recommendation. Keep technical labels here; never use them instead of explaining the problem or fix.
- State what approval authorizes as `<action> in <place> so <result>`, translating planner labels into concrete work. Example: `Check session expiry in the login handler and add a regression test so expired users are signed out.`
- If several paths are materially different, use approval variants per `## Interaction contract`; otherwise show one recommendation.
- Anchor each finding to the chosen audit type and the goal-match verdict. Avoid side findings that do not change the audit question being answered.
- Collapse duplicate symptoms into the smallest root-cause finding that can be discussed and planned cleanly.
- Fold material edge-case and failure-path gaps into normalized findings — never a separate planning-style section. An edge-case or failure-path finding requires an observed trigger path (code path, test, config, or repro) in the audited surface; a "could happen" case without one stays report-only, labeled speculative.
- When follow-up should go to `cdd-plan`, map approved findings into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- For `solution shape / boundaries`, `complexity / maintainability`, and `verification quality` findings, the cite is a file, symbol, diff, failing or missing test, or equivalent proof surface; keep each concrete and behavior-relevant.
- Prioritize correctness, contract drift, missing validation, missing failure-path coverage, and accidental complexity with real cost. Avoid style-only notes or vague refactor advice unless you can state a real behavior risk, confidence gap, or maintenance payoff.
- For `small_change`, collapse unrelated low-value drift aggressively; leave it report-only unless it materially changes the audit conclusion.

Example finding:

```text
Problem: Expired sessions remain active because the login handler does not check their expiry time.
Solution: Check expiry in the login handler and add a test that signs out expired sessions.
Assumptions: evidence-backed auth/session.ex:validate/1 — expiry is stored but never read at login; unconfirmed — no other layer is expected to enforce expiry.
Details: high correctness risk; boundary: session validation; evidence: auth/session.ex:validate/1; next: implementation_delta + verification_delta; approval: handler and regression-test follow-up.
```

## Interaction contract
This skill is interactive, read-only, and decision-driven.

- Stay read-only: do not patch code, docs, or TODO files in this skill.
- Ask a clarification only when the answer could materially change the audit conclusion — finding validity, severity, root-cause grouping, affected boundary, or recommended next path. Ask framing and proof-sufficiency questions before local implementation detail.
- Review edge-case and failure-path gaps only when they could change that same conclusion. Per `## Finding normalization`, an edge-case finding needs an observed trigger path; speculative cases stay report-only.
- Treat clarification as a loop, not a batch: ask the single highest-leverage question per message, combining ambiguities that share one root decision, then re-rank and ask the next after the user answers. Never list multiple open questions as a checklist.
- Each clarification states the current recommended finding direction and what audit conclusion would change if the answer differs.
- Do not re-ask what the user already answered, repo evidence already resolves, or an accepted assumption already covers.
- For qualifying retrospective audits, require exactly one baseline-confirmation pause after the `Core direction checkpoint` and before normalized findings; a baseline correction re-anchors the audit and does not consume a finding approval.
- Keep baseline confirmation, ambiguity clarification, and finding approval separate — never combined in one message; resolving an ambiguity does not approve a finding.
- Surface one proven finding at a time; collapse only symptoms with one root cause. After each decision, refresh the remaining list and show the next. Never batch findings into one approval checklist.
- Put choices last under `**Options**`. Give every option a visible letter selector; use numbers only when clearer. Tell the user they can reply with just the selector.
- Follow `## Plain-English output` and name each concrete action so every option stands alone.
- For one recommended follow-up path, use this shape and adapt its concrete nouns and actions to the finding (route choice happens at final closeout):
  - `A. Approve the session-expiry follow-up — include handler and regression-test work; no code changes yet`
  - `B. Backlog the session-expiry fix — record it for later; expired sessions remain possible`
  - `C. Keep current behavior — make no change; accept that expired sessions may stay active`
  - `D. Request evidence — reproduce the expired-session case; decide after results`
  - `E. Reject the finding — close it with no follow-up`
- When one finding has multiple credible approval paths, switch to variant mode:
  - `A. Choose the recommended path — same as A1`
  - `A1. <Recommended concrete action> — <immediate result>; <main trade-off>`
  - `A2. <Alternative concrete action> — <immediate result>; <main trade-off>`
  - `A3. <Alternative concrete action> — <immediate result>; <main trade-off>`
- Keep `B` through `E` from the single-path shape.
- Put the recommended variant first. Variants must differ in implementation, spec, verification, or sequence; collapse cosmetic variants into one recommendation.
- Accept compact replies such as `A`, `A1`, `A 1`, `A3`, `A 3`, `B`, `C`, `D`, or `E`. In variant mode, plain `A` selects `A1`.
- Minor findings and minor ambiguities can stay report-only unless they materially change the recommended follow-up.

## Flow
1) Read the contract docs and the likely proof surfaces for the requested audit, only far enough to stabilize framing, scope, and risk.
2) Frame the audit: classify audit type, intended goal, primary proof surface, read strategy, affected boundaries, review depth, and out-of-scope surfaces before detailed review.
3) Resolve the audit scope after framing stabilizes.
4) Choose the audit shape and review depth. Inventory affected boundaries or review order first for `big_branch` and `master_chef_multi_step` audits, and the `Existing-capability inventory` first for `enhancement_proposal` audits.
5) If the scope resolves to one or more TODO steps, record the selected step ids first and inspect each selected step's section contract before judging implementation quality.
6) For retrospective audits with an implemented surface, inspect one concrete implementation delta first: current branch diff, selected commits, or another repo-local changed-file surface appropriate to the chosen scope.
7) For retrospective shapes with an implemented surface, build and emit the visible as-built model per `## As-built model` before core-dimension review, honoring its blind-window ordering for `plan-vs-implementation` audits.
8) For qualifying retrospective audits, derive the smallest useful in-scope requirements set, map it to implementation evidence, emit the visible `Core direction checkpoint`, and pause for baseline confirmation or correction before normalized findings.
9) Apply `## Boundary and simplicity check` after any required retrospective baseline confirmation, or while ranking `Integration options` for an `enhancement_proposal`; then review the core audit dimensions together. Emit `Solution shape` and `Deletion opportunities` before normalized findings. If a baseline correction materially changes the checkpoint, refresh it before continuing. Do not audit code in isolation when the contract, proof surface, or tests are part of the issue.
10) Activate optional lenses only when the audit type, risk, or evidence triggers them. Note when specialist review is needed instead of pretending coverage you do not have.
11) Before listing normalized findings, emit the compact `Goal match` or equivalent verdict summary per `## Core audit dimensions`.
12) For step-scoped audits, decide whether the selected steps' checked tasks appear fully done, whether the observed implementation satisfies each step goal, and whether automated checks plus UAT evidence support the claimed completion. For `master_chef_multi_step`, also judge run-level execution quality and proof.
13) Normalize findings into root-cause items per `## Finding normalization`: simple-English `Problem` and `Solution`, tagged `Assumptions`, then `Details` evidence.
14) Resolve remaining ambiguities through the `## Interaction contract` clarification loop, asking only what could change the audit conclusion; otherwise report findings directly.
15) Triage each proven major finding per `## Interaction contract`: approve follow-up, backlog, accept, request evidence, or reject.
16) Keep a running list of:
   - findings approved for follow-up
   - findings backlogged
   - findings accepted as-is
   - findings needing more evidence
   - findings rejected
17) When the audit is complete, return a final audit summary that includes:
   - compact audit-framing summary — audit type, audited scope, review depth
   - core direction checkpoint summary per `## Core direction checkpoint`, when one was emitted
   - solution-shape verdict fields per `## Boundary and simplicity check`
   - goal-match verdict
   - which implementation delta, changed-file, or commit surface was reviewed
   - `Delta stats` and the `Deletion opportunities` outcome when a measurable delta was audited
   - findings by audit dimension
   - for step-scoped audits: the selected step ids plus the step-completion judgments from step 12
   - the full triage state from step 16, mapping approved findings to `cdd-plan` types (`spec_delta`, `implementation_delta`, `verification_delta`, `defer`) when the planning route is the recommended next action
   - notable missing proof surfaces, docs, specs, or tests
   - recommended next action
18) End with selector-labeled next actions.
   - Use the repo-local `NEXT` section when `AGENTS.md` defines one; otherwise use a final `**Options**` section.
   - When approved findings exist, present three routing options and put the recommended one first:
     - `A. Prepare implementation steps (recommended) — send approved findings to cdd-plan before changing code`
     - `B. Implement approved findings now — make a short plan here, then run cdd-implement`
     - `C. Stop here — leave approved findings for later; make no repo changes`
   - Route behavior: `A` asks one substantive planning question, compares fixes, and writes runnable TODO steps. `B` makes a short plan ordered by dependency, boundary, and validation, then invokes `$cdd-implement`; reuse existing TODO steps when available, otherwise use bounded direct tasks.
   - For `enhancement_proposal` audits, include the chosen integration option in the `cdd-plan` handoff as the pre-selected architecture option.
   - When no approved findings exist, do not recommend an empty `$cdd-plan` or direct implementation; offer concrete non-planning next actions such as backlog, stop, or rerun on a narrower audit slice.

## Guardrails
- Do not let a large scope erase the audit question. If the requested scope is broad, keep the audit ordered around the chosen shape and primary proof surfaces; if it is too large for one sane pass, propose a smaller first audit slice.
- If docs or specs are intentionally future-state, say so and audit for clarity rather than forcing current-state wording onto planned behavior.
