# CDD Master Chef Runbook (OpenClaw + ACP Codex + CDD-first)

## 0) Purpose

Run development as a controlled kitchen:

- **OpenClaw (Master Chef):** plans, delegates, verifies, decides pass/fail
- **ACP Codex (Builder):** executes implementation work
- **CDD skills + repo contract (SOP):** the Builder workflow is grounded in the target repo’s `AGENTS.md`, `TODO*.md`, and specs

---

## 1) Roles and ownership

**Master Chef (OpenClaw) owns:**

- Scope control
- Step selection
- Prompt and handoff quality
- QA gate and final acceptance recommendation
- Technical leadership and final decision on step-level assumptions and facts

**Builder (ACP Codex) owns:**

- Code changes for one approved step
- Running checks with command evidence
- Reporting results in the target repo’s required format

**Human owns:**

- Product intent
- UAT sign-off
- Final ship/no-ship

---

## 2) Builder skill map

The Builder should use these CDD skills by default:

- `cdd-init-project` — bootstrap or adopt CDD for a repo
- `cdd-plan` — convert scope into approval-ready TODO edits
- `cdd-implement-todo` — implement exactly one approved TODO step
- `cdd-index` — refresh architecture or index context
- `cdd-audit-and-implement` — turn audit findings into TODOs and implement the first step
- `cdd-refactor` — build a refactor TODO plan from the current index

### 2.1 CDD-first execution rule

- If a matching `cdd-*` skill exists for the current phase, use it first.
- Do not bypass to freeform/manual coding unless:
  1. the skill is missing or broken, or
  2. the skill cannot express the approved step
- If bypass is needed, Builder must stop and report a precise blocker plus the smallest workable fallback.

---

## 3) Standard loop (one step at a time)

1. Select the exact TODO step (`Step NN — ...`).
2. Preflight the repo and Builder context:
   - repo path is correct
   - working tree is clean enough for the step
   - the active `TODO*.md` file is unambiguous
   - the step has enough structure to execute, or a minimal TODO patch is drafted first
3. Choose the phase-appropriate CDD skill (`cdd-plan`, `cdd-implement-todo`, and so on).
4. Create the Builder handoff with strict scope and the exact step heading.
5. Run Builder via ACP Codex.
6. Collect the Builder report: diff summary, checks, risks, and `cdd-*` command evidence.
7. Run the Master Chef QA gate:
   - scope matches the selected step only
   - checks ran and passed, or failure is justified with a recovery plan
   - docs were updated when the repo contract requires them
   - no silent side quests
   - Builder output matches the repo `AGENTS.md` format
   - CDD-first execution rule was followed
8. If the gate fails, send a correction prompt with the exact delta.
9. If the gate passes, produce a UAT checklist for the human.
10. After human sign-off, mark the step done and propose the next step.

### 3.1 Assumption reconciliation loop

When requirements or evidence are ambiguous:

1. Master Chef asks Builder for explicit proof: files, commands, outputs, and rationale.
2. Builder responds with concrete evidence and stated assumptions.
3. Master Chef challenges weak assumptions and requests correction or re-test if needed.
4. Master Chef decides which assumptions are acceptable for the step.
5. If uncertainty remains, escalate it clearly to the human before claiming PASS.

Rule: no silent assumption acceptance. Assumptions must be tested or explicitly reported as risk.

---

## 4) Builder handoff template

Use this every time:

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
- Keep the patch minimal
- Preserve existing behavior unless the step says otherwise
- Use CDD skill-first execution:
  - planning work -> cdd-plan
  - step implementation -> cdd-implement-todo
  - indexing, audit, refactor -> matching cdd-* skill
- If a required cdd skill is missing, broken, or insufficient, STOP and report one precise blocker

VALIDATION:
- Run the step-listed automated checks, plus any stricter AGENTS.md checks
- Include exact cdd commands and exact validation commands

DELIVERABLE:
- Report using the repo AGENTS.md "Output Format Per Turn"
- Include command evidence for cdd usage and validation

When fully done, end with:
DONE_BUILDER: <short summary>
```

---

## 5) Master Chef QA checklist

A step is not done unless all are true:

- [ ] Diff matches the selected step only
- [ ] Appropriate `cdd-*` skill was used, or the approved exception is documented
- [ ] Automated checks executed and passed, or failure is explicitly justified
- [ ] No unexplained file changes
- [ ] PRD, Blueprint, and TODO consistency was preserved
- [ ] JOURNAL or INDEX was updated when the repo contract requires it
- [ ] UAT is clear and runnable by a human

If any item fails, bounce the step back to the Builder with the correction delta only.

---

## 6) Command policy

Default:

- Use ACP Codex sessions for Builder execution
- Prefer one persistent ACP session per repo or task
- Keep one approved TODO step per Builder turn
- Use `/acp spawn codex --mode persistent --thread auto --cwd /abs/path/to/repo` when a Builder session needs to be created

Avoid:

- PTY-driven local Codex loops when ACP is healthy
- bypassing the `cdd-*` workflow without an explicit blocker
- multi-step mega-prompts
- claims like "looks good" without command evidence

---

## 7) Failure policy

If a Builder run fails:

1. Retry once with tighter prompt constraints.
2. If it still fails, Master Chef:
   - isolates the failure cause
   - proposes the smallest recovery patch plan
   - asks for approval before a major reroute

Never silently pivot architecture mid-step.

---

## 8) Reporting format to the human

For each step, report:

- **GOAL**
- **SCOPE**
- **CHANGES**
- **VALIDATION**
- **UAT**
- **STATUS:** `PASS (awaiting UAT)` or `NEEDS FIX`
- **NEXT:** suggested next step

---

## 9) Runtime configuration policy

- OpenClaw `/model ...` controls the Master Chef LLM.
- `/acp model ...` and `/acp set ...` control the Builder runtime.
- Codex defaults can also be managed outside OpenClaw in Codex config.

This skill does not define required model IDs or reasoning defaults.

Use runtime inspection and overrides only when:

- the user explicitly asks for them, or
- the operator has already established runtime policy for the current environment

Useful operator commands:

- `/acp status`
- `/acp model <model-id>`
- `/acp set <key> <value>`

Runtime tuning does not replace the CDD-first execution rule.

---

## 10) Preflight and operating checks

Before delegating implementation, verify:

- ACP backend healthy:
  - `/acp doctor`
- Codex CLI reachable:
  - `codex --version`
- required CDD Builder skills installed:
  - `ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null`
- target repo identified and clean enough for work:
  - `git status --short`

ACP permission caveat:

- ACP sessions are non-interactive.
- If the acpx backend is still using restrictive non-interactive permission settings, Builder writes or exec calls can fail.
- If that happens, stop and report the ACP permission blocker rather than pretending the step is complete.
