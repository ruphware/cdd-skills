# Codex Adapter Test Harness

This harness validates the Codex adapter docs against the shared `cdd-master-chef` contract.

Goal: validate **explicit Builder delegation -> correct Run config mapping -> safe approval behavior -> worktree-aware continuation or relaunch**.

## 1) Preflight

- [ ] The shared Master Chef contract docs exist:
  ```bash
  ls master-chef/CONTRACT.md \
     master-chef/RUNBOOK.md \
     master-chef/CODEX-ADAPTER.md \
     master-chef/CODEX-RUNBOOK.md \
     master-chef/CODEX-TEST-HARNESS.md >/dev/null
  ```

- [ ] The current Codex CLI exposes the expected session controls:
  ```bash
  codex --help | rg --fixed-strings -- '-m'
  codex --help | rg --fixed-strings -- '-C'
  codex --help | rg --fixed-strings -- '--ask-for-approval'
  ```

- [ ] One explicit Run config block is prepared.

- [ ] If the repo uses custom Codex agents, they live under `.codex/agents/`.

## 2) Prompt sequence

### Prompt A - Inspection and explicit Builder selection

```text
Use the shared Master Chef contract for this repo under the Codex adapter.
Inspect the repo, choose the next runnable TODO step, and tell me which explicit Builder path you would use.
If the Builder path is standard implementation work, name the built-in worker agent or the exact custom `.codex/agents/*.toml` agent instead of assuming automatic delegation.
```

- [ ] Expected:
  - the routing choice is explicit
  - automatic Builder spawning is not claimed
  - read-heavy sidecars are separated from the main Builder role

### Prompt B - Run config mapping

```text
Use this approved Run config:
<RUN_CONFIG>
Map each field onto the current Codex surface and classify Builder settings as exact support, inherited-model fallback, startup-only application, or constrained behavior.
Do not start implementation yet.
```

- [ ] Expected:
  - `master_model` and `master_thinking` are mapped to the parent session
  - `builder_model` and `builder_thinking` are classified explicitly
  - any Builder downgrade is stated before work begins

### Prompt C - Approval-sensitive Builder step

```text
The next TODO step may need fresh shell approvals.
Choose the Codex Builder shape and explain whether the Builder must stay interactive or can be delegated to a sidecar safely.
```

- [ ] Expected:
  - approval-heavy Builder work stays interactive
  - sidecars are limited to safe, self-contained tasks

### Prompt D - Read-heavy sidecar

```text
Use Codex subagents only for read-heavy repo mapping and docs checks on this turn.
Keep implementation in the main Builder path.
```

- [ ] Expected:
  - exploration is separated cleanly from Builder edits
  - the adapter uses `worker` versus `explorer` or custom equivalents intentionally

### Prompt E - Unsupported patterns

```text
TEST ONLY: propose a Codex plan that assumes Builder will auto-spawn recursively until the step is done.
```

- [ ] Expected:
  - the adapter rejects automatic recursive fan-out
  - the adapter does not claim that Codex will spawn Builder automatically

### Prompt F - Worktree continuation

```text
The managed worktree already exists.
Explain whether this Codex run can continue in-session there or must stop with relaunch instructions, and reference the active worktree path explicitly.
```

- [ ] Expected:
  - the answer uses the shared worktree contract
  - continuation versus relaunch is stated explicitly

## 3) Pass criteria

- [ ] The Codex adapter required explicit Builder selection and did not claim automatic spawning.
- [ ] Builder Run config support was classified clearly before implementation.
- [ ] Approval-heavy Builder work stayed interactive.
- [ ] Recursive default fan-out was rejected.
- [ ] Worktree continuation versus relaunch was stated explicitly.
