# [CDD-8] Master Chef

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
- `[CDD-4] Audit + Implement` -> `cdd-audit-and-implement`
- `[CDD-5] Refactor` -> `cdd-refactor`
- `[CDD-6] Index` -> `cdd-index`
- `[CDD-7] Maintain` -> `cdd-maintain`

## What it does

The packaged OpenClaw adapter has two active actors:

- **Master Chef:** the current OpenClaw session that inspects repo state, chooses the next action, reviews Builder output, approves step-level UAT, commits, pushes, reports status, and checks Builder health directly when needed
- **Builder:** a fresh one-step OpenClaw subagent run that executes one approved action at a time using the shared internal `cdd-*` skill pack, normally `cdd-implement-todo`

There is no watchdog cron. The human approves one per-run Run config, approves how many TODO steps the current run should cover, approves whether Builder should start now, approves kickoff once, and then mainly checks final results or critical blockers.

## Managed worktree policy

- The source checkout must be clean before kickoff. If it is dirty, Master Chef stops and asks the human to stash, commit, or discard changes first.
- The OpenClaw adapter provisions a fresh per-run branch in a managed worktree rooted under `.cdd-runtime/master-chef/worktrees/<run-id>/`.
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

- `[CDD-8] Master Chef` -> `cdd-master-chef`
- `[CDD-0] Boot` -> `cdd-boot`
- `[CDD-7] Maintain` -> `cdd-maintain`
- `[CDD-1] Init Project` -> `cdd-init-project`
- `[CDD-2] Plan` -> `cdd-plan`
- `[CDD-3] Implement TODO` -> `cdd-implement-todo`
- `[CDD-6] Index` -> `cdd-index`
- `[CDD-4] Audit + Implement` -> `cdd-audit-and-implement`
- `[CDD-5] Refactor` -> `cdd-refactor`

The internal Builder variants are model-visible to OpenClaw agent runs and hidden from the user slash-command surface.

## How development starts

1. Open the OpenClaw session you want to use. That session is both Master Chef and the reporting surface for the run.
2. Choose how Master Chef should get the Run config:
   - either paste one inline, see `MASTER-CHEF-RUNBOOK.md`, section `2.1 Run config`
   - or keep a local-only default file at `~/.openclaw/config/master-chef/default-run-config.yaml`, see section `2.2 Local default Run config`
   - or omit both and let Master Chef recommend a candidate Run config from the current session model and current session thinking, then approve or edit it before kickoff
3. Select the current session model to match `master_model` from the Run config you plan to use, or the model you want copied into the recommendation path:

   ```text
   /model <master-model>
   ```

4. Start `[CDD-8] Master Chef` in the target repo or new project folder:

   ```text
   /cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
   Inspect where development is at, propose the next runnable TODO step, and wait for my kickoff approval before creating runtime state or spawning the Builder.
   ```

   If the prompt does not include `Run config`, Master Chef should load `~/.openclaw/config/master-chef/default-run-config.yaml` when that file exists, show the resolved config back to the human, and use it only after kickoff approval. Otherwise, if the current session model and current session thinking are visible, it should recommend a candidate Run config that copies them into all four fields, show it back to the human, and wait for approval or edits before kickoff. If it cannot observe both values, it should stop and ask for a Run config.

5. Master Chef should then:
   - verify whether the repo is already CDD-ready or first needs `cdd-init-project`
   - inspect git status, branch, upstream, active TODO state, and the next runnable step
   - choose the routing path: usually Builder via `[CDD-3] Implement TODO`, sometimes Builder via `[CDD-6] Index`, otherwise Master-Chef-direct planning or refactor work
   - ask how many TODO steps this run should cover: a positive integer count or `until_blocked_or_complete`
   - ask whether to spawn Builder now and start the autonomous run
   - initialize `.cdd-runtime/master-chef/` for durable run state and logs
   - ask for one approval covering:
     - the proposed next action and routing path
     - the approved Run config
     - the approved run step budget
     - whether to spawn Builder now
     - Builder handoff plus in-session reporting expectations

After that approval, Master Chef drives the Builder automatically until the run completes, blocks, or deadlocks.

After each passed, blocked, or stale delegated step, that Builder run is finished. If another delegated step exists, Master Chef re-inspects repo state and starts a fresh Builder run, normally via `cdd-implement-todo`.

## Reporting and Builder checks

Reporting is OpenClaw-native and session-native:

- the current Master Chef session is the only control/reporting route described by the shared package
- lifecycle reporting such as `START`, `STEP_PASS`, `STEP_BLOCKED`, and `RUN_COMPLETE` stays in that session
- `.cdd-runtime/master-chef/run.json` stores run state, not extra route metadata
- if a local operator wants external notifications, keep that as local-only behavior rather than shared skill config

Builder-check policy:

- no watchdog cron or timer-based heartbeat loop
- Master Chef checks runtime files, Builder health, and current progress directly in the main session
- if the Builder is stale during an active check, Master Chef replaces it quickly with a fresh one-step subagent run
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

- Builder stays fresh through one-step runs, normally booted with `cdd-implement-todo`.
- Master Chef checkpoints long-run memory in `.cdd-runtime/master-chef/context-summary.md` before deliberate compaction.
- Master Chef compacts only at safe workflow boundaries and resumes from runtime files, active TODO, and git state rather than transcript memory.

## Builder skill usage

Master Chef chooses the internal routing path.

Default delegated path:

- Master Chef chooses the next runnable TODO step
- Builder uses the internal `[CDD-3] Implement TODO` skill (`cdd-implement-todo`) for that step in a fresh one-step run
- Builder updates only the selected TODO step on success
- Master Chef reviews the evidence, approves UAT, commits, pushes, and reports
- If Master Chef QA rejects the result, Master Chef either sends concrete findings to a fresh Builder run for the same step or fixes the issue directly, then re-runs QA before any pass
- Passed steps are advertised as `STEP_PASS` in the current Master Chef session before automatic continuation
- if another runnable delegated step exists, Master Chef starts a new Builder run rather than continuing the old one
- if a step is blocked, Master Chef stops the autonomous loop, reports the blocker in-session, decomposes the work into smaller TODO steps when possible, cleans only stale retry artifacts, and restarts from the next smaller actionable step

Delegated exception:

- `[CDD-6] Index` (`cdd-index`) when Master Chef explicitly wants an index refresh as the delegated action

Manual helper:

- `[CDD-0] Boot` (`cdd-boot`) for best-effort repo context ingestion when a human wants a vanilla `AGENTS.md` boot; it is installed in the shared pack but is not part of the normal Master Chef routing flow
- `[CDD-7] Maintain` (`cdd-maintain`) for archive cleanup, support-doc drift review, and code-health review; it is installed in the shared pack but is not part of the normal Master Chef routing flow

Master-Chef-direct path:

- `[CDD-1] Init Project` (`cdd-init-project`), especially when the user wants a new project to start in CDD form
- `[CDD-2] Plan` (`cdd-plan`)
- `[CDD-5] Refactor` (`cdd-refactor`)

Excluded from the normal flow:

- `[CDD-4] Audit + Implement` (`cdd-audit-and-implement`), because it mixes roles in a way that does not fit the clean Master Chef / Builder split

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for the packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for operation details
- Fresh install fails if any managed OpenClaw `cdd-*` skill already exists in the target root; use `--update` to replace them or `--uninstall` to remove them first
