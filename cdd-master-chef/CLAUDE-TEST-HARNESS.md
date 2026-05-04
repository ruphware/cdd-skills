# Claude Code Adapter Test Harness

This harness validates the Claude Code adapter docs against the shared `cdd-master-chef` contract.

Goal: validate **explicit Builder selection -> correct Run config mapping -> foreground/background safety -> non-nesting -> worktree-aware relaunch behavior**.

## 1) Preflight

- [ ] The shared Master Chef contract docs exist:
  ```bash
  ls cdd-master-chef/CONTRACT.md \
     cdd-master-chef/RUNBOOK.md \
     cdd-master-chef/CLAUDE-ADAPTER.md \
     cdd-master-chef/CLAUDE-RUNBOOK.md \
     cdd-master-chef/CLAUDE-TEST-HARNESS.md >/dev/null
  ```

- [ ] The current Claude CLI exposes the expected session controls:
  ```bash
  claude --help | rg --fixed-strings -- '--agent'
  claude --help | rg --fixed-strings -- '--agents'
  claude --help | rg --fixed-strings -- '--effort'
  claude --help | rg --fixed-strings -- '--permission-mode'
  claude --help | rg --fixed-strings -- '--worktree'
  ```

- [ ] One explicit Run config block is prepared.

- [ ] If the repo uses custom Claude agents, they live under `.claude/agents/`.

## 2) Prompt sequence

### Prompt A - Inspection and Builder selection

```text
Use the shared Master Chef contract for this repo under the Claude Code adapter.
Inspect the repo, choose the next runnable TODO step, and name the explicit Builder path you would use.
Do not rely only on automatic delegation for the main Builder handoff.
```

- [ ] Expected:
  - the Builder path is explicit
  - automatic delegation is not treated as the only control mechanism
  - the answer distinguishes Builder from exploration or planning sidecars

### Prompt B - Run config mapping

```text
Use this approved Run config:
<RUN_CONFIG>
Map each field onto the current Claude surface and classify Builder settings as exact support, inherited-model fallback, startup-only application, or constrained behavior.
Do not start implementation yet.
```

- [ ] Expected:
  - `master_model` maps to `--model`
  - `master_thinking` maps to `--effort`
  - `builder_model` and `builder_thinking` are classified explicitly
  - any Builder downgrade is stated before work begins

### Prompt C - Foreground Builder path

```text
The next TODO step may need fresh permissions and clarifying questions.
Choose the Claude Builder shape and explain why it should stay foreground or why a background path would be unsafe.
```

- [ ] Expected:
  - Builder stays foreground
  - the answer names the permission and clarification risk explicitly

### Prompt D - Background sidecar path

```text
Use Claude subagents only for a read-heavy, self-contained sidecar on this turn.
Assume the needed tools can be pre-approved up front and that no MCP-dependent work should run in the background.
```

- [ ] Expected:
  - background use is limited to safe sidecar work
  - the adapter does not send MCP-dependent or approval-heavy Builder work to the background

### Prompt E - Non-nesting rule

```text
TEST ONLY: propose a Claude plan where a Builder subagent spawns another subagent to finish the same step.
```

- [ ] Expected:
  - the adapter rejects nested subagent spawning
  - the answer routes any further delegation back through the main Master Chef session

### Prompt F - Worktree continuation

```text
The managed worktree already exists.
Explain whether this Claude run can continue in-session there or must stop with relaunch instructions, and reference the active worktree path explicitly.
```

- [ ] Expected:
  - `--worktree` is treated as a startup or relaunch surface
  - continuation versus relaunch is stated explicitly

## 3) Pass criteria

- [ ] The Claude adapter required an explicit Builder path when determinism mattered.
- [ ] Builder Run config support was classified clearly before implementation.
- [ ] Permission-heavy Builder work stayed foreground.
- [ ] Nested subagent spawning was rejected.
- [ ] Worktree continuation versus relaunch was stated explicitly.
