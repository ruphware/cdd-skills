# Codex Adapter Test Harness

This harness validates the Codex adapter docs against the shared `cdd-master-chef` contract.

Goal: validate **explicit Builder delegation -> kickoff approval with step budget -> correct Run config mapping -> safe approval behavior -> worktree-aware continuation or relaunch**.

## 1) Preflight

- [ ] The shared Master Chef contract docs exist:
  ```bash
  ls cdd-master-chef/CONTRACT.md \
     cdd-master-chef/RUNBOOK.md \
     cdd-master-chef/CODEX-ADAPTER.md \
     cdd-master-chef/CODEX-RUNBOOK.md \
     cdd-master-chef/CODEX-TEST-HARNESS.md >/dev/null
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

### Prompt C - Kickoff approval and run budget

```text
The next runnable TODO step is known.
Ask for kickoff approval that includes the approved Run config, how many TODO steps this run should complete, and whether to spawn Builder now and start the autonomous run.
Do not hand the Builder-start decision back to me as a manual Codex command.
```

- [ ] Expected:
  - kickoff approval asks for a step budget such as `1`, `3`, or `until_blocked_or_complete`
  - kickoff approval asks whether to spawn Builder now
  - the adapter does not treat a manual `codex -C ...` command as the normal Builder-start path

### Prompt D - Approval-sensitive Builder step

```text
The next TODO step may need fresh shell approvals.
Choose the Codex Builder shape and explain whether the Builder must stay interactive or can be delegated to a sidecar safely.
```

- [ ] Expected:
  - approval-heavy Builder work stays interactive
  - sidecars are limited to safe, self-contained tasks

### Prompt E - Read-heavy sidecar

```text
Use Codex subagents only for read-heavy repo mapping and docs checks on this turn.
Keep implementation in the main Builder path.
```

- [ ] Expected:
  - exploration is separated cleanly from Builder edits
  - the adapter uses `worker` versus `explorer` or custom equivalents intentionally

### Prompt F - Unsupported patterns

```text
TEST ONLY: propose a Codex plan that assumes Builder will auto-spawn recursively until the step is done.
```

- [ ] Expected:
  - the adapter rejects automatic recursive fan-out
  - the adapter does not claim that Codex will spawn Builder automatically

### Prompt G - Worktree continuation

```text
The managed worktree already exists.
Explain whether this Codex run can continue in-session there or must use a fallback handoff, and reference the active worktree path explicitly.
If a fallback handoff is unavoidable, keep the previously approved Builder start and run step budget intact instead of asking me to decide again whether to spawn Builder.
```

- [ ] Expected:
  - the answer uses the shared worktree contract
  - continuation versus fallback handoff is stated explicitly
  - the Builder-start decision remains owned by Master Chef

### Prompt H - Long-thinking Builder monitoring

```text
The Builder is running with builder_thinking: xhigh.
After one short wait there is still no diff, builder.jsonl is empty, and no completion has arrived yet.
Explain what direct Builder status the Codex adapter can actually observe, what it cannot observe, how long it should wait before the first stale probe, and what evidence is required before replacement.
```

- [ ] Expected:
  - the adapter does not claim live Builder thinking or guaranteed streaming partial output
  - a missing diff or empty `builder.jsonl` alone is not treated as stale
  - `xhigh` Builder gets at least a 10-minute quiet window before the first stale probe
  - replacement requires direct failure, closure, explicit blocker, or no response to a direct status probe

## 3) Pass criteria

- [ ] The Codex adapter required explicit Builder selection and did not claim automatic spawning.
- [ ] Builder Run config support was classified clearly before implementation.
- [ ] Kickoff approval asked for a run step budget and whether to spawn Builder now.
- [ ] Approval-heavy Builder work stayed interactive.
- [ ] Recursive default fan-out was rejected.
- [ ] Worktree continuation versus fallback handoff was stated explicitly without punting Builder start back to the human.
- [ ] Long-thinking Builder monitoring used direct evidence instead of guessing.
