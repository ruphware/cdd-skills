# Boundary and dimensions

## Contents

- `## Boundary and simplicity check`: the six judgments, a practical example, the `Solution shape` fields, deletion opportunities
- `## Core audit dimensions`: the six questions every audit answers
- `## Optional lenses`: specialist lenses activated only when triggered

## Boundary and simplicity check

For every implemented or proposed solution, judge the audited delta against the simplest shape that preserves correct ownership and fits the real capability family. Reuse the as-built model (`Diagram`, `Delta stats`, `Prior art`, limits inventory) when emitted; for proposals, reuse the `Existing-capability inventory` and `Integration options` rather than creating another model.

Trace one representative path: entrypoint → validation/authority → state or durable effect → projection/adapter. Judge:

- `Boundaries`: give truth, policy, validation, persistence, orchestration, and presentation one appropriate owner; point dependencies toward it. Flag duplicated truth or reversed dependencies, but do not collapse a necessary boundary to reduce layers.
- `Simplicity / elegance`: try deletion, standardization onto the model's `Prior art`, an existing seam, or direct composition first. Keep an abstraction only when it owns policy/state, isolates a real dependency, or removes proven repetition. Flag indirection hiding a plain value (a getter, factory, or config layer over one fixed value, a single-variant wrapper or enum, a resolution chain returning a literal, a pass-through parameter that never varies): keep such values readable at the use site unless the indirection owns real variation, policy, or state. The main and failure paths should remain locally explainable; tie every concern to concrete cost or risk.
- `Limit discipline`: keep only contractual and minimum necessary defensive bounds, judged per the limit verdicts in `as-built-model.md`; missing protection at a real trust/resource boundary remains a correctness issue.
- `Reusable generality`: use the narrowest contract serving current consumers or an established extension seam. Flag duplicated shared concerns and generic APIs for hypothetical consumers; system-wide reuse is not maximum abstraction.
- `Duplication`: detect logic repeated within the delta and delta code reimplementing an existing repo surface, anchored to the model's `Prior art`. Cite both locations; prefer standardizing onto the existing owner over parallel copies.
- `Legacy load`: require compatibility aliases, deprecated dependencies, superseded paths, old-format writes, or parallel truth to have a live caller, durable-data, or public-contract reason, regression proof, and a permanence or retirement decision. Proposals name the evidence and proof plan. Do not confuse retry, failover, or recovery with compatibility.

Practical example: if two adapters need the same normalization, prefer one small function at their existing shared boundary; add a registry or strategy layer only when runtime selection is real. Reading stored v1 rows can be justified compatibility, while adding a new v1 write path without a live consumer is legacy-on-arrival. A provider timeout backed by its SLA and real cancellation can be defensive; a 100-row scan that silently hides valid results is over-defensive.

`Solution shape` fields (emission rule per depth: SKILL.md Stage 4):

- `Boundary integrity`: `respected` | `strained` | `violated` | `unclear`
- `Simplicity / elegance`: `simplest` | `justified complexity` | `over-engineered` | `unclear`
- `Limit posture`: `minimal` | `justified` | `over-defensive` | `under-defensive` | `unclear`
- `Reusable generality`: `right-sized` | `under-generalized` | `over-generalized` | `unclear`
- `Legacy load`: `none` | `justified compatibility` | `legacy-on-arrival` | `unclear`
- `Duplication`: `none` | `within-delta` | `vs-repo` | `both` | `unclear`
- `Deletion opportunities`: `none` | `found (<n> cited)` | `unclear`
- `Verdict`: `KISS and boundary-aligned` | `aligned with justified complexity` | `works but over-engineered` | `boundary-breaking` | `unclear`

`Deletion opportunities` lists every cited candidate: what to delete, why it is safe, the evidence (a dead or unreachable path, a superseded caller, a duplicate of named `Prior art` or an existing seam, or a limits-table `remove` / `too restrictive` verdict), and approximate LOC recoverable when measurable. A net-additive delta is never a finding by itself; an uncited candidate stays report-only, labeled speculative.

Expand only non-green or unclear judgments into findings, and only when they create concrete behavior risk or maintenance cost; still cite concrete evidence for a green verdict.

## Core audit dimensions

Every audit answers these questions, phrased relative to the chosen audit type and intended goal.

- `solution shape / boundaries`
  - Apply the boundary and simplicity check to the actual implementation or the recommended proposal integration shape, not only its names or file count; its expansion rule decides which judgments become findings.
- `goal / contract match`
  - Compare the implementation against the requested audit question, intended goal, `README.md`, `docs/specs/*`, the selected `TODO*.md` scope, and observable current behavior; for TODO-step scopes, per the step-scoped contract audit in `shapes.md`.
  - Treat drift between code, tests, and docs as a real finding.
  - The `Goal match` verdict rule lives in SKILL.md Stage 4.
- `correctness / failure handling`
  - Check happy paths, edge cases, failure paths, boundary validation, and state or data invariants.
  - Validate untrusted input early, separate syntactic from semantic validation when both matter, and keep invariants explicit where they protect real behavior.
  - Require only the bounds justified per the limit verdicts in `as-built-model.md`; verify cancellation, partial-work, retry, and user-visible behavior when each is reached.
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
  - Apply YAGNI: flag speculative abstraction, nested wrapper indirection, value-obscuring indirection (per `Simplicity / elegance`), generic APIs with one concrete use, parameterization or extension points without real consumers, and ceremony that does not protect a real boundary.
  - Apply SOLID pragmatically, with SRP first: use "one reason to change" as the first pressure test before broader rewrites.
- `documentation / operability`
  - Audit `README.md`, `docs/specs/*` (PRD, blueprint, and connected `*-definition.md` leaf specs), `docs/INDEX.md` (with `docs/index/**` siblings when INDEX split is active), `docs/runbooks/*.md`, repo-root `RUNBOOK.md`, and the current-state header of `docs/JOURNAL.md` when present and when they materially affect the audit verdict.
  - Documentation should stay compact and optimized for reading.
  - Specs should match the current codebase or clearly intended future implementation. Specs for removed features are `drifted` findings; major implementation areas without spec coverage are `missing` findings.
  - For `docs/INDEX.md`: verify the entrypoint layout matches the actual mode per the boilerplate INDEX-split scaling rules; single-file mode should not carry a Layout pointer block; split mode should carry Layout pointers and keep diagram or inventory bodies in `docs/index/**` siblings rather than inline. A single-file INDEX exceeding ~300 lines or with unbounded-growth sections is a structural drift finding; recommend INDEX split via `cdd-maintain` index mode. Stale INDEX (clearly older than current TODO or journal activity) is also a `documentation` finding.
  - For mermaid diagrams (inline in `docs/INDEX.md` for single-file mode, or in `docs/index/DIAGRAMS.md` for split mode): verify each diagram still matches the current supervision tree, flow shape, module boundaries, or component layout it claims to represent. Diagrams referencing removed components, missing newly-added ones, or showing structurally outdated edges are `drifted` findings; cite the specific node or edge.
  - For `docs/runbooks/*.md` and repo-root `RUNBOOK.md`: verify each documented procedure or command still resolves to a live entrypoint, service, or script. Procedures for decommissioned, renamed, or removed surfaces are `drifted` findings.

## Optional lenses

Activate optional lenses only when the scope, audit type, or evidence warrants them. A lens may deepen the audit, raise the review depth, or indicate specialist review is needed, but it should never become mandatory noise in every audit.

- `security / privacy`: trust boundaries, sensitive data handling, authorization, secrets, logging, privacy-sensitive flows, and places where failure-path behavior could expose data or privilege.
- `dependency / provenance / supply chain`: new or upgraded third-party components in the context of their expected use; secure configuration, dependency diffs, provenance or SBOM signals when available, and unresolved trust or vulnerability gaps that materially affect the audit.
- `reliability / availability / performance / scalability`: concurrency, retries, recovery, load-sensitive code paths, data volume assumptions, and operational behavior under failure or growth.
- `migration / compatibility / rollout / rollback`: schema, config, manifest, or API changes for deployment order, backward compatibility, state transitions, rollout safety, and rollback posture.
- `ux / accessibility / i18n / concurrency`: the relevant subset when the change affects user interaction, accessibility guarantees, localization behavior, or concurrency-sensitive flows that need specialist review or deeper proof.

If you are not qualified to judge a triggered lens confidently, say so and record that specialist review or stronger proof is required instead of pretending the audit is complete.
