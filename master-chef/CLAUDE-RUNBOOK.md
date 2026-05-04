# Claude Code Adapter Runbook

This runbook defines the operational Claude Code adapter path over the shared `cdd-master-chef` contract.

Use the shared contract in `CONTRACT.md` and the Claude adapter rules in `CLAUDE-ADAPTER.md` as the source of truth. Use this file for the concrete Claude operating shape.

## 1) Session shape

- Launch the main Claude session with the approved `master_model` and `master_thinking`.
- Treat the main Claude session as Master Chef.
- Prefer explicit Builder selection through a named agent, `@`-mention, or a deliberate `--agent` / `--agents` launch path when the Builder role must be deterministic.

Typical launch controls:

- `--model <master_model>` for the main session model
- `--effort <master_thinking>` for the main session effort
- `--agent <name>` or `--agents <json>` when the run needs a specific Builder or helper definition
- `--worktree [name]` when Claude is relaunched directly into a managed worktree

## 2) Builder selection

Use one-step Builder runs only.

- For main implementation, prefer a project-scoped `.claude/agents/` Builder agent or an explicit named agent selection.
- For read-heavy exploration, use `Explore` or a custom read-only agent.
- For isolated planning, use `Plan` only as a sidecar; the main Master Chef control loop still owns final routing and next-step decisions.
- For QA or docs checks, use narrow custom agents when they benefit from tighter tool scope or explicit model selection.

Adapter rule:

- Claude can delegate automatically, but Master Chef should not rely on automatic delegation alone for the main Builder path.
- Subagents cannot spawn other subagents, so every additional agent handoff returns to the main Master Chef session first.

## 3) Run config handling

Before kickoff, Master Chef must state how the approved `Run config` maps into Claude:

- `master_model`: exact when the parent session is launched with `--model`
- `master_thinking`: exact when the parent session is launched with `--effort`
- `builder_model`: exact when the chosen Builder agent sets `model`, inherited when the Builder follows the parent session, startup-only when the Builder is applied through a relaunch path such as `--agent` or `--worktree`, constrained when the requested Builder override cannot be honored cleanly
- `builder_thinking`: inherited by default in this adapter, startup-only when applied through a relaunch path, constrained when no reliable per-agent effort override exists for the current Builder path

Do not start implementation until Master Chef has named which of `exact support`, `inherited-model fallback`, `startup-only application`, or `constrained behavior` applies to the Builder settings.

## 4) Foreground and background policy

- Keep Builder in the foreground when the task may need fresh permissions, clarifying questions, or multi-phase implementation context.
- Use background subagents only for self-contained sidecar work that can finish with pre-approved tools and no interactive recovery.
- Once a background subagent starts, it inherits the approved permissions and auto-denies anything not approved before launch.
- If a background subagent fails because it needs additional permission or clarification, do not stretch that path. Return control to Master Chef and retry through a foreground agent or the main session.

## 5) Tool and MCP policy

- If `tools` is omitted, Claude subagents inherit the main session tools.
- Foreground subagents may use inherited tools or explicitly scoped MCP servers when the configured agent definition allows it.
- Do not rely on background Builder work for MCP-dependent or approval-heavy tasks.

## 6) Worktree hand-off

- Follow the shared clean-checkout-first worktree contract.
- Treat `--worktree` as a startup-time or relaunch-time tool, not proof of a safe in-session repo-root switch.
- If the current Claude session cannot safely continue from the managed worktree, stop after provisioning and relaunch Claude there.

## 7) Blocked paths

- Do not treat nested subagent spawning as available.
- Do not let a background Builder path absorb clarifying-question or permission failures silently.
- Do not hide Builder Run config downgrades.
