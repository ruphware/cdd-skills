# [CDD-6] Master Chef

This folder contains the current OpenClaw adapter docs inside the canonical `cdd-master-chef/` package.

Shared contract surfaces now live in the parent package root:

- `../README.md`
- `../CONTRACT.md`
- `../RUNTIME-CAPABILITIES.md`

This `openclaw/` folder documents how the OpenClaw runtime satisfies that shared contract.

It is one current concrete adapter in this package. Codex and Claude Code adapter docs live in the package root as current subagent-backed alternatives.

Installed form:

- `~/.openclaw/skills/cdd-master-chef`
- `/cdd-master-chef`

`./scripts/install.sh --runtime openclaw` installs this adapter plus OpenClaw-ready internal Builder variants of the full `cdd-*` skill pack into `~/.openclaw/skills`. Those Builder skills are generated from the canonical repo source in `skills/` and are meant for Master Chef and the Builder subagent, not for direct user invocation.

The internal Builder routing map stays aligned with the core skill pack:

- `[CDD-0] Boot` -> `cdd-boot`
- `[CDD-1] Init Project` -> `cdd-init-project`
- `[CDD-2] Plan` -> `cdd-plan`
- `[CDD-3] Implement TODO` -> `cdd-implement-todo`
- `[CDD-4] Implementation Audit` -> `cdd-implementation-audit`
- `[CDD-5] Maintain` -> `cdd-maintain`

## What it does

The packaged OpenClaw adapter has two active actors:

- **Master Chef:** the current OpenClaw session that inspects repo state, chooses the next action, reviews Builder output, approves step-level UAT, commits, pushes, reports status, and checks Builder health directly when needed
- **Builder:** a fresh single-step OpenClaw subagent run that executes one approved action at a time using the shared internal `cdd-*` skill pack, normally `cdd-implement-todo`

There is no watchdog cron. The human verifies the current session settings, chooses any optional `Builder override`, approves how many TODO steps the current run should cover, approves whether Builder should start now, approves kickoff once, and then mainly checks the final mission report or a hard stop.

## Managed worktree policy

- The source checkout must be clean before kickoff. If it is dirty, Master Chef stops and asks the human to stash, commit, or discard changes first.
- The OpenClaw adapter provisions a fresh per-run branch in a managed worktree rooted under `.cdd-runtime/worktrees/<run-id>/`.
- The current OpenClaw adapter then stops with exact relaunch instructions rather than assuming safe live cwd switching inside the already-running session.
- After relaunch, treat the managed worktree as the active repo root for TODO inspection, QA, commit, and push.

## Relationship to the shared contract

- The shared, runtime-agnostic Master Chef contract is defined in the parent `cdd-master-chef/` package root.
- `openclaw/` is the OpenClaw adapter subtree under that shared contract.
- `skills/` remains the canonical Builder workflow source for the internal `cdd-*` skills used by Master Chef and Builder.

## Prerequisites

- OpenClaw installed and healthy
- `git` on `PATH`
- target workspace is either:
  - an existing repo that already has the CDD boilerplate (`AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`), or
  - a new/adoptable project folder that should be initialized into CDD first
- a pushable upstream branch is required before the normal autonomous commit/push loop begins

You do not need a separate Codex or ACP skill install for this OpenClaw package. `./scripts/install.sh --runtime openclaw` installs both `cdd-master-chef` and the internal OpenClaw Builder `cdd-*` skills into `~/.openclaw/skills`.

## Install

From the repo root:

```bash
./scripts/install.sh --runtime openclaw
```

Explicit target example:

```bash
./scripts/install.sh --runtime openclaw --target ~/.openclaw/skills
```

Link install for local iteration:

```bash
./scripts/install.sh --runtime openclaw --link --update
```

Notes:

- Canonical source skills are symlinked only when the runtime package can use them directly.
- The canonical `cdd-master-chef` package is symlinked or copied from source depending on install mode, and the generated internal Builder skills are still materialized as normal directories in the target root.

Update:

```bash
./scripts/install.sh --runtime openclaw --update
```

Uninstall:

```bash
./scripts/install.sh --runtime openclaw --uninstall
```

## What gets installed

`./scripts/install.sh --runtime openclaw` installs:

- `[CDD-6] Master Chef` -> `cdd-master-chef`
- `[CDD-0] Boot` -> `cdd-boot`
- `[CDD-5] Maintain` -> `cdd-maintain`
- `[CDD-1] Init Project` -> `cdd-init-project`
- `[CDD-2] Plan` -> `cdd-plan`
- `[CDD-3] Implement TODO` -> `cdd-implement-todo`
- `[CDD-4] Implementation Audit` -> `cdd-implementation-audit`

The internal Builder variants are model-visible to OpenClaw agent runs and hidden from the user slash-command surface.

## How development starts

1. Open the OpenClaw session you want to use. That session is both Master Chef and the reporting surface for the run.
2. Make sure the current session already has the model and thinking you want Master Chef to mirror into runtime state.
3. If Builder should diverge from that active session, prepare an optional `Builder override` block:

   ```text
   Builder override:
     builder_model: gpt-5.4
     builder_thinking: xhigh
   ```

4. Set the current session model before you start the run:

   ```text
   /model <master-model>
   ```

5. Start `[CDD-6] Master Chef` in the target repo or new project folder:

   ```text
   /cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
   Inspect where development is at, propose the next runnable TODO step, or split an oversized one first, and present selector-driven kickoff options before creating runtime state or spawning the Builder.
   ```

   Master Chef should read the current session model and thinking directly, report them back as Master Chef facts, default Builder to inherit them, and apply a `Builder override` only when one is supplied and the adapter can honor it cleanly. If the runtime cannot observe those values concretely enough, it should stop before kickoff.

6. Master Chef should then:
   - verify whether the repo is already CDD-ready or first needs `cdd-init-project`
   - inspect git status, branch, upstream, active TODO state, and the next runnable step
   - if the next runnable top-level TODO step is oversized for one Builder run, split it first
   - inspect the remaining unfinished top-level TODO step-heading count in the active TODO file when that count is finite
   - if this is a fresh run from a long-lived branch, suggest a descriptive feature branch before managed worktree kickoff
   - choose the routing path: usually Builder via `[CDD-3] Implement TODO`, otherwise Master-Chef-direct setup, planning, audit, or maintain work
   - route approved findings from `[CDD-4] Implementation Audit` or external review through `[CDD-2] Plan` before any delegated implementation
   - when that top-level step count is finite, recommend that exact count as the default/max step budget, meaning all remaining steps, after any step split
   - ask how many TODO steps this run should cover: a positive integer count or `until_blocked_or_complete`
   - ask whether to spawn Builder now and start the autonomous run
   - initialize `.cdd-runtime/master-chef/` for durable run state and logs
   - present one selector-driven kickoff approval covering:
      - the proposed next action and routing path
      - current session model and thinking
      - effective Builder settings
      - the shared kickoff recommendation for fresh-start feature-branch creation and default/max step budget
      - the approved run step budget
      - whether to spawn Builder now
      - Builder handoff plus in-session reporting expectations
   - follow the shared selector contract
   - prefer `A. approve kickoff and start the autonomous run now`, `B. approve kickoff but do not spawn Builder yet`, and `C. revise the next action, Builder settings, or step budget before kickoff`
   - replying with just `A`, `B`, or `C` is enough

After that approval, Master Chef drives the Builder automatically until the run completes, hits a hard technical or physical stop, or deadlocks.

After each passed, blocked, or stale delegated step, that Builder run is finished. If another delegated step exists, Master Chef re-inspects repo state and starts a fresh Builder run, normally via `cdd-implement-todo`.

Every non-passing Builder attempt becomes a continuation-review boundary. Master Chef reviews completed work, failed proof, whether the remainder is still one bounded implementation action, whether a fresh Builder would spend most of its effort on recovery rather than completion, and whether the unfinished remainder now has cleaner sub-step boundaries than the original parent step.

## Reporting and Builder checks

Reporting is OpenClaw-native and session-native:

- the current Master Chef session is the only control/reporting route described by the shared package
- lifecycle reporting such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `BLOCKER_CLEARED`, and `RUN_COMPLETE` stays in that session
- terminal states end with a final mission report covering completed work and decisions made
- `.cdd-runtime/master-chef/run.json` stores run state, not extra route metadata
- if a local operator wants external notifications, keep that as local-only behavior rather than shared skill config

Builder-check policy:

- no watchdog cron or timer-based heartbeat loop
- Master Chef checks runtime files, Builder health, and current progress directly in the main session
- if the Builder is stale during an active check, Master Chef replaces it quickly with a fresh single-step subagent run
- do not use Builder session resurrection as the normal continuation or recovery path
- if 2 replacement attempts fail without forward progress, stop the run instead of limping on
- lifecycle reporting still happens in-session even without a watchdog

Runtime files:

- `.cdd-runtime/master-chef/run.json`
- `.cdd-runtime/master-chef/run.lock.json`
- `.cdd-runtime/master-chef/master-chef.jsonl`
- `.cdd-runtime/master-chef/builder.jsonl`
- `.cdd-runtime/master-chef/context-summary.md`

Keep these runtime files out of git, preferably via `.git/info/exclude`.

Context-limit policy:

- Builder stays fresh through single-step runs, normally booted with `cdd-implement-todo`.
- Master Chef checkpoints long-run memory in `.cdd-runtime/master-chef/context-summary.md` before deliberate compaction.
- Master Chef compacts only at safe workflow boundaries and resumes from runtime files, active TODO, and git state rather than transcript memory.

## Builder skill usage

Master Chef chooses the internal routing path.

Default delegated path:

- Master Chef chooses the next runnable TODO step
- if that top-level TODO step is oversized for one Builder run, Master Chef splits it first and delegates the first new runnable step
- Builder uses the internal `[CDD-3] Implement TODO` skill (`cdd-implement-todo`) for that step in a fresh single-step run
- Builder updates only the selected TODO step on success
- Master Chef reviews the evidence, approves UAT, commits, pushes, and reports
- If Master Chef QA rejects the result, Master Chef either sends concrete findings to a fresh Builder run for the same step or fixes the issue directly, then re-runs QA before any pass
- Passed steps are advertised as `STEP_PASS` in the current Master Chef session before automatic continuation
- if another runnable delegated step exists, Master Chef starts a new Builder run rather than continuing the old one
- if a Builder attempt does not pass, Master Chef chooses one of four outcomes in-session: `continue_same_step`, `repair_in_place`, `split_remainder_into_child_steps`, or `hard_stop`
- `continue_same_step` is valid when progress is coherent and a fresh Builder can plausibly finish the remainder without reopening planning
- `repair_in_place` is valid when the parent step boundary still holds but the TODO needs tighter sequencing, contract, or proof notes before the next Builder run
- `split_remainder_into_child_steps` is valid when the unfinished portion has become too risky for one Builder run and now forms a clearer lower-risk child-step sequence
- if Master Chef splits the remainder, it records what part of the parent is already done, what exact remainder is being separated, why the first child is the next runnable step, and what checks, UAT, and invariants carry forward
- if repair or split yields a safe autonomous next step, Master Chef reports `BLOCKER_CLEARED` with the original blocked step, replacement step ids when applicable, preserved remaining budget, and next delegated action, then continues the same run from the repaired parent step or first runnable child with a fresh Builder
- keep the run stopped only when a hard technical or physical limit still blocks safe autonomous continuation

Manual helper:

- `[CDD-0] Boot` (`cdd-boot`) for best-effort repo context ingestion when a human wants a vanilla `AGENTS.md` boot; it is installed in the shared pack but is not part of the normal Master Chef routing flow
- `[CDD-5] Maintain` (`cdd-maintain`) for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review; it is installed in the shared pack and used directly in the main session when one of those tasks is the actual next action

Master-Chef-direct path:

- `[CDD-1] Init Project` (`cdd-init-project`), especially when the user wants a new project to start in CDD form
- `[CDD-2] Plan` (`cdd-plan`)
- `[CDD-4] Implementation Audit` (`cdd-implementation-audit`) when the human explicitly wants an implementation or codebase audit checkpoint
- `[CDD-5] Maintain` (`cdd-maintain`) when the repo needs maintenance, cleanup, index refresh, or refactor architecture audit before delegated implementation

Audit findings:

- approved findings from `[CDD-4] Implementation Audit` or external review are normalized through `[CDD-2] Plan` (`cdd-plan`) in the main session, then hand the selected runnable step to Builder through `[CDD-3] Implement TODO` (`cdd-implement-todo`)

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for the packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for operation details
- Fresh install fails if any managed OpenClaw `cdd-*` skill already exists in the target root; use `--update` to replace them or `--uninstall` to remove them first
