# Fixture — Init Project Open Decisions Gate

Use this fixture to prove the init-project contract keeps plan-shaping setup decisions visible and asks one queued decision before it drafts a finished apply plan.

## Prompt shape

- Docs-seeded init or existing-repo adoption request.
- Workspace review supports a default direction, but at least two plan-shaping setup decisions remain.
- Final file-by-file proposal is not ready until the first decision is answered.

## Expected response shape

### State

- Detected state: `DOCS_SEEDED_INIT`
- Main evidence: source/reference docs exist, but no code/build manifests are present

### Intent and assumptions

- Project purpose: bootstrap a repo from the discovered docs
- Recommended starting shape: local-only bootstrap first

### Open decisions (queued for one-at-a-time loop)

1. Repo backing
   Boundary: network + repo-admin posture
   Why it matters: changes bootstrap flow and confirmation surface
   Recommended option: local-only bootstrap first
   Status: asking now
2. Source-input set
   Boundary: Step 00 input scope
   Why it matters: changes PRD/Blueprint evidence and TODO Step 01+ shape
   Recommended option: exclude archived notes unless the user says otherwise
   Status: queued

Ask only decision 1 in this message. Decision 2 stays visible but unanswered.

**Options**

- A. Local-only bootstrap first. Recommended.
- B. GitHub-backed bootstrap now.
- C. Keep read-only and revise the decision framing first.

## Forbidden before the first decision is answered

- `## Proposed edits`
- `### AGENTS.md`
- `### README.md`
- `### docs/specs/prd.md`
- `### TODO.md`
- `A. apply now`
