# CDD Skills

Explicit-only Chat-Driven-Development skills and process docs.

This repo contains two skill blocks:

## 1. Core: CDD Skills

The core product is the Builder skill pack in `skills/`.

This is the single-agent workflow:

- one coding agent works the repo
- the human stays in the loop for planning, approvals, and acceptance
- the agent uses the `cdd-*` skills to plan and implement exactly one approved TODO step at a time

Source of truth:

- `skills/`

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

## 2. Upgrade: CDD Master Chef

The optional upgrade is the OpenClaw skill in `openclaw/`, installed as `/cdd-master-chef`.

This is the master-agent workflow:

- the human selects the Master Chef model and the Builder model
- the human starts Master Chef in an existing repo that already has the CDD boilerplate
- Master Chef checks where development is at, proposes the next runnable TODO step, and initializes durable runtime state
- the human confirms the kickoff, the reporting channel, and the isolated watchdog cron setup
- after that, Master Chef drives the Builder automatically and the human checks final results unless Master Chef reports a blocker or deadlock
- the watchdog supervises both Master Chef and Builder from a separate cron-driven supervisor turn

Source of truth:

- `openclaw/`

Installed form:

- OpenClaw: `~/.openclaw/skills/cdd-master-chef`
- slash command: `/cdd-master-chef`

The OpenClaw upgrade does not replace the Builder skill pack. It depends on the core `cdd-*` skills and delegates actual repo work to ACP Codex.

## Relationship Between the Two

- Start with the core `cdd-*` skills if you want the normal single-agent, human-approved CDD loop.
- Add `cdd-master-chef` only when you want OpenClaw to orchestrate the Builder, maintain an isolated watchdog supervisor, and keep the human mostly at kickoff plus final review.

## Recommended tools

- `git` — effectively required
- `gh` — recommended when working with GitHub-backed repos
- `bash` — required for the install scripts
- `python3` — recommended for local validation
- writable local repos — required because the Builder edits target workspaces

## Install

Clone the repo:

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
```

Install the core Builder skills for Codex CLI:

```bash
./scripts/install.sh
```

Install the OpenClaw Master Chef upgrade:

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

For the core single-agent workflow:

- install the Builder skill pack
- use the `cdd-*` skills directly from Codex CLI or Claude Code

For the Master Chef upgrade:

- install both the Builder skill pack and `cdd-master-chef`
- select models with `/model <master-model>` and `/acp model <builder-model>`
- launch `/cdd-master-chef` from the OpenClaw session you want to use as the default reporting channel, or be ready to name a different reporting route
- let Master Chef inspect the repo, propose the next TODO step, set up `.cdd-runtime/master-chef/`, and ask for kickoff confirmation before autonomous execution begins
- after kickoff, expect the isolated watchdog cron to check both Master Chef and Builder every 5 minutes and emit a combined status heartbeat every 15 minutes
