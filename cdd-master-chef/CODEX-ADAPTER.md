# Codex Adapter Contract

This file defines how the shared `cdd-master-chef` contract maps onto Codex.

Use this adapter when the controlling runtime is Codex CLI, Codex app, or another Codex surface that exposes explicit subagent workflows.

This is one of the current concrete subagent-backed adapters shipped in the `cdd-master-chef` package.

## 1) Delegation model

- Codex supports subagent workflows by spawning specialized agents in parallel and then collecting their results in one response.
- Codex only spawns subagents when you explicitly ask it to.
- Treat Builder delegation as explicit and intentional; do not write adapter rules that assume automatic delegation.

Master Chef routing in Codex:

- **Builder:** use the execution-focused `worker` built-in agent or a project-scoped custom worker when the task is implementation-heavy
- **Exploration / mapping:** use the read-heavy `explorer` built-in agent or a project-scoped custom explorer when the task is codebase mapping, evidence gathering, or read-only discovery
- **QA support / docs research:** prefer narrow custom agents when the task needs a dedicated MCP server, custom sandbox, or different model profile

## 2) Built-in vs custom agents

Codex ships with built-in agents:

- `default` — general-purpose fallback
- `worker` — execution-focused implementation and fixes
- `explorer` — read-heavy codebase exploration

Use built-in agents when:

- the task matches the built-in role closely
- the default parent model and sandbox policy are acceptable
- no custom MCP wiring or adapter-specific instructions are needed

Use project-scoped custom agents when:

- the agent needs specialized instructions beyond the built-in roles
- the agent needs a different model or reasoning effort
- the agent needs different sandbox defaults
- the agent needs adapter-specific MCP server configuration
- the project wants reproducible shared agent behavior under version control

Project-scoped custom agents belong under:

```text
.codex/agents/*.toml
```

Codex also supports personal agents under:

```text
~/.codex/agents/*.toml
```

## 3) Parent session and child session behavior

- Subagents inherit the current sandbox policy from the parent session.
- In interactive CLI sessions, approval requests can surface from inactive agent threads.
- In non-interactive flows, or whenever a run cannot surface a fresh approval, an action that needs new approval fails and Codex surfaces the error back to the parent workflow.
- Codex reapplies the parent turn's live runtime overrides when it spawns a child, including interactive approval changes.

Adapter implication:

- Master Chef should keep Builder work interactive when the delegated step may need fresh approvals.
- Read-heavy sidecar agents are the safest place to use narrower sandboxes and specialized MCP/tool setups.
- This adapter does not guarantee live access to Builder chain-of-thought or streaming partial output.
- Direct Builder visibility in this adapter is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Codex exposes them.
- A returned Builder handle or session key proves only that Codex accepted the spawn request. It does not prove that the child has loaded its usable repo, tool, or MCP context.
- Master Chef should require one early Builder readiness ACK before treating the child as fully live. That ACK should confirm the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- A quiet agent, missing diff, or empty `builder.jsonl` is not enough by itself to prove that Builder has died.
- A timed-out wait or one unanswered progress request is still inconclusive unless Codex also reports closure or failure.
- Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.
- When progress is uncertain, prefer direct runtime status, final agent messages, or one explicit progress request over guesswork.

## 4) Run config mapping

Shared Run config:

- `master_model`
- `master_thinking`
- `builder_model`
- `builder_thinking`

Codex mapping rules:

- `master_model` maps directly to the parent Codex session model when the operator launches Codex with that model.
- `master_thinking` maps to the parent Codex reasoning effort when the active model supports it.
- `builder_model` maps directly only when the selected built-in or custom agent sets `model` explicitly or inherits the parent model intentionally.
- `builder_thinking` maps directly only when the spawned built-in or custom agent sets `model_reasoning_effort` explicitly or inherits the parent reasoning effort intentionally.

Allowed adapter outcomes:

- **Exact support:** custom agent TOML sets `model` and `model_reasoning_effort` exactly
- **Inherited-model fallback:** custom agent omits one or both fields and intentionally inherits from the parent Codex session
- **Startup-only application:** the requested setting is applied only when the parent Codex session is launched or relaunched with that setting, and the Builder intentionally inherits it from that session
- **Constrained behavior:** built-in agents are used and Builder follows parent-session runtime settings because no narrower per-agent override exists in the current flow

Do not silently ignore Run config differences. State explicitly whether the Builder agent is using exact support, inherited-model fallback, startup-only application, or constrained behavior.

## 5) Recommended Codex adapter shapes

### Minimal path

- Master Chef stays in the main Codex session.
- Builder runs through the built-in `worker` agent.
- Read-only exploration runs through the built-in `explorer` agent.
- Model and reasoning settings inherit from the parent session unless a custom agent is introduced.

### Structured path

- Project-level `.codex/config.toml` defines:

  ```toml
  [agents]
  max_threads = 6
  max_depth = 1
  ```

- Project-level `.codex/agents/` defines narrow custom agents such as:
  - `todo_builder`
  - `code_mapper`
  - `docs_researcher`
  - `qa_reviewer`

Use `max_depth = 1` unless the project has a compelling reason for recursive delegation. The adapter should not encourage deeper nesting by default.

## 6) Worktree handling

- Codex app documentation supports Codex-managed worktrees and handoff between worktree and local.
- Codex-managed worktrees start in detached `HEAD` and may carry uncommitted changes in the app workflow.
- This shared repo contract remains stricter: Step 17 requires clean-checkout-first worktree creation for `cdd-master-chef`.

Adapter rule:

- Do not rely on Codex app dirty-state transfer for `cdd-master-chef`.
- Prefer continuing in-session after worktree creation when Master Chef can keep both its own commands and Builder delegation rooted at `active_worktree_path` coherently.
- The Codex adapter must either:
  - continue safely in the managed worktree in-session when the concrete runtime path supports that, or
  - stop with exact relaunch or handoff instructions when that path is not coherent in the active runtime surface
- If a relaunch or handoff fallback is unavoidable, do not hand the Builder-start decision back to the human. The kickoff approval should already have captured whether Builder should start immediately once the managed worktree path is active.

## 7) Unsupported or blocked patterns

- Do not claim that Codex will spawn Builder automatically without explicit delegation instructions.
- Do not assume a background or detached worker can recover fresh approvals in non-interactive mode.
- Do not encourage recursive multi-level fan-out as the default Master Chef behavior.
- Do not promise that Codex app worktree behavior and Codex CLI worktree behavior are identical without adapter-specific proof.

## 8) Source notes

This adapter is grounded in:

- current official Codex subagents documentation
- current official Codex worktrees documentation
- the current local `codex --help` CLI surface for session flags and runtime controls
