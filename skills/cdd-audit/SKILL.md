---
name: cdd-audit
description: "Audit implemented work or proposed enhancements against stated intent using proportional proof; model as-built behavior before retrospective verdicts; explain every finding's problem and solution in simple English; then route approved follow-up into cdd-plan, direct implementation, or backlog (interactive, read-only)."
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
  - `Perceived intent vs stated intent` — the implementation's apparent design goal, stated independently, then marked `matches` or `diverges at <point>` against the stated contract.
  - `Limits & assumptions` — every encoded bound in the audited surface (string lengths, collection caps, numeric ranges, timeouts, retries, concurrency caps, enum sets, truncations, defaults) as `value | location (file:symbol) | origin | verdict`:
    - `contractual` — required by the stated contract
    - `defensive` — justified guard, rationale evident
    - `arbitrary` — no consumer or rationale found → useless-limit candidate
    - `missing` — unbounded input that should be bounded → false-assumption candidate
- Evidence: the model cites only code, tests, configs, manifests, and observable behavior — never plan or spec wording.
- Blind window: when `Read strategy` is `plan-vs-implementation`, the stated contract is locator-only until `Gist`, `Perceived intent`, and the limits inventory are drafted. Locator use answers where the audited surface is (scope, shape, files, step ids, boundaries); semantic use answers what it should do. Deep-read the stated claims only after drafting, then emit the diff.
- No stated contract (`implementation-only`): the diff line reads `no stated contract`, perceived intent stands as the audit baseline, and the missing contract surface stays a finding per the missing-proof-surface rule.
- Depth scaling: `quick` = `Gist` + limits inventory, diagram optional; `standard`/`deep` = full four-part model.
- Soft checkpoint: intent divergence or a load-bearing ambiguous limit routes through the existing one-framing-clarification rule — no second question gate. User corrections re-anchor the audit without consuming a finding approval.
- Scope: one model per audited scope. Multi-step and branch scopes model the composed result, not per-step; bound the limits inventory to the audited delta plus directly touched surfaces.
- Exemptions: `enhancement_proposal` — the `Existing-capability inventory` plays this role per `## Enhancement-proposal audit`; readiness audits of unbuilt TODO steps skip the model with a one-line reason.
- Findings map into existing dimensions: intent divergence → `goal / contract match`; missing bounds → `correctness / failure handling`; arbitrary limits → `complexity / maintainability`.

Example shape:

```
As-built model — import pipeline

  file ──▶ parse() ──▶ validate() ──▶ apply()
              │             │
              ▼             ▼
         defaults.py   limits.py (MAX_ROWS=500)

Gist: streams rows from CSV, validates per-row, applies in one transaction.
Perceived intent: bulk-import with all-or-nothing semantics.
Stated intent (Step 42): "import user CSVs" -> diverges: contract is silent
on atomicity; implementation chose all-or-nothing.

Limits & assumptions:
| limit        | value     | where        | origin    | verdict                 |
| max rows     | 500       | limits.py:12 | arbitrary | useless-limit candidate |
| email length | unbounded | parse.py:33  | —         | missing bound           |
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
  - `A. Baseline is correct — continue into missing items and findings`
  - `B. Correct the intended direction or requirement set — re-anchor the audit to this correction`
  - `C. Narrow or change the audited scope before findings`
  - `D. Stop after the baseline review`
- Baseline confirmation validates the auditor's reading of product direction, requirements understanding, implementation shape, and audit scope. It neither approves findings nor authorizes follow-up work. Major-finding approval still happens later per `## Interaction contract`.

## Core audit dimensions

Every audit uses these core dimensions. Treat them as five questions the audit must answer, phrased relative to the chosen audit type and intended goal.

- `goal / contract match`
  - Compare implementation against the requested audit question, intended goal, `README.md`, `docs/specs/*`, the selected `TODO*.md` scope, and observable current behavior.
  - For one-step or multi-step TODO audits, compare each selected step's `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, and `UAT` against the concrete implementation delta reviewed for that scope, not only the final filesystem state.
  - Treat drift between code, tests, and docs as a real finding.
  - Before listing normalized findings, emit a compact `Goal match` or equivalent summary stating whether the intended goal is understood, whether the implementation matches, partially matches, or misses it, and whether the proof surface is strong enough to justify that verdict. When an as-built model was emitted, build this verdict on the model's `Perceived intent vs stated intent` diff. When a `Core direction checkpoint` was emitted, build the verdict on the confirmed baseline, not the pre-confirmation draft.
- `correctness / failure handling`
  - Check happy paths, edge cases, failure paths, boundary validation, and state or data invariants.
  - Validate untrusted input early, separate syntactic from semantic validation when both matter, and keep invariants explicit where they protect real behavior.
  - For `bug_report`, treat missing repro closure or new adjacent regression risk as first-class findings.
- `verification quality`
  - Prioritize confidence over coverage theater.
  - Prefer a layered suite with mostly integration where it buys meaningful confidence, plus narrower unit tests and fewer high-level tests.
  - Flag brittle tests that assert implementation details, broad unrelated object equality, mock choreography, fragile snapshots, or other harmless-refactor breakpoints.
  - Flag useless tests that duplicate lower-level coverage without adding confidence, or that mainly check framework behavior instead of product behavior.
  - Check whether tests, automated checks, and UAT cover the real contract, edge cases, and failure paths instead of only the happy path.
- `complexity / maintainability`
  - Default to KISS: prefer simpler, clearer solutions over clever indirection.
  - Apply YAGNI: flag speculative flexibility, premature abstraction, and extension points with no real caller need.
  - Apply SOLID pragmatically, with SRP first: use "one reason to change" as the first pressure test before broader rewrites.
  - Expose speculative abstraction, wrapper indirection, generic APIs with one concrete use, parameterization without real consumers, and ceremony that does not protect a real boundary.
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

## Finding normalization
Do not emit raw audit bullets as the final output.

- The compact `Goal match` verdict answers the audit question. Normalized findings explain why that verdict is justified or weak.
- Normalize each finding into three blocks:
  - `Problem` — in simple English, state what happens now, why, who or what it affects, and why it matters.
  - `Solution` — in simple English, state the smallest safe change, where it belongs, and how to prove it worked. If the evidence is insufficient, state what must be learned first instead of guessing.
  - `Details` — audit dimension; severity (`high`, `medium`, or `low`); affected boundary; exact evidence; recommended next path; and approval recommendation.
- A reader must understand `Problem` and `Solution` without knowing internal vocabulary. Use short sentences and familiar words; keep necessary file, symbol, command, acronym, taxonomy, and routing labels in `Details`.
- Do not use labels such as `contract drift`, `proof gap`, `boundary`, or `implementation_delta` in place of explaining the problem, impact, or fix.
- The `approval recommendation` tells the user, in plain practical terms, what approving this finding would authorize next. Translate planner labels such as `implementation_delta plus verification_delta` into a bounded action summary the user can recognize quickly.
- Write the recommendation as `do X in Y so Z`: name the likely change, where it lands, and why it matters. Prefer `Show checkpoint lineage in local --chat from the existing session-context read, then add focused proof for that output` over raw taxonomy labels alone.
- When there are several materially different ways forward, include `approval variants` under the recommendation. Keep them to the smallest useful set, usually `2` to `4`, and make each one a distinct user-facing action rather than an abstract planning bucket. In variant mode, the recommendation names the approval family and each variant carries the concrete path text.
- Anchor each finding to the chosen audit type and the goal-match verdict. Avoid side findings that do not change the audit question being answered.
- Collapse duplicate symptoms into the smallest root-cause finding that can be discussed and planned cleanly.
- Fold material edge-case and failure-path gaps into normalized findings; do not add a separate planning-style section for them.
- When follow-up should go to `cdd-plan`, map approved findings into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- For non-trivial `complexity / maintainability` and `verification quality` findings, cite the file, symbol, diff, failing or missing test, or equivalent proof surface, and keep the finding concrete, evidence-backed, and behavior-relevant.
- Prioritize correctness, contract drift, missing validation, missing failure-path coverage, and accidental complexity with real cost. Avoid style-only notes or vague refactor advice unless you can state a real behavior risk, confidence gap, or maintenance payoff.
- For `small_change`, collapse unrelated low-value drift aggressively; leave it report-only unless it materially changes the audit conclusion.

## Interaction contract
This skill is interactive, read-only, and decision-driven.

- Stay read-only during the audit.
- Do not patch code, docs, or TODO files in this skill.
- Prefer framing or proof-surface clarifications before lower-level implementation-detail questions when ambiguity would materially change the audit conclusion.
- Review edge-case and failure-path gaps only when they could materially change whether a finding is real, its severity, its root-cause grouping, the affected boundary, or the recommended follow-up route.
- Ask clarifications only when the answer could materially change the audit conclusion — finding validity, severity, root-cause grouping, affected boundary, or recommended next path.
- Treat clarification as a loop, not a batch: ask the single highest-leverage question per message, combining ambiguities that share one root decision, then re-rank and ask the next after the user answers. Never list multiple open questions as a checklist.
- Each clarification states the current recommended finding direction and what audit conclusion would change if the answer differs.
- Prefer questions that resolve the audit question or proof sufficiency before questions about local implementation detail.
- Do not re-ask what the user already answered, repo evidence already resolves, or an accepted assumption already covers.
- Keep baseline confirmation separate from both ambiguity clarification and finding approval; do not combine them in one message.
- For qualifying retrospective audits, require exactly one baseline-confirmation pause after the `Core direction checkpoint` and before normalized findings.
- Use that pause to validate product direction, requirements understanding, implementation scope, and any claim that an in-scope requirement is missing.
- If the user corrects the baseline, re-anchor the audit and refresh the checkpoint if needed before proceeding; that correction does not consume a finding approval.
- Keep ambiguity resolution separate from finding approval: resolving an ambiguity does not approve a finding.
- Surface proven follow-up findings one at a time (collapse only when several share one root cause). After each decision (approve/defer/accept/reject), refresh the remaining list and surface the next — never batch findings into one approval checklist.
- Put decision choices at the bottom under a final `**Options**` section.
- Prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key.
- default to letters: `A.`, `B.`, `C.`.
- use numbers only when the surrounding context is already numeric and that would be clearer.
- When practical, tell the user they can reply with just the selector.
- Do not make `A.` a bare approval verb. Put the approval recommendation directly in the option text so the user can see what approval means without rereading the whole finding.
- Default major-finding options when there is one recommended follow-up path (per-finding triage; route choice happens in the final closeout stage):
  - `A. Approve recommended follow-up — <approval recommendation>`
  - `B. Postpone or backlog — <short practical summary>`
  - `C. Accept current state — <short practical summary of what stays unchanged>`
  - `D. Reject finding or ask for more evidence — <short practical summary>`
- When one finding has multiple credible approval paths, switch to variant mode:
  - `A. Approve one of the follow-up paths below — defaults to A1 if the user replies with just A`
  - `A1. Recommended path — <recommended approval path>`
  - `A2. Alternative path — <second approval path>`
  - `A3. Alternative path — <third approval path>`
  - `B. Postpone or backlog — <short practical summary>`
  - `C. Accept current state — <short practical summary of what stays unchanged>`
  - `D. Reject finding or ask for more evidence — <short practical summary>`
- Keep the recommended variant first. Mark it explicitly as recommended only when the ordering alone may be ambiguous.
- Each approval variant must be a real alternative in implementation, spec, verification, or sequencing terms, not cosmetic rewording. If the variants are not meaningfully different, collapse back to one `A.` recommendation.
- Accept compact selector replies such as `A`, `A1`, `A 1`, `A3`, `A 3`, `B`, `C`, or `D`.
- In variant mode, treat plain `A` as approval of the recommended path `A1` unless the user explicitly selects another numbered variant.
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
9) After the baseline is confirmed or corrected, review the core audit dimensions together. If the correction materially changes the checkpoint, refresh it before continuing. Do not audit code in isolation when the contract, proof surface, or tests are part of the issue.
10) Activate optional lenses only when the audit type, risk, or evidence triggers them. Note when specialist review is needed instead of pretending coverage you do not have.
11) Before listing normalized findings, emit the compact `Goal match` or equivalent verdict summary, built on the confirmed baseline and the as-built model's intent diff when a model was emitted.
12) For step-scoped audits, decide whether the selected steps' checked tasks appear fully done, whether the observed implementation satisfies each step goal, and whether automated checks plus UAT evidence support the claimed completion. For `master_chef_multi_step`, also judge run-level execution quality and proof.
13) Normalize findings into root-cause items that lead with a simple-English `Problem` and `Solution`, followed by explicit evidence and any material edge-case or failure-path gaps.
14) Collapse related unresolved ambiguities into root decisions. Ask only when one could materially change the audit conclusion; otherwise report the finding directly. Follow the `Interaction contract` clarification loop.
15) Once a major finding is proven and recommends follow-up, surface it with a short approval recommendation and `**Options**` (approve / defer / accept / reject) per the `Interaction contract`: one at a time, refresh after each decision, collapse only when symptoms share one root cause. When approval has real variants, use `A.` as the approval family, show explicit variants as `A1`, `A2`, `A3`, etc., and let plain `A` default to `A1`.
16) Keep a running list of:
   - findings approved for follow-up
   - findings deferred
   - findings accepted as-is
   - findings rejected or needing more evidence
17) When the audit is complete, return a final audit summary that includes:
   - audit type
   - audited scope
   - review depth
   - compact audit-framing summary
   - core direction checkpoint summary — recent delta reviewed, intent provenance, requirements coverage summary, direction verdict, open assumptions / proof gaps
   - goal-match verdict
   - selected TODO step ids when the scope is step-scoped
   - which implementation delta or changed-file or commit surface was reviewed
   - findings by audit dimension
   - whether the selected steps' checked tasks appear fully done
   - whether the observed implementation matches the selected step goals
   - whether automated checks and UAT evidence support the claimed completion
   - approved findings (mapped to `cdd-plan` types — `spec_delta`, `implementation_delta`, `verification_delta`, `defer` — when the planning route is the recommended next action)
   - deferred or accepted findings
   - notable missing proof surfaces, docs, specs, or tests
   - recommended next action
18) End with selector-labeled next actions.
   - Use the repo-local `NEXT` section when `AGENTS.md` defines one; otherwise use a final `**Options**` section.
   - When approved findings exist, present three routing options and put the recommended one first:
     - `A. hand off to cdd-plan on the approved findings` — recommended default; on approval, invoke `cdd-plan` on the approved set to weigh remediation options, ask one substantive clarification, and normalize them into runnable TODO steps before any implementation
     - `B. plan all approved findings inline, then implement directly` — skip the `cdd-plan` handoff: sequence every approved finding (and each collapsed root-cause package) into one compact in-session plan — order, affected boundaries, validation — then invoke `$cdd-implement` to execute it, TODO-backed where a finding maps to an existing step and bounded-direct otherwise
     - `C. backlog the approved findings or stop without further action this session` — defer to a later audit/plan cycle or close out
   - For `enhancement_proposal` audits, include the chosen integration option in the `cdd-plan` handoff as the pre-selected architecture option.
   - When no approved findings exist, do not recommend an empty `$cdd-plan` or direct implementation; offer concrete non-planning next actions such as backlog, stop, or rerun on a narrower audit slice.

## Guardrails
- cdd-audit stays read-only; do not patch code, docs, or TODO files from within this skill. When the user is ready to act, surface the final routing options so they can choose a `cdd-plan` handoff, an inline plan-and-implement over all approved findings, or backlog or stop.
- Do not let optional lenses become mandatory noise. Activate them only when the audit type, risk, or evidence justifies them.
- Do not force branch-scale review onto a bounded `small_change` audit.
- Do not let a large scope erase the audit question. If the requested scope is broad, keep the audit ordered around the chosen shape and primary proof surfaces.
- If the audited scope is too large to review sanely in one pass, propose a smaller first audit slice before continuing.
- If docs or specs are intentionally future-state, say that explicitly and audit for clarity rather than forcing current-state wording onto planned behavior.
