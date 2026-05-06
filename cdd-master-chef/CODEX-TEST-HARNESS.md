# Codex Adapter Test Harness

This harness validates the Codex adapter docs against the shared `cdd-master-chef` contract.

Goal: validate **explicit Builder delegation -> current-session settings plus Builder override handling -> kickoff approval with step budget -> safe approval behavior -> worktree-aware continuation or relaunch**.

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

- [ ] Current session model and current session thinking are observable when Codex exposes them, or will be reported as `unknown` without blocking kickoff.
- [ ] If Builder divergence is being tested, one explicit `Builder override` block is prepared.

- [ ] If the repo uses custom Codex agents, they live under `.codex/agents/`.

## 2) Prompt sequence

### Prompt A - Inspection and explicit Builder selection

```text
Use the shared Master Chef contract for this repo under the Codex adapter.
Inspect the repo, choose the next runnable TODO step, tell me how many unfinished top-level TODO step headings remain in that TODO when the count is finite, and tell me which explicit Builder path you would use.
If this is a fresh run from a long-lived branch, say whether you would suggest a descriptive feature branch before managed worktree kickoff.
If the next top-level TODO step looks oversized for one Builder run, say that you would review it in Master Chef first, keep it intact unless the split cost is clearly justified, and recompute the remaining top-level-step count only if a split is actually chosen.
If the Builder path is standard implementation work, name the built-in worker agent or the exact custom `.codex/agents/*.toml` agent instead of assuming automatic delegation.
```

- [ ] Expected:
  - the routing choice is explicit
  - the remaining top-level-step count is stated when finite
  - a fresh-start feature-branch suggestion is surfaced when applicable
  - an oversized-looking top-level step is reviewed in Master Chef before Builder handoff, and any split is justified as cheaper than preserving the parent step
  - automatic Builder spawning is not claimed
  - read-heavy sidecars are separated from the main Builder role

### Prompt B - Session settings and Builder override

```text
Report the current session model and thinking as Master Chef facts.
If no Builder override is provided, say Builder inherits those settings.
If this Builder override is provided:
<BUILDER_OVERRIDE>
say whether Codex can honor it cleanly and what effective Builder settings will be used.
Do not start implementation yet.
```

- [ ] Expected:
  - current session model and thinking are stated explicitly
  - if Codex does not expose one or both fields exactly, only those fields are stated as `unknown` and kickoff still proceeds with the active session as-is
  - inherited Builder settings are the default path
  - any Builder override limitation is stated before work begins

### Prompt C - Kickoff approval and run budget

```text
The next runnable TODO step is known.
Present visible `A.`, `B.`, `C.` kickoff options that cover the current session model, current session thinking, effective Builder settings, how many TODO steps this run should complete, and whether to spawn Builder now and start the autonomous run.
If the active TODO has a finite remaining unfinished top-level step-heading count, recommend that exact count as the default/max budget.
Do not hand the Builder-start decision back to me as a manual Codex command.
Make the selected option itself the kickoff approval.
```

- [ ] Expected:
  - kickoff approval is presented as selector-based options rather than a free-form approval question
  - kickoff approval asks for a step budget such as `1`, `3`, or `until_blocked_or_complete`
  - kickoff approval recommends the exact remaining top-level-step count when that count is finite
  - kickoff approval asks whether to spawn Builder now
  - replying with just `A`, `B`, or `C` would be enough to approve or revise kickoff
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
  - the answer says the active worktree must be bootstrapped locally before Builder or `hard_gate` validation rely on it
  - the answer records or references `source_branch_decision`, `worktree_env_status`, and bootstrap evidence for the active worktree
  - the Builder-start decision remains owned by Master Chef

### Prompt H - Long-thinking Builder monitoring

```text
The Builder is running with a long-thinking or otherwise high-latency configuration.
After one short wait there is still no diff, builder.jsonl is empty, and no completion has arrived yet.
Explain what direct Builder status the Codex adapter can actually observe, what it cannot observe, how it chooses the quiet-work window, and what evidence is required before replacement.
```

- [ ] Expected:
  - the adapter does not claim live Builder thinking or guaranteed streaming partial output
  - a missing diff or empty `builder.jsonl` alone is not treated as stale
  - the adapter chooses a longer quiet-work window for a clearly high-latency Builder instead of hard-coding one reasoning label
  - foreground Codex usually uses about 10 minutes when the approved Builder effort is clearly high-latency
  - a `wait` timeout or one unanswered status request is still treated as inconclusive unless Codex also reports closure or failure
  - a coherent status or discovery reply counts as proof of life even if the step is not finished yet
  - replacement requires direct failure, closure, explicit blocker, or no response to a direct status probe

### Prompt I - Builder boot readiness

```text
Master Chef asked Codex to spawn Builder and received a `builder_session_key`, but there is no completion yet.
Explain what proves that Builder has actually started operating, what runtime fields should be written before and after readiness, show the preferred boot prompt, when the first boot-status probe is allowed, and when the chosen quiet-work window begins.
```

- [ ] Expected:
  - a returned `builder_session_key` alone is treated as spawn evidence, not readiness proof
  - `builder_phase: booting` and `builder_spawn_requested_at_utc` are recorded immediately after spawn
  - readiness comes from a runtime child-started signal, a coherent Builder ACK, or a Builder-authored `BUILDER_READY` record
  - the preferred boot prompt starts with `Hi. You are Builder`
  - the preferred boot prompt asks for `READY` or `BLOCKED: <reason>`
  - foreground Codex uses a short boot window of about 2 minutes before the first boot-status probe
  - the chosen quiet-work window starts only after `builder_phase` reaches `running` and `builder_ready_at_utc` is recorded

### Prompt I1 - Normal next-step continuation

```text
The current delegated step just passed and another runnable delegated step exists in the same run.
Explain how Codex Master Chef should continue with the active Builder, what step-start compaction attempt happens first when supported, what fallback applies when the active Codex surface has no supported manual compaction command, and when Builder replacement is allowed instead.
```

- [ ] Expected:
  - normal next-step continuation reuses the same Builder first when it remains usable
  - any step-start compaction attempt happens before the next delegated handoff only when the active Codex surface actually exposes a supported compaction command or API
  - if no supported manual compaction path is exposed, the adapter keeps the same Builder and relies on native context management or runtime auto-compaction instead of inventing one
  - the adapter should not claim a clean official parent-visible context meter, exact token-left budget, or universal numeric threshold
  - replacement is reserved for explicit failure, runtime closure, deadlock, unusable drift, or inability to continue safely after status or worktree-safety checks

### Prompt J - Blocked-step autonomy

```text
The active TODO step just had a non-passing Builder attempt with partial progress.
Explain how Codex Master Chef should report STEP_BLOCKED, review what completed and what failed, choose between `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, or `hard_stop`, emit BLOCKER_CLEARED when a safe next step exists, and continue under the existing approval unless a hard technical or physical limit forces a stop.
```

- [ ] Expected:
  - ordinary scope or sequencing ambiguity is resolved by Master Chef in-session rather than handed back to the human
  - the continuation review inspects what completed, what failed, whether the remainder is still one bounded implementation action, whether the active Builder is still usable after status or compaction checks, and whether a recovery replacement Builder would spend most of its effort on recovery rather than completion
  - `continue_same_step` remains valid when the step boundary still holds and the active Builder can plausibly finish the remainder, or one recovery replacement Builder can do so if the active one is no longer usable
  - blocked broad work is repaired or split in the main Master Chef session only when the remainder has become the lower-risk choice
  - `split_remainder_into_child_steps` is chosen only when the unfinished portion has cleaner sub-step boundaries than the original parent step
  - a split records what part of the parent is already done, what exact remainder is being separated, why the first child is next, and what checks, UAT, and invariants carry forward
  - successful repair emits `BLOCKER_CLEARED` and preserves the existing approval
  - continuation reuses the same Builder first for the same repaired parent step or the next smaller actionable child step, replacing only when defined recovery conditions require it
  - stopping is reserved for hard technical or physical limits

### Prompt K - Final mission report

```text
The autonomous run just reached a terminal state.
Describe the final mission report Master Chef should emit so the human can see completed work, decisions made, and any remaining work or exact stop reason.
```

- [ ] Expected:
  - the report is described as a final mission report
  - it includes completed work, completed TODO step ids, checklist completion status for those steps, validations, commits or pushes, Builder restarts, blocker repairs or splits, decisions made, and any remaining work or exact stop reason
  - for `RUN_COMPLETE` and budget-stop `RUN_STOPPED`, it includes a compact post-run recommendation bundle: run `cdd-implementation-audit` on the completed run scope, push only when the branch is ahead of origin or still unpublished, open a PR only once the branch is published and PR creation is still pending, clean up the managed worktree only when it still exists and no immediate continuation is planned there, and return to the source checkout or parent folder

## 3) Pass criteria

- [ ] The Codex adapter required explicit Builder selection and did not claim automatic spawning.
- [ ] Effective Builder settings were stated clearly before implementation, with inherited Builder behavior as the default.
- [ ] Kickoff approval used selector-based options and asked for a run step budget plus whether to spawn Builder now.
- [ ] Approval-heavy Builder work stayed interactive.
- [ ] Recursive default fan-out was rejected.
- [ ] Worktree continuation versus fallback handoff was stated explicitly without punting Builder start back to the human.
- [ ] The active worktree was treated as branch-backed but not usable for Builder or `hard_gate` validation until repo-native bootstrap evidence marked it `env_ready`.
- [ ] Long-thinking Builder monitoring used direct evidence instead of guessing.
- [ ] Builder boot readiness required a real ACK or runtime-ready signal rather than only a spawn handle.
- [ ] Normal next-step continuation reused the same Builder first, attempted step-start compaction only when supported, and used native-context or auto-compaction fallback when manual compaction was unavailable.
- [ ] Non-passing Builder results were reviewed for continue_same_step versus split_remainder_into_child_steps, and Master Chef continued autonomously when safe while paying split cost only when justified.
- [ ] Terminal states ended with a final mission report covering completed work, completed TODO step ids plus checklist state, decisions made, and state-based closeout recommendations.
