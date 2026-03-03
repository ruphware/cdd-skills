# cdd-skills

Explicit-only CDD (Chat‑Driven Development) skills.

These skills follow the agent-skills folder standard (`.agents/skills`) and are designed to work well in Codex CLI.

Runtimes:
- Codex CLI: install to `~/.agents/skills/`, invoke via `$cdd-*`.
- Claude Code: install to `~/.claude/skills/`, invoke via `/cdd-*`.
- OpenClaw: install to `~/.openclaw/skills/` (or `<workspace>/skills/`).

## Start here (two workflows)

### Start a new project

1) Run:

```text
$cdd-start
```

2) The skill will:
- ask for context / files to read
- draft PRD → ask approval → write `docs/specs/prd.md`
- draft Blueprint → ask approval → write `docs/specs/blueprint.md`
- draft TODO plan → ask approval → write `TODO.md`

### Ongoing development

- Plan new work:

```text
$cdd-plan
```

- Implement the next TODO step:

```text
$cdd-implement
```

Optional maintenance:
- `$cdd-audit` — turn audit bullets into TODO steps (approval-gated)
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-refactor` — convert INDEX refactor targets into `TODO-refactoring-<tag>.md` (approval-gated)

## Human in the loop

Humans own product intent and final acceptance. Skill outputs include UAT checklists per step. An agent can run UAT commands, but a human should approve the result.

## Install

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
./scripts/install.sh
```

This copies skills into `~/.agents/skills/` (Codex CLI).

To install for multiple runtimes:

```bash
./scripts/install.sh --target ~/.agents/skills --target ~/.claude/skills --target ~/.openclaw/skills
```

## Update

```bash
cd cdd-skills
git pull
./scripts/install.sh --force
```

Notes:
- If you install via the default copy mode, updating the repo does not update installed skills until you rerun `./scripts/install.sh`.
- If newly installed/updated skills don’t appear, restart Codex.

## Commands

Golden path:
- `$cdd-start` — PRD → Blueprint → TODO (approval-gated)
- `$cdd-plan` — plan changes and TODO steps (approval-gated)
- `$cdd-implement` — implement a TODO step
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-audit` — audit list → TODO steps (approval-gated)
- `$cdd-refactor` — INDEX refactor targets → refactor TODO file (approval-gated)

Atomic (optional):
- `$cdd-prd`
- `$cdd-blueprint`
- `$cdd-todo`
