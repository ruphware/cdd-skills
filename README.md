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
$cdd-init-project
```

2) The skill will:
- ask for context / files to read
- help complete `TODO.md` Step 00 (PRD + Blueprint + README)
- propose Step 01+ and ask approval to apply

### Ongoing development

- Plan new work:

```text
$cdd-plan
```

- Implement the next TODO step:

```text
$cdd-implement-todo
```

Optional maintenance:
- `$cdd-audit-and-implement` — audit bullets → TODO steps → implement first step (two approvals)
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-refactor` — refactor candidates → `TODO-refactor-<tag>.md` (approval-gated)

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

Breaking changes:
- Renamed: `$cdd-start` → `$cdd-init-project`, `$cdd-implement` → `$cdd-implement-todo`, `$cdd-audit` → `$cdd-audit-and-implement`
- Removed: `$cdd-prd`, `$cdd-blueprint`, `$cdd-todo`

Golden path:
- `$cdd-init-project` — complete Step 00 → propose Step 01+ (approval-gated)
- `$cdd-plan` — plan changes and TODO steps (approval-gated)
- `$cdd-implement-todo` — implement a TODO step
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-audit-and-implement` — audit → TODO steps → implement first step (two approvals)
- `$cdd-refactor` — refactor candidates → refactor TODO file (approval-gated)
