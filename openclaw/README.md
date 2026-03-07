# cdd-master-chef

This folder is the source for the OpenClaw-only `cdd-master-chef` upgrade.

Installed form:

- directory: `~/.openclaw/skills/cdd-master-chef`
- slash command: `/cdd-master-chef`

This is not the core CDD workflow. It is the OpenClaw upgrade that sits on top of the core `cdd-*` Builder skills.

## What it does

The skill runs a three-part process:

- **Master Chef (OpenClaw):** inspects repo state, selects the next action, drives the Builder, approves step-level UAT, commits, pushes, and reports status
- **Builder (ACP Codex):** executes one approved step at a time using the core `cdd-*` skills
- **Watchdog (OpenClaw cron):** checks the run every 5 minutes and emits heartbeat every 15 minutes

The human chooses models, approves the kickoff once, and mainly checks final results or critical blockers.

## Prerequisites

- OpenClaw with ACP enabled
- Healthy ACP backend:
  - `/acp doctor`
- Codex CLI reachable on `PATH`:
  - `codex --version`
- Separate core CDD Builder skills already installed for Codex:
  - `~/.agents/skills/cdd-init-project`
  - `~/.agents/skills/cdd-plan`
  - `~/.agents/skills/cdd-implement-todo`
  - `~/.agents/skills/cdd-index`
  - `~/.agents/skills/cdd-audit-and-implement`
  - `~/.agents/skills/cdd-refactor`
- Target repo already has the CDD boilerplate:
  - `AGENTS.md`
  - `README.md`
  - `TODO.md` or `TODO-*.md`

This package does not install or duplicate the Builder skills. Install them separately with `./scripts/install.sh`.

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

Update an existing install:

```bash
./scripts/install-openclaw.sh --update
```

Uninstall the packaged skill:

```bash
./scripts/install-openclaw.sh --uninstall
```

## How development is initiated

1. Open the OpenClaw session you want to use as the reporting channel.
2. Select the Master Chef model with a standalone directive:

   ```text
   /model <master-model>
   ```

3. Select the Builder model with a standalone directive:

   ```text
   /acp model <builder-model>
   ```

4. Start Master Chef in the existing CDD repo:

   ```text
   /cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
   Inspect where development is at, propose the next runnable TODO step, and wait for my kickoff approval before creating the watchdog cron.
   ```

5. Master Chef should then:
   - verify model status with `/model status` and `/acp status`
   - verify the repo already has the CDD boilerplate
   - inspect git status, active TODO state, and the next runnable step
   - propose the next action, normally `cdd-implement-todo` on the next runnable TODO step
   - ask for one approval covering:
     - the proposed next action
     - use of the current session as the reporting channel
     - creation of the 5-minute watchdog cron

6. After that approval, Master Chef drives the Builder automatically until the run completes, blocks, or deadlocks.

## Reporting and watchdog

Reporting is OpenClaw-native:

- the current OpenClaw session is the reporting channel
- if that is not the right channel, relaunch `/cdd-master-chef` from the correct session before kickoff
- there is no external `REPORTING_COMMAND` wrapper contract

Watchdog policy:

- one recurring 5-minute cron job
- target the current main session
- inject a system event into the active Master Chef session
- emit `HEARTBEAT` every 15 minutes from that same loop
- resume dead Builder runs and report `RESUME`
- remove the cron when the autonomous run completes or stops

Useful cron commands:

```bash
openclaw cron list
openclaw cron rm <job-id>
```

## Runtime configuration

Model selection stays outside the skill.

- OpenClaw `/model ...` controls the Master Chef LLM
- `/acp model ...` and `/acp set ...` control the Builder runtime
- `/model status` and `/acp status` are the right checks before kickoff

The skill should not invent or hardcode model ids.

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for a packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for day-to-day operation
- Fresh install fails if `cdd-master-chef` is already present in the target root; use `--update` to replace it or `--uninstall` to remove it first
