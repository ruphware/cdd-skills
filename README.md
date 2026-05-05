# CDD Skills

Chat Driven Development workflow skills for controlled agentic software engineering.

## Quick Install

Install the full repo skill set, for Codex, Claude Code, Gemini CLI and others (adjust):

```bash
npx skills add https://github.com/ruphware/cdd-skills/ --skill '*' -a codex -a claude-code -a gemini-cli -g
```

## Skill Map

- `[CDD-0] Boot` — `cdd-boot` — ingest `AGENTS.md` plus project and development docs for vanilla AGENTS-driven work when no other `cdd-*` skill will be used
- `[CDD-1] Init Project` — `cdd-init-project` — init or adopt the CDD workflow in the current folder
- `[CDD-2] Plan` — `cdd-plan` — plan changes and TODO steps
- `[CDD-3] Implement TODO` — `cdd-implement-todo` — implement exactly one TODO step and mark that step done on success
- `[CDD-4] Audit + Implement` — `cdd-audit-and-implement` — turn audit items into TODO steps and implement the first dependency-ordered step
- `[CDD-5] Refactor` — `cdd-refactor` — create a refactor TODO plan from the current index
- `[CDD-6] Index` — `cdd-index` — regenerate `docs/INDEX.md`
- `[CDD-7] Maintain` — `cdd-maintain` — archive long CDD files, audit support-doc drift, propose README/spec refreshes for approval, and doctor the codebase for refactor and dead-code signals
- `[CDD-8] Master Chef` — `cdd-master-chef` — start the autonomous development process through the canonical Master Chef package and its current runtime adapters

## When to Use What

- Use the core `$cdd-*` loop when you want a single coding agent, explicit human approvals, and one approved TODO step at a time.
- Use `$cdd-master-chef` when you want an autonomous run after kickoff approval and one of the current concrete adapters fits your runtime.

## What's Included

- Core `[CDD-0]` through `[CDD-7]` skills for the normal single-agent, human-in-the-loop CDD workflow
- `[CDD-8] Master Chef` package with current Codex, Claude Code, and OpenClaw adapters for orchestrated autonomous runs

Details on the skill packs, canonical Master Chef package, manual repo install scripts, and the current concrete adapters are below.

## 1. Core: `[CDD-0]` through `[CDD-7]`

The core product is the canonical `cdd-*` skill pack in `skills/`, covering `[CDD-0]` through `[CDD-7]`.

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

Typical core path:

- `[CDD-1] Init Project` when the repo is new or adopting CDD
- `[CDD-2] Plan` then `[CDD-3] Implement TODO` for normal feature work
- `[CDD-0] Boot` for a one-time vanilla AGENTS boot when you are working directly
- `[CDD-4] Audit + Implement`, `[CDD-5] Refactor`, `[CDD-6] Index`, and `[CDD-7] Maintain` when audit, refactor, index-refresh, or maintenance work is the actual task

## 2. `[CDD-8] Master Chef` (Shared Contract + Runtime Adapters)

The optional `[CDD-8] Master Chef` package starts the autonomous development process through the canonical multi-runtime package rooted in `cdd-master-chef/`.

`[CDD-8] Master Chef` remains in active development. The contract and adapters are stable enough for iteration, but the workflow is still evolving.

If you want useful UI output, provide strong UX mockups with the plan. Without good mockups, agents will usually produce useless AI slop.

The shared workflow is:

- the human approves one per-run Run config with `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`, supplied inline, loaded from a local default, or recommended from the current session model and thinking when the runtime can surface them concretely
- on a fresh run from a long-lived branch, Master Chef can suggest a descriptive feature branch; when the active TODO has a finite remaining unfinished top-level step-heading count, it recommends that exact count as the default/max step budget
- the human also approves how many TODO steps this run should cover and whether Master Chef should spawn Builder now and start the autonomous run
- the human starts Master Chef in either an existing CDD-ready repo or a new project folder that should be set up in CDD form first
- Master Chef inspects where development is at, proposes the next runnable TODO step, initializes runtime state, and asks for kickoff approval
- after kickoff, Master Chef drives the Builder automatically with fresh one-step Builder runs and the human mostly checks final results unless Master Chef reports a blocker or deadlock

Current repo state:

- canonical Master Chef package root: `cdd-master-chef/`
- shared operational runbook: `cdd-master-chef/RUNBOOK.md`
- Codex adapter docs: `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md`
- Claude Code adapter docs: `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md`
- current OpenClaw adapter docs: `cdd-master-chef/openclaw/`
- runtime capability matrix: `cdd-master-chef/RUNTIME-CAPABILITIES.md`
- canonical Builder workflow source still lives in `skills/`

Current concrete adapters in this repo:

- OpenClaw — current packaged adapter, installed with `./scripts/install.sh --runtime openclaw`
- Codex — current subagent-backed adapter docs in `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md`
- Claude Code — current subagent-backed adapter docs in `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md`

Potential future adapters:

- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters.
- No Hermes adapter ships in this repo today.

The unified installer ships `[CDD-8] Master Chef` to generic/Codex-style, Claude Code, and OpenClaw installs. On OpenClaw it also installs internal `cdd-*` Builder variants into `~/.openclaw/skills`.

Routing note: `[CDD-8] Master Chef` chooses the path. New projects should normally start with `[CDD-1] Init Project` so they enter the CDD contract before implementation. After that, the normal delegated Builder path is `[CDD-3] Implement TODO`; `[CDD-6] Index` is a delegated exception when Master Chef explicitly wants an index refresh; planning-oriented skills such as `[CDD-1] Init Project`, `[CDD-2] Plan`, and `[CDD-5] Refactor` stay in Master Chef; `[CDD-4] Audit + Implement` is excluded from the normal flow because it mixes roles. One Builder run equals one approved delegated action, so the next delegated step gets a fresh Builder run rather than session resurrection.

Source of truth:

- `cdd-master-chef/` for the shared contract and packaged skill root
- `cdd-master-chef/openclaw/` for the current OpenClaw adapter docs
- canonical Builder workflow source still lives in `skills/`

Installed form:

- `~/.agents/skills/cdd-master-chef` on generic and Codex-style installs
- `~/.claude/skills/cdd-master-chef` on Claude Code installs
- `~/.openclaw/skills/cdd-master-chef` on OpenClaw installs
- internal OpenClaw `cdd-*` Builder skills under `~/.openclaw/skills/`
- current packaged runtime command surface: `/cdd-master-chef` in OpenClaw

## Relationship Between the Two

- Start with `[CDD-0]` through `[CDD-7]` when you want the normal single-agent, human-approved CDD loop.
- Add `[CDD-8] Master Chef` when you want the shared autonomous workflow and one of the current adapters fits your runtime. Today that means OpenClaw, Codex, or Claude Code.
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

Install the core Builder skills plus the canonical `[CDD-8] Master Chef` package for Codex CLI or similar single-agent runtimes:

```bash
./scripts/install.sh
```

Install into every existing runtime home in one pass. The installer checks for `~/.agents`, `~/.claude`, and `~/.openclaw`, then installs into each matching default skills directory:

```bash
./scripts/install.sh --all
```

Install the same core pack to Claude Code's default skill root:

```bash
./scripts/install.sh --runtime claude
```

Install the current OpenClaw adapter from the same entrypoint:

```bash
./scripts/install.sh --runtime openclaw
```

Typical combined setup when you want both workflows available:

```bash
./scripts/install.sh --target ~/.agents/skills
./scripts/install.sh --runtime claude --target ~/.claude/skills
./scripts/install.sh --runtime openclaw --target ~/.openclaw/skills
```

## Update

```bash
cd cdd-skills
git pull
./scripts/install.sh --all --update
./scripts/install.sh --update
./scripts/install.sh --runtime openclaw --update
```

If the install target already contains one of the managed skill directories, rerunning the installer without `--update` fails by design.

Builder update automatically runs the conservative prune logic. Use `--yes` if you want to auto-confirm prune prompts in non-interactive contexts:

```bash
./scripts/install.sh --update --yes
```

## Uninstall

```bash
./scripts/install.sh --all --uninstall
./scripts/install.sh --uninstall
./scripts/install.sh --runtime openclaw --uninstall
```

Notes:

- `--uninstall` lists matching installed paths and installer artifacts, asks for `y/N`, and removes them only on confirmation.
- `./scripts/install.sh --all` installs or updates every runtime home that already exists under `~/.agents`, `~/.claude`, and `~/.openclaw`.
- `./scripts/install.sh` installs the canonical `[CDD-8] Master Chef` package on core single-agent targets and the same package plus generated OpenClaw Builder skills on OpenClaw targets.
- `./scripts/install-openclaw.sh` remains only as a deprecated compatibility wrapper around `./scripts/install.sh --runtime openclaw`.
- If newly installed or updated skills do not appear, start a new session or restart the runtime.

## Start Here

For the core single-agent workflow:

- install the Builder skill pack
- use `[CDD-0] Boot` when the repo is already CDD-ready and you want a one-time vanilla AGENTS boot before working directly
- use `[CDD-7] Maintain` when you want archive cleanup, support-doc review, and code-health review without entering a normal implementation step
- use `[CDD-1] Init Project`, `[CDD-2] Plan`, `[CDD-3] Implement TODO`, `[CDD-5] Refactor`, and `[CDD-6] Index` directly from Codex CLI or Claude Code when you want the structured CDD loop

For `[CDD-8] Master Chef`:

- install the full repo skill set for Codex or Claude Code with `npx skills add https://github.com/ruphware/cdd-skills/ --skill '*' -a codex -a claude-code -g`, or use `./scripts/install.sh --all`
- for OpenClaw, use `./scripts/install.sh --runtime openclaw` or `./scripts/install.sh --all` so the internal Builder skills are generated too
- start `cdd-master-chef` from the main session for the runtime you want to control, such as `$cdd-master-chef` in Codex or `/cdd-master-chef` in Claude Code or OpenClaw
- provide one Run config block with `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`, or omit it and let Master Chef recommend one from the current session model and thinking, then approve or edit that recommendation before kickoff
- let Master Chef inspect the repo, propose the next TODO step, ask how many TODO steps this run should cover, ask whether it should spawn Builder now, set up `.cdd-runtime/master-chef/`, and ask for kickoff confirmation before autonomous execution begins
- after kickoff, expect Master Chef to manage one-step Builder runs, QA, UAT evidence, commits, pushes, and blocker reporting in the main session

Adapter docs are for maintainers, debugging, and adding runtime support. Use `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md` for Codex-specific adapter behavior, `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md` for Claude Code-specific adapter behavior, and `cdd-master-chef/openclaw/` for the OpenClaw adapter.


## License

Free-to-use-adjust-just-don't-blame-me-for-anything-licence. _Peace._ ✌️

___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)
<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `[CDD-0] Boot`. Use `[CDD-2] Plan` + `[CDD-3] Implement TODO` for feature work, `[CDD-7] Maintain` for upkeep and drift control, and `[CDD-5] Refactor` for structured refactors.</sup>
