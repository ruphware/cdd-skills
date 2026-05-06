# [CDD-6] Master Chef

This directory is the canonical committed package root for `[CDD-6] Master Chef`, an in-development multi-runtime autonomous workflow that sits beside the core `[CDD-0]` through `[CDD-5]` CDD skills.

The shared contract treats the current session model and thinking as best-effort Master Chef facts. When a runtime cannot expose one or both exactly, Master Chef records only those fields as `unknown`, proceeds with the active session as-is, and still defaults Builder to inherit the effective settings unless an adapter can honor an explicit `Builder override` cleanly.

Startup is branch-backed and environment-backed. On fresh runs from long-lived branches, Master Chef should default to recommending a descriptive source feature branch unless the human declines. It then still provisions a separate fresh per-run worktree branch, activates the managed worktree, bootstraps the repo-native environment there, records branch and bootstrap evidence in runtime state, and only then lets Builder or `hard_gate` validation depend on that worktree.

After kickoff approval, Master Chef owns the mission under the approved run step budget: it keeps continuation and blocker decisions in-session, restarts Builders as needed, repairs or splits blocked work when safe, and ends terminal states with a final mission report covering completed work, unresolved session-setting fields, and decisions made.

Split decisions follow one shared rule: keep the current step intact while one fresh Builder can still finish it safely in one run. If not, Master Chef first tries a minimal in-place repair; only then does it split the remainder into smaller decision-complete steps. Many checklist tasks, many touched files, or broad-looking wording are not triggers by themselves; the real trigger is one-run failure risk.

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
