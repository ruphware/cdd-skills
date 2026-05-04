# CDD Master Chef

This directory is the shared source of truth for the multi-runtime `cdd-master-chef` workflow.

Use these files as the canonical contract surfaces:

- `CONTRACT.md` — runtime-agnostic Master Chef behavior
- `RUNBOOK.md` — shared worktree, hand-off, and operational procedure
- `RUNTIME-CAPABILITIES.md` — capability boundaries for OpenClaw, Codex, and Claude Code

Runtime adapters consume that shared contract and define how a specific runtime realizes it:

- `openclaw/` — current installable adapter package and runtime-specific docs
- `CODEX-ADAPTER.md` — Codex Builder delegation contract
- `CODEX-RUNBOOK.md` — Codex operating path over the shared contract
- `CODEX-TEST-HARNESS.md` — Codex adapter verification checklist
- `CLAUDE-ADAPTER.md` — Claude Code Builder delegation contract
- `CLAUDE-RUNBOOK.md` — Claude Code operating path over the shared contract
- `CLAUDE-TEST-HARNESS.md` — Claude Code adapter verification checklist

Relationship to the rest of the repo:

- `skills/` remains the canonical Builder workflow source for the `cdd-*` skills.
- `openclaw/` is one adapter over the shared contract defined here; it is no longer the only Master Chef source of truth.
- Codex and Claude adapter docs live in `master-chef/` today even though OpenClaw remains the only packaged installer path for the current repo state.
- Packaging and installer unification are separate follow-on work. This directory defines the shared behavior first so adapter and packaging work can follow a stable contract.
