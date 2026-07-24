# CDD Skills: controlled autonomous coding

**Plan once. Approve the run. Let agents work while you sleep.**

Skills for Codex and Claude Code that keep long agent runs on a leash: you plan into TODO steps, approve the kickoff, and get back an isolated branch plus a mission report.

**Master Chef** is the multi-step runner. It walks those TODO steps with recovery, commits, and checks so you can review in the morning instead of babysitting every edit.

Powered by [cdd-boilerplate](https://github.com/ruphware/cdd-boilerplate).

---

## 30-second path

```sh
# 1) Install (Codex + Claude defaults)
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all

# 2) Runtime permissions so the run does not stall on tool prompts:
#    Codex  → Permissions: approve for me
#    Claude → permission mode: Auto

# 3) In a CDD repo: plan → readiness check → autonomous run
$cdd-plan docs/specs/blueprint.md into TODO.md
$cdd-audit TODO.md and confirm cdd-master-chef readiness
$cdd-master-chef TODO.md all steps, session gpt-5.6 max builder gpt-5.6 high, worktree and branch todo-123
```

Use `$cdd-*` in Codex; `/cdd-*` (or your runtime's skill entry) in Claude Code.

Swap the model names for whatever your session actually runs. Session model must match the live session.

---

## Master Chef

Built for unattended runs you can still merge after review.

| | |
|---|---|
| **What it does** | Walks runnable TODO steps end to end in a branch-backed worktree |
| **Why trust it** | One kickoff approval, paced execution, checks, commits, mission report |
| **Budget** | Predictable token use from careful pacing, not a free-form agent ramble |
| **Required input** | A CDD TODO from `$cdd-plan` (or equivalent chunked steps). No plan, no run. |

### Prerequisites, then how the run stays reviewable

1. **`$cdd-plan` first** so `TODO.md` has bounded, checkable steps. Master Chef executes a plan; it does not invent one.
2. **`$cdd-audit` (recommended)** to confirm step size and Master Chef readiness before a long run.
3. **One kickoff approval** sets how far the run can go.
4. **Branch-backed worktrees** keep changes isolated until you review.
5. **Persistent Builder context** carries knowledge across steps instead of starting cold each time.
6. **Oversized work** is reviewed first; split only when the split cost is justified.
7. **Wave-parallel (opt-in):** TODO steps annotated with `deps:` / `touches:` can run declared-disjoint work as bounded waves with a serial merge queue.
8. **Mission report** records completed steps, checks, pushes, decisions, and next actions.

```sh
$cdd-plan docs/specs/blueprint.md into TODO.md
$cdd-audit TODO.md and confirm cdd-master-chef readiness
$cdd-master-chef TODO.md all steps, session gpt-5.6 max builder gpt-5.6 high, worktree and branch todo-123
```

> [!NOTE]
> Session model must match the running session. Example above uses `gpt-5.6 max` + builder `gpt-5.6 high`; change both to your stack.
>
> Runtime tool permissions are separate from Master Chef's one-time kickoff approval. For long runs, set Codex **Permissions → approve for me**, or Claude **permission mode → Auto**, so shell/tool calls do not block overnight.

### Runtime-native alternatives

Codex: `/goal $cdd-implement TODO.md all undone steps`  
Claude: `/workflows $cdd-implement TODO.md all undone steps`

These skip Master Chef's orchestration (worktree lifecycle, recovery, mission report). Prefer Master Chef for multi-step unattended delivery; watch spend on long native loops.

Start Master Chef via `$cdd-master-chef` (Codex) or `/cdd-master-chef` (Claude Code).

---

## When to use what

| You want | Use |
|----------|-----|
| Overnight / multi-step autonomous delivery | **Plan** (+ audit), then **Master Chef** |
| One bounded change with you in the loop | Boot → Plan → Implement |
| Review shipped work or a proposal | Audit → Plan approved follow-up |
| Doc drift, cleanup, index, refactor sweep | Maintain |
| New or non-CDD repo | Init Project |

**Human-guided:** Boot → Plan → Implement  
**Review:** Audit → Plan  
**Autonomous:** Plan → Audit (readiness) → Master Chef

---

## Skill map

Core loop: boot context, plan work, implement one step, audit the result. Master Chef runs the loop unattended once the plan is ready.

| | Skill | When |
|---|--------|------|
| **[CDD-0]** | `cdd-boot` | Load repo context; route to the right next skill or vanilla work |
| **[CDD-1]** | `cdd-init-project` | Adopt CDD in the current repo (`gh` helps on GitHub) |
| **[CDD-2]** | `cdd-plan` | Turn a change request or audit findings into TODO steps |
| **[CDD-3]** | `cdd-implement` | Ship exactly one bounded task (TODO-backed preferred) |
| **[CDD-4]** | `cdd-audit` | Goal-fit review with proportional proof; route follow-up to plan |
| **[CDD-5]** | `cdd-maintain` | Doc drift, cleanup, indexes, refactor candidates |
| **[CDD-6]** | `cdd-master-chef` | Controlled multi-step autonomous execution |

---

## Install

### Fastest (no clone)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all
```

Update:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/install-remote.sh) --all --update --yes
```

Uninstall:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ruphware/cdd-skills/main/uninstall-remote.sh) --all
```

### Local clone (specific runtime or target)

```bash
git clone git@github.com:ruphware/cdd-skills.git
cd cdd-skills
./scripts/install.sh --all          # or --runtime claude
./scripts/install.sh --help
```

### Optional NPX (first install only)

Codex, Claude Code, and Gemini CLI. No managed update/uninstall or prune semantics; prefer the scripts above for day-to-day.

```bash
npx skills add https://github.com/ruphware/cdd-skills/ \
  --skill cdd-boot --skill cdd-init-project --skill cdd-plan \
  --skill cdd-implement --skill cdd-audit --skill cdd-maintain \
  --skill cdd-master-chef -a codex -a claude-code -a gemini-cli -g
```

Gemini gets the core skills path; concrete Master Chef adapters today are **Codex** and **Claude Code**.

---

## Adapters & runtimes

| Runtime | Docs |
|---------|------|
| **Codex** | [`CODEX-ADAPTER.md`](skills/cdd-master-chef/CODEX-ADAPTER.md) · [`CODEX-RUNBOOK.md`](skills/cdd-master-chef/CODEX-RUNBOOK.md) |
| **Claude Code** | [`CLAUDE-ADAPTER.md`](skills/cdd-master-chef/CLAUDE-ADAPTER.md) · [`CLAUDE-RUNBOOK.md`](skills/cdd-master-chef/CLAUDE-RUNBOOK.md) |

Shared:

- [`RUNBOOK.md`](skills/cdd-master-chef/RUNBOOK.md)
- [`RUNTIME-CAPABILITIES.md`](skills/cdd-master-chef/RUNTIME-CAPABILITIES.md)

---

## License

Free-to-use-adjust-just-don't-blame-me-for-anything-license. ✌️

---

[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)
[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)

*Structured [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow via local [`AGENTS.md`](./AGENTS.md).*
