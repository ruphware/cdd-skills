# Master Chef Runtime Capabilities

This matrix records the current capability boundaries for the shared `cdd-master-chef` contract.

Runtime adapters may be stricter than this matrix, but they must not claim broader behavior than the documented or observed runtime surface can support.

## Capability matrix

| Runtime | Delegation model | Agent config surface | Nested delegation | Tool or MCP inheritance | Child working directory | Worktree hand-off | Current repo status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OpenClaw | OpenClaw subagent Builder under one Master Chef control loop | Internal `cdd-*` skills installed under `~/.openclaw/skills` | Adapter-defined; keep one Master Chef loop and one-step Builder runs | Adapter-defined in the OpenClaw runtime | Adapter-defined by the runtime/session | Shared contract follow-up required | Current installable adapter package |
| Codex | Explicit subagent delegation; do not assume automatic spawning | Project-scoped `.codex/agents/*.toml` plus runtime tooling | Adapter-specific; define explicit limits in the Codex adapter | Adapter-specific; must reflect Codex runtime policy | Adapter-specific; runtime can choose child working dirs | Codex supports worktree-oriented flows, but CLI and package mapping stays adapter-specific | Shared contract target; dedicated adapter contract follows |
| Claude Code | Built-in or custom subagents delegated from the main Claude session | `.claude/agents/`, `~/.claude/agents/`, and CLI `--agents` | Subagents cannot spawn other subagents | If `tools` is omitted, subagents inherit main-thread tools, including MCP tools | CLI exposes session-scoping flags such as `--add-dir` | Local CLI exposes `--worktree [name]`; startup-time support is visible, in-session switching remains adapter-specific | Shared contract target; dedicated adapter contract follows |

## Runtime notes

### OpenClaw

- The repo currently ships the OpenClaw adapter in `openclaw/`.
- The OpenClaw adapter remains the only packaged Master Chef runtime today, but it is no longer the canonical shared contract surface.

### Codex

- Treat Builder delegation as explicit and intentional.
- Project-level agent configuration belongs under `.codex/agents/*.toml`.
- The Codex adapter must define how shared Run config fields map onto the actual runtime configuration surface.

### Claude Code

- Current local CLI surface checked in this repo on 2026-05-04: `claude 2.1.126`.
- Visible session and runtime flags include `--agent`, `--agents`, `--worktree`, `--tmux`, `--effort`, and `--permission-mode auto`.
- Project and user agent surfaces are `.claude/agents/` and `~/.claude/agents/`.
- Adapter rules must distinguish startup-time worktree support from any stronger claim about in-session worktree switching.
