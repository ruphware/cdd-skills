# Chat Driven Development Skills

These skills support a human-in-the-loop development workflow. Results are better when agentic software engineering is controlled.

No skill runs on its own. The driver stays in control and invokes the skill they need, when they need it.

## Quick Install

Install or upgrade through the repo-managed no-clone wrapper:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all
```

## Quick Uninstall

Remove managed installs through the matching no-clone wrapper:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/uninstall-remote.sh) --all
```

## Skill Map

- `[CDD-0] Boot` — `cdd-boot` — ingest `AGENTS.md` plus project and development docs for vanilla AGENTS-driven work and recommend whether to stay in the main folder or move into a worktree
- `[CDD-1] Init Project` — `cdd-init-project` — init or adopt the CDD workflow in the current folder
- `[CDD-2] Plan` — `cdd-plan` — plan change requests or external audit findings into implementation-ready TODO steps
- `[CDD-3] Implement TODO` — `cdd-implement-todo` — implement exactly one TODO step and mark that step done on success
- `[CDD-4] Implementation Audit` — `cdd-implementation-audit` — audit a selected implementation scope for spec, code, test, complexity, and documentation findings, then route approved follow-up into planning
- `[CDD-5] Refactor` — `cdd-refactor` — create a refactor TODO plan from the current index
- `[CDD-6] Index` — `cdd-index` — regenerate `docs/INDEX.md`
- `[CDD-7] Maintain` — `cdd-maintain` — archive long CDD files, audit support-doc drift, review repo-local runtime cleanup for approval, and doctor the codebase for refactor and dead-code signals
- `[CDD-8] Master Chef` — `cdd-master-chef` — start the autonomous development process through the canonical Master Chef package and its current runtime adapters

## What's Included

- `skills/` contains the flat `[CDD-0]` through `[CDD-7]` skill pack for direct, human-approved work.
- `cdd-master-chef/` contains `[CDD-8] Master Chef`, its shared contract, runbook, runtime matrix, and adapter docs.
- The unified installer ships all skills to generic/Codex-style, Claude Code, and OpenClaw installs. On OpenClaw it also generates internal Builder variants from `skills/`.

Current concrete adapters in this repo:

- OpenClaw — packaged adapter installed with `./scripts/install.sh --runtime openclaw`
- Codex — subagent-backed adapter docs in `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md`
- Claude Code — subagent-backed adapter docs in `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md`
- No Hermes adapter ships in this repo today.

## General Workflow

- Use the core `$cdd-*` loop when you want a single coding agent, explicit human approvals, and one approved TODO step at a time.
- Use `[CDD-0] Boot` to load `AGENTS.md`, project docs, and current work context before working directly.
- Use `[CDD-1] Init Project` for new or newly adopted repos, `[CDD-2] Plan` plus `[CDD-3] Implement TODO` for feature work, and `[CDD-4] Implementation Audit` plus `[CDD-2] Plan` when audit findings should become TODO work.
- Use `[CDD-5] Refactor`, `[CDD-6] Index`, and `[CDD-7] Maintain` when refactor planning, index refresh, or maintenance is the actual task.
- Use `$cdd-master-chef` when you want an autonomous run after kickoff approval and one of the current concrete adapters fits your runtime.

For `[CDD-8] Master Chef`:

- start `cdd-master-chef` from the main session for the runtime you want to control, such as `$cdd-master-chef` in Codex or `/cdd-master-chef` in Claude Code or OpenClaw
- provide a Run config block with `master_model`, `master_thinking`, `builder_model`, and `builder_thinking`, or let Master Chef recommend one from the current session model and thinking, then approve or edit it
- on a fresh run from a long-lived branch, Master Chef can suggest a descriptive feature branch; when the active TODO has a finite remaining unfinished top-level step-heading count, it recommends that exact count as the default/max step budget
- Master Chef inspects the repo, proposes the next TODO step, may split an oversized top-level step before Builder handoff, sets up `.cdd-runtime/master-chef/`, and asks how many TODO steps this run should cover
- kickoff asks whether Master Chef should spawn Builder now; after approval, Master Chef manages fresh single-step Builder runs, QA, UAT evidence, commits, pushes, and blocker reporting
- Adapter docs are for maintainers, debugging, and adding runtime support: use `cdd-master-chef/RUNBOOK.md`, `cdd-master-chef/CODEX-ADAPTER.md`, `cdd-master-chef/CODEX-RUNBOOK.md`, `cdd-master-chef/CLAUDE-ADAPTER.md`, `cdd-master-chef/CLAUDE-RUNBOOK.md`, `cdd-master-chef/RUNTIME-CAPABILITIES.md`, and `cdd-master-chef/openclaw/`

## Recommended tools

- `git` — effectively required
- `gh` — recommended when working with GitHub-backed repos
- `bash` — required for the install scripts
- `python3` — required for OpenClaw Builder skill generation and recommended for local validation
- writable local repos — required because the Builder edits target workspaces

## Manual Install

If you want a local checkout and the repo-managed install scripts instead of the optional `npx skills` path below:

Clone the repo:

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
```

Install the core Builder skills plus the canonical `[CDD-8] Master Chef` package for Codex CLI or similar single-agent runtimes:

```bash
./scripts/install.sh
```

For no-clone install or uninstall, use the Quick Install and Quick Uninstall wrappers above.

Common local installs:

```bash
./scripts/install.sh --all
./scripts/install.sh --runtime claude
./scripts/install.sh --runtime openclaw
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

No-clone upgrade path:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all --update --yes
```

If the install target already contains one of the managed skill directories, rerunning the installer without `--update` fails by design.

Builder update automatically runs the conservative prune logic. It also deletes retired `cdd-audit-and-implement` leftovers, including visible `cdd-audit-and-implement.pruned.*` artifacts. Use `--yes` if you want to auto-confirm prune prompts in non-interactive contexts:

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
- `install-remote.sh` is the no-clone install and update wrapper: it downloads the repo tarball and forwards all flags to `./scripts/install.sh`.
- `uninstall-remote.sh` is the no-clone uninstall wrapper: it downloads the repo tarball and forwards all flags to `./scripts/install.sh --uninstall`.
- `./scripts/install-openclaw.sh` remains only as a deprecated compatibility wrapper around `./scripts/install.sh --runtime openclaw`.
- If newly installed or updated skills do not appear, start a new session or restart the runtime.

## Optional `npx skills` Path

Supported for first installs on Codex, Claude Code, and Gemini CLI only. It does not generate OpenClaw Builder skills, and upgrades or uninstall do not get this repo's managed prune semantics. Prefer `install-remote.sh` and `uninstall-remote.sh`.

```bash
npx skills add https://github.com/ruphware/cdd-skills/ --skill cdd-boot --skill cdd-init-project --skill cdd-plan --skill cdd-implement-todo --skill cdd-implementation-audit --skill cdd-refactor --skill cdd-index --skill cdd-maintain --skill cdd-master-chef -a codex -a claude-code -a gemini-cli -g
```

## License

Free-to-use-adjust-just-don't-blame-me-for-anything-licence. _Peace._ ✌️

___

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)
<sup>This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.</sup>
<sup>Start with `[CDD-0] Boot`. Use `[CDD-4] Implementation Audit` for implementation or codebase audits, `[CDD-2] Plan` + `[CDD-3] Implement TODO` for feature work, `[CDD-7] Maintain` for upkeep and drift control, and `[CDD-5] Refactor` for structured refactors.</sup>
