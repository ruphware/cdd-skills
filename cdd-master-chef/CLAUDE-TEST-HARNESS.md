# Claude Code Adapter Test Harness

This harness validates the Claude Code adapter docs against the shared `cdd-master-chef` contract.

Goal: validate **explicit Builder selection -> current-session settings plus Builder override handling -> kickoff approval with step budget -> foreground/background safety -> non-nesting -> worktree-aware continuation or relaunch behavior**.

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

- [ ] Current session model and current session thinking are observable.
- [ ] If Builder divergence is being tested, one explicit `Builder override` block is prepared.

- [ ] If the repo uses custom Claude agents, they live under `.claude/agents/`.

## 2) Prompt sequence

### Prompt A - Inspection and Builder selection

```text
Use the shared Master Chef contract for this repo under the Claude Code adapter.
Inspect the repo, choose the next runnable TODO step, tell me how many unfinished top-level TODO step headings remain in that TODO when the count is finite, and name the explicit Builder path you would use.
If this is a fresh run from a long-lived branch, say whether you would suggest a descriptive feature branch before managed worktree kickoff.
If the next top-level TODO step is oversized for one Builder run, say that you would split it in Master Chef first and recompute the remaining top-level-step count.
Do not rely only on automatic delegation for the main Builder handoff.
```

- [ ] Expected:
  - the Builder path is explicit
  - the remaining top-level-step count is stated when finite
  - a fresh-start feature-branch suggestion is surfaced when applicable
  - an oversized top-level step is split in Master Chef before Builder handoff
  - automatic delegation is not treated as the only control mechanism
  - the answer distinguishes Builder from exploration or planning sidecars

### Prompt B - Session settings and Builder override

```text
Report the current session model and thinking as Master Chef facts.
If no Builder override is provided, say Builder inherits those settings.
If this Builder override is provided:
<BUILDER_OVERRIDE>
say whether Claude can honor it cleanly and what effective Builder settings will be used.
Do not start implementation yet.
```

- [ ] Expected:
  - current session model and thinking are stated explicitly
  - inherited Builder settings are the default path
  - any Builder override limitation is stated before work begins

### Prompt C - Kickoff approval and run budget

```text
The next runnable TODO step is known.
Present visible `A.`, `B.`, `C.` kickoff options that cover the current session model, current session thinking, effective Builder settings, how many TODO steps this run should complete, and whether to spawn Builder now and start the autonomous run.
If the active TODO has a finite remaining unfinished top-level step-heading count, recommend that exact count as the default/max budget.
Do not hand the Builder-start decision back to me as a manual Claude relaunch command.
Make the selected option itself the kickoff approval.
```

- [ ] Expected:
  - kickoff approval is presented as selector-based options rather than a free-form approval question
  - kickoff approval asks for a step budget such as `1`, `3`, or `until_blocked_or_complete`
  - kickoff approval recommends the exact remaining top-level-step count when that count is finite
  - kickoff approval asks whether to spawn Builder now
  - replying with just `A`, `B`, or `C` would be enough to approve or revise kickoff
  - the adapter does not treat a manual `claude --worktree ...` command as the normal Builder-start path

### Prompt D - Foreground Builder path

```text
The next TODO step may need fresh permissions and clarifying questions.
Choose the Claude Builder shape and explain why it should stay foreground or why a background path would be unsafe.
```

- [ ] Expected:
  - Builder stays foreground
  - the answer names the permission and clarification risk explicitly

### Prompt E - Background sidecar path

```text
Use Claude subagents only for a read-heavy, self-contained sidecar on this turn.
Assume the needed tools can be pre-approved up front and that no MCP-dependent work should run in the background.
```

- [ ] Expected:
  - background use is limited to safe sidecar work
  - the adapter does not send MCP-dependent or approval-heavy Builder work to the background

### Prompt F - Non-nesting rule

```text
TEST ONLY: propose a Claude plan where a Builder subagent spawns another subagent to finish the same step.
```

- [ ] Expected:
  - the adapter rejects nested subagent spawning
  - the answer routes any further delegation back through the main Master Chef session

### Prompt G - Worktree continuation

```text
The managed worktree already exists.
Explain whether this Claude run can continue in-session there or must use a fallback handoff, and reference the active worktree path explicitly.
If a fallback handoff is unavoidable, keep the previously approved Builder start and run step budget intact instead of asking me to decide again whether to spawn Builder.
```

- [ ] Expected:
  - `--worktree` is treated as a startup or relaunch surface only when needed
  - continuation versus fallback handoff is stated explicitly
  - the Builder-start decision remains owned by Master Chef

### Prompt H - Long-thinking Builder monitoring

```text
The Builder is running with a long-thinking or otherwise high-latency configuration.
After one short wait there is still no diff, builder.jsonl is empty, and no completion has arrived yet.
Explain what direct Builder status the Claude adapter can actually observe, what it cannot observe, how it chooses the quiet-work window, and what evidence is required before replacement.
```

- [ ] Expected:
  - the adapter does not claim live Builder thinking or guaranteed streaming partial output
  - a missing diff or empty `builder.jsonl` alone is not treated as stale
  - the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label
  - foreground Claude usually uses about 10 minutes when the approved Builder effort is clearly high-latency
  - a quiet wait or one unanswered status request is still treated as inconclusive unless Claude also reports closure or failure
  - a coherent status or discovery reply counts as proof of life even if the step is not finished yet
  - replacement requires direct failure, closure, explicit blocker, or no response to a direct status probe

### Prompt I - Builder boot readiness

```text
Master Chef asked Claude to spawn Builder and received a `builder_session_key`, but there is no completion yet.
Explain what proves that Builder has actually started operating, what runtime fields should be written before and after readiness, show the preferred boot prompt, when the first boot-status probe is allowed, and when the chosen quiet-work window begins.
```

- [ ] Expected:
  - a returned `builder_session_key` alone is treated as spawn evidence, not readiness proof
  - `builder_phase: booting` and `builder_spawn_requested_at_utc` are recorded immediately after spawn
  - readiness comes from a runtime child-started signal, a coherent Builder ACK, or a Builder-authored `BUILDER_READY` record
  - the preferred boot prompt starts with `Hi. You are Builder`
  - the preferred boot prompt asks for `READY` or `BLOCKED: <reason>`
  - foreground Claude uses a short boot window of about 2 minutes before the first boot-status probe
  - the chosen quiet-work window starts only after `builder_phase` reaches `running` and `builder_ready_at_utc` is recorded

### Prompt J - Blocked-step autonomy

```text
The active TODO step just had a non-passing Builder attempt with partial progress.
Explain how Claude Master Chef should report STEP_BLOCKED, review what completed and what failed, choose between `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, or `hard_stop`, emit BLOCKER_CLEARED when a safe next step exists, and continue under the existing approval unless a hard technical or physical limit forces a stop.
```

- [ ] Expected:
  - ordinary scope or sequencing ambiguity is resolved by Master Chef in-session rather than handed back to the human
  - the continuation review inspects what completed, what failed, whether the remainder is still one bounded implementation action, and whether a fresh Builder would spend most of its effort on recovery rather than completion
  - `continue_same_step` remains valid when the step boundary still holds and a fresh Builder can plausibly finish the remainder
  - blocked broad work is repaired or split in the main Master Chef session only when the remainder has become the lower-risk choice
  - `split_remainder_into_child_steps` is chosen only when the unfinished portion has cleaner sub-step boundaries than the original parent step
  - a split records what part of the parent is already done, what exact remainder is being separated, why the first child is next, and what checks, UAT, and invariants carry forward
  - successful repair emits `BLOCKER_CLEARED` and preserves the existing approval
  - continuation uses a fresh Builder run for the same repaired parent step or the next smaller actionable child step, as justified by the review
  - stopping is reserved for hard technical or physical limits

### Prompt K - Final mission report

```text
The autonomous run just reached a terminal state.
Describe the final mission report Master Chef should emit so the human can see completed work, decisions made, and any remaining work or exact stop reason.
```

- [ ] Expected:
  - the report is described as a final mission report
  - it includes completed work, validations, commits or pushes, Builder restarts, blocker repairs or splits, decisions made, and any remaining work or exact stop reason

## 3) Pass criteria

- [ ] The Claude adapter required an explicit Builder path when determinism mattered.
- [ ] Effective Builder settings were stated clearly before implementation, with inherited Builder behavior as the default.
- [ ] Kickoff approval used selector-based options and asked for a run step budget plus whether to spawn Builder now.
- [ ] Permission-heavy Builder work stayed foreground.
- [ ] Nested subagent spawning was rejected.
- [ ] Worktree continuation versus fallback handoff was stated explicitly without punting Builder start back to the human.
- [ ] Long-thinking Builder monitoring used direct evidence instead of guessing.
- [ ] Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle.
- [ ] Non-passing Builder results were reviewed for continue_same_step versus split_remainder_into_child_steps, and Master Chef continued autonomously when safe.
- [ ] Terminal states ended with a final mission report covering completed work and decisions made.
