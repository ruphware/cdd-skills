# [CDD-6] Master Chef

This directory is the committed package root for `[CDD-6] Master Chef`, the multi-runtime autonomous workflow that complements the core `[CDD-0]` through `[CDD-5]` CDD skills.

## Compact policy flow

- Session settings: observe the current session model and thinking when the runtime exposes them, record only unresolved fields as `unknown`, and continue with the active session as-is. Builder inherits those effective settings unless an adapter can honor an explicit `Builder override` cleanly.
- Startup: on fresh runs from long-lived branches, recommend a descriptive source feature branch unless the human declines, then create a fresh per-run worktree branch, bootstrap that worktree, and wait for `env_ready` before Builder or `hard_gate` depends on it.
- Builder lifecycle: keep one persistent Builder per active autonomous run, attempt step-start Builder compaction when the runtime supports it, and replace Builder only for recovery conditions.
- Step shaping: review oversized-looking work before delegation, keep or minimally repair the parent step while one-run delivery is still viable, and split only when the added Builder, hard-gate, QA, and mission-delay cost is justified.
- Mission ownership: after kickoff approval, Master Chef owns the mission under the approved run step budget and ends terminal states with a final mission report covering completed work, unresolved session-setting fields, and decisions made.

Everything else in this package elaborates that shared flow.

Use these files as the canonical contract surfaces:

- `SKILL.md` — current installable `cdd-master-chef` skill entrypoint
- `CONTRACT.md` — runtime-agnostic Master Chef behavior
- `RUNBOOK.md` — shared procedural sequence over the compact policy
- `RUNTIME-CAPABILITIES.md` — capability boundaries for OpenClaw, Codex, and Claude Code

Runtime adapters consume that shared contract and define how a specific runtime realizes it:

- `openclaw/` — current OpenClaw adapter docs and runtime-specific runbooks
- `CODEX-ADAPTER.md` — Codex Builder delegation contract
- `CODEX-RUNBOOK.md` — Codex operating path over the shared contract
- `CODEX-TEST-HARNESS.md` — Codex adapter verification checklist
- `CLAUDE-ADAPTER.md` — Claude Code Builder delegation contract
- `CLAUDE-RUNBOOK.md` — Claude Code operating path over the shared contract
- `CLAUDE-TEST-HARNESS.md` — Claude Code adapter verification checklist

Current concrete adapters in this package:

- OpenClaw — current packaged runtime adapter and generated Builder install flow
- Codex — current subagent-backed adapter docs
- Claude Code — current subagent-backed adapter docs

Potential future adapters:

- Additional subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through new adapter docs and runtime packaging.
- No Hermes adapter ships in this package today.

Relationship to the rest of the repo:

- `skills/` remains the canonical Builder workflow source for the core `[CDD-0]` through `[CDD-5]` `cdd-*` skills.
- `openclaw/` inside this package is one adapter over the shared `[CDD-6] Master Chef` contract defined here.
- Codex and Claude adapter docs now live directly in this package root.
- This directory is the single canonical source tree.
