# CDD Skills

Chat-Driven-Development skills and process docs.

This repo contains two skill blocks.

## 1. Core: CDD Skills

The core product is the canonical `cdd-*` skill pack in `skills/`.

This is the single-agent, human-in-the-loop workflow:

- one coding agent works the repo
- the human stays in the loop for planning, approvals, and acceptance
- the agent uses the `cdd-*` skills to plan and implement exactly one approved TODO step at a time

Source of truth:

- `skills/`

Typical runtimes:

- Codex CLI: install to `~/.agents/skills/`, invoke via `$cdd-*`
- Claude Code: install to `~/.claude/skills/`, invoke via `/cdd-*`

Golden path:

- `$cdd-boot` — ingest `AGENTS.md` plus project and development docs for vanilla AGENTS-driven work when no other `cdd-*` skill will be used
- `$cdd-init-project` — init or adopt the CDD workflow in the current folder
- `$cdd-plan` — plan changes and TODO steps
- `$cdd-implement-todo` — implement exactly one TODO step and mark that step done on success
- `$cdd-index` — regenerate `docs/INDEX.md`
- `$cdd-audit-and-implement` — turn audit items into TODO steps and implement the first one
- `$cdd-refactor` — create a refactor TODO plan from the current index

## 2. Upgrade: CDD Master Chef for OpenClaw

The optional upgrade is the experimental OpenClaw skill package rooted in `openclaw/`.

`CDD Master Chef` is very experimental, in active development, and far from done. Treat it as a rough workflow for iteration, not a finished product.

If you want useful UI output, provide strong UX mockups with the plan. Without good mockups, agents will usually produce useless AI slop.

This is the master-agent workflow:

- the human selects the Master Chef model
- the human chooses the Builder model and thinking level
- the human starts Master Chef in an existing repo that already has the CDD boilerplate
- Master Chef inspects where development is at, proposes the next runnable TODO step, initializes runtime state, and asks for kickoff approval
- after kickoff, Master Chef drives the Builder automatically and the human mostly checks final results unless Master Chef reports a blocker or deadlock

The Builder in this workflow is an OpenClaw subagent. It uses OpenClaw-ready internal variants of the full `cdd-*` skill pack. Those internal Builder skills are generated from the canonical repo source in `skills/` and installed into `~/.openclaw/skills` by `./scripts/install-openclaw.sh`.

Routing note: Master Chef chooses the path. The normal delegated Builder path is `cdd-implement-todo`; `cdd-index` is a delegated exception when Master Chef explicitly wants an index refresh; planning-oriented skills such as `cdd-init-project`, `cdd-plan`, and `cdd-refactor` stay in Master Chef; `cdd-audit-and-implement` is excluded from the normal flow because it mixes roles.

Source of truth:

- `openclaw/`
- canonical Builder workflow source still lives in `skills/`

Installed form:

- `~/.openclaw/skills/cdd-master-chef`
- internal OpenClaw `cdd-*` Builder skills under `~/.openclaw/skills/`
- slash command: `/cdd-master-chef`

## Relationship Between the Two

- Start with the core `cdd-*` skills when you want the normal single-agent, human-approved CDD loop.
- Add `cdd-master-chef` when you want OpenClaw to orchestrate the process, keep the Builder on the OpenClaw subagent runtime, and reduce the human role to kickoff plus final review.
- `skills/` remains the canonical definition of the Builder workflow in both cases.

## Recommended tools

- `git` — effectively required
- `gh` — recommended when working with GitHub-backed repos
- `bash` — required for the install scripts
- `python3` — required for OpenClaw Builder skill generation and recommended for local validation
- writable local repos — required because the Builder edits target workspaces

## Install

Clone the repo:

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
```

Install the core Builder skills for Codex CLI or similar single-agent runtimes:

```bash
./scripts/install.sh
```

Install the OpenClaw package:

```bash
./scripts/install-openclaw.sh
```

Typical combined setup when you want both workflows available:

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
- `./scripts/install-openclaw.sh` manages both `cdd-master-chef` and the internal OpenClaw Builder `cdd-*` skills in the target root.
- If newly installed or updated skills do not appear, start a new session or restart the runtime.

## Start Here

For the core single-agent workflow:

- install the Builder skill pack
- use `$cdd-boot` when the repo is already CDD-ready and you want a one-time vanilla AGENTS boot before working directly
- use the remaining `cdd-*` skills directly from Codex CLI or Claude Code when you want the structured CDD plan / implement loop

For the experimental Master Chef OpenClaw skill:

- install the OpenClaw package
- select the Master Chef model with `/model <master-model>`
- decide the Builder model and thinking level for subagent spawns
- launch `/cdd-master-chef` from the OpenClaw session you want to use as the control route
- let Master Chef inspect the repo, propose the next TODO step, set up `.cdd-runtime/master-chef/`, and ask for kickoff confirmation before autonomous execution begins
- after kickoff, expect the main-session watchdog cron to check Builder health every 5 minutes; healthy ticks may stay quiet except for periodic heartbeats, but configured lifecycle status updates must still be attempted on step/run transitions
