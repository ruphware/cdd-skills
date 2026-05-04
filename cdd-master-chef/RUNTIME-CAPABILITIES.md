# Master Chef Runtime Capabilities

This matrix records the current capability boundaries for the shared `cdd-master-chef` contract.

Runtime adapters may be stricter than this matrix, but they must not claim broader behavior than the documented or observed runtime surface can support.

Current concrete adapters in this package are OpenClaw, Codex, and Claude Code. Additional adapters can be added for other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, but no such adapter ships here today.

## Capability matrix

| Runtime | Delegation model | Agent config surface | Nested delegation | Tool or MCP inheritance | Child working directory | Worktree hand-off | Current repo status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OpenClaw | OpenClaw subagent Builder under one Master Chef control loop | Internal `cdd-*` skills installed under `~/.openclaw/skills` | Adapter-defined; keep one Master Chef loop and one-step Builder runs | Adapter-defined in the OpenClaw runtime | Adapter-defined by the runtime/session | Provision managed worktree, then stop with relaunch instructions before implementation begins | Current packaged runtime adapter in this repo |
| Codex | Explicit subagent delegation; do not assume automatic spawning | Project-scoped `.codex/agents/*.toml` plus runtime tooling | Adapter-specific; default to shallow delegation and keep `max_depth = 1` unless the repo proves otherwise | Child agents inherit the parent sandbox policy; approval-heavy work should stay interactive | Adapter-specific; runtime can choose child working dirs | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; otherwise use a fallback handoff without handing Builder-start decisions back to the human | Current subagent-backed adapter docs shipped in this package |
| Claude Code | Built-in or custom subagents delegated from the main Claude session; Master Chef should force explicit Builder selection when determinism matters | `--agents`, `.claude/agents/`, `~/.claude/agents/`, and plugin `agents/` directories | Subagents cannot spawn other subagents | If `tools` is omitted, subagents inherit main-thread tools; background subagents should use pre-approved, non-MCP-critical paths only | CLI exposes session-scoping flags such as `--add-dir` | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; treat `--worktree` as a fallback handoff surface when in-session continuation is not coherent | Current subagent-backed adapter docs shipped in this package |

## Runtime notes

### OpenClaw

- The repo currently ships the OpenClaw adapter docs in `cdd-master-chef/openclaw/`.
- The OpenClaw adapter is the current packaged runtime adapter, but it is not the only current adapter in this package.
- The current adapter should provision the managed worktree, write worktree metadata, and stop with exact relaunch instructions before autonomous implementation starts.

### Codex

- Treat Builder delegation as explicit and intentional.
- Project-level agent configuration belongs under `.codex/agents/*.toml`.
- The Codex adapter must define how shared Run config fields map onto the actual runtime configuration surface.
- The Codex adapter must also define how kickoff approval captures the run step budget and Builder start decision before any fallback handoff is used.
- The Codex adapter must also define whether a managed worktree can become active in-session or only after a fallback handoff rooted in that worktree.
- Current repo docs: `CODEX-ADAPTER.md`, `CODEX-RUNBOOK.md`, and `CODEX-TEST-HARNESS.md`.

### Claude Code

- Current local CLI surface checked in this repo on 2026-05-04: `claude 2.1.126`.
- Visible session and runtime flags include `--agent`, `--agents`, `--worktree`, `--tmux`, `--effort`, and `--permission-mode auto`.
- Project and user agent surfaces are `.claude/agents/` and `~/.claude/agents/`.
- Use explicit Builder selection when the delegated role must be deterministic, even though Claude can also delegate automatically.
- Background subagents inherit only pre-approved permissions; do not rely on them for interactive recovery.
- Adapter rules must distinguish in-session continuation from startup-time fallback handoff support.
- The Claude adapter must also define how kickoff approval captures the run step budget and Builder start decision before any fallback handoff is used.
- Current repo docs: `CLAUDE-ADAPTER.md`, `CLAUDE-RUNBOOK.md`, and `CLAUDE-TEST-HARNESS.md`.

### Future adapters

- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters over the shared contract.
- No Hermes adapter or other extra runtime adapter ships in this repo today.
