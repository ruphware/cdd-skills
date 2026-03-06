# CDD Skills

Explicit-only Agent CDD (Chat‑Driven-Development) skills.

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
- route based on repo state (empty dir / docs-seeded folder / fresh boilerplate repo / existing repo)
- for empty dirs: propose the current folder name as the repo name, bring the boilerplate template into that same folder, and start Step 00 there
- for docs-seeded folders: inventory raw source documents, bring the boilerplate template into that same folder, and use the discovered docs to drive Step 00
- for boilerplate repos: help complete `TODO.md` Step 00 (PRD + Blueprint + README) and propose Step 01+
- for existing repos: draft a CDD adoption + docs migration plan (approval-gated)

### Ongoing development

- Plan new work:

```text
$cdd-plan
```

- Implement the next TODO step:

```text
$cdd-implement-todo
```

- Implement a specific step directly:

```text
$cdd-implement-todo step 008
```

If the requested step resolves to exactly one match across `TODO.md` and `TODO-*.md`, the skill should implement it immediately. It should ask follow-up questions only when step resolution is ambiguous or the TODO step itself is underspecified.

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

Golden path:
- `$cdd-init-project` — init or adopt the CDD workflow in the current folder, including empty and docs-seeded folders (approval-gated)
- `$cdd-plan` — plan changes and TODO steps (approval-gated)
- `$cdd-implement-todo` — implement a TODO step; explicit step selectors should run immediately when they match exactly one step
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-audit-and-implement` — audit → TODO steps → implement first step (two approvals)
- `$cdd-refactor` — refactor candidates → refactor TODO file (approval-gated)
