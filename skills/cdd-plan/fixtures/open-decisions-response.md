# Fixture — Open Decisions Gate

Use this fixture to prove the plan contract asks one queued decision before it drafts a finished TODO step, and that audit-shaped planning surfaces remediation options instead of silently accepting the first plausible fix.

## Prompt shape

- Behavior-changing multi-surface request.
- Repo evidence supports a default, but does not close every plan-shaping decision automatically.
- At least two plan-shaping choices remain open.

## Expected response shape

### Frame

- Requested change: add a new persisted context surface
- Hardest constraint: heartbeat path must not regress
- Recommended direction: extend the existing authored-context pattern

### Architecture / implementation options

- Option A: full parity with the existing authored-context kinds. Recommended.
- Option B: content-only persistence now; defer activation parity.
- Option C: no new persistence surface yet; capture the audit issue as a narrower compatibility fix.
- Explain what boundaries and validation strategy change under each option.

### Open decisions (queued for one-at-a-time loop)

1. Storage shape
   Boundary: persistence + activation contract
   Why it matters: changes implementation shape, migration expectations, and validation
   Recommended option: full parity with the existing authored-context kinds
   Status: asking now
2. Compat posture
   Boundary: rollout / migration
   Why it matters: changes import behavior and historical-envelope handling
   Recommended option: clean break with historical reads left untouched
   Status: queued

Ask only decision 1 in this message. Decision 2 stays visible but unanswered.

**Options**

- A. Full parity with the existing authored-context kinds. Recommended.
- B. Content-only for now; defer activation parity.
- C. Keep read-only and revise the decision framing first.

## Forbidden before the first decision is answered

- `## Step`
- `### Goal`
- `### Tasks`
- `### Automated checks`
- `### UAT`
