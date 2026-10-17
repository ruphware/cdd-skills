# As-built model

The model commits the auditor to a reading of what the implementation actually is before any verdict compares it against what it should be. Emit one model per audited scope: multi-step and branch scopes model the composed result, not each step, and the limits inventory stays bounded to the audited delta plus directly touched surfaces.

## Model parts

- `Diagram`: compact ASCII of components, data/control flow, and boundary crossings.
- `Gist`: 2-4 sentences on what the audited surface actually does as built.
- `Delta stats`: the audited delta's measured size (files changed, LOC added/deleted, net) from tool output (`git diff --numstat`-style), never estimated. Report generated, vendored, and lockfile churn separately so it cannot distort the counts. With no measurable delta (whole-codebase scope, no diff surface), one line naming why, no numbers.
- `Perceived intent vs stated intent`: the implementation's apparent design goal, stated independently, then marked `matches` or `diverges at <point>` against the stated contract.
- `Limits & assumptions`: the inventory under `## Limits and assumptions`.
- `Prior art`: existing similar solutions or established repo patterns the audited surface overlaps, each marked `standardizable onto <surface>` or `novel`.

Depth scaling: `quick` = `Gist` + `Delta stats` + limits inventory, with `Diagram` and `Prior art` optional; `standard` and `deep` = the full model including `Prior art`.

## Limits and assumptions

List every encoded bound in the audited surface (string lengths, collection caps, numeric ranges, timeouts, retries, concurrency caps, enum sets, truncations, defaults) as `limit | value | location/owner | behavior when reached | verdict`. The verdict is an action plus its reason:

- `keep — <reason>`: required by an external or public contract, or a minimum necessary guard at the owner of a proven trust, resource, external-deadline, or liveness risk; being contractual is provenance, not proof the bound is well designed.
- `too restrictive — <reason>`: the risk may be real, but the value or placement rejects valid production work, silently truncates truth, duplicates another owner, or adds defense at every layer; name what to relax.
- `remove — <reason>`: nothing breaks without it; the bound is arbitrary (no consumer or rationale found) or over-defensive where deleting beats relaxing.
- `add bound — <reason>`: reserved for a proven trust, resource, external-deadline, or liveness risk with a named owner; most values should stay unbounded, and a missing bound without such proof is not a defect.

A `keep` verdict needs a strong reason: the contract or proven risk, the value, the owner, and the reached behavior all justified; otherwise the verdict is `remove` or `too restrictive`. An implementation may need to honor a fixed external contract; when the contract itself is in scope, flag an unsupported cap as a contract weakness. Prefer one canonical bound at the risk owner plus streaming, pagination, backpressure, cancellation, or explicit failure over cascading caps and silent truncation. Do not turn an arbitrary bound into configuration unless operators have a real tuning need.

## Evidence and blind window

- Evidence: the model cites only code, tests, configs, manifests, and observable behavior, never plan or spec wording.
- Blind window: when `Read strategy` is `plan-vs-implementation`, the stated contract is locator-only until `Gist`, `Perceived intent`, and the limits inventory are drafted. Locator use answers where the audited surface is (scope, shape, files, step ids, boundaries); semantic use answers what it should do. Deep-read the stated claims only after drafting, then emit the diff.
- No stated contract (`implementation-only`): the diff line reads `no stated contract`, perceived intent stands as the audit baseline, and the missing contract surface stays a finding per the missing-proof-surface rule.
- Intent divergence or a load-bearing ambiguous limit goes through the SKILL.md question policy; there is no second question gate.

## Mapping into dimensions

Model findings map into the core dimensions:

- intent divergence → `goal / contract match`
- `add bound` verdicts → `correctness / failure handling`
- `remove` and `too restrictive` verdicts → `complexity / maintainability`, plus `correctness / failure handling` when production behavior changes
- deletion opportunities, duplicate logic, and obscured values → `complexity / maintainability`
- test-cost findings → `verification quality`

## Example

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
