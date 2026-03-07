# CDD Master Chef Runbook (OpenClaw + ACP Codex + main-session cron + CDD-first)

## 0) Purpose

Run autonomous development as an upgrade on top of the core CDD Builder workflow:

- **OpenClaw (Master Chef):** inspects repo state, selects the next action, drives the Builder, approves step-level UAT, commits, pushes, and reports status
- **ACP Codex (Builder):** executes repo work for one approved step at a time
- **OpenClaw main-session cron (Watchdog):** injects a 5-minute system event into the active Master Chef session, checks health, resumes dead runs, and emits heartbeat every 15 minutes
- **Human:** selects models, confirms the kickoff, and mainly reviews final results or critical blockers

This runbook assumes the repo already has the CDD boilerplate and the core `cdd-*` skills are installed.

---

## 1) Two skill blocks

Keep the distinction explicit:

- **Core CDD Skills** are the primary single-agent workflow:
  - one coding agent
  - human in the loop for approvals and acceptance
  - direct use of `cdd-plan`, `cdd-implement-todo`, `cdd-index`, and related skills
- **CDD Master Chef** is the OpenClaw upgrade:
  - the human approves the kickoff once
  - Master Chef then drives the Builder across TODO steps autonomously
  - the human mainly reviews final results, blockers, or deadlocks

Never use Master Chef to paper over a repo that is not already CDD-ready.

---

## 2) Startup prerequisites

Before `/cdd-master-chef` is invoked:

1. The user must select the Master Chef model with a standalone directive:
   - `/model <master-model>`
2. The user must select the Builder model with a standalone directive:
   - `/acp model <builder-model>`
3. The target repo must already contain the CDD boilerplate:
   - `AGENTS.md`
   - `README.md`
   - `TODO.md` or `TODO-*.md`
4. The user must launch `/cdd-master-chef` from the OpenClaw session they want to use as the reporting channel.

If model selection has not been made explicitly, stop and ask the user to run the directives first. Do not pick models on the user's behalf.

If the repo is not CDD-ready, stop and route the user back to the core CDD workflow or `cdd-init-project`.

---

## 3) Kickoff flow

On the first `/cdd-master-chef` turn:

1. Verify model selection and environment:
   - `/model status`
   - `/acp status`
   - `/acp doctor`
2. Verify repo readiness:
   - `AGENTS.md` exists
   - `README.md` exists
   - one active TODO file exists
   - `git status --short`
   - `git branch --show-current`
3. Inspect where development is at:
   - current branch and upstream
   - active TODO file
   - last completed step
   - next runnable TODO step
   - any obvious blockers in the working tree
4. Choose the next action:
   - default: the next runnable TODO step via `cdd-implement-todo`
   - fallback: `cdd-plan` only when the TODO state is stale, ambiguous, or not executable
5. Present one kickoff approval that includes:
   - repo state summary
   - proposed next action
   - confirmation that the current session is the reporting channel
   - creation of the 5-minute watchdog cron
6. Do not create the cron job and do not start implementation until the user confirms the kickoff.

After kickoff approval, the run becomes autonomous.

---

## 4) Roles and ownership

**Master Chef owns:**

- repo inspection and next-step selection
- kickoff proposal quality
- Builder handoff quality
- QA gate and step-level UAT approval
- commit, push, and status reporting after each passed step
- autonomous progression to subsequent TODO steps
- final results summary

**Builder owns:**

- code changes for one approved step
- running checks with command evidence
- reporting exact `cdd-*` usage and blockers
- defending technical choices with concrete evidence when challenged

**Watchdog owns:**

- checking the active run every 5 minutes
- sending `HEARTBEAT` every 15 minutes
- resuming a dead Builder run
- reporting `RESUME`, `STEP_BLOCKED`, and `DEADLOCK_STOPPED`

**Human owns:**

- model selection
- kickoff approval
- final review of results
- intervention only when Master Chef reports a blocker or deadlock

---

## 5) Control block

Keep this block in the active OpenClaw session and update it after every material state change:

```text
CONTROL BLOCK
- REPO:
- MASTER_MODEL:
- BUILDER_MODEL:
- REPORTING_SESSION:
- WATCHDOG_CRON_ID:
- ACTIVE_STEP:
- PHASE:
- BUILDER_SESSION:
- LAST_PROGRESS_AT_UTC:
- LAST_HEARTBEAT_AT_UTC:
- LAST_RESUME_AT_UTC:
- RESTART_COUNT:
- DISPUTE_LOOP_COUNT:
- CURRENT_BLOCKER:
```

The current session is the reporting session.

If the user wants a different reporting channel, stop and have them restart `/cdd-master-chef` there before the autonomous run begins.

---

## 6) Builder skill map

The Builder should use these CDD skills by default:

- `cdd-init-project` — bootstrap or adopt CDD for a repo
- `cdd-plan` — convert scope into approval-ready TODO edits
- `cdd-implement-todo` — implement exactly one approved TODO step
- `cdd-index` — refresh architecture or index context
- `cdd-audit-and-implement` — turn audit findings into TODOs and implement the first step
- `cdd-refactor` — build a refactor TODO plan from the current index

### 6.1 CDD-first execution rule

- If a matching `cdd-*` skill exists for the current phase, use it first.
- Do not bypass to freeform/manual coding unless:
  1. the skill is missing or broken, or
  2. the skill cannot express the approved step
- If bypass is needed, Builder must stop and report a precise blocker plus the smallest workable fallback.

---

## 7) Standard autonomous loop

After the kickoff approval:

1. Open or refresh the control block.
2. Ensure the watchdog cron exists and record its id.
3. Spawn or reuse the Builder session:
   - `/acp spawn codex --mode persistent --thread auto --cwd <repo>`
4. Hand the selected step to the Builder.
5. Collect the Builder report: diff summary, checks, risks, blockers, and exact `cdd-*` command evidence.
6. Run the Master Chef QA gate.
7. Run step-level UAT internally from repo state plus Builder evidence.
8. If the step passes:
   - commit
   - push
   - report `STEP_PASS`
9. Re-inspect the TODO state.
10. If another runnable step exists, continue automatically without a new human approval.
11. If no runnable step remains and the autonomous scope is complete, send final results and report `RUN_COMPLETE`.

Only stop autonomy when:

- the run is complete
- a hard blocker requires human input
- a deadlock is declared
- cron, reporting, or push behavior fails in a way that makes unattended progress unsafe

---

## 8) Builder handoff template

Use this every time:

```text
You are the Builder. Execute exactly one approved TODO step.

REPO:
- <path>

STEP:
- <exact Step NN - Title heading>

MANDATORY CONTEXT (read first):
- AGENTS.md
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
- If the step passes, update only the selected step in the active `TODO*.md` file to mark its task items done before handing control back:
  - existing checkbox tasks -> `[x]`
  - plain task bullets -> checked markdown checkboxes
  - do not add a new step-level status field
  - do not touch future or unrelated steps
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

## 9) Watchdog cron

Use one recurring OpenClaw cron job:

- cadence: every 5 minutes
- target: current main session
- payload: system event
- keep it running until the autonomous run completes or stops

Preferred behavior:

- use the gateway `cron.add` tool when available
- otherwise use the documented CLI equivalent

Canonical shape:

```json
{
  "name": "cdd-master-chef-watchdog:<repo>",
  "schedule": { "kind": "every", "everyMs": 300000 },
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "CDD_MASTER_CHEF_WATCHDOG"
  },
  "wakeMode": "now",
  "deleteAfterRun": false
}
```

CLI equivalent:

```bash
openclaw cron add \
  --name "cdd-master-chef-watchdog:<repo>" \
  --every 5m \
  --session main \
  --system-event "CDD_MASTER_CHEF_WATCHDOG" \
  --wake now
```

Record the returned cron id in `WATCHDOG_CRON_ID`.

On completion, blocker, cancellation, or deadlock, remove the job:

```bash
openclaw cron rm <job-id>
```

---

## 10) Watchdog policy

On each 5-minute watchdog event:

1. Read the control block.
2. If no step is active, do nothing except keep the control block accurate.
3. If a step is active, inspect Builder health and last progress evidence.
4. If the Builder session is healthy and progress is coherent, leave the run alone.
5. If the Builder session or active process is dead before the step is complete:
   - resume the same step from the control block
   - increment `RESTART_COUNT`
   - update `LAST_RESUME_AT_UTC`
   - report `RESUME`
6. If 15 minutes have elapsed since the last status report, send `HEARTBEAT`.

Resume-to-deadlock rule:

- if the same phase needs 2 automatic resumes without any forward movement in `LAST_PROGRESS_AT_UTC`, stop the run and report `DEADLOCK_STOPPED`

---

## 11) QA, UAT, commit, and push gate

A step is not passed unless all are true:

- [ ] Diff matches the selected step only
- [ ] Appropriate `cdd-*` skill was used, or the approved exception is documented
- [ ] Automated checks executed and passed, or failure is explicitly justified
- [ ] No unexplained file changes
- [ ] The selected step's task items in the active `TODO*.md` are marked done, and unrelated steps were not changed
- [ ] PRD, Blueprint, TODO, JOURNAL, and INDEX consistency was preserved when required by repo contract
- [ ] Builder evidence is concrete enough to challenge and retest
- [ ] Master Chef step-level UAT is clear, runnable, and explicitly approved
- [ ] Commit was created on the configured branch
- [ ] Push to the configured upstream succeeded
- [ ] Status report was sent in the reporting session

If any item fails, do not claim pass. Report `STEP_BLOCKED` instead.

---

## 12) Reporting format

Status reports live in the current OpenClaw reporting session.

Event labels:

- `START`
- `HEARTBEAT`
- `RESUME`
- `STEP_PASS`
- `STEP_BLOCKED`
- `DISPUTE_RESOLVED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

Normal step reports must include:

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

`RUN_COMPLETE` must include:

- completed steps summary
- final branch / head commit
- remaining TODO items, if any
- known risks
- exact final review actions for the human

---

## 13) Dispute and deadlock policy

Disputes between Master Chef and Builder must be resolved internally first.

Use this loop:

1. Master Chef states the exact disputed claim or design choice.
2. Builder responds with concrete evidence, commands, and reasoning.
3. Master Chef challenges weak assumptions, requests re-tests, or proposes a tighter alternative.
4. Builder either proves its position or adjusts to the stronger solution.
5. Master Chef decides the winning path and records why.

After a resolved dispute, report `DISPUTE_RESOLVED` with:

- disputed issue
- Builder position
- Master Chef position
- evidence used to decide
- final chosen solution

`DISPUTE_LOOP_COUNT` increments for each full challenge cycle on the same blocker.

If 2 full dispute loops finish without clear forward progress, declare deadlock, stop the run, remove the cron job, and report `DEADLOCK_STOPPED`.

---

## 14) Preflight checks

Before implementation begins, verify:

- Master Chef model status:
  - `/model status`
- Builder model status:
  - `/acp status`
- ACP backend healthy:
  - `/acp doctor`
- Codex CLI reachable:
  - `codex --version`
- required CDD Builder skills installed:
  - `ls ~/.agents/skills/cdd-init-project ~/.agents/skills/cdd-plan ~/.agents/skills/cdd-implement-todo ~/.agents/skills/cdd-index ~/.agents/skills/cdd-audit-and-implement ~/.agents/skills/cdd-refactor >/dev/null`
- repo contains the CDD boilerplate:
  - `ls AGENTS.md README.md >/dev/null`
  - `ls TODO*.md >/dev/null`
- target repo identified and clean enough for work:
  - `git status --short`
- active branch known:
  - `git branch --show-current`
- upstream exists and is resolvable:
  - `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`

If upstream is missing, do not proceed into implementation. Stop and report the missing push target.

If the active TODO state is not runnable, stop the implementation path and propose `cdd-plan` instead.

---

## 15) Failure policy

If a Builder run fails:

1. Retry once with tighter prompt constraints.
2. If it still fails, isolate the failure cause and decide whether it is:
   - a normal blocker -> report `STEP_BLOCKED`
   - a technical dispute -> enter the dispute loop
   - a dead process -> let Watchdog resume it
   - a cyclical failure or deadlock -> report `DEADLOCK_STOPPED`

If push fails:

- do not mark the step passed
- report `STEP_BLOCKED`
- include the failing command, branch, upstream, and smallest recovery action

If cron setup fails before kickoff:

- do not start autonomous execution
- ask the human to resolve the cron setup first

If the reporting session is not the intended one:

- do not start autonomous execution
- have the user relaunch `/cdd-master-chef` from the correct session or channel

Never silently pivot architecture mid-step.
