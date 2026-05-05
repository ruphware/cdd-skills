# Chat Driven Development (CDD) Skills

These skills support a human-in-the-loop development workflow, ensuring controlled agentic software engineering, respecting the simple project structure defined by [cdd-boilerplate](https://github.com/ruphware/cdd-boilerplate).

Skills never run autonomously; the developer invokes each skill surgically, when needed.

## Skill Map

**Core workflow**

- **[CDD-0] Boot**  
  *`cdd-boot`*  
  Ingest `AGENTS.md`, project docs, and current work context; decide whether to stay in the current checkout, continue in a linked worktree, or create a branch-backed worktree under `.cdd-runtime/worktrees/`.

- **[CDD-1] Init Project**  
  *`cdd-init-project`*  
  Initialize or adopt CDD in the current repo. *`gh` is a great tool to have when the repo is GitHub-backed.*

- **[CDD-2] Plan**  
  *`cdd-plan`*  
  Convert change requests or audit findings into implementation-ready TODO steps.

- **[CDD-3] Implement TODO**  
  *`cdd-implement-todo`*  
  Implement exactly one approved TODO step and mark it done.

- **[CDD-4] Implementation Audit**  
  *`cdd-implementation-audit`*  
  Audit spec, code, tests, complexity, and docs, then route approved follow-up into planning.

- **[CDD-5] Maintain**  
  *`cdd-maintain`*  
  Address doc drift, refresh indexes, sweep approved leftovers, and plan cleanup or refactors.

**Autonomous workflow**

- **[CDD-6] Master Chef**  
  *`cdd-master-chef`*  
  Run the autonomous multi-step workflow through the canonical Master Chef skill and runtime adapters.

## Quick Install (and Uninstall)

Install or upgrade through the repo-managed no-clone wrapper:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all
```

Uninstall through the matching no-clone wrapper:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/uninstall-remote.sh) --all
```

## What's Included

- `skills/` contains the flat `[CDD-0]` through `[CDD-5]` skill pack for direct, human-approved work.
- `cdd-master-chef/` contains `[CDD-6] Master Chef`, its shared contract, runbook, runtime matrix, and adapter docs.
- The unified installer ships all skills to generic/Codex-style, Claude Code, and OpenClaw installs. On OpenClaw it also generates internal Builder variants from `skills/`.

Current concrete adapters in this repo:

- OpenClaw — packaged adapter installed with `./scripts/install.sh --runtime openclaw`
- Codex — subagent-backed adapter docs in `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md`
- Claude Code — subagent-backed adapter docs in `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md`
- No Hermes adapter ships in this repo today.

## General Workflow

- Use the core `$cdd-*` loop when you want a single coding agent, explicit human approvals, and one approved TODO step at a time.
- Start with `[CDD-0] Boot` to load `AGENTS.md`, project docs, and current work context, then decide whether to keep working in the current checkout or move into a branch-backed worktree.
- Use `[CDD-1] Init Project` for new or newly adopted repos; use `[CDD-2] Plan` plus `[CDD-3] Implement TODO` for feature work.
- Use `[CDD-4] Implementation Audit` plus `[CDD-2] Plan` when audit findings should become TODO work.
- Use `[CDD-5] Maintain` for doc drift, codebase cleanup, index refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review.
- Use `cdd-master-chef` when you want an autonomous run after kickoff approval and one of the current concrete adapters fits your runtime.

For `[CDD-6] Master Chef`:

- start `cdd-master-chef` from the main session for the runtime you want to control, such as `$cdd-master-chef` in Codex or `/cdd-master-chef` in Claude Code or OpenClaw.
- Provide a Run config block with `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`, or let Master Chef recommend one from the current session model and thinking, then approve or edit it.
- On a fresh run from a long-lived branch, Master Chef can suggest a descriptive feature branch. When the active TODO has a finite remaining unfinished top-level step-heading count, it recommends that exact count as the default/max step budget.
- Master Chef inspects the repo, proposes the next TODO step, may split an oversized top-level step before Builder handoff, sets up `.cdd-runtime/master-chef/`, and asks how many TODO steps this run should cover.
- Kickoff asks whether Master Chef should spawn Builder now. After approval, Master Chef manages fresh single-step Builder runs, QA, UAT evidence, commits, pushes, and blocker reporting.
- Adapter docs are for maintainers, debugging, and runtime support: `cdd-master-chef/RUNBOOK.md`, `cdd-master-chef/CODEX-ADAPTER.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-ADAPTER.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, `cdd-master-chef/RUNTIME-CAPABILITIES.md`, and `cdd-master-chef/openclaw/`.

## Manual Install

Use a local checkout when you want the repo-managed scripts directly instead of the optional `npx skills` path below.

1. Clone the repo:

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
```

2. Install the default package for Codex CLI or similar single-agent runtimes:

```bash
./scripts/install.sh
```

3. Common variants:

```bash
./scripts/install.sh --all
./scripts/install.sh --runtime claude
./scripts/install.sh --runtime openclaw
./scripts/install.sh --target ~/.agents/skills
./scripts/install.sh --runtime claude --target ~/.claude/skills
./scripts/install.sh --runtime openclaw --target ~/.openclaw/skills
```

Run `./scripts/install.sh --help` for the full flag set. The no-clone wrappers above also support `--help`.

## Update

Use `--update` from a local checkout; add `--all` to refresh every existing default runtime home.

```bash
cd cdd-skills
git pull
./scripts/install.sh --all --update
./scripts/install.sh --update
./scripts/install.sh --runtime openclaw --update
```

No-clone upgrade path:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all --update --yes
```

If the install target already contains one of the managed skill directories, rerun with `--update`; without it the installer fails by design. Builder update automatically runs the conservative prune logic and removes retired `cdd-audit-and-implement`, `cdd-index`, and `cdd-refactor` leftovers, including visible `.pruned.*` artifacts. Use `--yes` to auto-confirm managed or obviously invalid prune prompts in non-interactive contexts.

## Uninstall

Use the local script from a checkout, or the `uninstall-remote.sh` wrapper above when you do not want a clone.

```bash
./scripts/install.sh --all --uninstall
./scripts/install.sh --uninstall
./scripts/install.sh --runtime openclaw --uninstall
```

`--uninstall` lists matching installed paths and installer artifacts, asks for `y/N`, and removes them only on confirmation. `install-remote.sh` is the no-clone install and update wrapper, `uninstall-remote.sh` is the matching no-clone uninstall wrapper, and `./scripts/install-openclaw.sh` remains only as a deprecated compatibility wrapper around `./scripts/install.sh --runtime openclaw`. If newly installed or updated skills do not appear, start a new session or restart the runtime.

## Optional `npx skills` Path

Supported for first installs on Codex, Claude Code, and Gemini CLI only. It does not generate OpenClaw Builder skills, and upgrades or uninstall do not get this repo's managed prune semantics. Prefer `install-remote.sh` and `uninstall-remote.sh`.

```bash
npx skills add https://github.com/ruphware/cdd-skills/ --skill cdd-boot --skill cdd-init-project --skill cdd-plan --skill cdd-implement-todo --skill cdd-implementation-audit --skill cdd-maintain --skill cdd-master-chef -a codex -a claude-code -a gemini-cli -g
```

## License

Free-to-use-adjust-just-don't-blame-me-for-anything-licence. _Peace._ ✌️

___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)
<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `[CDD-0] Boot`. Use `[CDD-4] Implementation Audit` for implementation or codebase audits, `[CDD-2] Plan` + `[CDD-3] Implement TODO` for feature work, and `[CDD-5] Maintain` for doc drift, codebase cleanup, index refresh, refactor architecture audit, and upkeep.</sup>
