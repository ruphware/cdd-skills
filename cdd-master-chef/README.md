# [CDD-8] Master Chef

This directory is the canonical committed package root for `[CDD-8] Master Chef`, the multi-runtime autonomous development process that sits beside the core `[CDD-0]` through `[CDD-7]` CDD skills.

Use these files as the canonical contract surfaces:

- `SKILL.md` — current installable `cdd-master-chef` skill entrypoint
- `CONTRACT.md` — runtime-agnostic Master Chef behavior
- `RUNBOOK.md` — shared worktree, hand-off, and operational procedure
- `RUNTIME-CAPABILITIES.md` — capability boundaries for OpenClaw, Codex, and Claude Code

Runtime adapters consume that shared contract and define how a specific runtime realizes it:

- `openclaw/` — current OpenClaw adapter docs and runtime-specific runbooks
- `CODEX-ADAPTER.md` — Codex Builder delegation contract
- `CODEX-RUNBOOK.md` — Codex operating path over the shared contract
- `CODEX-TEST-HARNESS.md` — Codex adapter verification checklist
- `CLAUDE-ADAPTER.md` — Claude Code Builder delegation contract
- `CLAUDE-RUNBOOK.md` — Claude Code operating path over the shared contract
- `CLAUDE-TEST-HARNESS.md` — Claude Code adapter verification checklist

Relationship to the rest of the repo:

- `skills/` remains the canonical Builder workflow source for the core `[CDD-0]` through `[CDD-7]` `cdd-*` skills.
- `openclaw/` inside this package is one adapter over the shared `[CDD-8] Master Chef` contract defined here.
- Codex and Claude adapter docs now live directly in this package root.
- The top-level `master-chef/` and `openclaw/` directories are compatibility stubs only; this directory is the single canonical source tree.
