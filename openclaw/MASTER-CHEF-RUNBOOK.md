# CDD Master Chef Runbook (OpenClaw + ACP Codex + Watchdog + CDD-first)

## 0) Purpose

Run development as a controlled kitchen with reporting and supervision:

- **OpenClaw (Master Chef):** plans, delegates, verifies, approves step-level UAT, commits, pushes, reports
- **ACP Codex (Builder):** executes one approved step at a time
- **OpenClaw (Watchdog):** checks health every 5 minutes, emits heartbeat every 15 minutes, resumes dead runs, reports stalls
- **CDD skills + repo contract (SOP):** the Builder workflow is grounded in the target repo's `AGENTS.md`, `TODO*.md`, and specs

---

## 1) Roles and ownership

**Master Chef owns:**

- Scope control
- Step selection
- Prompt and handoff quality
- QA gate and step-level UAT approval
- Commit, push, and reporting after each passed step
- Technical leadership and final internal decision on step-level facts
- Dispute handling with the Builder

**Builder owns:**

- Code changes for one approved step
- Running checks with command evidence
- Reporting exact `cdd-*` usage, outputs, risks, and blockers
- Defending technical choices with concrete evidence when challenged

**Watchdog owns:**

- Checking the active run every 5 minutes
- Sending `HEARTBEAT` every 15 minutes
- Detecting dead Builder progress and resuming the same step
- Reporting `RESUME`, `STEP_BLOCKED`, and `DEADLOCK_STOPPED` when needed

**Human owns:**

- Product intent
- Choosing the reporting target
- Final overall ship/no-ship for the broader workstream

---

## 2) Startup contract and control block

Before any Builder work, Master Chef must confirm:

- `REPO` — absolute repo path
- `REPORTING_COMMAND` — executable path for the user-provided reporting wrapper
- `REPORTING_TARGET` — user-selected destination or channel identifier
- optional `BRANCH` override
- optional `UPSTREAM` override

Default branch behavior:

- if no override is supplied, use the current checked-out branch
- if no upstream override is supplied, use the configured upstream for that branch

If any of the above is missing, unclear, or not confirmed, stop before preflight completion.

### 2.1 Reporting command contract

Master Chef and Watchdog must call the reporting command like this:

```bash
CDD_REPORT_TARGET="<target>" \
CDD_REPORT_EVENT="<event>" \
CDD_REPORT_REPO="<repo>" \
CDD_REPORT_STEP="<step-or-none>" \
CDD_REPORT_STATUS="<status>" \
CDD_REPORT_BODY="<markdown>" \
"$REPORTING_COMMAND"
```

Required event types:

- `START`
- `HEARTBEAT`
- `RESUME`
- `STEP_PASS`
- `STEP_BLOCKED`
- `DISPUTE_RESOLVED`
- `DEADLOCK_STOPPED`

If the reporting command fails, retry once. If it still fails, stop unattended progress and report the failure in chat as `STEP_BLOCKED`.

### 2.2 Control block

Maintain this state block in the OpenClaw chat and keep it current:

```text
CONTROL BLOCK
- REPO:
- REPORTING_COMMAND:
- REPORTING_TARGET:
- BRANCH:
- UPSTREAM:
- ACTIVE_STEP:
- PHASE:
- BUILDER_SESSION:
- LAST_PROGRESS_AT_UTC:
- LAST_REPORT_AT_UTC:
- LAST_RESUME_AT_UTC:
- RESTART_COUNT:
- DISPUTE_LOOP_COUNT:
- CURRENT_BLOCKER:
```

Update the control block after every material state change, every watchdog tick, every resume, and every report.

---

## 3) Builder skill map

The Builder should use these CDD skills by default:

- `cdd-init-project` — bootstrap or adopt CDD for a repo
- `cdd-plan` — convert scope into approval-ready TODO edits
- `cdd-implement-todo` — implement exactly one approved TODO step
- `cdd-index` — refresh architecture or index context
- `cdd-audit-and-implement` — turn audit findings into TODOs and implement the first step
- `cdd-refactor` — build a refactor TODO plan from the current index

### 3.1 CDD-first execution rule

- If a matching `cdd-*` skill exists for the current phase, use it first.
- Do not bypass to freeform/manual coding unless:
  1. the skill is missing or broken, or
  2. the skill cannot express the approved step
- If bypass is needed, Builder must stop and report a precise blocker plus the smallest workable fallback.

---

## 4) Standard loop (one step at a time)

Every approved planning step, TODO-edit step, or implementation step follows the same completion contract.

1. Confirm the startup contract and open the control block.
2. Send `START` if the run is new, or continue the existing run with the current control block.
3. Run preflight:
   - repo path is correct
   - working tree is clean enough for the step
   - the active `TODO*.md` file is unambiguous
   - the step has enough structure to execute, or a minimal TODO patch is drafted first
   - branch and upstream are known and pushable
   - reporting command works
4. Select the exact TODO step (`Step NN — ...`).
5. Choose the phase-appropriate CDD skill (`cdd-plan`, `cdd-implement-todo`, and so on).
6. Create the Builder handoff with strict scope and the exact step heading.
7. Run Builder via ACP Codex.
8. Collect the Builder report: diff summary, checks, risks, blockers, and `cdd-*` command evidence.
9. Run the Master Chef QA gate.
10. Run step-level UAT yourself from the Builder evidence and repo state.
11. If the step passes, commit and push it on the configured branch.
12. Send `STEP_PASS` with explicit `Master Chef UAT approved`.
13. Reset the control block for the next step, preserving branch, upstream, reporting contract, and session identifiers that remain valid.

If any item from QA, UAT, commit, push, or reporting fails, do not mark the step passed. Report `STEP_BLOCKED` instead.

---

## 5) Builder handoff template

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
- Do not commit or push; Master Chef owns commit, push, and reporting
- If Master Chef challenges a claim, answer with exact files, commands, outputs, and rationale

VALIDATION:
- Run the step-listed automated checks, plus any stricter AGENTS.md checks
- Include exact cdd commands and exact validation commands

DELIVERABLE:
- Report using the repo AGENTS.md "Output Format Per Turn"
- Include command evidence for cdd usage and validation
- Include a short UAT checklist and a suggested commit message

When fully done, end with:
DONE_BUILDER: <short summary>
```

---

## 6) Master Chef QA and step-completion gate

A step is not done unless all are true:

- [ ] Diff matches the selected step only
- [ ] Appropriate `cdd-*` skill was used, or the approved exception is documented
- [ ] Automated checks executed and passed, or failure is explicitly justified
- [ ] No unexplained file changes
- [ ] PRD, Blueprint, TODO, JOURNAL, and INDEX consistency was preserved when required by repo contract
- [ ] Builder evidence is concrete enough to challenge and retest
- [ ] Master Chef step-level UAT is clear, runnable, and explicitly approved
- [ ] Commit was created on the configured branch
- [ ] Push to the configured upstream succeeded
- [ ] External status report succeeded

If any item fails, bounce the step back to the Builder or report `STEP_BLOCKED`. Do not claim PASS.

---

## 7) Watchdog policy

The Watchdog is instruction-driven inside this skill. It assumes OpenClaw can trigger periodic turns or events.

### 7.1 Every 5 minutes

On each 5-minute watchdog turn:

1. Read the control block.
2. If no step is active, do nothing except keep the control block accurate.
3. If a step is active, inspect Builder health and last progress evidence.
4. If the Builder session is alive and progress is still coherent, leave the run alone.
5. If the Builder session or active process is dead before the step is complete:
   - resume the same step from the control block
   - increment `RESTART_COUNT`
   - update `LAST_RESUME_AT_UTC`
   - send `RESUME`

If the same phase dies twice without clear forward progress, stop the step and send `DEADLOCK_STOPPED`.

### 7.2 Every 15 minutes

Every 15 minutes, send `HEARTBEAT` even if the process is healthy.

Heartbeat content should include:

- repo
- active step
- phase
- last progress timestamp
- current blocker or `none`
- restart count
- next expected action

---

## 8) Dispute resolution policy

Disputes between Master Chef and Builder must be resolved internally first.

Use this loop:

1. Master Chef states the exact disputed claim or design choice.
2. Builder responds with concrete evidence, commands, and reasoning.
3. Master Chef challenges weak assumptions, requests re-tests, or proposes a tighter alternative.
4. Builder either proves its position or adjusts to the stronger solution.
5. Master Chef decides the winning path and records why.

After a resolved dispute, send `DISPUTE_RESOLVED` with:

- disputed issue
- Builder position
- Master Chef position
- evidence used to decide
- final chosen solution

`DISPUTE_LOOP_COUNT` increments for each full challenge cycle on the same blocker.

If 2 full dispute loops finish without clear forward progress, declare deadlock, stop the step, and send `DEADLOCK_STOPPED`.

Do not ask the human to break normal technical ties unless the human explicitly intervenes.

---

## 9) Reporting format

Master Chef must report both in chat and through the reporting command.

For normal step reports, include:

- **EVENT**
- **GOAL**
- **STEP**
- **PHASE**
- **CHANGES**
- **VALIDATION**
- **UAT**
- **STATUS**
- **MASTER CHEF UAT APPROVED**
- **COMMIT**
- **PUSH**
- **NEXT**

Event-specific expectations:

- `STEP_PASS` must include commit SHA, branch, upstream, and explicit `Master Chef UAT approved: yes`
- `STEP_BLOCKED` must include blocker, current control-block state, and the smallest recovery action
- `RESUME` must include why the process was considered dead and how it was resumed
- `DISPUTE_RESOLVED` must include both positions and the final decision
- `DEADLOCK_STOPPED` must include the deadlock reason, loop count or restart count, and the recommended unblock path

---

## 10) Runtime configuration policy

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

## 11) Preflight and operating checks

Before delegating implementation, verify:

- ACP backend healthy:
  - `/acp doctor`
- Codex CLI reachable:
  - `codex --version`
- required CDD Builder skills installed:
  - `ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null`
- reporting command is executable:
  - `test -x "$REPORTING_COMMAND"`
- target repo identified and clean enough for work:
  - `git status --short`
- active branch known:
  - `git branch --show-current`
- upstream exists and is resolvable:
  - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`

If upstream is missing, do not proceed into implementation. Stop and report the missing push target.

ACP permission caveat:

- ACP sessions are non-interactive.
- If the acpx backend is still using restrictive non-interactive permission settings, Builder writes or exec calls can fail.
- If that happens, stop and report the ACP permission blocker rather than pretending the step is complete.

---

## 12) Failure policy

If a Builder run fails:

1. Retry once with tighter prompt constraints.
2. If it still fails, isolate the failure cause and decide whether it is:
   - a normal blocker -> report `STEP_BLOCKED`
   - a technical dispute -> enter the dispute loop
   - a dead process -> let Watchdog resume it
   - a cyclical failure or deadlock -> report `DEADLOCK_STOPPED`

If commit or push fails:

- do not mark the step passed
- report `STEP_BLOCKED`
- include the failing command, branch, upstream, and smallest recovery action

If reporting fails twice:

- stop unattended progress
- leave the repo state untouched after the current safe point
- report the reporting failure in chat as `STEP_BLOCKED`

Never silently pivot architecture mid-step.
