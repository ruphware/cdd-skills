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
- **Watchdog (OpenClaw cron):** runs as an isolated supervisor every 5 minutes, probes Master Chef health, checks Builder health, restores the run when needed, and emits a dual-actor heartbeat every 15 minutes

The human chooses models, approves the kickoff once, and mainly checks final results or critical blockers.

## Prerequisites

- OpenClaw with ACP enabled
- OpenClaw session-tool visibility wide enough for an isolated watchdog to reach the active Master Chef session:
  - `tools.sessions.visibility = "agent"` or `"all"`
  - if sandboxed, `agents.defaults.sandbox.sessionToolsVisibility` must preserve that reach
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
The OpenClaw installer checks for the required Builder skills in the default Codex location, `~/.agents/skills`, and prints either `Verified` or a warning if they are missing there.

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

1. Open the OpenClaw session you want to use as the reporting channel, or decide the exact route you want reports delivered to.
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
   Inspect where development is at, propose the next runnable TODO step, confirm my reporting route, and wait for my kickoff approval before creating the watchdog cron.
   ```

5. Master Chef should then:
   - verify model status with `/model status` and `/acp status`
   - verify session-tool visibility is sufficient for isolated watchdog supervision
   - verify the repo already has the CDD boilerplate
   - inspect git status, active TODO state, and the next runnable step
   - propose the next action, normally `cdd-implement-todo` on the next runnable TODO step
   - initialize `.cdd-runtime/master-chef/` for durable run state and logs
   - ask for one approval covering:
     - the proposed next action
     - the selected reporting route
     - creation of the 5-minute isolated watchdog cron

6. After that approval, Master Chef drives the Builder automatically until the run completes, blocks, or deadlocks.

## Reporting and watchdog

Reporting is OpenClaw-native:

- the user selects the reporting route at kickoff
- the current session is only the default route if the user explicitly accepts it
- the selected route is written into `.cdd-runtime/master-chef/run.json`
- there is no external `REPORTING_COMMAND` wrapper contract

Watchdog policy:

- one recurring 5-minute cron job
- run in an isolated session, not the main Master Chef session
- read `.cdd-runtime/master-chef/run.json` plus actor logs on each tick
- probe Master Chef first before attempting recovery
- if Master Chef is healthy but Builder is stale, tell Master Chef to resume Builder and report `BUILDER_RESUMED`
- if Master Chef is stale or dead, rehydrate the run from `run.json`, restart Master Chef, and report `MASTER_CHEF_RESTARTED`
- emit `HEARTBEAT` every 15 minutes with both Master Chef and Builder summaries
- remove the cron when the autonomous run completes or stops

Runtime files:

- `.cdd-runtime/master-chef/run.json`
- `.cdd-runtime/master-chef/master-chef.jsonl`
- `.cdd-runtime/master-chef/builder.jsonl`
- `.cdd-runtime/master-chef/watchdog.jsonl`

These files are operational state, not project docs. Keep them out of git, preferably via `.git/info/exclude`.

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
- the isolated watchdog cron should reuse the Master Chef model selected at kickoff time

The skill should not invent or hardcode model ids.

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for a packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for day-to-day operation
- Fresh install fails if `cdd-master-chef` is already present in the target root; use `--update` to replace it or `--uninstall` to remove it first
