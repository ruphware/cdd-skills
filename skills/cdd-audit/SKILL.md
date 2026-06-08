---
name: cdd-audit
description: "Audit implementation scope for spec drift, code quality, test quality, accidental complexity, and documentation drift; triage major findings; then route approved follow-up into cdd-plan, direct implementation, or backlog (interactive, read-only)."
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
- If the scope references TODO steps, resolve them the same way `cdd-implement` would: normalize numeric step identifiers and ask only if multiple matches remain.
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
  - Audit `README.md`, `docs/specs/*` (PRD, blueprint, and connected `*-definition.md` leaf specs), `docs/INDEX.md` (with `docs/index/**` siblings when INDEX split is active), `docs/runbooks/*.md`, repo-root `RUNBOOK.md`, and the current-state header of `docs/JOURNAL.md` when present.
  - Documentation should stay compact and optimized for reading.
  - Specs should match the current codebase or clearly intended future implementation. Specs for removed features are `drifted` findings; major implementation areas without spec coverage are `missing` findings (treat as findings, do not invent specs during the audit).
  - For `docs/INDEX.md`: verify the entrypoint layout matches the actual mode per the boilerplate INDEX-split scaling rules — single-file mode should not carry a Layout pointer block; split mode should carry Layout pointers and keep diagram/inventory bodies in `docs/index/**` siblings rather than inline. A single-file INDEX exceeding ~300 lines or with unbounded-growth sections is a structural drift finding — recommend INDEX split via `cdd-maintain` index mode. Stale INDEX (clearly older than current TODO or journal activity) is also a `documentation` finding.
  - For mermaid diagrams (inline in `docs/INDEX.md` for single-file mode, or in `docs/index/DIAGRAMS.md` for split mode): verify each diagram still matches the current supervision tree, flow shape, module boundaries, or component layout it claims to represent. Diagrams referencing removed components, missing newly-added ones, or showing structurally outdated edges are `drifted` findings — cite the specific node or edge.
  - For `docs/runbooks/*.md` and repo-root `RUNBOOK.md`: verify each documented procedure or command still resolves to a live entrypoint, service, or script. Procedures for decommissioned, renamed, or removed surfaces are `drifted` findings.

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
- Review edge-case and failure-path gaps only when they could materially change whether a finding is real, its severity, its root-cause grouping, the affected boundary, or the recommended follow-up route.
- Ask clarifications only when the answer could materially change the audit conclusion — finding validity, severity, root-cause grouping, affected boundary, or recommended next path.
- Treat clarification as a loop, not a batch: ask the single highest-leverage question per message, combining ambiguities that share one root decision, then re-rank and ask the next after the user answers. Never list multiple open questions as a checklist.
- Each clarification states the current recommended finding direction and what audit conclusion would change if the answer differs.
- Do not re-ask what the user already answered, repo evidence already resolves, or an accepted assumption already covers.
- Keep ambiguity resolution separate from finding approval: resolving an ambiguity does not approve a finding.
- Surface proven follow-up findings one at a time (collapse only when several share one root cause). After each decision (approve/defer/accept/reject), refresh the remaining list and surface the next — never batch findings into one approval checklist.
- Put decision choices at the bottom under a final `**Options**` section.
- Prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key.
- default to letters: `A.`, `B.`, `C.`.
- use numbers only when the surrounding context is already numeric and that would be clearer.
- When practical, tell the user they can reply with just the selector.
- Default major-finding options (per-finding triage; route choice happens at step 12):
  - `A. Approve for follow-up`
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
8) Collapse related unresolved ambiguities into root decisions. Ask only when one could materially change the audit conclusion; otherwise report the finding directly. Follow the `Interaction contract` clarification loop.
9) Once a major finding is proven and recommends follow-up, surface it with `**Options**` (approve / defer / accept / reject) per the `Interaction contract`: one at a time, refresh after each decision, collapse only when symptoms share one root cause.
10) Keep a running list of:
   - findings approved for follow-up
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
   - approved findings (mapped to `cdd-plan` types — `spec_delta`, `implementation_delta`, `verification_delta`, `defer` — when the planning route is the recommended next action)
   - deferred or accepted findings
   - notable missing proof surfaces, docs, specs, or tests
   - recommended next action
12) End with selector-labeled next actions.
   - Use the repo-local `NEXT` section when `AGENTS.md` defines one; otherwise use a final `**Options**` section.
   - When approved findings exist, present three routing options and put the recommended one first:
     - `A. hand off to cdd-plan on the approved findings` — recommended default; on approval, invoke `cdd-plan` on the approved set to weigh remediation options, ask one substantive clarification, and normalize them into runnable TODO steps before any implementation
     - `B. plan all approved findings inline, then implement directly` — skip the `cdd-plan` handoff: sequence every approved finding (and each collapsed root-cause package) into one compact in-session plan — order, affected boundaries, validation — then invoke `$cdd-implement` to execute it, TODO-backed where a finding maps to an existing step and bounded-direct otherwise
     - `C. backlog the approved findings or stop without further action this session` — defer to a later audit/plan cycle or close out
   - When no approved findings exist, do not recommend an empty `$cdd-plan` or direct implementation; offer concrete non-planning next actions such as backlog, stop, or rerun on a narrower audit slice.

## Guardrails
- cdd-audit stays read-only; do not patch code, docs, or TODO files from within this skill. When the user is ready to act, surface the step 12 routing options so they can choose a `cdd-plan` handoff, an inline plan-and-implement over all approved findings, or backlog or stop.
- If the audited scope is too large to review sanely in one pass, propose a smaller first audit slice before continuing.
- If docs or specs are intentionally future-state, say that explicitly and audit for clarity rather than forcing current-state wording onto planned behavior.
