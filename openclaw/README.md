# cdd-master-chef

This folder is the source for the OpenClaw-only `cdd-master-chef` upgrade.

Installed form:

- `~/.openclaw/skills/cdd-master-chef`
- `/cdd-master-chef`

`./scripts/install-openclaw.sh` also installs OpenClaw-ready internal Builder variants of the full `cdd-*` skill pack into `~/.openclaw/skills`. Those Builder skills are generated from the canonical repo source in `skills/` and are meant for Master Chef and the Builder subagent, not for direct user invocation.

## What it does

The packaged OpenClaw workflow has two active actors:

- **Master Chef:** the current OpenClaw session that inspects repo state, chooses the next action, reviews Builder output, approves step-level UAT, commits, pushes, reports status, and checks Builder health directly when needed
- **Builder:** an OpenClaw subagent that executes one approved action at a time using the shared internal `cdd-*` skill pack, normally `cdd-implement-todo`

There is no watchdog cron. The human supplies one explicit per-run Run config, approves kickoff once, and then mainly checks final results or critical blockers.

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
- `cdd-boot`
- `cdd-maintain`
- `cdd-init-project`
- `cdd-plan`
- `cdd-implement-todo`
- `cdd-index`
- `cdd-audit-and-implement`
- `cdd-refactor`

The internal Builder variants are model-visible to OpenClaw agent runs and hidden from the user slash-command surface.

## How development starts

1. Open the OpenClaw session you want to use. The standard Run config uses `control_route: current-session`.
2. Choose how Master Chef should get the Run config:
   - either paste one inline, see `MASTER-CHEF-RUNBOOK.md`, section `2.1 Run config`
   - or keep a local-only default file at `~/.openclaw/config/master-chef/default-run-config.yaml`, see section `2.2 Local default Run config`
3. Select the current session model to match `master_model` from the Run config you plan to use:

   ```text
   /model <master-model>
   ```

4. Start Master Chef in the existing CDD repo:

   ```text
   /cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
   Inspect where development is at, propose the next runnable TODO step, and wait for my kickoff approval before creating runtime state or spawning the Builder.
   ```

   If the prompt does not include `Run config`, Master Chef should load `~/.openclaw/config/master-chef/default-run-config.yaml` when that file exists, show the resolved config back to the human, and use it only after kickoff approval.

5. Master Chef should then:
   - verify the repo already has the CDD boilerplate
   - inspect git status, branch, upstream, active TODO state, and the next runnable step
   - choose the routing path: usually Builder via `cdd-implement-todo`, sometimes Builder via `cdd-index`, otherwise Master-Chef-direct planning or refactor work
   - initialize `.cdd-runtime/master-chef/` for durable run state and logs
   - ask for one approval covering:
     - the proposed next action and routing path
     - the approved Run config
     - Builder handoff plus direct status-route reporting

After that approval, Master Chef drives the Builder automatically until the run completes, blocks, or deadlocks.

## Reporting and Builder checks

Reporting is OpenClaw-native:

- `control_route` comes from the Run config and normally resolves to the current session
- the standard default `status_route` in the Run config is the placeholder Telegram route shown in the example Run config below
- if a run should report elsewhere or nowhere, change only the Run config block for that run
- the chosen route policy is written into `.cdd-runtime/master-chef/run.json`
- the main session sends direct status updates; there is no external reporting wrapper
- if `status_route` is configured, Master Chef must attempt direct delivery for lifecycle events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, and `RUN_COMPLETE`
- successful status delivery updates `last_status_report_at_utc`; failed delivery records `STATUS_DELIVERY_FAILED`

Builder-check policy:

- no watchdog cron or timer-based heartbeat loop
- Master Chef checks runtime files, Builder health, and current progress directly in the main session
- if the Builder is stale during an active check, Master Chef steers it or replaces it with a fresh subagent run
- lifecycle status delivery remains required even without a watchdog

Runtime files:

- `.cdd-runtime/master-chef/run.json`
- `.cdd-runtime/master-chef/run.lock.json`
- `.cdd-runtime/master-chef/master-chef.jsonl`
- `.cdd-runtime/master-chef/builder.jsonl`

Keep these runtime files out of git, preferably via `.git/info/exclude`.

## Builder skill usage

Master Chef chooses the internal routing path.

Default delegated path:

- Master Chef chooses the next runnable TODO step
- Builder uses the internal OpenClaw `cdd-implement-todo` skill for that step
- Builder updates only the selected TODO step on success
- Master Chef reviews the evidence, approves UAT, commits, pushes, and reports

Delegated exception:

- `cdd-index` when Master Chef explicitly wants an index refresh as the delegated action

Manual helper:

- `cdd-boot` for best-effort repo context ingestion when a human wants a vanilla `AGENTS.md` boot; it is installed in the shared pack but is not part of the normal Master Chef routing flow
- `cdd-maintain` for archive cleanup, support-doc drift review, and code-health review; it is installed in the shared pack but is not part of the normal Master Chef routing flow

Master-Chef-direct path:

- `cdd-init-project`
- `cdd-plan`
- `cdd-refactor`

Excluded from the normal flow:

- `cdd-audit-and-implement`, because it mixes roles in a way that does not fit the clean Master Chef / Builder split

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for the packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for operation details
- Fresh install fails if any managed OpenClaw `cdd-*` skill already exists in the target root; use `--update` to replace them or `--uninstall` to remove them first
