---
name: cdd-implementation-audit
description: "Audit implementation scope for spec drift, code quality, test quality, accidental complexity, and documentation drift; triage major findings; then route approved follow-up into cdd-plan (explicit-only)."
disable-model-invocation: true
---

# CDD Implementation Audit (explicit-only)

Use this skill for explicit implementation or codebase audits. Output findings plus approved follow-up, not code changes.

## Sources of truth
Read:
- `AGENTS.md`
- `README.md`
- `TODO.md` and adjacent `TODO*.md`
- `docs/specs/prd.md`
- `docs/specs/blueprint.md`
- `docs/INDEX.md` when present
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

## Audit dimensions
Audit the chosen scope against all of the following:

- `spec compliance`
  - Compare implementation against `README.md`, `docs/specs/*`, the selected `TODO*.md` scope, and observable current behavior.
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
- When follow-up should go to `cdd-plan`, map approved findings into one or more of:
  - `spec_delta`
  - `implementation_delta`
  - `verification_delta`
  - `defer`

## Interaction contract
This skill is interactive, read-only, and decision-driven.

- Stay read-only during the audit.
- Do not patch code, docs, or TODO files in this skill.
- Ask at most one substantive clarification or decision question per message.
- Major findings must be checked with the user one at a time unless multiple findings clearly collapse into one root-cause decision.
- Put decision choices at the bottom under a final `**Options**` section.
- Prefix every option label with a visible selector in the label itself so plan-mode UIs still show a selectable key.
- default to letters: `A.`, `B.`, `C.`.
- use numbers only when the surrounding context is already numeric and that would be clearer.
- When practical, tell the user they can reply with just the selector.
- Default major-finding options:
  - `A. Plan fix now in cdd-plan`
  - `B. Postpone or backlog`
  - `C. Accept current state`
  - `D. Reject finding or ask for more evidence`
- Minor findings can stay report-only unless they materially change the recommended follow-up.

## Flow
1) Read the contract docs and the relevant implementation surfaces for the chosen scope.
2) Resolve the audit scope before starting the audit proper.
3) Audit code, tests, docs, configs, and entrypoints together; do not audit code in isolation when the contract or tests are part of the issue.
4) Normalize findings into root-cause items with explicit evidence.
5) Report concise minor findings and surface major findings one at a time with `**Options**`.
6) Keep a running list of:
   - findings approved for planning now
   - findings deferred
   - findings accepted as-is
   - findings rejected or needing more evidence
7) When the audit is complete, return a final audit summary that includes:
   - audited scope
   - findings by audit dimension
   - approved findings mapped for `cdd-plan`
   - deferred or accepted findings
   - notable missing proof surfaces, docs, or tests
   - recommended next action
8) End by recommending `$cdd-plan` for the approved findings set.

## Guardrails
- If the user asks to fix findings directly from this skill, stop and recommend `$cdd-plan` first.
- If the audited scope is too large to review sanely in one pass, propose a smaller first audit slice before continuing.
- If docs or specs are intentionally future-state, say that explicitly and audit for clarity rather than forcing current-state wording onto planned behavior.
