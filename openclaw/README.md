# Master Chef (Codex CLI over ACP) — Dev Convention

This folder defines the **Master Chef** development convention:

- **Master Chef (OpenClaw):** planning, delegation, QA gate, pass/fail.
- **Builder (Codex via ACP/acpx):** implementation worker for one approved step.
- **CDD-first policy:** if a `cdd-*` skill exists for the phase, use it first.

## Files

- `MASTER-CHEF-RUNBOOK.md` — canonical process + hard QA gate.
- `MASTER-CHEF-TEST-HARNESS.md` — quick end-to-end validation of the loop.

## Master Chef runtime defaults (OpenClaw)

- `openai-codex/gpt-5.3-codex`
- reasoning: `xhigh`
- role: technical leader + step-level final decider (human still does final result sign-off)

## Builder runtime defaults (Codex)

These are **Codex CLI** settings (not OpenClaw `/model`):

- `model = "gpt-5.4"`
- `model_reasoning_effort = "xhigh"`
- Previous default: `gpt-5.2` @ `xhigh`

### OpenClaw model vs ACP/Codex model

- ` /model ... ` controls OpenClaw’s own LLM.
- ` /acp model ... ` and ` /acp set ... ` control the Builder harness (Codex).

Do not treat `gpt-5.4` as an OpenClaw `openai-codex/...` model ref.

## CDD-first usage map (Builder should lean on this heavily)

Use these by default:

- `cdd-init-project` — bootstrap/adopt CDD for repo
- `cdd-plan` — convert scope into approval-ready TODO plan
- `cdd-implement-todo` — implement exactly one approved TODO step
- `cdd-index` — refresh architecture/index context
- `cdd-audit-and-implement` — audit findings -> TODOs -> implement first approved step
- `cdd-refactor` — build refactor plan from index

Rule:

- If a matching `cdd-*` skill exists, Builder must use it.
- Freeform/manual coding is fallback-only (must be justified explicitly).

## How to set model + reasoning for ACP/Codex

### Option A (recommended): defaults in `~/.codex/config.toml`

```toml
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
```

### Option B: per ACP session override

```text
/acp model gpt-5.4
/acp set model_reasoning_effort xhigh
```

Under the hood:

- `/acp set <key> <value>` -> `acpx codex set <key> <value> --session <name>`

## Quick start (typical loop)

1) Spawn Builder session:

```text
/acp spawn codex --mode persistent --thread off --cwd /abs/path/to/repo
```

2) Pin Builder model/effort (optional if already in `~/.codex/config.toml`):

```text
/acp model gpt-5.4
/acp set model_reasoning_effort xhigh
```

3) Run CDD-first workflow:

- Refresh context if needed: `cdd-index`
- Plan: `cdd-plan` (draft first, approval-gated)
- Implement approved step: `cdd-implement-todo` (one step only)
- For audit/refactor tracks: `cdd-audit-and-implement` / `cdd-refactor`

4) Master Chef QA gate (scope, checks, docs, evidence), then UAT.
   - If inconsistencies/gaps appear, Master Chef must interrogate Builder assumptions with evidence and decide factual correctness before PASS.

## Preflight checks

- ACP backend healthy:
  - `/acp doctor`
- Codex installed:
  - `codex --version`
- Required CDD skills available:
  - `ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null`
