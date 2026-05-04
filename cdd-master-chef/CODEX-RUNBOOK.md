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

## 4) Kickoff approval and run budget

Before autonomous implementation starts, Master Chef should ask for one explicit kickoff approval that covers:

- the next runnable TODO step or other chosen routing action
- the approved `Run config`
- the approved run step budget for this run: a positive integer count such as `1` or `3`, or `until_blocked_or_complete`
- whether to spawn Builder now and start the autonomous run

After that approval, Master Chef owns the Builder handoff. Do not treat "here is a `codex -C ...` command for you to run" as the normal Builder-start path.

## 5) Approval and sidecar policy

- Keep Builder interactive when the delegated step may need fresh approvals.
- Use read-heavy sidecars for discovery, file mapping, or documentation checks that can safely run with narrower permissions.
- If a sidecar fails because it cannot surface a new approval, return control to Master Chef and decide whether to retry interactively or keep the work in the main session.

## 6) Worktree hand-off

- Follow the shared clean-checkout-first worktree contract.
- Prefer `worktree_continue_mode: in_session` when the active Codex surface can keep Master Chef and Builder operating against `active_worktree_path` coherently.
- If the active Codex surface truly cannot continue in the managed worktree, stop after provisioning and use the smallest coherent relaunch or handoff path.
- If a handoff is unavoidable, keep the approved Builder start and run step budget as part of that continuation plan rather than asking the human to decide again whether to spawn Builder.
- Do not assume Codex app worktree behavior and Codex CLI worktree behavior are identical.

## 7) Builder monitoring

- The current Codex adapter should not claim live access to Builder thinking or guaranteed streaming partial output.
- Direct surfaces in this adapter are limited to final completion/failure notifications, explicit status replies, and runtime-reported closure/errors when Codex exposes them.
- Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second.
- A returned spawn handle or `builder_session_key` is spawn evidence only. It is not enough to prove that Builder has started operating.
- Keep `builder_phase: booting` until Codex surfaces a runtime child-started signal, a coherent Builder readiness ACK, or a Builder-authored `BUILDER_READY` record in `builder.jsonl`.
- Use the shared boot prompt: `Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.`
- The preferred readiness ACK confirms the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- A `wait` result that says no agent has completed yet means `running` or `unknown`, not `dead`.
- One unanswered direct status request is still inconclusive unless Codex also reports closure or failure.
- Do not mark Builder stale only because there is no diff yet, `builder.jsonl` is still empty, or one short wait window passed quietly.
- Use a short boot window, about 2 minutes in foreground Codex flows, before the first boot-status probe.
- For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless Codex reports direct failure sooner.
- In foreground Codex flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
- Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
- After that grace window, use one direct status request before replacement when the active Codex surface can send it coherently.
- If Builder sends any coherent status or discovery reply, treat that as proof of life and decide whether the issue is route drift or normal progress, not Builder death.
- Replace Builder only after direct failure, unexpected closure, an explicit Builder blocker, or no reply to that direct status probe after the grace window.

## 8) Blocked paths

- Do not use recursive multi-level fan-out as the default Master Chef pattern.
- Do not hide Builder downgrade decisions.
- Do not send approval-heavy Builder work into detached or non-interactive sidecars and expect automatic recovery.
