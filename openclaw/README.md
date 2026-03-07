# cdd-master-chef

This folder is the source for the OpenClaw-only `cdd-master-chef` skill.

Installed form:

- directory: `~/.openclaw/skills/cdd-master-chef`
- slash command: `/cdd-master-chef`

The skill defines a three-actor development process:

- **Master Chef (OpenClaw):** planning, delegation, dispute handling, step-level UAT approval, commit, push, reporting
- **Builder (ACP Codex):** implementation worker for one approved step
- **Watchdog (OpenClaw):** 5-minute health checks, 15-minute heartbeat reports, resume on death
- **CDD-first policy:** if a `cdd-*` Builder skill exists for the phase, use it first

## Files

- `SKILL.md` — OpenClaw skill entrypoint
- `MASTER-CHEF-RUNBOOK.md` — canonical operating procedure and QA gate
- `MASTER-CHEF-TEST-HARNESS.md` — smoke test for the packaged skill

## Prerequisites

- OpenClaw with ACP enabled
- Healthy ACP backend for Codex:
  - `/acp doctor`
- Codex CLI reachable on `PATH`:
  - `codex --version`
- Separate CDD Builder skills already installed for Codex:
  - `~/.agents/skills/cdd-init-project`
  - `~/.agents/skills/cdd-plan`
  - `~/.agents/skills/cdd-implement-todo`
  - `~/.agents/skills/cdd-index`
  - `~/.agents/skills/cdd-audit-and-implement`
  - `~/.agents/skills/cdd-refactor`

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

## How to use it

Use the slash command to start or continue the Master Chef process:

```text
/cdd-master-chef Use the Master Chef process for /abs/path/to/repo.
REPORTING_COMMAND=/abs/path/to/report-status.sh
REPORTING_TARGET=slack:dev-loop
Open the control block, send START, and draft the next approved step.
```

Required startup contract:

- `REPO` — absolute repo path
- `REPORTING_COMMAND` — executable path to the user-provided reporting wrapper
- `REPORTING_TARGET` — user-selected channel or destination
- optional branch/upstream overrides; otherwise use the current branch and configured upstream

Reporting command interface:

```bash
CDD_REPORT_TARGET="<target>" \
CDD_REPORT_EVENT="<event>" \
CDD_REPORT_REPO="<repo>" \
CDD_REPORT_STEP="<step-or-none>" \
CDD_REPORT_STATUS="<status>" \
CDD_REPORT_BODY="<markdown>" \
"/abs/path/to/report-status.sh"
```

The skill should:

1. open and maintain the control block
2. preflight ACP, Builder, git branch/upstream, and reporting prerequisites
3. keep work scoped to one approved step at a time
4. delegate implementation to ACP `codex`
5. enforce CDD-first Builder behavior
6. run the hard QA gate
7. approve step-level UAT, commit, push, and send status reports for each passed step

## Watchdog and reporting

This skill assumes OpenClaw can trigger periodic watchdog turns.

- Every 5 minutes: Watchdog checks the control block and Builder health
- Every 15 minutes: Watchdog sends `HEARTBEAT`
- If the active process dies before the step is complete: Watchdog resumes it and sends `RESUME`
- If disputes resolve internally: send `DISPUTE_RESOLVED`
- If the step hits a serious standstill, repeated death/resume, or 2 unresolved challenge loops: stop the step and send `DEADLOCK_STOPPED`

Status reports must include explicit `Master Chef UAT approved` state.

Step-level push policy:

- every passed step ends with Master Chef UAT approval, commit, push, and `STEP_PASS`
- if push fails, the step is `STEP_BLOCKED`
- human control remains at the broader product level: intent, channel selection, and final overall ship/no-ship

## Runtime configuration

Model selection is managed outside this skill.

- OpenClaw `/model ...` controls the Master Chef LLM
- `/acp model ...` and `/acp set ...` control the Builder runtime
- Codex defaults can also be managed in Codex config outside OpenClaw

The skill should inspect runtime state when needed, but it should not encode preferred model IDs or reasoning defaults.

## Validation

- Use `MASTER-CHEF-TEST-HARNESS.md` for a packaged smoke test
- Use `MASTER-CHEF-RUNBOOK.md` as the source of truth for day-to-day operation
- Fresh install fails if `cdd-master-chef` is already present in the target root; use `--update` to replace it or `--uninstall` to remove it first
