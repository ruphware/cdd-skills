# 🚀 Autonomous Agent Development in Chat Driven Development Guardrails

**Gen AI for code generation. CDD for control.**

CDD Skills wrap agentic coding in the guardrails busy developers need: scoped plans, auditable TODO steps, isolated worktrees, validation evidence, and clear human approval points.

Use the core skills for precise human-guided work. Use Master Chef when the plan is ready for autonomous execution.

Powered by [cdd-boilerplate](https://github.com/ruphware/cdd-boilerplate).

---

## 📖 Typical Workflows

* **Human-guided feature work:** `[CDD-0] Boot` → `[CDD-2] Plan` → `[CDD-3] Implement`.
* **Post-implementation review:** `[CDD-4] Audit` → `[CDD-2] Plan` for approved follow-up.
* **Repo upkeep:** `[CDD-5] Maintain` for doc drift, source cleanup, index refresh, and refactor review.
* **Autonomous delivery:** `[CDD-6] Master Chef` for controlled multi-step execution after kickoff approval.

Here's a refined version for your `cdd-skills` repo README section:

---

## Autonomous Development

Multiple ways to run autonomous development steps using CDD boilerplate:

### 1. Codex `/goal $cdd-implement TODO.md all undone steps`

* **Reliability:** ⚠️ Can be unreliable on `gpt-5.4 xhigh`.

### 2. Claude `/workflows $cdd-implement TODO.md all undone steps`

* **Reliability:** ✅ Works well and fast on `Opus 4.8 xhigh`.
* **Token use:** Can be token-hungry, watch your budget.

### 3. 🧑‍🍳 Master Chef `$cdd-master-chef TODO.md all steps`

* **Process:** Executes each step methodically in a highly controlled manner.
* **Reliability:** ✅ Highly dependable; ideal for unattended runs (e.g., overnight).
* **Budget:** Predictable token usage due to careful pacing; avoids excessive costs.
* **Performance:** Might be slower compared to Claude.

#### Quickstart for Master Chef

```sh
$cdd-plan docs/specs/blueprint.md into TODO.md
# Optional audit step:
$cdd-audit TODO.md and confirm cdd-master-chef readiness
$cdd-master-chef TODO.md all steps, session gpt-5.5 xhigh builder gpt-5.4 xhigh, worktree and branch todo-123
```

> [!NOTE]
> The session model is fixed to ensure smooth operation and consistency. In the authors’ opinion, gpt-5.5 xhigh is better for longer-running tasks, while gpt-5.4 xhigh is better for detailed work, albeit slower.

> [!TIP]
> Autonomous runs work best with well-defined, properly chunked steps. Run `$cdd-audit TODO.md and confirm it's cdd-master-chef ready` first to review and adjust step size.

### How does it work?

Master Chef works through runnable TODO steps in a branch-backed worktree, with persistent Builder context, recovery rules, commits, pushes, and a final mission report.

* One kickoff approval controls how far the run can go.
* Branch-backed worktrees keep autonomous changes isolated and reviewable.
* Persistent Builder sessions carry context across steps instead of starting cold every time.
* Oversized work is reviewed first and split only when the split cost is justified.
* Mission reports make the result auditable: completed steps, checks, pushes, decisions, and next actions.

Start `cdd-master-chef` via `$cdd-master-chef` for Codex or `/cdd-master-chef` for Claude Code or OpenClaw runtime.

---

## 🛠️ Skill Map

The core loop is intentionally simple: boot context, plan work, implement one step, audit the result.

- **[CDD-0] Boot**
 *cdd-boot*
 Read the repo's root entrypoints first; in scaled repos follow only one relevant split lane or body when needed, then use a specialized `cdd-*` continuation only when it adds real leverage, otherwise hand back to vanilla AGENTS-driven work, with a branch-backed worktree under `.cdd-runtime/worktrees/` when warranted.

- **[CDD-1] Init Project**
 *cdd-init-project*
 Initialize or adopt CDD in the current repo. *gh is a great tool to have when the repo is GitHub-backed.*

- **[CDD-2] Plan**
 *cdd-plan*
 Convert change requests or audit findings into implementation-ready TODO steps.

- **[CDD-3] Implement**
 *cdd-implement*
 Implement exactly one bounded task; prefer TODO-backed steps and use direct mode only when the task is already decision-complete.

- **[CDD-4] Audit**
 *cdd-audit*
 Audit intent and goal match first, using the right audit shape, depth, and proof surfaces, then route approved follow-up into planning.

- **[CDD-5] Maintain**
 *cdd-maintain*
 Review doc drift and repo upkeep, run source cleanup sweeps, refresh indexes, and audit refactor candidates.

- **[CDD-6] Master Chef**
 *cdd-master-chef*
 Run the autonomous multi-step workflow through the canonical Master Chef skill and runtime adapters.

---

## 📦 Quick Install & Update

> [!TIP]
> Fastest path — no-clone install or upgrade for all detected default runtime homes:
>
> ```bash
> bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all
> ```

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

* **Codex** — subagent-backed adapter docs in `skills/cdd-master-chef/CODEX-ADAPTER.md` and `skills/cdd-master-chef/CODEX-RUNBOOK.md`
* **Claude Code** — subagent-backed adapter docs in `skills/cdd-master-chef/CLAUDE-ADAPTER.md` and `skills/cdd-master-chef/CLAUDE-RUNBOOK.md`
* **OpenClaw** — packaged adapter installed with `./scripts/install.sh --runtime openclaw`

Runtime details live in:

* [`skills/cdd-master-chef/RUNBOOK.md`](skills/cdd-master-chef/RUNBOOK.md)
* [`skills/cdd-master-chef/CODEX-ADAPTER.md`](skills/cdd-master-chef/CODEX-ADAPTER.md)
* [`skills/cdd-master-chef/CLAUDE-ADAPTER.md`](skills/cdd-master-chef/CLAUDE-ADAPTER.md)
* [`skills/cdd-master-chef/RUNTIME-CAPABILITIES.md`](skills/cdd-master-chef/RUNTIME-CAPABILITIES.md)
* [`skills/cdd-master-chef/openclaw/README.md`](skills/cdd-master-chef/openclaw/README.md)

---

## 🛠️ Manual Install

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
npx skills add https://github.com/ruphware/cdd-skills/ --skill cdd-boot --skill cdd-init-project --skill cdd-plan --skill cdd-implement --skill cdd-audit --skill cdd-maintain --skill cdd-master-chef -a codex -a claude-code -a gemini-cli -g
```

This path does not provide the repo-managed update or uninstall flow and does not preserve managed prune semantics.

---

## 📜 License

Free-to-use-adjust-just-don't-blame-me-for-anything-license. ✌️

---

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)

*This repository follows the structured [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) and [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow using the local [`AGENTS.md`](./AGENTS.md) contract.*
