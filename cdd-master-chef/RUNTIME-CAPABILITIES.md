# Master Chef Runtime Capabilities

This matrix records the current capability boundaries for the shared `cdd-master-chef` contract.

Runtime adapters may be stricter than this matrix, but they must not claim broader behavior than the documented or observed runtime surface can support.

Current concrete adapters in this package are OpenClaw, Codex, and Claude Code. Additional adapters can be added for other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, but no such adapter ships here today.

## Capability matrix

| Runtime | Delegation model | Agent config surface | Nested delegation | Tool or MCP inheritance | Child working directory | Persistent Builder continuation | Manual Builder compaction | Fallback context management | Parent-visible context budget | Worktree hand-off | Current repo status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OpenClaw | OpenClaw subagent Builder under one Master Chef control loop | Internal `cdd-*` skills installed under `~/.openclaw/skills` | Adapter-defined; keep one Master Chef loop | Adapter-defined in the OpenClaw runtime | Adapter-defined by the runtime/session | Supported after relaunch into the active managed worktree; same Builder is the normal path once the relaunched session is live | No documented manual Builder compaction command or API in this repo's OpenClaw surfaces | Keep the same Builder and rely on native context management; record truthful step-boundary fallback results such as `unsupported` or `native_context_management` | No documented parent-visible Builder fullness meter or exact token-left surface | Provision managed worktree, then stop with relaunch instructions before implementation begins | Current packaged runtime adapter in this repo |
| Codex | Explicit subagent delegation; do not assume automatic spawning | Project-scoped `.codex/agents/*.toml` plus runtime tooling | Adapter-specific; default to shallow delegation and keep `max_depth = 1` unless the repo proves otherwise | Child agents inherit the parent sandbox policy; approval-heavy work should stay interactive | Adapter-specific; runtime can choose child working dirs | Supported when the active Codex surface can keep Master Chef and Builder coherently rooted at the managed worktree; otherwise hand off or relaunch before delegated work continues | No clean parent-visible Builder compaction command or API is documented by current repo docs or the local `codex --help` surface | Keep the same Builder and rely on native context management or any runtime auto-compaction the active Codex surface performs | No clean official parent-visible subagent context meter or exact token-left budget is documented for Master Chef decisions | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; otherwise use a fallback handoff without handing Builder-start decisions back to the human | Current subagent-backed adapter docs shipped in this package |
| Claude Code | Built-in or custom subagents delegated from the main Claude session; Master Chef should force explicit Builder selection when determinism matters | `--agents`, `.claude/agents/`, `~/.claude/agents/`, and plugin `agents/` directories | Subagents cannot spawn other subagents | If `tools` is omitted, subagents inherit main-thread tools; background subagents should use pre-approved, non-MCP-critical paths only | CLI exposes session-scoping flags such as `--add-dir` | Supported when the active Claude surface can keep Master Chef and Builder coherently rooted at the managed worktree; separate subagent contexts are normal | Supported when the active Claude surface exposes slash commands such as `/compact`; do not assume that surface exists in every invocation mode | Keep the same Builder and rely on Claude auto-compaction or native context management when manual `/compact` is unavailable or inappropriate for the active surface | Do not claim exact parent-visible subagent fullness percentages or a precise token-left meter for Master Chef decisions | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; treat `--worktree` as a fallback handoff surface when in-session continuation is not coherent | Current subagent-backed adapter docs shipped in this package |

## Runtime notes

Shared policy anchors for every adapter in this package:

- record unresolved current-session fields as `unknown` and continue with the active session as-is
- recommend a descriptive source feature branch on fresh runs from long-lived branches, still create a fresh per-run managed worktree branch, and bootstrap the active worktree to `env_ready` before Builder or `hard_gate`
- keep Builder persistent across normal delegated-step transitions, attempt step-start compaction only when supported, and replace Builder only for recovery conditions
- review oversized-looking work first, keep or repair the parent step when one-run delivery is still viable, and split only when the split cost is justified

All adapters in this package must satisfy the same startup gate:

- optionally recommend and record a descriptive source feature branch on fresh runs from long-lived branches
- always create a separate fresh per-run managed worktree branch
- activate or relaunch into that managed worktree
- bootstrap the repo-native environment there
- record `source_branch_decision`, `worktree_env_status`, `worktree_env_prepared_at_utc`, and `worktree_env_bootstrap_summary`
- do not let Builder or `hard_gate` validation rely on the worktree until it is `env_ready`

### OpenClaw

- The repo currently ships the OpenClaw adapter docs in `cdd-master-chef/openclaw/`.
- The OpenClaw adapter is the current packaged runtime adapter, but it is not the only current adapter in this package.
- OpenClaw-specific delta: when OpenClaw cannot expose an exact model or thinking value, record that field as `unknown`, report the limitation honestly, and continue kickoff.
- OpenClaw-specific delta: provision the managed worktree, write branch and worktree metadata, stop with exact relaunch instructions, and bootstrap the repo-native environment after relaunch before autonomous implementation starts.
- OpenClaw-specific delta: the packaged path now treats same-Builder continuation across delegated steps as the normal path after relaunch, but this repo does not document a manual Builder compaction command or a parent-visible context meter for OpenClaw.

### Codex

- Treat Builder delegation as explicit and intentional.
- Project-level agent configuration belongs under `.codex/agents/*.toml`.
- The Codex adapter must define how current session model and thinking are observed when available, how `unknown` is reported when the runtime does not expose an exact field, and how optional Builder overrides map onto the actual runtime configuration surface.
- The Codex adapter must also define how kickoff approval captures the run step budget and Builder start decision before any fallback handoff is used.
- The Codex adapter must also define whether a managed worktree can become active in-session or only after a fallback handoff rooted in that worktree.
- The Codex adapter must define how the active worktree environment is bootstrapped and evidenced before Builder or `hard_gate` validation rely on it.
- The Codex adapter must not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it.
- The Codex adapter must describe persistent Builder reuse conservatively, state that the current repo docs and local `codex --help` do not document a clean parent-visible manual Builder compaction command, and avoid claiming an official parent-visible subagent context meter.
- The Codex adapter must require a real Builder readiness signal before treating the child as live; a spawn handle alone is not enough.
- Current repo docs: `CODEX-ADAPTER.md`, `CODEX-RUNBOOK.md`, and `CODEX-TEST-HARNESS.md`.

### Claude Code

- Current local CLI surface checked in this repo on 2026-05-04: `claude 2.1.126`.
- Visible session and runtime flags include `--agent`, `--agents`, `--worktree`, `--tmux`, `--effort`, and `--permission-mode auto`.
- Project and user agent surfaces are `.claude/agents/` and `~/.claude/agents/`.
- Use explicit Builder selection when the delegated role must be deterministic, even though Claude can also delegate automatically.
- Background subagents inherit only pre-approved permissions; do not rely on them for interactive recovery.
- The Claude adapter must define how current session model and thinking are observed when available, how `unknown` is reported when the runtime does not expose an exact field, and how optional Builder overrides are honored or rejected.
- Adapter rules must distinguish in-session continuation from startup-time fallback handoff support.
- The Claude adapter must also define how kickoff approval captures the run step budget and Builder start decision before any fallback handoff is used.
- The Claude adapter must define how the active worktree environment is bootstrapped and evidenced before Builder or `hard_gate` validation rely on it.
- The Claude adapter must not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it.
- The Claude adapter should describe persistent Builder reuse, manual `/compact` when the active Claude surface exposes it, auto-compaction fallback when it does not, and the lack of any trustworthy parent-visible exact subagent fullness percentage.
- The Claude adapter must require a real Builder readiness signal before treating the child as live; a spawn handle alone is not enough.
- Current repo docs: `CLAUDE-ADAPTER.md`, `CLAUDE-RUNBOOK.md`, and `CLAUDE-TEST-HARNESS.md`.

### Future adapters

- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters over the shared contract.
- No Hermes adapter or other extra runtime adapter ships in this repo today.
