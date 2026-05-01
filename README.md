# CDD Skills

CDD workflow skills for agentic software engineering.

## Quick Install

Install the core `skills/` pack for Codex, Claude Code, Gemini CLI and others (adjust):

```bash
npx skills add https://github.com/ruphware/cdd-skills/tree/main/skills --skill '*' -a codex -a claude-code -a gemini-cli -g
```

Do not use the repo root URL here. The `skills` CLI scans both the repo root and `skills/`, so the root URL also picks up the `openclaw/` package as well.

## Basic Commands

Start with these core commands:

- `cdd-boot` — ingest `AGENTS.md` plus project and development docs for vanilla AGENTS-driven work when no other `cdd-*` skill will be used
- `cdd-plan` — plan changes and TODO steps
- `cdd-implement-todo` — implement exactly one TODO step and mark that step done on success
- `cdd-maintain` — archive long CDD files, audit support-doc drift, propose README/spec refreshes for approval, and doctor the codebase for refactor and dead-code signals

## What's Included

- Core `cdd-*` skills for the normal single-agent, human-in-the-loop CDD workflow
- Optional `cdd-master-chef` OpenClaw package for orchestrated master-agent runs

Details on the skill packs, manual repo install scripts, and OpenClaw setup are below.

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
- Gemini CLI: install the same `cdd-*` skills with the `skills` installer and invoke the same skill names there

Golden path:

- `$cdd-boot` — ingest `AGENTS.md` plus project and development docs for vanilla AGENTS-driven work when no other `cdd-*` skill will be used
- `$cdd-maintain` — archive long CDD files, audit support-doc drift, propose README/spec refreshes for approval, and doctor the codebase for refactor and dead-code signals
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

- the human supplies one explicit per-run Run config with `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`
- the human starts Master Chef in either an existing CDD-ready repo or a new project folder that should be set up in CDD form first
- Master Chef inspects where development is at, proposes the next runnable TODO step, initializes runtime state, and asks for kickoff approval
- after kickoff, Master Chef drives the Builder automatically with fresh one-step Builder runs and the human mostly checks final results unless Master Chef reports a blocker or deadlock

The Builder in this workflow is an OpenClaw subagent. It uses OpenClaw-ready internal variants of the full `cdd-*` skill pack. Those internal Builder skills are generated from the canonical repo source in `skills/` and installed into `~/.openclaw/skills` by `./scripts/install-openclaw.sh`.

Routing note: Master Chef chooses the path. New projects should normally start with `cdd-init-project` so they enter the CDD contract before implementation. After that, the normal delegated Builder path is `cdd-implement-todo`; `cdd-index` is a delegated exception when Master Chef explicitly wants an index refresh; planning-oriented skills such as `cdd-init-project`, `cdd-plan`, and `cdd-refactor` stay in Master Chef; `cdd-audit-and-implement` is excluded from the normal flow because it mixes roles. One Builder run equals one approved delegated action, so the next delegated step gets a fresh Builder run rather than session resurrection.

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

## Manual Install

If you want a local checkout and the repo-managed install scripts instead of the `npx` flow above:

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
- use `$cdd-maintain` when you want archive cleanup, support-doc review, and code-health review without entering a normal implementation step
- use the remaining `cdd-*` skills directly from Codex CLI or Claude Code when you want the structured CDD plan / implement loop

For the experimental Master Chef OpenClaw skill:

- install the OpenClaw package
- prepare one Run config block and set the main session to `master_model` from that block with `/model <master-model>`
- launch `/cdd-master-chef` from the OpenClaw session you want to use as Master Chef
- let Master Chef inspect the repo, propose the next TODO step, set up `.cdd-runtime/master-chef/`, and ask for kickoff confirmation before autonomous execution begins
- after kickoff, expect Master Chef to handle Builder checks directly in the main session, replace stale Builders quickly with fresh one-step runs, avoid normal session resurrection, stop after repeated failed replacements, and keep lifecycle reporting in that same session


## License

Free-to-use-adjust-just-don't-blame-me-for-anything-licence. _Peace._ ✌️

___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)
<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `$cdd-boot`. Use `$cdd-plan` + `$cdd-implement-todo` for feature work, `$cdd-maintain` for upkeep and drift control, and `$cdd-refactor` for structured refactors.</sup>

