# [CDD-6] Master Chef

This directory is the committed package root for `[CDD-6] Master Chef`, the multi-runtime autonomous workflow that complements the core `[CDD-0]` through `[CDD-5]` CDD skills.

## Compact policy flow

The canonical policy flow is `CONTRACT.md §0.5`; everything else in this package elaborates it.

The remaining adapter differences are runtime mechanics only: delegation trigger, agent surface, worktree activation, tool or approval inheritance, context or compaction visibility, and child-session cleanup surface.

Use these files as the canonical contract surfaces:

- `SKILL.md` — current installable `cdd-master-chef` skill entrypoint
- `CONTRACT.md` — runtime-agnostic Master Chef behavior
- `RUNBOOK.md` — shared procedural sequence over the compact policy
- `RUNTIME-CAPABILITIES.md` — capability boundaries for Codex and Claude Code

Runtime adapters consume that shared contract and define how a specific runtime realizes it:

- `CODEX-ADAPTER.md` — Codex Builder delegation contract
- `CODEX-RUNBOOK.md` — Codex operating path over the shared contract
- `CODEX-TEST-HARNESS.md` — Codex adapter verification checklist
- `CLAUDE-ADAPTER.md` — Claude Code Builder delegation contract
- `CLAUDE-RUNBOOK.md` — Claude Code operating path over the shared contract
- `CLAUDE-TEST-HARNESS.md` — Claude Code adapter verification checklist

Current concrete adapters in this package:

- Codex — current subagent-backed adapter docs
- Claude Code — current subagent-backed adapter docs

Relationship to the rest of the repo:

- `skills/` remains the canonical Builder workflow source for the core `[CDD-0]` through `[CDD-5]` `cdd-*` skills.
- Codex and Claude adapter docs live directly in this package root.
- This directory is the single canonical source tree.
