# Master Chef Runbook (v3 — ACP + CDD-first)

## 0) Purpose
Run development as a controlled kitchen:

- **OpenClaw (Master Chef):** plans, delegates, verifies, decides pass/fail.
- **Codex CLI / ACP Builder (Builder):** executes implementation work.
- **CDD skills + repo contract (SOP):** workflow is grounded in the target repo’s `AGENTS.md` / `TODO*.md` / specs.

---

## 1) Roles and ownership

**Master Chef (OpenClaw) owns:**
- Scope control
- Step selection
- Prompt/handoff quality
- QA gate + final acceptance recommendation
- Technical leadership + final decision on step-level assumptions/facts (human keeps final ship/no-ship authority)

**Builder (Codex CLI via ACP) owns:**
- Code changes for one approved step
- Running checks (with command evidence)
- Reporting results in the repo’s required format

**Human owns:**
- Product intent
- UAT sign-off
- Final “ship it”

---

## 2) Skill map (what to run when)

Current CDD skill names (post-rename):

- New repo **or** adopt CDD in an existing repo: `cdd-init-project`
- Plan new work / update TODO steps (approval-gated): `cdd-plan`
- Implement exactly one TODO step: `cdd-implement-todo`
- Refresh architecture snapshot: `cdd-index` (or `docs/prompts/PROMPT-INDEX.md` if that is canonical in the repo)
- Convert audit bullets → TODO steps → implement first step (two approvals): `cdd-audit-and-implement`
- Create refactor plan from INDEX: `cdd-refactor`

### 2.1 CDD-first execution rule (mandatory)

- If a `cdd-*` skill exists for the current phase, **use it first**.
- Do **not** bypass to freeform/manual coding unless:
  1) the skill is missing/broken, or
  2) the skill cannot express the approved step.
- If bypass is needed, Builder must stop and report a precise blocker + proposed workaround.

---

## 3) Standard loop (one step at a time)

1) Select exact TODO step (`Step NN — ...`).
2) Preflight gate (Master Chef):
   - repo clean enough for work,
   - step has Goal / Deliverable / Tasks / Automated checks / UAT (or draft minimal TODO patch first),
   - confirm active `TODO*.md` when multiple exist.
3) Select phase-appropriate CDD skill (`cdd-plan`, `cdd-implement-todo`, etc.).
4) Create Builder handoff (strict scope, exact step heading, constraints).
5) Run Builder via ACP Codex session.
6) Collect Builder report (diff summary + checks + risks + cdd command evidence).
7) Master Chef QA gate:
   - scope matches selected step only,
   - checks ran and passed (or justified failure + recovery plan),
   - docs updated if required,
   - no silent side quests,
   - Builder output matches repo `AGENTS.md` output format,
   - CDD-first rule was followed.
8) If failed gate: send correction prompt (delta-only).
9) If passed gate: produce UAT checklist for human.
10) After human sign-off: mark step done and propose next step.

### 3.1 Assumption reconciliation loop (Master Chef <-> Builder)

When there are inconsistencies, ambiguous requirements, or conflicting evidence:

1) Master Chef asks Builder for explicit evidence (files, commands, outputs, and rationale).
2) Builder responds with concrete proof + stated assumptions.
3) Master Chef challenges weak assumptions and requests correction/re-test if needed.
4) Master Chef decides which assumptions are factually acceptable for the step.
5) If still uncertain, escalate uncertainty clearly to human before claiming PASS.

Rule: no silent assumption acceptance. Assumptions must be tested or explicitly marked as risk.

---

## 4) Builder handoff template (use every time)

```text
You are the Builder. Execute exactly one approved TODO step.

REPO:
- <path>

STEP:
- <exact Step NN — Title heading>

MANDATORY CONTEXT (read first):
- AGENTS.md (follow its rules + Output Format Per Turn)
- README.md
- the active TODO file(s): TODO.md / TODO-*.md
- docs/specs/prd.md and docs/specs/blueprint.md (if present)
- docs/JOURNAL.md (skim top)
- docs/INDEX.md (if present)

CONSTRAINTS:
- Implement only this step; no scope creep
- Keep patch minimal
- Preserve existing behavior unless the step says otherwise
- Use CDD skill-first execution:
  - planning work -> cdd-plan
  - step implementation -> cdd-implement-todo
  - indexing/audit/refactor -> matching cdd-* skill
- If cdd skill is missing/broken/insufficient, STOP and ask one precise blocker question

VALIDATION:
- Run step-listed automated checks (plus stricter AGENTS.md checks)
- Include exact cdd commands run + exact validation commands run

DELIVERABLE:
- Report using repo AGENTS.md "Output Format Per Turn"
- Include command evidence (cdd + validation)

When fully done, end with:
DONE_BUILDER: <short summary>
```

---

## 5) Master Chef QA checklist (hard gate)

A step is **not done** unless all are true:

- [ ] Diff matches selected step only
- [ ] Appropriate `cdd-*` skill was used for the phase (or approved exception is documented)
- [ ] Automated checks executed and pass (or justified failure)
- [ ] No unexplained file changes
- [ ] PRD / Blueprint / TODO consistency preserved
- [ ] JOURNAL / INDEX updated when required by repo contract
- [ ] UAT checklist is clear and runnable by a human

If any item fails -> bounce back to Builder with correction delta.

---

## 6) Command policy (Builder runtime)

Default:
- Use **ACP Codex sessions** for Builder execution.
- Prefer one persistent ACP session per repo/task.
- Set/pin Builder runtime model/effort when needed.
- Keep one approved TODO step per Builder turn.

Avoid:
- PTY-driven local Codex loops when ACP path is healthy.
- Bypassing `cdd-*` workflow without explicit blocker + approval.
- Multi-step mega-prompts.
- “Looks good” without command evidence.

---

## 7) Failure policy

If Builder run fails:

1. Retry once with tighter prompt constraints.
2. If still failing, Master Chef:
   - isolates failure cause,
   - proposes smallest recovery patch plan,
   - asks approval before major reroute.

Never silently pivot architecture mid-step.

---

## 8) Reporting format to human (Master Chef output)

For each step, report:

- **GOAL**
- **SCOPE**
- **CHANGES**
- **VALIDATION**
- **UAT**
- **STATUS:** `PASS (awaiting UAT)` / `NEEDS FIX`
- **NEXT:** suggested next step

---

## 9) Working model policy (current convention)

- **Master Chef (OpenClaw):** planning + QA owner (never rubber-stamp).
- **Builder (Codex via ACP):** implementation worker.

Master Chef defaults:

- **Model:** `openai-codex/gpt-5.3-codex`
- **Reasoning effort:** `xhigh`

Builder defaults:

- **Model:** `gpt-5.4`
- **Reasoning effort:** `xhigh` (Codex key: `model_reasoning_effort`)
- **Previous builder default:** `gpt-5.2` @ `xhigh`

Naming note:

- `gpt-5.4` here is a **Codex CLI model id**.
- It is not an OpenClaw model ref like `openai-codex/...`.

---

## 10) How model + reasoning are set when using ACP (Codex)

ACP sessions run an external harness (Codex CLI via `acpx`). OpenClaw `/model` selection is separate from harness model.

### A) Set defaults in Codex CLI config (recommended)

In `~/.codex/config.toml`:

```toml
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
```

### B) Override per ACP session (experiments / per-task pinning)

- Set model:
  - `/acp model gpt-5.4`
  - (equivalent to `/acp set model gpt-5.4`)
- Set reasoning effort:
  - `/acp set model_reasoning_effort xhigh`

Under the hood:

- `/acp set <key> <value>` -> `acpx codex set <key> <value> --session <name>`

Notes:

- Not every harness exposes identical config keys.
- In thread-bound ACP sessions, overrides apply to that bound Codex session.
- Model/effort settings do not replace the CDD-first execution rule.
