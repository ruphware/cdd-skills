# Codex Adapter Contract

This file defines how the shared `cdd-master-chef` contract maps onto Codex.

Use this adapter when the controlling runtime is Codex CLI, Codex app, or another Codex surface that exposes explicit subagent workflows.

This is one of the shipped subagent-backed adapters in `cdd-master-chef`.

## Runtime mechanics only

The shared contract already defines Builder lifecycle, monitoring, replacement thresholds, and one-active-Builder cleanup. This adapter should document only the Codex mechanics that implement that lifecycle: explicit delegation, agent surfaces, sandbox and approval inheritance, worktree coherence, readiness or status visibility, and documented compaction or context-meter limits.

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

## 3) Runtime mechanics in live sessions

- `Approvals:` subagents inherit the current sandbox policy from the parent session. In interactive CLI sessions approval requests can surface from inactive agent threads; in non-interactive flows, or whenever a run cannot surface a fresh approval, an action that needs new approval fails and Codex surfaces the error back to the parent workflow. Keep approval-heavy Builder work interactive, and use read-heavy sidecars for narrower sandboxes or specialized MCP or tool setups.
- `Continuation:` same Builder continuation across delegated steps is the normal path when the active Codex surface can keep the child session and managed worktree coherent.
- `Compaction:` before a new delegated step, attempt Builder compaction only if the active Codex surface exposes a supported command or API. Current repo docs and the local `codex --help` surface do not document a clean parent-visible subagent compaction command or API, so this adapter must not invent one. When no supported compaction surface is exposed, keep the same Builder and rely on native context management or any runtime auto-compaction that the active Codex surface performs. Do not claim a clean official parent-visible subagent context meter, exact token-left budget, or other precise fullness percentage for Master Chef decisions.
- `Visibility:` this adapter does not guarantee live access to Builder chain-of-thought or streaming partial output. Direct Builder visibility is limited to runtime-reported completion/failure, explicit status replies, and closure/error surfaces when Codex exposes them.
- `Readiness:` a returned Builder handle or session key proves only that Codex accepted the spawn request. It does not prove that the child has loaded its usable repo, tool, or MCP context. Master Chef should require one early Builder readiness ACK before treating the child as fully live. That ACK should confirm the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- `Monitoring policy:` Builder-monitoring cadence, boot timeout, suspect classification, and replacement policy live in `CONTRACT.md` §7 — Kickoff and Builder lifecycle.
- `Codex direct-status surfaces:` direct visibility is limited to runtime-reported completion / failure notifications, explicit progress replies from the child agent, and runtime-reported closure or error events; a `wait` result that reports no agent has completed yet means `running` or `unknown`, not `dead`. Live chain-of-thought and streaming partial output are not exposed. Prefer those surfaces or one explicit progress request over guesswork.
- `Codex probe form:` send the explicit status probe through the named agent (built-in `worker` / `explorer` / project-scoped custom) that owns the Builder, using the same delegation surface that spawned it rather than creating a new agent.
- `Codex session close:` close or purge the child agent through the runtime's session-management surface; preserve lineage and durable evidence first so only one live Builder remains visible.

## 4) Session settings and Builder override

- `master_model` and `master_thinking` come directly from the active Codex session.
- Builder inherits those settings by default.
- A Builder override is clean only when the selected custom agent TOML sets `model` and/or `model_reasoning_effort`, or when the parent Codex session is deliberately relaunched and Builder intentionally inherits the new setting.
- If built-in agents are used without narrower agent config, effective Builder settings remain inherited from the parent session.
- Do not silently ignore a requested Builder override. State whether it landed cleanly or whether Builder is falling back to inherited settings.

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
- Do not claim a manual Builder compaction path or parent-visible context meter unless a concrete Codex surface in this repo actually documents it.

## 8) Source notes

This adapter is grounded in:

- current official Codex subagents documentation
- current official Codex worktrees documentation
- the current local `codex --help` CLI surface for session flags and runtime controls
