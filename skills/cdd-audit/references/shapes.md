# Shape-specific audits

## Enhancement-proposal audit

For `enhancement_proposal`, audit the proposal against the current codebase instead of judging an implementation delta.

- Before findings, produce a visible `Existing-capability inventory`: each entry names an existing surface, tags it `overlaps`, `duplicates`, `depends on`, or `conflicts`, and cites a file or symbol.
- Emit a `Proposal fit` verdict as this shape's `Goal match` equivalent: `fits as proposed`, `fits with adjustments`, `needs reshaping`, `mostly already exists`, or `conflicts with current architecture`.
- Produce a visible `Integration options` block with 2-4 materially different integration shapes (approach, affected boundaries, reuse versus new surface, trade-offs), recommended option first, surfaced through approval variant mode (`A1.`, `A2.`, `A3.`). Collapse to one justified option when alternatives would be cosmetic.
- Apply the boundary and simplicity check to the recommended integration shape and use it to rank materially different alternatives; do not invent implementation details that the proposal or current architecture cannot support.
- Prioritize, and keep findings about, the proposal itself: duplication with shipped surfaces, architectural conflicts, unstated decisions, gaps, acceptance-criteria weaknesses, and integration seams; never the absence of the proposed artifact, its tests, or its TODO normalization.
- In per-finding triage, `C.` (keep current state) means keeping the proposal as written, with no repo change.

## Step-scoped TODO contract audit

When the scope resolves to one or more TODO steps, audit each selected step against its own step contract rather than only the broader TODO topic.

- Before judging implementation quality, inspect each selected step's `Goal`, `Constraints`, `Tasks`, `Implementation notes`, `Automated checks`, and `UAT`. A step lacking one of these preferred sections has a contract weakness or missing proof surface; never skip it silently.
- Judge whether the implementation delta inspected in Stage 3 actually satisfies the step contract, not only the final filesystem state or the surrounding TODO theme.
- Unchecked TODO tasks, missing completion evidence, weak automated-check or UAT proof, or implementation that misses the step goal are first-class findings.
- Decide for each selected step whether its checked tasks appear fully done, whether the observed implementation satisfies its goal, and whether automated checks plus UAT evidence support the claimed completion; these are the step-completion judgments in the final summary.
- Keep this audit additive to the broader README, spec, code, test, config, manifest, and entrypoint review; never narrow the audit into TODO-only review.

## Multi-step run audit

For `master_chef_multi_step`, audit both the per-step contract above and the run-level execution evidence, and judge run-level execution quality and proof:

- step sizing: declared `points:` against the delivered shape
- dependency order
- completion evidence and continuation quality
- proof quality: whether automated checks plus UAT actually prove completion
- whether the run stopped at the right boundary for the evidence available
