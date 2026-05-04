# Codex Adapter Runbook

This runbook defines the operational Codex adapter path over the shared `cdd-master-chef` contract.

Use the shared contract in `CONTRACT.md` and the Codex adapter rules in `CODEX-ADAPTER.md` as the source of truth. Use this file for the concrete Codex operating shape.

## 1) Session shape

- Launch the main Codex session with the approved `master_model`.
- Treat the main Codex session as Master Chef.
- Treat Builder delegation as explicit. Master Chef should name the agent it wants rather than waiting for Codex to improvise the Builder shape.

Typical launch controls:

- `-m <master_model>` for the parent model
- `-C <repo-or-worktree>` for the active repo root
- `-a on-request` when Builder or QA may need new approvals

## 2) Builder selection

Use one-step Builder runs only.

- For normal implementation, explicitly use the built-in `worker` agent or a project-scoped custom Builder agent.
- For read-heavy repo mapping, explicitly use the built-in `explorer` agent or a project-scoped custom explorer.
- For narrow QA or docs checks, prefer project-scoped custom agents when the task benefits from different MCP wiring, sandboxing, or model settings.

Adapter rule:

- Do not claim that Codex will spawn Builder automatically without explicit delegation instructions.
- If the repo defines `.codex/agents/*.toml`, prefer those named agents over ad hoc behavior when the run needs stable, repeatable roles.

## 3) Run config handling

Before kickoff, Master Chef must state how the approved `Run config` maps into Codex:

- `master_model`: exact when the parent session is launched with that model
- `master_thinking`: exact when the parent session reasoning effort matches the requested setting
- `builder_model`: exact when the Builder agent TOML sets `model`, inherited when the Builder intentionally follows the parent session, startup-only when the Builder path depends on relaunching the parent session, constrained when a built-in agent is used without a narrower override
- `builder_thinking`: exact when the Builder agent TOML sets `model_reasoning_effort`, inherited when it follows the parent session, startup-only when it depends on session launch or relaunch, constrained when the current Builder path cannot narrow it cleanly

Do not start implementation until Master Chef has named which of `exact support`, `inherited-model fallback`, `startup-only application`, or `constrained behavior` applies to the Builder settings.

## 4) Approval and sidecar policy

- Keep Builder interactive when the delegated step may need fresh approvals.
- Use read-heavy sidecars for discovery, file mapping, or documentation checks that can safely run with narrower permissions.
- If a sidecar fails because it cannot surface a new approval, return control to Master Chef and decide whether to retry interactively or keep the work in the main session.

## 5) Worktree hand-off

- Follow the shared clean-checkout-first worktree contract.
- If the active Codex surface cannot safely continue in the managed worktree, stop after provisioning and relaunch with `-C <active_worktree_path>`.
- Do not assume Codex app worktree behavior and Codex CLI worktree behavior are identical.

## 6) Blocked paths

- Do not use recursive multi-level fan-out as the default Master Chef pattern.
- Do not hide Builder downgrade decisions.
- Do not send approval-heavy Builder work into detached or non-interactive sidecars and expect automatic recovery.
