# Claude Code Adapter Runbook

This runbook defines the operational Claude Code adapter path over the shared `cdd-master-chef` contract.

Use the shared contract in `CONTRACT.md` and the Claude adapter rules in `CLAUDE-ADAPTER.md` as the source of truth. Use this file for the concrete Claude operating shape.

## 1) Session shape

- Launch the main Claude session with the desired Master Chef model and effort. The active session values become `master_model` and `master_thinking` for the run.
- Treat the main Claude session as Master Chef.
- Prefer explicit Builder selection through a named agent, `@`-mention, or a deliberate `--agent` / `--agents` launch path when the Builder role must be deterministic.

Typical launch controls:

- `--model <model>` for the main session model
- `--effort <effort>` for the main session effort
- `--agent <name>` or `--agents <json>` when the run needs a specific Builder or helper definition
- `--worktree [name]` when Claude is relaunched directly into a managed worktree

## 2) Builder selection

Use single-step Builder runs only.

- For main implementation, prefer a project-scoped `.claude/agents/` Builder agent or an explicit named agent selection.
- For read-heavy exploration, use `Explore` or a custom read-only agent.
- For isolated planning, use `Plan` only as a sidecar; the main Master Chef control loop still owns final routing and next-step decisions.
- For QA or docs checks, use narrow custom agents when they benefit from tighter tool scope or explicit model selection.

Adapter rule:

- Claude can delegate automatically, but Master Chef should not rely on automatic delegation alone for the main Builder path.
- Subagents cannot spawn other subagents, so every additional agent handoff returns to the main Master Chef session first.

## 3) Session settings and Builder override

Before kickoff, Master Chef must report the current session model and thinking as read-only Master Chef facts.

- If the active Claude surface does not expose one or both fields exactly, Master Chef must record only those fields as `unknown`, say Claude does not expose them here, and keep kickoff moving.
- If no `Builder override` is supplied, Builder inherits those settings.
- If Builder inherits from an unresolved parent field and no explicit override replaces it, the inherited Builder field stays `unknown`.
- If a `Builder override` is supplied, Master Chef must say whether the chosen Builder path can honor the requested `builder_model` and/or `builder_thinking` cleanly.
- If the current Builder path cannot honor the requested override cleanly, say so explicitly and use inherited Builder settings instead.
- Do not ask the human to type replacement `master_*` settings when Claude cannot expose them.

Do not start implementation until the effective Builder settings for the run are explicit.

## 4) Kickoff approval and run budget

Before autonomous implementation starts, Master Chef should present one selector-driven kickoff approval that covers:

- the next runnable TODO step or other chosen routing action
- any pre-delegation split of an oversized next top-level TODO step, plus the recomputed remaining top-level-step count
- current session model
- current session thinking
- effective Builder settings
- the shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget
- the approved run step budget for this run: a positive integer count such as `1` or `3`, or `until_blocked_or_complete`
- whether to spawn Builder now and start the autonomous run

Follow the shared selector contract.

- `A. approve kickoff and start the autonomous run now`
- `B. approve kickoff but do not spawn Builder yet`
- `C. revise the next action, Builder settings, or step budget before kickoff`

After that selector-based approval, Master Chef owns the Builder handoff. Do not treat "here is a `claude --worktree ...` command for you to run" as the normal Builder-start path.

Once kickoff approval lands, Master Chef owns the mission under the approved run step budget. It keeps continuation, Builder restarts, blocker repair, TODO splitting, and terminal reporting in-session unless a hard technical or physical limit forces a stop.

## 5) Foreground and background policy

- Keep Builder in the foreground when the task may need fresh permissions, clarifying questions, or multi-phase implementation context.
- Use background subagents only for self-contained sidecar work that can finish with pre-approved tools and no interactive recovery.
- Once a background subagent starts, it inherits the approved permissions and auto-denies anything not approved before launch.
- If a background subagent fails because it needs additional permission or clarification, do not stretch that path. Return control to Master Chef and retry through a foreground agent or the main session.

## 6) Tool and MCP policy

- If `tools` is omitted, Claude subagents inherit the main session tools.
- Foreground subagents may use inherited tools or explicitly scoped MCP servers when the configured agent definition allows it.
- Do not rely on background Builder work for MCP-dependent or approval-heavy tasks.

## 7) Worktree hand-off

- Follow the shared clean-checkout-first worktree contract.
- If the shared kickoff rule approved a feature branch, create it in the source checkout first; then provision the managed worktree from that branch `HEAD`.
- Prefer `worktree_continue_mode: in_session` when the active Claude surface can keep Master Chef and Builder coherently rooted at `active_worktree_path`.
- Treat `--worktree` as a startup-time or relaunch-time tool when the current Claude surface cannot continue safely in-session.
- If a relaunch or restart is unavoidable, keep the approved Builder start and run step budget as part of that continuation plan rather than asking the human to decide again whether to spawn Builder.

## 8) Builder monitoring

- The current Claude adapter should not claim live access to Builder thinking or guaranteed streaming partial output.
- Direct surfaces in this adapter are limited to final completion/failure notifications, explicit status replies, and runtime-reported closure/errors when Claude exposes them.
- Treat Builder monitoring as two phases: boot/readiness first, quiet-work monitoring second.
- A returned spawn handle or `builder_session_key` is spawn evidence only. It is not enough to prove that Builder has started operating.
- Keep `builder_phase: booting` until Claude surfaces a runtime child-started signal, a coherent Builder readiness ACK, or a Builder-authored `BUILDER_READY` record in `builder.jsonl`.
- Use the shared boot prompt: `Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.`
- The preferred readiness ACK confirms the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
- A quiet wait with no completion means `running` or `unknown`, not `dead`.
- One unanswered direct status request is still inconclusive unless Claude also reports closure or failure.
- Do not mark Builder stale only because there is no diff yet, `builder.jsonl` is still empty, or one short wait window passed quietly.
- Use a short boot window, about 2 minutes in foreground Claude flows, before the first boot-status probe.
- For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless Claude reports direct failure sooner.
- In foreground Claude flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
- Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
- After that grace window, use one direct status request before replacement when the active Claude surface can send it coherently.
- If Builder sends any coherent status or discovery reply, treat that as proof of life and decide whether the issue is route drift or normal progress, not Builder death.
- Replace Builder only after direct failure, unexpected closure, an explicit Builder blocker, or no reply to that direct status probe after the grace window.

## 9) Blocked paths

- Treat every non-passing Builder attempt, including QA reject, explicit blocker, or stale replacement with no usable pass result, as a continuation-review boundary in the main Master Chef session.
- Review completed work, failed proof, whether the remainder is still one bounded implementation action, whether a fresh Builder would spend most of its effort on recovery rather than completion, and whether the unfinished remainder now has cleaner sub-step boundaries than the original parent step.
- Choose one explicit outcome:
  - `continue_same_step` when progress is coherent, the step boundary still holds, and a fresh Builder can plausibly finish the remainder without reopening planning
  - `repair_in_place` when the step boundary still holds but the TODO step needs a tighter contract, sequencing note, or proof note before the next Builder run
  - `split_remainder_into_child_steps` when the unfinished portion is now too risky to keep as one Builder run and can be expressed as clearer executable child steps with explicit dependency order
  - `hard_stop` when a hard technical or physical limit still prevents safe continuation
- If a safe next action still exists, report `STEP_BLOCKED`, keep the decision in the main session, emit `BLOCKER_CLEARED` once the next action is explicit, and continue with a fresh Builder under the existing approval.
- If the chosen outcome is `split_remainder_into_child_steps`, record what part of the parent step is already done, what exact remainder is being separated, why the first child is the next runnable step, and what checks, UAT, and invariants carry forward to the child steps.
- Do not split too eagerly without one-run failure-risk evidence, and do not keep retrying same-step continuation after the remaining work has clearly become a lower-risk child-step sequence.
- Do not hand ordinary scope, sequencing, or blocker-resolution decisions back to the human during an active autonomous run.
- End terminal states with a final mission report covering completed work, validations and pushes, Builder restarts or blocker repairs, unresolved session-setting fields, which effective Builder settings were concrete versus `unknown`, decisions made, and remaining work or the exact stop reason.
- Do not treat nested subagent spawning as available.
- Do not let a background Builder path absorb clarifying-question or permission failures silently.
- Do not hide Builder override failures or inherited-setting fallback decisions.
