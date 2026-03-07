# CDD Skills

Explicit-only Chat-Driven-Development skills and process docs for a multi-agent development loop.

This repo packages two complementary layers:

- **Builder skill pack** in `skills/` for Codex CLI or Claude Code.
- **Master Chef orchestration skill** in `openclaw/`, installed as the OpenClaw slash command `/cdd-master-chef`.

## Multi-agent development process

The intended workflow is:

1. A human sets product intent and approves work.
2. OpenClaw runs the **Master Chef** process through `/cdd-master-chef`.
3. Master Chef selects or plans exactly one approved TODO step.
4. Master Chef delegates implementation to an ACP Codex Builder session.
5. The Builder uses the separate `cdd-*` skills first (`cdd-plan`, `cdd-implement-todo`, `cdd-index`, and related helpers).
6. Master Chef performs the QA gate, returns UAT, and the human decides whether to ship.

This keeps planning, implementation, and acceptance separate:

- **Human**: product intent, UAT, final ship/no-ship
- **OpenClaw Master Chef**: scope control, delegation, QA gate
- **ACP Codex Builder**: code changes and command evidence for one approved step

## Components

### Builder skill pack

Source of truth: `skills/`

Runtimes:

- Codex CLI: install to `~/.agents/skills/`, invoke via `$cdd-*`
- Claude Code: install to `~/.claude/skills/`, invoke via `/cdd-*`

Golden path commands:

- `$cdd-init-project` — init or adopt the CDD workflow in the current folder
- `$cdd-plan` — plan changes and TODO steps
- `$cdd-implement-todo` — implement exactly one TODO step
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-audit-and-implement` — audit -> TODO steps -> implement first step
- `$cdd-refactor` — create a refactor TODO plan from the current index

### OpenClaw Master Chef skill

Source of truth: `openclaw/`

Install target:

- OpenClaw: `~/.openclaw/skills/cdd-master-chef`

Invocation:

- `/cdd-master-chef`

The OpenClaw skill does not replace the Builder skill pack. It orchestrates Codex over ACP and expects the separate `cdd-*` Builder skills to already be installed. See `openclaw/README.md` for operator details.

## Recommended tools

- `git` — effectively required
- `gh` — recommended when working with GitHub-backed repos
- `bash` — required for the install scripts
- `python3` — recommended for local validation
- Writable local repos — required because the Builder edits target workspaces

## Install

Clone the repo:

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
```

Install the Builder skills for Codex CLI:

```bash
./scripts/install.sh
```

Install the OpenClaw Master Chef skill:

```bash
./scripts/install-openclaw.sh
```

Typical OpenClaw + Codex setup:

```bash
./scripts/install.sh --target ~/.agents/skills
./scripts/install-openclaw.sh --target ~/.openclaw/skills
```

## Update

```bash
cd cdd-skills
git pull
./scripts/install.sh --update
./scripts/install-openclaw.sh --update
```

If the install target already contains one of the managed skill directories, rerunning the installer without `--update` fails by design.

Builder update automatically runs the conservative prune logic. Use `--yes` if you want to auto-confirm prune prompts in non-interactive contexts:

```bash
./scripts/install.sh --update --yes
```

## Uninstall

```bash
./scripts/install.sh --uninstall
./scripts/install-openclaw.sh --uninstall
```

Notes:

- `--uninstall` lists matching installed paths and installer artifacts, asks for `y/N`, and removes them only on confirmation.
- If newly installed or updated skills do not appear, start a new session or restart the runtime.

## Start here

Builder-only work:

- Use the `cdd-*` skill pack directly from Codex CLI or Claude Code.

OpenClaw-driven work:

- Install both the Builder skills and `cdd-master-chef`.
- Use `/cdd-master-chef` to run the Master Chef process and delegate Builder work through ACP Codex.
