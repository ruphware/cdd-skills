# cdd-master-chef

This folder is the source for the OpenClaw-only `cdd-master-chef` skill.

Installed form:

- directory: `~/.openclaw/skills/cdd-master-chef`
- slash command: `/cdd-master-chef`

The skill defines a development process:

- **Master Chef (OpenClaw):** planning, delegation, QA gate, pass/fail
- **Builder (ACP Codex):** implementation worker for one approved step
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
/cdd-master-chef Use the Master Chef process for /abs/path/to/repo and draft the next approved step.
```

The skill should:

1. preflight ACP and Builder prerequisites
2. keep work scoped to one approved step at a time
3. delegate implementation to ACP `codex`
4. enforce CDD-first Builder behavior
5. run the hard QA gate before reporting PASS

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
