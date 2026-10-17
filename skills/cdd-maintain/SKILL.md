---
name: cdd-maintain
description: "Maintain a CDD repo through doc drift and upkeep, approval-gated source cleanup, docs/INDEX refresh, and refactor architecture audit (interactive)."
---

# CDD Maintain (interactive)

Use this skill for explicit repo maintenance: doc drift and repo upkeep, approval-gated source cleanup, `docs/INDEX.md` refresh, and refactor architecture audit.

## Shared routing read
- Read `AGENTS.md` first.
- Read only the minimum repo context needed to route the selected mode before doing deeper review.
- Each mode's read list lives in its mode file (`## Mode files`); do not front-load support-doc, journal, or runtime review when the selected mode does not require it.

## Mode selection
- If the user request already clearly maps to one mode, use it directly. Otherwise ask and wait:
  - `A. doc drift + upkeep`
  - `B. source cleanup`
  - `C. index`
  - `D. refactor`
  - `E. do all`
- Ask at most one substantive question per message. After each answer, re-rank what remains and ask the next highest-leverage question; never list several open questions as a checklist.
- End every decision message with repo-local `NEXT` when `AGENTS.md` defines one, otherwise `**Options**`: question, any reply hint, then choices; nothing follows the final choice.
- Label every choice with a lettered selector, also in native option UIs (`A.`, `B.`, …; nested `A1.`, `A2.`); put the recommended choice first and mark it; say the user may reply with the selector alone. The selected option is the approval; never append a separate approval question.
- Allow selecting more than one option in the same reply. If the user selects `E`, says `do all`, or selects multiple modes, execute them in fixed order `A -> B -> C -> D` regardless of the order they were named; read and report them in that order too.
- Keep the mode-specific write scope tight. Do not widen from one mode into another without asking.

## Approval contract
- Documentation, ad-hoc archive, stale-TODO deletion, runtime-cleanup, source-cleanup, and INDEX-update approvals all reuse the options block above: the selected option is the approval.
- Keep documentation, stale-TODO deletion, runtime-cleanup, and source-cleanup approvals separate even when the same report surfaces them together.
- Present multiple approval decisions one at a time as a loop: surface the highest-priority approval first, wait for the user's selector, apply the approved actions for that decision, then surface the next remaining approval. Do not list multiple approval decisions in one message as a checklist for the user to triage at once.
- When a single apply decision is ready, prefer `A. apply now`, `B. keep the report only`, and `C. revise scope first`.

## Safe write behavior
- Apply safe archive moves immediately.
- Do not silently rewrite support docs or silently delete `.cdd-runtime/` content.
- `A. doc drift + upkeep`: apply ad-hoc-doc archive moves only after documentation approval; ask before deleting stale adjacent `TODO*.md` files.
- `B. source cleanup`: remove only clearly approved dead or obsolete code and artifacts.
- `C. index`: write only `docs/INDEX.md` (plus `docs/index/**` siblings when INDEX split is active).
- `D. refactor`: read-only; no implementation edits and no TODO authoring.

## INDEX freshness
- Check how old `docs/INDEX.md` is using the last git change when available, otherwise filesystem mtime. When INDEX split is active, take the most recent mtime across `docs/INDEX.md` and `docs/index/**` siblings.
- Report the exact age in days.
- Classify freshness as:
  - `fresh` for 0-14 days
  - `stale` for 15-30 days
  - `very stale` for over 30 days or clearly older than current TODO or journal activity

## Output
Return a mode-scoped maintenance report.

Always include:
- `Mode`
- `Recommended next action`

Include only the sections for the selected mode or modes, in execution order:
- For `A`:
  - `Archive actions applied`
  - `Deletion approval needed`
  - `Journal archive status`
  - `Local runtime cleanup status`
  - `Runtime cleanup approval needed`
  - `Support documentation status`
  - `Documentation updates proposed` or `Documentation updates applied`
  - `Documentation approval needed`
- For `B`:
  - `Source cleanup status`
  - `Cleanup approval needed`
- For `C`:
  - `INDEX freshness`
  - `INDEX mode` (`single-file` or `split-file`, with the trigger that decided it)
  - `Index update status`
- For `D`:
  - `INDEX freshness`
  - `Refactor audit status`
  - `Refactor options proposed`

- For a pure `B` pass, report cleanup findings, proof, approval need, and validation only; omit archive, journal, runtime, and support-doc status blocks unless one of those surfaces was used as proof for a cleanup candidate.
- When multiple modes are selected, include only the status blocks for those selected modes. Omit non-selected mode status blocks.

Recommend follow-up such as `cdd-plan`, direct cleanup work, or direct implementation work when supported by the findings, but do not widen beyond the selected mode automatically.

## Mode files
After selection, read the file for each selected mode in execution order:
- `A. doc drift + upkeep`: `references/mode-a-doc-drift.md`
- `B. source cleanup`: `references/mode-b-source-cleanup.md`
- `C. index`: `references/mode-c-index.md`
- `D. refactor`: `references/mode-d-refactor.md`
