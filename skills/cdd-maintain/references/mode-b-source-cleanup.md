# Mode B — Source cleanup

## Cleanup candidates
- Start from tracked source, tests, configs, manifests, and entrypoints. Treat this as a tracked-code cleanup pass, not a broad repo-maintenance audit. Read `README.md`, `TODO*.md`, journal surfaces, repo-local `.agents/skills/*/SKILL.md`, or `.cdd-runtime/` only when one of those surfaces is needed as proof for a specific cleanup candidate.
- Prefer repo-native lint, typecheck, unused-code, or dead-code tooling when present.
- Otherwise use conservative heuristic scans for:
  - dead modules or orphaned tracked files
  - dead or unreachable code branches
  - duplicate retired implementation paths
  - stale feature code no longer wired into entrypoints
  - obsolete generated leftovers
  - unused exports when the evidence is strong
  - prototype, POC, or experimental code paths (signaled by names like `prototype_*`, `poc_*`, `experimental_*`, `scratch_*`, `sandbox_*`; comments like `// XXX`, `// TODO remove`, `// experimental`, `// throwaway`; or directory placement like `prototypes/`, `scratch/`, `sandbox/`, `_experiments/`) that never shipped or were superseded by a production path
  - backward-compatibility shims, legacy bridges, or deprecated APIs (often in files like `compat.*`, `legacy.*`, `deprecated.*` or function names like `*_v1`, `legacy_*`, `compat_*`, `old_*`) with no remaining callers in the repo; verify call sites with repo-grep before flagging
  - feature flags, config gates, or env-var toggles that are permanently ON or permanently OFF in current code paths and no longer guard real branching
  - migration helpers, one-shot data backfill code, or schema-translation shims from completed migrations
  - removed-vendor or removed-integration adapters whose external dependency or sidecar has already been deleted from manifests/configs

## Classification
- Classify each cleanup candidate as `confirmed_cleanup`, `probable_cleanup`, or `unclear`.
- Do not remove anything classified as `unclear`.

## Candidate record
- For each candidate, record:
  - affected boundary
  - why it appears dead or obsolete
  - proof surface
  - any must-preserve behavior or contract

## Concern batches
- Do not silently refactor, redesign, or broaden the scope while cleaning.
- If cleanup needs matching test, config, or doc deletion to keep the repo coherent, include those edits in the same proposed cleanup patch.
- Group approved removals into cleanup patches by concern (e.g. prototypes, backcompat shims, dead modules, unused exports, completed-migration helpers); each concern batch is one cleanup approval.
- If the user approves, remove only the approved dead lines, files, folders, tests, configs, or generated leftovers.
- If the user does not approve, leave code unchanged and report the remaining cleanup candidates clearly.
