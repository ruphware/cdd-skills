# [CDD-6] Master Chef Test Harness Checklist (OpenClaw adapter)

This harness validates the current OpenClaw adapter against the shared Master Chef contract.

Goal: validate the flow **kickoff -> Master-Chef skill routing -> repo-local runtime state -> Builder subagent -> direct in-session Builder checks -> in-session lifecycle reporting -> final mission report**.

## 1) Preflight

- [ ] Installed skill pack exists:
  ```bash
  ls ~/.openclaw/skills/cdd-master-chef/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-boot/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-maintain/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-init-project/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-plan/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-implement-todo/SKILL.md >/dev/null
  ls ~/.openclaw/skills/cdd-implementation-audit/SKILL.md >/dev/null
  ```

- [ ] Repo is CDD-ready:
  ```bash
  ls <REPO>/AGENTS.md <REPO>/README.md >/dev/null
  ls <REPO>/TODO*.md >/dev/null
  ```

- [ ] Repo has an upstream:
  ```bash
  git -C <REPO> rev-parse --abbrev-ref --symbolic-full-name @{upstream}
  ```

- [ ] Current session model and current session thinking are either observable or expected to be reported as `unknown` without blocking kickoff.

- [ ] Main session is already using the model that should be mirrored into `master_model`.

- [ ] If Builder divergence is being tested, an explicit `Builder override` block is prepared.

- [ ] Any `Builder override` stays model-only:

  ```text
  Builder override:
    builder_model: gpt-5.4
    builder_thinking: xhigh
  ```

- [ ] The run step budget is prepared as either a positive integer step count or `until_blocked_or_complete`.

---

## 2) Prompt sequence

### Prompt A0 - Session-settings path

```text
/cdd-master-chef Use the Master Chef process for repo <REPO>.
No Builder override is provided for this test.
Read the current session model and thinking directly, report them back as Master Chef facts, default Builder to inherit them, and do not create runtime state yet.
```

- [ ] Expected:
  - current session model and thinking are shown back to the human
  - if OpenClaw does not expose one or both fields exactly, only those fields are reported as `unknown` and Master Chef says kickoff would proceed with the active session as-is
  - Builder is reported as inheriting those same settings
  - no runtime state is created yet
  - no Builder is spawned yet
  - there is no separate Run-config approval or edit loop before kickoff

### Prompt A - Inspection only

```text
/cdd-master-chef Use the Master Chef process for repo <REPO>.
Builder override:
<BUILDER_OVERRIDE>
Inspect the repo, tell me which TODO step is next, and prepare selector-driven kickoff options before creating runtime state or spawning the Builder.
```

- [ ] Expected:
  - repo readiness check
  - branch/upstream check
  - TODO inspection
  - proposed next runnable step
  - remaining unfinished top-level TODO step-heading count is stated when finite
  - a fresh-start feature-branch suggestion is surfaced when the source checkout is still on a long-lived branch
  - an oversized-looking top-level step is reviewed in Master Chef before Builder handoff, and any split is justified as cheaper than preserving the parent step
  - explicit routing choice: usually Builder via `cdd-implement-todo`, otherwise Master Chef direct for setup/planning/audit/maintain work
  - explicit selector-driven kickoff approval request

### Prompt A1 - Oversized-step review before delegation

```text
/cdd-master-chef TEST ONLY: assume the next top-level TODO step is oversized for one Builder run.
Review whether that step truly needs a pre-delegation split. Keep it intact when it is still one coherent Builder action, repair it in place when a minimal TODO fix restores that shape, and split it into smaller decision-complete TODO steps only when the added Builder, test, and QA cost is clearly justified. Recompute the remaining unfinished top-level TODO step-heading count only if a split is chosen, and then present selector-driven kickoff options on the selected next runnable step.
```

- [ ] Expected:
  - Master Chef does not split automatically just because the step looks oversized
  - the pre-delegation review happens in the main session before any Builder spawn
  - any split is justified as cheaper than preserving the parent step
  - the remaining top-level-step count is recomputed only when a split occurs
  - kickoff approval targets either the intact parent step or the first new runnable child step, as justified by the review

### Prompt B - Selector-driven kickoff approval

```text
/cdd-master-chef Present kickoff options with visible `A.`, `B.`, `C.` selectors. The selected option itself should count as the approval.
Builder override:
<BUILDER_OVERRIDE>
Require a clean source checkout, create the managed worktree and fresh branch, initialize runtime state there, acquire the run lease, and stop with exact relaunch instructions if the adapter cannot safely continue in-session.
```

- [ ] Expected:
  - the source checkout is refused if dirty
  - any approved fresh-start feature branch is created before managed worktree creation
  - a managed worktree is created on a fresh branch from the current `HEAD`
  - the managed worktree contains `.cdd-runtime/master-chef/`
  - `run.json`, `run.lock.json`, `master-chef.jsonl`, and `builder.jsonl` exist in the managed worktree
  - `run.json` records the effective session-derived `master_*` settings, the effective `builder_*` settings, the approved run step budget, and source/worktree metadata, using `unknown` for only the unresolved session-setting fields
  - `run.json` also records whether the default feature-branch recommendation was accepted or declined and the current worktree environment status
  - kickoff approval is presented with selector-based options rather than a free-form approval question
  - kickoff approval recommends the exact remaining top-level-step count when that count is finite
  - replying with just `A`, `B`, or `C` would be enough to approve or revise kickoff
  - no watchdog cron is created
  - the OpenClaw adapter stops with exact relaunch instructions before delegated implementation starts
  - the relaunch plan says the active worktree environment must be bootstrapped there before Builder or `hard_gate` validation rely on it
  - the routing choice is named explicitly in the handoff or main-session action

### Prompt C - Verify runtime files

```bash
ls <WORKTREE>/.cdd-runtime/master-chef/run.json \
   <WORKTREE>/.cdd-runtime/master-chef/run.lock.json \
   <WORKTREE>/.cdd-runtime/master-chef/master-chef.jsonl \
   <WORKTREE>/.cdd-runtime/master-chef/builder.jsonl \
   <WORKTREE>/.cdd-runtime/master-chef/context-summary.md >/dev/null
```

- [ ] Expected: all runtime files exist.

### Prompt C1 - Dirty checkout refusal

```text
/cdd-master-chef TEST ONLY: simulate kickoff from a dirty source checkout.
Do not create the managed worktree. Stop and tell me to stash, commit, or discard changes first.
```

- [ ] Expected:
  - no managed worktree is created
  - no implementation begins
  - the refusal names the clean-checkout-first rule clearly

### Prompt D - Verify no cron exists

```bash
openclaw cron list | rg cdd-master-chef-watchdog
```

- [ ] Expected: no watchdog cron exists.

### Prompt E - Healthy Builder check

```text
/cdd-master-chef TEST ONLY: simulate one direct Builder health check in the main session.
Check runtime files and Builder health. If healthy, do not replace Builder and do not send unnecessary extra chatter.
A healthy Builder check may stay quiet, but lifecycle events should still be reported clearly in-session when they actually happen.
```

- [ ] Expected:
  - no false restart
  - no false blocker
  - Builder-check reasoning happens in the main session
  - healthy tick silence does not redefine or bypass in-session lifecycle reporting expectations

### Prompt F - Stale Builder

```text
/cdd-master-chef TEST ONLY: simulate that Builder progress has gone stale.
Replace it quickly with a fresh Builder subagent for the same step rather than resurrecting the old session.
Keep the same TODO step, update runtime state, and report BUILDER_RESTARTED.
```

- [ ] Expected:
  - Builder recovery happens in the main session
  - stale recovery prefers fresh replacement over session resurrection
  - runtime state is updated
  - no duplicate control loop is created

### Prompt G - Duplicate-run prevention

```text
/cdd-master-chef TEST ONLY: simulate a second kickoff attempt while an active coherent lease exists.
Refuse to start a duplicate run and report the active lease owner.
```

- [ ] Expected:
  - no duplicate run starts
  - lease conflict is reported clearly

### Prompt H - Routing model

```text
/cdd-master-chef TEST ONLY: explain the routing choice for the current repo state.
Use Builder via [CDD-3] Implement TODO (`cdd-implement-todo`) for a normal runnable TODO step.
Explain why [CDD-0] Boot (`cdd-boot`) is a manual helper rather than part of the normal flow.
Explain why [CDD-5] Maintain (`cdd-maintain`) is used directly when the repo specifically needs doc drift review, codebase cleanup, docs/INDEX.md refresh, or refactor architecture audit.
Use [CDD-1] Init Project (`cdd-init-project`), [CDD-2] Plan (`cdd-plan`), [CDD-4] Implementation Audit (`cdd-implementation-audit`), or [CDD-5] Maintain (`cdd-maintain`) directly in Master Chef when setup, planning, implementation audit, or maintenance work is needed.
Explain how approved findings from [CDD-4] Implementation Audit or external review should go through [CDD-2] Plan (`cdd-plan`) before delegated implementation.
```

- [ ] Expected:
  - `[CDD-0] Boot` is called out as a manual / non-routed helper
  - `[CDD-5] Maintain` is called out as a direct maintenance helper
  - `[CDD-3] Implement TODO` is the default Builder path
  - `[CDD-1] Init Project`, `[CDD-2] Plan`, `[CDD-4] Implementation Audit`, and `[CDD-5] Maintain` are treated as Master-Chef-direct skills
  - audit findings are routed through `[CDD-2] Plan` before delegated implementation

### Prompt I - Continue the run

```text
/cdd-master-chef Continue the autonomous run.
If another runnable TODO step exists after the current one, keep going automatically.
If the run is complete, send the final mission report covering completed work and decisions made.
```

- [ ] Expected:
  - this prompt is run from the managed worktree after the relaunch step
  - Master Chef reviews Builder output
  - the delegated path matches the routing choice rather than defaulting blindly
  - if another runnable delegated step exists, Master Chef reuses the same Builder first when it remains usable
  - if the active OpenClaw surface does not expose a supported manual Builder compaction operation, the next-step handoff relies on native context management rather than inventing one
  - the adapter should not claim a documented parent-visible Builder fullness meter, exact token-left budget, or universal numeric threshold
  - if replacement is needed instead, it is justified by explicit recovery conditions rather than treated as the normal step-transition path
  - passed steps include TODO writeback, QA, UAT, commit, push, and `STEP_PASS`
  - run completion emits a final mission report covering completed work, completed TODO step ids plus whether their task checklists are fully checked, and decisions made
  - for `RUN_COMPLETE` and budget-stop `RUN_STOPPED`, the report includes a compact post-run recommendation bundle: run `cdd-implementation-audit` on the completed run scope, push only when the branch is ahead of origin or still unpublished, open a PR only once the branch is published and PR creation is still pending, clean up the managed worktree only when it still exists and no immediate continuation is planned there, and return to the source checkout or parent folder
  - lifecycle events such as `START` / `STEP_PASS` / `STEP_BLOCKED` / `RUN_COMPLETE` are reported clearly in the current session

### Prompt J - QA reject remediation

```text
/cdd-master-chef TEST ONLY: simulate that Builder returned a result that fails Master Chef QA.
Keep the same TODO step active, record concrete QA findings, choose either the same Builder when it remains usable, a fresh Builder run for the same step when recovery requires replacement, or a direct Master Chef fix, re-run QA/UAT, and only then commit, push, advertise STEP_PASS, and continue automatically.
```

- [ ] Expected:
  - no `STEP_PASS`, commit, or push happens before remediation and re-run QA
  - QA findings are recorded in `master-chef.jsonl`
  - remediation uses the same Builder first when it remains usable, otherwise a fresh single-step Builder run for the same step, or a direct Master Chef fix
  - after QA passes, `STEP_PASS` is advertised in the current Master Chef session before TODO re-inspection and automatic continuation

### Prompt K - Deadlock

```text
/cdd-master-chef TEST ONLY: simulate two failed Builder replacements without forward progress.
Stop the run and report DEADLOCK_STOPPED.
```

- [ ] Expected:
  - run stops cleanly
  - deadlock is reported clearly

### Prompt L - Blocked-step decomposition

```text
/cdd-master-chef TEST ONLY: simulate a non-passing Builder attempt with partial progress on the active TODO step.
Report STEP_BLOCKED in the current session, inspect runtime logs and the working tree, review what completed and what failed, choose between `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, or `hard_stop`, clean only stale retry artifacts when they materially increase retry risk, and continue under the existing approval unless a hard technical or physical limit still blocks safe autonomous continuation.
```

- [ ] Expected:
  - no fresh Builder is spawned blindly before the continuation review is complete
  - `STEP_BLOCKED` is reported in the current Master Chef session with concrete evidence
  - the continuation review inspects what completed, what failed, whether the remainder is still one bounded implementation action, whether the active Builder is still usable after status or compaction checks, and whether a recovery replacement Builder would spend most of its effort on recovery rather than completion
  - `continue_same_step` remains valid when the step boundary still holds and the active Builder can plausibly finish the remainder, or one recovery replacement Builder can do so if the active one is no longer usable
  - TODO planning is repaired into smaller decision-complete steps only when the unfinished portion has become the lower-risk child-step sequence
  - split is justified only when its added Builder, test, and QA cost is lower than preserving the parent step
  - cleanup is scoped to stale runtime/build artifacts and does not revert unrelated user work
  - ordinary scope or decision ambiguity is resolved by Master Chef in-session rather than handed back to the human as the default path
  - `split_remainder_into_child_steps` records what part of the parent is already done, what exact remainder is being separated, why the first child is next, and what checks, UAT, and invariants carry forward
  - successful repair emits `BLOCKER_CLEARED` with the original blocked step, replacement step ids when applicable, preserved remaining budget, and next delegated action
  - successful repair does not trigger a new kickoff or increment `steps_completed_this_run`
  - continuation reuses the same Builder first for the same repaired parent step or the first runnable child step, replacing only when defined recovery conditions require it
  - Master Chef does not stop cleanly at the first decomposed step when continuation is still authorized
  - the run stops only when a hard technical or physical limit still blocks safe autonomous continuation after repair

### Prompt M - In-session reporting contract

```text
/cdd-master-chef TEST ONLY: simulate one successful STEP_PASS update and one STEP_BLOCKED update.
Report them in the current session and update runtime evidence exactly as the reporting contract requires.
```

- [ ] Expected:
  - both lifecycle updates are reported in the current Master Chef session
  - `master-chef.jsonl` records the lifecycle events
  - `run.json` stays focused on run state and does not grow route metadata

### Prompt N - Context compaction and resume

```text
/cdd-master-chef TEST ONLY: simulate Master Chef context pressure after a STEP_PASS boundary.
Write run.json, run.lock.json, JSONL evidence, and context-summary.md first; compact only after that safe boundary; then resume by reading runtime files, active TODO, and git status before choosing the next action.
```

- [ ] Expected:
  - `context-summary.md` records run, state, recent decisions, current diff, pending proof, and next action
  - no compaction happens while QA, commit, push, blocker strategy, or next-action details exist only in transcript
  - Builder continuation stays persistent across delegated steps, while Master Chef compaction remains a separate control-loop behavior
  - if the active OpenClaw surface lacks a supported manual Builder compaction operation, step-boundary continuation falls back to native context management rather than a fake compaction command
  - resumed Master Chef state is verified against `TODO*.md`, runtime files, logs, and `git status`

---

## 3) Pass criteria

- [ ] Main session acted as the only control plane.
- [ ] Builder ran as an OpenClaw subagent.
- [ ] No watchdog cron or second supervising loop was used.
- [ ] Runtime files were created in the managed worktree.
- [ ] Dirty source checkouts were refused before managed worktree creation.
- [ ] The run started from a fresh branch in a managed worktree rather than the source checkout branch.
- [ ] The OpenClaw adapter stopped with exact relaunch instructions before delegated implementation began.
- [ ] The active worktree environment was bootstrapped and evidenced there before Builder or `hard_gate` validation relied on it.
- [ ] `context-summary.md` was created and used as the Master Chef compaction checkpoint.
- [ ] Duplicate-run prevention worked.
- [ ] Builder recovery stayed inside the main session.
- [ ] Master Chef chose the correct routing path for the repo state.
- [ ] `cdd-implement-todo` remained the default delegated path for normal step execution.
- [ ] Normal next-step continuation reused the same Builder first, used native-context fallback when manual Builder compaction was unsupported, and replaced Builder only under defined recovery conditions.
- [ ] Builder session resurrection was not used as the normal continuation or recovery path.
- [ ] Passed Builder steps updated only the selected TODO step on success.
- [ ] Passed steps included QA, UAT, commit, push, and reporting.
- [ ] QA-rejected Builder output was remediated and rechecked before `STEP_PASS`, commit, push, and automatic continuation.
- [ ] Non-passing Builder results were reviewed for continue_same_step versus split_remainder_into_child_steps, and lower-risk child steps were created only when the remainder truly needed them and the added Builder/test/QA cost was justified.
- [ ] Lifecycle events were reported in the Master Chef session.
- [ ] Session-derived Master Chef settings, effective Builder settings, and runtime state stayed free of extra route metadata.
- [ ] Master Chef compaction happened only after a durable checkpoint and resume used runtime files, active TODO, and git state.
- [ ] Repeated failed Builder replacements stopped the run instead of limping onward.
- [ ] Run ended with `RUN_COMPLETE`, `RUN_STOPPED`, a hard-stop `STEP_BLOCKED`, or `DEADLOCK_STOPPED`, and emitted a final mission report with completed TODO step ids, fully checked task checklists, and state-based closeout recommendations.

---

## 4) Cleanup

If the runtime directory should be removed from the test repo:

```bash
rm -rf <REPO>/.cdd-runtime/master-chef
```
