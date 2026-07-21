# Master Chef Runtime Capabilities

This matrix records the current capability boundaries for the shared `cdd-master-chef` contract.

Runtime adapters may be stricter than this matrix, but they must not claim broader behavior than the documented or observed runtime surface can support, and they must not restate shared Builder lifecycle policy as if it were runtime-specific.

Current concrete adapters in this package are OpenClaw, Codex, and Claude Code. Additional adapters can be added for other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, but no such adapter ships here today.

## Capability matrix

| Runtime | Delegation model | Transport-ladder rungs | Agent config surface | Nested delegation | Tool or MCP inheritance | Child working directory | Persistent Builder continuation | Manual Builder compaction | Fallback context management | Parent-visible context budget | Worktree hand-off | Current repo status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OpenClaw | OpenClaw subagent Builder under one Master Chef control loop | Rung 0 `native_subagent` only today; no agent-config or exec rung claimed | Internal `cdd-*` skills installed under `~/.openclaw/skills` | Adapter-defined; keep one Master Chef loop | Adapter-defined in the OpenClaw runtime | Adapter-defined by the runtime/session | Supported after relaunch into the active managed worktree; same Builder is the normal path once the relaunched session is live | No documented manual Builder compaction command or API in this repo's OpenClaw surfaces | Keep the same Builder and rely on native context management; record truthful step-boundary fallback results such as `unsupported` or `native_context_management` | No documented parent-visible Builder fullness meter or exact token-left surface | Provision managed worktree, then stop with relaunch instructions before implementation begins | Current packaged runtime adapter in this repo |
| Codex | Explicit subagent delegation; do not assume automatic spawning | Rungs 0-3 per CONTRACT.md §4: `.codex/agents/*.toml` agent config plus `codex exec` / `codex exec resume` exec transports | Project-scoped `.codex/agents/*.toml` plus runtime tooling | Adapter-specific; default to shallow delegation and keep `max_depth = 1` unless the repo proves otherwise | Child agents inherit the parent sandbox policy; approval-heavy work should stay interactive | Adapter-specific; runtime can choose child working dirs | Supported when the active Codex surface can keep Master Chef and Builder coherently rooted at the managed worktree; otherwise hand off or relaunch before delegated work continues | No clean parent-visible Builder compaction command or API is documented by current repo docs or the local `codex --help` surface | Keep the same Builder and rely on native context management or any runtime auto-compaction the active Codex surface performs | No clean official parent-visible subagent context meter or exact token-left budget is documented for Master Chef decisions | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; otherwise use a fallback handoff without handing Builder-start decisions back to the human | Current subagent-backed adapter docs shipped in this package |
| Claude Code | Built-in or custom subagents delegated from the main Claude session; Master Chef should force explicit Builder selection when determinism matters | Rungs 0-3 per CONTRACT.md §4: `--agents` / `.claude/agents/` agent config plus `claude -p --resume` exec transports | `--agents`, `.claude/agents/`, `~/.claude/agents/`, and plugin `agents/` directories | Subagents cannot spawn other subagents | If `tools` is omitted, subagents inherit main-thread tools; background subagents should use pre-approved, non-MCP-critical paths only | CLI exposes session-scoping flags such as `--add-dir` | Supported when the active Claude surface can keep Master Chef and Builder coherently rooted at the managed worktree; separate subagent contexts are normal | Supported when the active Claude surface exposes slash commands such as `/compact`; do not assume that surface exists in every invocation mode | Keep the same Builder and rely on Claude auto-compaction or native context management when manual `/compact` is unavailable or inappropriate for the active surface | Do not claim exact parent-visible subagent fullness percentages or a precise token-left meter for Master Chef decisions | Prefer in-session continuation when Master Chef and Builder can both target the managed worktree coherently; treat `--worktree` as a fallback handoff surface when in-session continuation is not coherent | Current subagent-backed adapter docs shipped in this package |

## Runtime notes

Shared policy anchors for every adapter in this package:

- record unresolved current-session fields as `unknown` and continue with the active session as-is
- resolve Builder overrides through the transport ladder in CONTRACT.md §4, name the effective transport and any exec permission profile at kickoff, and record `builder_transport` / `builder_permission_profile` in runtime state
- wave-parallel execution is opt-in per CONTRACT.md §12: bounded Builder pool, per-slot worktrees, serial merge queue; adapters define only per-slot spawn, probe, and close mechanics
- recommend a descriptive worktree branch on fresh runs from long-lived branches, keep the source checkout on its original branch, create the managed worktree on the approved branch name, and bootstrap the active worktree to `env_ready` before Builder or `hard_gate`
- keep Builder persistent across normal delegated-step transitions, attempt step-start compaction only when supported, and replace Builder only for recovery conditions
- follow the active-monitoring ladder, boot timeout, suspect classification, and replacement policy defined in CONTRACT.md §7 — Kickoff and Builder lifecycle
- preserve lineage and durable evidence, then close or mark older Builder sessions inactive so one active Builder remains after recovery or direct completion
- review oversized-looking work first, keep or repair the parent step when one-run delivery is still viable, and split only when the split cost is justified

## Runtime mechanics only

The shared contract already fixes Builder continuation, monitoring, replacement thresholds, and one-active-Builder hygiene for every adapter in this package. The remaining differences are runtime mechanics only:

- delegation trigger and explicit agent-selection surface
- transport-ladder rung realization: config generation, exec spawn and resume commands, model and effort pinning, permission flags
- agent configuration and install surface
- nesting and control-loop boundaries
- tool, MCP, sandbox, and approval inheritance
- worktree activation, relaunch, or fallback handoff
- child-session visibility, compaction, and parent-visible context-budget surface
- child-session close or inactive-marking surface after lineage and durable evidence are preserved

All adapters in this package must satisfy the same startup gate:

- optionally recommend and record a descriptive worktree branch on fresh runs from long-lived branches
- otherwise create a separate fresh per-run managed worktree branch
- activate or relaunch into that managed worktree
- bootstrap the repo-native environment there
- record `source_branch_decision`, `worktree_env_status`, `worktree_env_prepared_at_utc`, and `worktree_env_bootstrap_summary`
- do not let Builder or `hard_gate` validation rely on the worktree until it is `env_ready`

### OpenClaw

- The repo currently ships the OpenClaw adapter docs in `skills/cdd-master-chef/openclaw/`.
- The OpenClaw adapter is the current packaged runtime adapter, but it is not the only current adapter in this package.
- Session settings: when OpenClaw cannot expose an exact model or thinking value, record that field as `unknown`, report the limitation honestly, and continue kickoff.
- Worktree: provision the managed worktree, write branch and worktree metadata, stop with exact relaunch instructions, then bootstrap the repo-native environment after relaunch before autonomous implementation starts.
- Monitoring and compaction: same-Builder continuation remains the normal path after relaunch, active checks follow the monitoring ladder defined in CONTRACT.md §7, and this repo does not document a manual Builder compaction command or a parent-visible context meter for OpenClaw.
- Cleanup: when an older Builder is no longer needed, close the older session when the runtime exposes that surface or otherwise mark it inactive so one active Builder identity remains in runtime state and control flow.
- Wave mode: not claimed today; serial execution only.

### Codex

- Delegation: treat Builder delegation as explicit and intentional, and keep project-level agent configuration under `.codex/agents/*.toml`.
- Session settings and kickoff: observe current session model and thinking when available, report `unknown` when a field is not exposed, map optional Builder overrides onto the runtime configuration surface, and keep the Builder start plus run step budget inside kickoff before any fallback handoff.
- Worktree: define whether a managed worktree can become active in-session or only after a fallback handoff rooted in that worktree, and bootstrap plus evidence the active worktree environment before Builder or `hard_gate` validation rely on it.
- Monitoring and compaction: do not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it; follow the monitoring ladder defined in CONTRACT.md §7, and note that current repo docs and local `codex --help` do not document a clean parent-visible manual Builder compaction command or an official parent-visible subagent context meter.
- Readiness and cleanup: require a real Builder readiness signal before treating the child as live, and preserve lineage and durable evidence before closing or purging older child sessions so only one live Builder remains visible after recovery or direct completion.
- Wave mode: slots via subagent threads or exec children per CONTRACT.md §12; keep `max_threads` at or above the approved `max_parallel`.
- Current repo docs: `CODEX-ADAPTER.md`, `CODEX-RUNBOOK.md`, and `CODEX-TEST-HARNESS.md`.

### Claude Code

- Current local CLI surface checked in this repo on 2026-05-04: `claude 2.1.126`.
- Visible session and runtime flags include `--agent`, `--agents`, `--worktree`, `--tmux`, `--effort`, and `--permission-mode auto`.
- Delegation: project and user agent surfaces are `.claude/agents/` and `~/.claude/agents/`; use explicit Builder selection when the delegated role must be deterministic, even though Claude can also delegate automatically.
- Nesting and approvals: subagents cannot spawn other subagents, and background subagents inherit only pre-approved permissions; do not rely on them for interactive recovery.
- Session settings and kickoff: observe current session model and thinking when available, report `unknown` when a field is not exposed, honor or reject optional Builder overrides explicitly, and keep the Builder start plus run step budget inside kickoff before any fallback handoff.
- Worktree: distinguish in-session continuation from fallback handoff, and bootstrap plus evidence the active worktree environment before Builder or `hard_gate` validation rely on it.
- Monitoring and compaction: do not claim live Builder reasoning visibility unless a concrete runtime surface actually provides it; follow the monitoring ladder defined in CONTRACT.md §7, document manual `/compact` only when the active Claude surface exposes it, auto-compaction fallback when it does not, and the lack of any trustworthy parent-visible exact subagent fullness percentage.
- Readiness and cleanup: require a real Builder readiness signal before treating the child as live, and preserve lineage and durable evidence before closing or purging older child sessions so only one live Builder remains visible after recovery or direct completion.
- Wave mode: concurrent slots via exec-transport children per CONTRACT.md §12; interactive foreground subagents stay serial.
- Current repo docs: `CLAUDE-ADAPTER.md`, `CLAUDE-RUNBOOK.md`, and `CLAUDE-TEST-HARNESS.md`.

### Future adapters

- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters over the shared contract.
- No Hermes adapter or other extra runtime adapter ships in this repo today.
