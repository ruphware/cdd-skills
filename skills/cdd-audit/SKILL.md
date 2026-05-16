---
name: cdd-audit
description: "Audit implementation scope for spec drift, code quality, test quality, accidental complexity, and documentation drift; triage major findings; then route approved follow-up into cdd-plan (explicit-only)."
disable-model-invocation: true
---

# CDD Audit (explicit-only)

Use this skill for explicit implementation or codebase audits. Output findings plus approved follow-up, not code changes.

## Sources of truth
Read:
- `AGENTS.md`
- `README.md`
- `TODO.md` and adjacent `TODO*.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/INDEX.md` when present (also `docs/index/**` siblings when INDEX split is active)
- relevant code, tests, configs, manifests, entrypoints, and validation surfaces for the chosen scope

Treat missing docs, specs, or tests as findings. Do not invent missing contract surfaces during the audit.

## Scope resolution
- Supported audit scopes:
  - last commit
  - uncommitted changes
  - one TODO step
  - multiple TODO steps
  - one TODO file
  - whole codebase
- Resolve the scope before asking anything.
- Ask only when the scope is missing or ambiguous, and keep the question scoped to the smallest missing decision.
- If the scope references TODO steps, resolve them the same way `cdd-implement-todo` would: normalize numeric step identifiers and ask only if multiple matches remain.
- If the scope resolves to one or more TODO steps, record the selected step ids explicitly and audit each selected step against its own step contract rather than only the broader TODO topic.

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

## Audit dimensions
Audit the chosen scope against all of the following:

- `spec compliance`
  - Compare implementation against `README.md`, `docs/specs/*`, the selected `TODO*.md` scope, and observable current behavior.
  - For one-step or multi-step TODO audits, compare each selected step's `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, and `UAT` against the concrete implementation delta reviewed for that scope, not only the final filesystem state.
  - Treat drift between code, tests, and docs as a real finding.
- `code quality`
  - Default to KISS: prefer simpler, clearer solutions over clever indirection.
  - Apply YAGNI: flag speculative flexibility, premature abstraction, and extension points with no real caller need.
  - Apply SOLID pragmatically, with SRP first: use "one reason to change" as the first pressure test before broader rewrites.
  - Check defensive code at boundaries: validate untrusted input early, separate syntactic from semantic validation when both matter, and keep invariants explicit where they protect real behavior.
- `test quality`
  - Prioritize confidence over coverage theater.
  - Prefer a layered suite with mostly integration where it buys meaningful confidence, plus narrower unit tests and fewer high-level tests.
  - Flag brittle tests that assert implementation details, broad unrelated object equality, mock choreography, fragile snapshots, or other harmless-refactor breakpoints.
  - Flag useless tests that duplicate lower-level coverage without adding confidence, or that mainly check framework behavior instead of product behavior.
  - Check whether tests cover the real contract, edge cases, and failure paths instead of only the happy path.
- `accidental complexity`
  - Expose speculative abstraction, wrapper indirection, generic APIs with one concrete use, parameterization without real consumers, and ceremony that does not protect a real boundary.
- `documentation`
  - Audit `README.md` and `docs/specs/*` when present.
  - Documentation should stay compact and optimized for reading.
  - Specs should match the current codebase or clearly intended future implementation.

## Finding normalization
Do not emit raw audit bullets as the final output.

- Normalize each finding into a root-cause item with:
  - audit dimension
  - severity: `high`, `medium`, or `low`
  - user-visible symptom
  - likely root cause
  - affected boundary
  - evidence or proof surface
  - recommended next path
- Collapse duplicate symptoms into the smallest root-cause finding that can be discussed and planned cleanly.
- Fold material edge-case and failure-path gaps into normalized findings; do not add a separate planning-style section for them.
- When follow-up should go to `cdd-plan`, map approved findings into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`
- For non-trivial `code quality` and `test quality` findings, cite the file, symbol, diff, failing or missing test, or equivalent proof surface, and keep the finding concrete, evidence-backed, and behavior-relevant.
- Prioritize correctness, contract drift, missing validation, missing failure-path coverage, and accidental complexity with real cost. Avoid style-only notes or vague refactor advice unless you can state a real behavior risk, confidence gap, or maintenance payoff.

## Interaction contract
This skill is interactive, read-only, and decision-driven.

- Stay read-only during the audit.
- Do not patch code, docs, or TODO files in this skill.
- Review edge-case and failure-path gaps only when they could materially change whether a finding is real, its severity, its root-cause grouping, the affected boundary, or the recommended `cdd-plan` follow-up.
- Collapse duplicate or closely related audit ambiguities into the smallest root decision that can be discussed cleanly.
- Ask at most one substantive clarification or decision question per message, and use ambiguity clarifications only when the answer could materially change the audit conclusion.
- Treat clarification as a loop, not a batch: after each user answer, re-rank the remaining unresolved ambiguities and ask the next single highest-leverage question, then wait again. Never list multiple open clarification questions in one message as a checklist for the user to answer all at once.
- Prefer the fewest questions that resolve the most audit uncertainty.
- Separate ambiguity resolution from finding approval: resolving an ambiguity does not approve a major finding for planning.
- Once a major finding is sufficiently proven and recommends follow-up, surface it to the user one at a time unless multiple findings clearly collapse into one root-cause decision. After each approval decision (approve/defer/accept/reject), refresh the remaining major-finding list and surface the next one. Do not present multiple major findings as a batch approval checklist for the user to triage at once.
- When several unresolved major ambiguities remain, ask the highest-leverage one first: prefer the question whose answer resolves the most uncertainty about finding validity, severity, grouping, affected boundary, or recommended next path.
- When multiple major ambiguities share one underlying decision, ask one combined clarification instead of separate repetitive questions.
- Each major clarification should state the current recommended finding direction and what audit conclusion would change if the answer differs.
- Do not re-ask a question already answered by the user, already resolved by repo evidence, or already covered by an accepted audit assumption.
- Put decision choices at the bottom under a final `**Options**` section.
- Prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key.
- default to letters: `A.`, `B.`, `C.`.
- use numbers only when the surrounding context is already numeric and that would be clearer.
- When practical, tell the user they can reply with just the selector.
- Default major-finding options:
  - `A. Approve for cdd-plan`
  - `B. Postpone or backlog`
  - `C. Accept current state`
  - `D. Reject finding or ask for more evidence`
- Minor findings and minor ambiguities can stay report-only unless they materially change the recommended follow-up.

## Flow
1) Read the contract docs and the relevant implementation surfaces for the chosen scope.
2) Resolve the audit scope before starting the audit proper.
3) If the scope resolves to one or more TODO steps, record the selected step ids first and inspect each selected step's section contract before judging implementation quality.
4) For step-scoped audits, inspect the corresponding implementation delta first: current branch diff, selected commits, or another repo-local changed-file surface appropriate to the chosen scope.
5) Audit code, tests, docs, configs, manifests, entrypoints, and validation surfaces together; do not audit code in isolation when the contract or tests are part of the issue.
6) For step-scoped audits, decide whether the selected steps' checked tasks appear fully done, whether the observed implementation satisfies each step goal, and whether automated checks plus UAT evidence support the claimed completion.
7) Normalize findings into root-cause items with explicit evidence, including material edge-case and failure-path gaps.
8) Collapse related unresolved ambiguities into root decisions. Ask only when an unresolved major ambiguity could materially change the audit conclusion; otherwise report the finding directly.
   - Ask the highest-leverage unresolved major question first, applying the loop rule from `Interaction contract`: one question per message, then refresh remaining ambiguities and ask the next after the user answers.
   - Use one combined clarification when several related ambiguities share one underlying decision.
9) Once a major finding is sufficiently proven and recommends follow-up, surface each planning-relevant major finding or collapsed root-cause finding one at a time with `**Options**` so it is either approved for planning now, deferred, accepted as-is, or rejected. After each approval decision, refresh the remaining major-finding list and surface the next one; do not batch approvals into one checklist.
   - Resolving ambiguity does not approve the finding for planning.
   - Use one approval decision when several symptoms clearly collapse into one root-cause finding.
10) Keep a running list of:
   - findings approved for planning now
   - findings deferred
   - findings accepted as-is
   - findings rejected or needing more evidence
11) When the audit is complete, return a final audit summary that includes:
   - audited scope
   - selected TODO step ids when the scope is step-scoped
   - which implementation delta or changed-file or commit surface was reviewed when the scope is step-scoped
   - findings by audit dimension
   - whether the selected steps' checked tasks appear fully done
   - whether the observed implementation matches the selected step goals
   - whether automated checks and UAT evidence support the claimed completion
   - approved findings mapped for `cdd-plan`
   - deferred or accepted findings
   - notable missing proof surfaces, docs, specs, or tests
   - recommended next action
12) End with selector-labeled next actions.
   - Use the repo-local `NEXT` section when `AGENTS.md` defines one; otherwise use a final `**Options**` section.
   - If approved findings exist, make `A. run cdd-plan on the approved findings` the recommended first option.
   - Otherwise, do not recommend an empty `$cdd-plan` invocation; offer concrete non-planning next actions such as backlog, stop, or rerun on a narrower audit slice.

## Guardrails
- If the user asks to fix findings directly from this skill, stop and recommend `$cdd-plan` first.
- If the audited scope is too large to review sanely in one pass, propose a smaller first audit slice before continuing.
- If docs or specs are intentionally future-state, say that explicitly and audit for clarity rather than forcing current-state wording onto planned behavior.
