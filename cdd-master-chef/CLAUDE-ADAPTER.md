# Claude Code Adapter Contract

This file defines how the shared `cdd-master-chef` contract maps onto Claude Code.

Use this adapter when the controlling runtime is Claude Code and Master Chef wants Builder delegation through Claude subagents.

This is one of the current concrete subagent-backed adapters shipped in the `cdd-master-chef` package.

## 1) Delegation model

- Claude Code supports built-in and custom subagents from the main Claude session.
- Claude can delegate automatically based on the request and the subagent description.
- Automatic delegation is acceptable for low-risk sidecar work, but the Master Chef adapter should use explicit Builder selection when the delegated role must be deterministic.

Master Chef routing in Claude Code:

- **Builder:** use an explicitly selected implementation agent, preferably a project-scoped custom agent or a named built-in agent that clearly matches the task
- **Exploration / mapping:** use a read-heavy agent such as `Explore` or a project-scoped custom explorer
- **Planning sidecars:** use `Plan` or a narrow project-scoped planning agent when the main session wants isolated decomposition
- **QA support / docs research:** use custom agents when the task benefits from stricter tool restrictions, a dedicated model, or isolated MCP server scope

Adapter rule:

- Do not rely on automatic delegation alone for the main Builder handoff.
- Use a named agent, an `@`-mention, or a session-scoped configured agent when Master Chef needs a specific Builder role.

## 2) Agent surfaces

Claude Code supports these configured-agent surfaces:

- `--agents <json>` for session-scoped agent definitions
- `.claude/agents/` for project-scoped shared agents
- `~/.claude/agents/` for user-scoped personal agents
- plugin `agents/` directories for plugin-provided agents when that plugin is enabled

Claude also exposes:

- `--agent <name>` to run the whole session as a specific agent
- `agents` and `/agents` to inspect and manage available agents

Use project-scoped `.claude/agents/` definitions when:

- the repo wants a reproducible Builder role under version control
- the Builder needs a fixed description, tool list, or model
- the team wants a stable named agent that Master Chef can invoke explicitly

Use `--agents` when:

- the run needs a temporary session-only Builder definition
- the operator wants to test an adapter shape before checking it into the repo

## 3) Foreground vs background policy

- Foreground subagents block the main conversation and can pass permission prompts and clarifying questions through to the human.
- Background subagents run concurrently after permissions are gathered up front.
- Once a background subagent is running, it inherits the pre-approved permissions and auto-denies anything that was not approved before launch.
- If a background subagent needs clarifying questions, that tool call fails and the subagent continues.

Adapter implication:

- Keep Builder in the foreground when the step may need fresh approvals, human clarification, multi-phase reasoning, or interactive recovery.
- Background subagents are appropriate only for self-contained sidecar work that is read-heavy, pre-approved, and safe to fail without interactive recovery.
- Do not rely on background Builder flows for MCP-dependent or approval-heavy work, even though foreground Claude subagents can inherit tool access from the main session.

## 4) Non-nesting and tool inheritance

- Subagents cannot spawn other subagents.
- If `tools` is omitted, a Claude subagent inherits the main session's tools.
- Claude subagents can be given dedicated MCP server scope through their configured agent definition.

Adapter implication:

- Multi-step delegation must be chained by the main Master Chef session rather than delegated recursively through Builder.
- If a Builder step needs another agent, return control to Master Chef and let the main session launch the next agent explicitly.
- This adapter does not guarantee live access to Builder chain-of-thought or streaming partial output.
- Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Claude exposes them.
- A returned Builder handle or session key proves only that Claude accepted the spawn request. It does not prove that the child has loaded its usable repo, tool, or MCP context.
- Master Chef should require one early Builder readiness ACK before treating the child as fully live. That ACK should confirm the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- A quiet agent, missing diff, or empty `builder.jsonl` is not enough by itself to prove that Builder has died.
- A quiet wait or one unanswered progress request is still inconclusive unless Claude also reports closure or failure.
- Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.
- When progress is uncertain, prefer direct runtime status, final agent messages, or one explicit progress request over guesswork.

## 5) Session settings and Builder override

- `master_model` and `master_thinking` come directly from the active Claude session.
- Builder inherits those settings by default.
- A Builder override is clean only when the chosen Builder agent sets `model` explicitly or when Builder is applied through a relaunch path that can carry the requested `builder_model` and/or `builder_thinking`.
- If the current Claude path cannot honor a requested Builder override cleanly, Master Chef must say so and use inherited Builder settings instead.
- Do not silently ignore `builder_model` or `builder_thinking`.

## 6) Worktree handling

- The local Claude CLI exposes `--worktree [name]` and optional `--tmux`.
- That is enough to support a startup-time or relaunch-time worktree path.
- It is not enough to claim that a live Claude session can safely switch its active repo root mid-run.

Adapter rule:

- Follow the shared clean-checkout-first worktree contract from Step 17.
- Prefer continuing in-session after worktree creation when the current Claude surface can keep Master Chef and Builder coherently rooted at `active_worktree_path`.
- Prefer relaunching or restarting Claude into the managed worktree when the active session cannot safely continue there.
- Keep `worktree_continue_mode` explicit. Do not claim in-session continuation unless the concrete Claude runtime path has been proven for that adapter flow.
- If relaunch is unavoidable, do not give the human the Builder-start decision back. The kickoff approval should already cover whether Builder should start immediately once the managed worktree path is active.

## 7) Unsupported or blocked patterns

- Do not claim that Claude Builder delegation is recursively nestable.
- Do not rely on background subagents to recover fresh approvals or clarifying questions.
- Do not rely on background Builder work for MCP-dependent tasks.
- Do not silently downgrade `builder_thinking` when the current Claude surface can only satisfy it through parent-session inheritance or relaunch.

## 8) Source notes

This adapter is grounded in:

- current Claude Code subagent documentation
- the current local `claude --help` CLI surface for agent, worktree, and effort flags
