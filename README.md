# 🚀 Autonomous Agent Development in CDD Guardrails

**AI agents build. CDD keeps control.**

CDD Skills wrap agentic coding in the guardrails busy developers need: scoped plans, auditable TODO steps, isolated worktrees, validation evidence, and clear human approval points.

Use the core skills for precise human-guided work. Use Master Chef when the plan is ready for bounded autonomous execution.

Powered by [cdd-boilerplate](https://github.com/ruphware/cdd-boilerplate), CDD helps you:

* Turn intent into TODO contracts.
* Keep approval at the right checkpoints.
* Let agents move without drifting.
* Audit shipped work against goals, checks, and UAT.
* Run autonomous missions when the work is ready.

---

## 🧑‍🍳 Master Chef: Bounded Autonomous Development

Approve once, set a step budget, and Master Chef works through TODO steps in an isolated worktree with persistent Builder context, recovery rules, commits, pushes, and a final mission report.

Why use it:

* One kickoff approval controls how far the run can go.
* Branch-backed worktrees keep autonomous changes isolated and reviewable.
* Persistent Builder sessions carry context across steps instead of starting cold every time.
* Oversized work is reviewed first and split only when the split cost is justified.
* Mission reports make the result auditable: completed steps, checks, pushes, decisions, and next actions.

Start `cdd-master-chef` from the main session for the runtime you want to control:

```bash
$cdd-master-chef  # Codex runtime
/cdd-master-chef  # Claude Code or OpenClaw runtime
```

---

## 🛠️ Skill Map

The core loop is intentionally simple: boot context, plan work, implement one step, audit the result.

- **[CDD-0] Boot** 
 *cdd-boot*
 Ingest AGENTS.md, project docs, and current work context; decide whether to stay in the current checkout, continue in a linked worktree, or create a branch-backed worktree under .cdd-runtime/worktrees/. 

- **[CDD-1] Init Project**
 *cdd-init-project*
 Initialize or adopt CDD in the current repo. *gh is a great tool to have when the repo is GitHub-backed.* 

- **[CDD-2] Plan**
 *cdd-plan*
 Convert change requests or audit findings into implementation-ready TODO steps. 

- **[CDD-3] Implement TODO**
 *cdd-implement-todo*
  Implement exactly one approved TODO step and mark it done. 

- **[CDD-4] Implementation Audit**
 *cdd-implementation-audit*
 Audit spec, code, tests, complexity, and docs, then route approved follow-up into planning. 

- **[CDD-5] Maintain**
 *cdd-maintain*
 Review doc drift and repo upkeep, run source cleanup sweeps, refresh indexes, and audit refactor candidates.

- **[CDD-6] Master Chef**
 *cdd-master-chef*
 Run the autonomous multi-step workflow through the canonical Master Chef skill and runtime adapters.
 
---

## 📦 Quick Install & Update

No-clone install or upgrade for detected default runtime homes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all
```

No-clone update:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all --update --yes
```

Uninstall:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/uninstall-remote.sh) --all
```

Use the local installer when you want a specific runtime, target directory, or direct control.

---

## 🔧 Adapters & Runtimes

Current concrete Master Chef adapters:

* **OpenClaw** — packaged adapter installed with `./scripts/install.sh --runtime openclaw`
* **Codex** — subagent-backed adapter docs in `cdd-master-chef/CODEX-ADAPTER.md` and `cdd-master-chef/CODEX-RUNBOOK.md`
* **Claude Code** — subagent-backed adapter docs in `cdd-master-chef/CLAUDE-ADAPTER.md` and `cdd-master-chef/CLAUDE-RUNBOOK.md`

Runtime details live in:

* [`cdd-master-chef/RUNBOOK.md`](cdd-master-chef/RUNBOOK.md)
* [`cdd-master-chef/CODEX-ADAPTER.md`](cdd-master-chef/CODEX-ADAPTER.md)
* [`cdd-master-chef/CLAUDE-ADAPTER.md`](cdd-master-chef/CLAUDE-ADAPTER.md)
* [`cdd-master-chef/RUNTIME-CAPABILITIES.md`](cdd-master-chef/RUNTIME-CAPABILITIES.md)
* [`cdd-master-chef/openclaw/README.md`](cdd-master-chef/openclaw/README.md)

No Hermes adapter ships in this repo today.

---

## 📖 Typical Workflows

* **Human-guided feature work:** `[CDD-0] Boot` → `[CDD-2] Plan` → `[CDD-3] Implement TODO`.
* **Post-implementation review:** `[CDD-4] Implementation Audit` → `[CDD-2] Plan` for approved follow-up.
* **Repo upkeep:** `[CDD-5] Maintain` for doc drift, source cleanup, index refresh, and refactor review.
* **Autonomous delivery:** `[CDD-6] Master Chef` for controlled multi-step execution after kickoff approval.

---

## 🛠 Manual Install

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
./scripts/install.sh
```

Common variants:

```bash
./scripts/install.sh --all
./scripts/install.sh --runtime claude
./scripts/install.sh --runtime openclaw
./scripts/install.sh --help
```

---

## 🚩 Optional NPX Path

Quick first install for Codex, Claude Code, and Gemini CLI only:

```bash
npx skills add https://github.com/ruphware/cdd-skills/ --skill cdd-boot --skill cdd-init-project --skill cdd-plan --skill cdd-implement-todo --skill cdd-implementation-audit --skill cdd-maintain --skill cdd-master-chef -a codex -a claude-code -a gemini-cli -g
```

This path does not provide the repo-managed update or uninstall flow and does not preserve managed prune semantics.

---

## 📜 License

Free-to-use-adjust-just-don't-blame-me-for-anything-license. ✌️

---

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)

*This repository follows the structured [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) and [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow using the local [`AGENTS.md`](./AGENTS.md) contract.*
