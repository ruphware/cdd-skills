# cdd-master-chef

This folder is the source for the OpenClaw-only `cdd-master-chef` upgrade.

Installed form:

- `~/.openclaw/skills/cdd-master-chef`
- `/cdd-master-chef`

`./scripts/install-openclaw.sh` also installs OpenClaw-ready internal Builder variants of the full `cdd-*` skill pack into `~/.openclaw/skills`. Those Builder skills are generated from the canonical repo source in `skills/` and are meant for Master Chef and the Builder subagent, not for direct user invocation.

## What it does

The packaged OpenClaw workflow has three actors:

- **Master Chef:** the current OpenClaw session that inspects repo state, chooses the next action, reviews Builder output, approves step-level UAT, commits, pushes, and reports status
- **Builder:** an OpenClaw subagent that executes one approved action at a time using the shared internal `cdd-*` skill pack, normally `cdd-implement-todo`
- **Watchdog:** a 5-minute cron `systemEvent` that wakes the main session, checks runtime state, and nudges or replaces stale Builder runs

The human chooses the Master Chef model, chooses the Builder model and thinking level, approves kickoff once, and then mainly checks final results or critical blockers.

## Prerequisites

- OpenClaw installed and healthy
- `git` on `PATH`
- target repo already has the CDD boilerplate:
  - `AGENTS.md`
  - `README.md`
  - `TODO.md` or `TODO-*.md`
- target repo has a pushable upstream branch

You do not need a separate Codex or ACP skill install for this OpenClaw package. `./scripts/install-openclaw.sh` installs both `cdd-master-chef` and the internal OpenClaw Builder `cdd-*` skills into `~/.openclaw/skills`.

## Install

From the repo root:

```bash
./scripts/install-openclaw.sh
```

Explicit target example:

```bash
./scripts/install-openclaw.sh --target ~/.openclaw/skills
```

Link install for local iteration:

```bash
./scripts/install-openclaw.sh --link --update
```

Notes:

- `--link` symlinks `cdd-master-chef` itself.
- The generated internal Builder skills are still materialized as normal directories in the target root.

Update:

```bash
./scripts/install-openclaw.sh --update
```

Uninstall:

```bash
./scripts/install-openclaw.sh --uninstall
```

## What gets installed

`./scripts/install-openclaw.sh` installs:

- `cdd-master-chef`
- `cdd-init-project`
- `cdd-plan`
- `cdd-implement-todo`
- `cdd-index`
- `cdd-audit-and-implement`
- `cdd-refactor`

The internal Builder variants are model-visible to OpenClaw agent runs and hidden from the user slash-command surface.

## How development starts

1. Open the OpenClaw session you want to use as the control route.
2. Select the Master Chef model:

   ```text
   /model <master-model>
   ```

3. Decide the Builder model and thinking level you want Master Chef to use for subagent spawns.
4. Start Master Chef in the existing CDD repo:

   ```text
   /cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
   Treat this session as the control route.
   Use Builder model <BUILDER_MODEL> with thinking <BUILDER_THINKING>.
   Inspect where development is at, propose the next runnable TODO step, and wait for my kickoff approval before creating runtime state or the watchdog cron.
   ```

5. Master Chef should then:
   - verify the repo already has the CDD boilerplate
   - inspect git status, branch, upstream, active TODO state, and the next runnable step
   - propose the next action, normally `cdd-implement-todo` on the next runnable TODO step
   - initialize `.cdd-runtime/master-chef/` for durable run state and logs
   - ask for one approval covering:
     - the proposed next action
     - the chosen status route if any
     - creation of the 5-minute watchdog cron

After that approval, Master Chef drives the Builder automatically until the run completes, blocks, or deadlocks.

## Reporting and watchdog

Reporting is OpenClaw-native:

- `control_route` is the current session
- `status_route` is optional and can be an external route such as Slack
- the chosen route policy is written into `.cdd-runtime/master-chef/run.json`
- the main session sends direct status updates; there is no external reporting wrapper

Watchdog policy:

- one recurring 5-minute cron job
- `sessionTarget: "main"`
- `payload.kind: "systemEvent"`
- the cron wakes Master Chef in the main session
- Master Chef checks runtime files, Builder health, and current progress
- if the Builder is stale, Master Chef steers it or replaces it with a fresh subagent run
- `HEARTBEAT` is emitted about every 15 minutes
- the cron is removed when the autonomous run completes or is stopped

Runtime files:

- `.cdd-runtime/master-chef/run.json`
- `.cdd-runtime/master-chef/run.lock.json`
- `.cdd-runtime/master-chef/master-chef.jsonl`
- `.cdd-runtime/master-chef/builder.jsonl`
- `.cdd-runtime/master-chef/watchdog.jsonl`

Keep these runtime files out of git, preferably via `.git/info/exclude`.

## Builder skill usage

The normal Builder path is:

- Master Chef chooses the next runnable TODO step
- Builder uses the internal OpenClaw `cdd-implement-todo` skill for that step
- Builder updates only the selected TODO step on success
- Master Chef reviews the evidence, approves UAT, commits, pushes, and reports

Fallback usage:

- `cdd-plan` only when the TODO state needs repair or the next action is not executable
- `cdd-index`, `cdd-refactor`, `cdd-audit-and-implement`, and `cdd-init-project` only when the repo state actually calls for them

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for the packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for operation details
- Fresh install fails if any managed OpenClaw `cdd-*` skill already exists in the target root; use `--update` to replace them or `--uninstall` to remove them first
