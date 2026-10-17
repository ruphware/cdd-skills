# Mode D — Refactor

## Preconditions
- Refactor mode requires a fresh `docs/INDEX.md` (and fresh `docs/index/**` siblings when INDEX split is active).
- If the current selection already includes `C. index`, complete that refreshed index first and run the refactor audit against the post-index repo state. If `docs/INDEX.md` is missing, `stale`, or `very stale` and `C. index` is not part of the current selection, stop and ask whether to add `C. index` before continuing.
- When multiple modes are selected, run refactor mode against the repo state after any approved `doc drift + upkeep`, `source cleanup`, and `index` work has completed.

## Candidate sources
- file inventory rows tagged `refactor-candidate` when present, sourced from `docs/INDEX.md` in single-file mode or `docs/index/INVENTORY-*.md` in split-file mode
- explicit refactor notes already in `docs/INDEX.md` (or `docs/index/**` siblings when split) or `TODO*.md`
- refactor pressure discovered during maintain-mode review

## Review
- Read `docs/INDEX.md` (and `docs/index/**` siblings when INDEX split is active) plus the relevant code, tests, entrypoints, configs, support docs, and current TODO/JOURNAL context needed for the selected architecture audit, so the audit reflects the real implementation state.
- Normalize findings around architecture boundaries, design pressure, duplicated responsibility, unclear ownership, oversized files, brittle seams, and other concrete refactor drivers.

## Options
- Present 2-3 context-specific refactor options. Each option should identify the target boundary, intended design direction, key benefits, main risks, and the validation evidence needed to prove it is safe.
- Keep the options KISS: minimal scope first, no speculative cleanup, no pattern cargo-culting.

## Report
- Finish with an architecture audit report and recommend `cdd-plan` as the next step for any selected or preferred refactor direction.
