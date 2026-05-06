---
name: cdd-master-chef
description: Start the cdd-master-chef autonomous workflow package. Use for non-trivial development where Master Chef ownership is wanted; current concrete adapters in this package are Codex, Claude Code, and OpenClaw, with OpenClaw carrying the current packaged runtime adapter and Codex and Claude Code provided as subagent-backed adapter docs.
user-invocable: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["git"],"config":[]}}}
---

# [CDD-6] Master Chef

Use this skill as the entrypoint for the shared `[CDD-6] Master Chef` workflow.

Adapter note:

- The runtime-agnostic Master Chef contract now lives beside this skill in `CONTRACT.md`, `RUNBOOK.md`, and `RUNTIME-CAPABILITIES.md`.
- Current concrete adapters in this package are Codex, Claude Code, and OpenClaw.
- Codex and Claude Code ship here as subagent-backed adapter docs.
- OpenClaw is the packaged runtime adapter.
- Other subagent-capable coding tools and autonomous systems, including Hermes-style runtimes, can be supported through additional adapters, but no Hermes adapter ships here today.
- Codex and Claude Code adapters should ask for the run step budget and whether to spawn Builder now, then own that Builder handoff rather than pushing the Builder-start decision back to the human.
- Master Chef approval requests should use visible selector-based options, defaulting to `A.`, `B.`, `C.` when practical, and the selected option itself should count as the approval.
- The operating contract below describes the current OpenClaw runtime path.
- When this file repeats a shared rule, treat the shared contract as canonical and this file as the OpenClaw runtime mapping of that rule.

References:

- `{baseDir}/openclaw/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/openclaw/MASTER-CHEF-TEST-HARNESS.md`

Shared policy flow:

- Session settings are best-effort facts: record unresolved current-session fields as `unknown` and continue with the active session as-is.
- Startup is branch-backed and environment-backed: on fresh runs from long-lived branches, default to recommending a descriptive source feature branch, still create a fresh per-run managed worktree branch, and bootstrap the active worktree to `env_ready` before Builder or `hard_gate`.
- Builder lifecycle is persistent: keep the same Builder across normal delegated-step transitions, attempt step-start compaction when supported, and replace Builder only for recovery conditions.
- Oversized-looking work is reviewed first: keep the parent step when one-run delivery is still viable, repair it in place when a minimal TODO fix restores that shape, and split only when the split cost is justified.

Operating contract:

1. Use this skill for non-trivial development where Master Chef ownership is wanted.
   - Preferred path: an existing repo that is already CDD-ready with `AGENTS.md`, `README.md`, and `TODO.md` or `TODO-*.md`
   - Allowed bootstrap path: a new or adoptable project folder that should be brought into the CDD contract first via `cdd-init-project`
2. The current runtime's main session is always Master Chef.
3. The Builder runs as a runtime-native subagent under the active adapter, not as a second Master Chef control loop.
4. There is no watchdog cron or separate supervising agent; Master Chef checks Builder health directly in the main session when active.
5. State is durable and repo-local:
   - `.cdd-runtime/master-chef/run.json`
   - `.cdd-runtime/master-chef/run.lock.json`
   - `.cdd-runtime/master-chef/master-chef.jsonl`
   - `.cdd-runtime/master-chef/builder.jsonl`
   - `.cdd-runtime/master-chef/context-summary.md`
6. Before kickoff, resolve current session settings and any optional `Builder override`:
   - read the current session model and thinking directly from the active runtime surface
   - if either value is not visible enough to report exactly, record only that field as `unknown`, say the runtime does not expose it here, and continue kickoff with the active session as-is
   - if the current prompt includes a `Builder override` block, use it as the requested Builder settings for that run
   - otherwise, default Builder to inherit those settings
   - if the runtime cannot honor a requested Builder override cleanly, say so explicitly and fall back to inherited Builder settings
   - if Builder inherits from an unresolved parent field and no explicit override replaces it, keep the inherited Builder field as `unknown`
   - treat current-session `master_model` / `master_thinking` plus effective `builder_model` / `builder_thinking` as the only per-run source of truth; do not infer model settings from repo docs, USER.md, memory, previous `run.json`, or earlier runs
   - do not ask the human to type replacement `master_*` settings when the runtime cannot expose them
   - keep shared docs and commits free of local-only operator overrides
7. Before autonomous work starts, inspect:
   - current git status and branch
   - upstream branch when present
   - active TODO file when present
   - last completed step when present
   - next runnable TODO step when present
   - whether the next runnable top-level TODO step is oversized for one Builder run
   - remaining unfinished top-level TODO step-heading count in the active TODO file when that count is finite
   - whether this looks like a fresh run from a long-lived branch and should first suggest a descriptive feature branch
   - whether the repo first needs `cdd-init-project` before the normal TODO loop can start
   - whether the source checkout is clean enough for managed worktree creation
   - which repo-native install, dependency, build, test, or validation entrypoints will have to be prepared in the active worktree before Builder or `hard_gate` validation can rely on it
8. Master Chef chooses the internal `cdd-*` routing model for the core `[CDD-0]` through `[CDD-5]` skills.
   - `[CDD-1] Init Project` (`cdd-init-project`): for a new or not-yet-CDD project, propose and normally start here in the main session before any autonomous TODO execution.
   - `[CDD-3] Implement TODO` (`cdd-implement-todo`): Builder default for the next runnable TODO step.
   - If the next runnable top-level TODO step is oversized for one Builder run, apply the shared review-first split policy rather than splitting by default. Prefer delegating the step unchanged while one Builder delegation can still finish it safely in one run; if a minimal TODO fix restores that viability without changing scope, repair it in place; split before delegation only when the parent step is not safely delegable as one coherent Builder action or cannot be made so with a minimal repair, and only when concrete evidence shows the split cost is justified. Charge split cost explicitly: extra Builder boots, extra hard-gate reruns, extra QA cycles, extra mission delay, and extra proof boundaries. Recompute the remaining unfinished top-level TODO step-heading count after a justified split, then treat the first new runnable step as the proposed delegated action.
   - `[CDD-2] Plan` (`cdd-plan`): Master Chef direct path that stays in the main session rather than being delegated to Builder.
   - `[CDD-4] Implementation Audit` (`cdd-implementation-audit`): installed direct audit helper for explicit implementation or codebase audits; approved findings still flow through `[CDD-2] Plan` before any delegated implementation begins.
   - External audit findings and review-derived work packages: normalize them through `[CDD-2] Plan` (`cdd-plan`) in the main session before any delegated implementation begins.
   - `[CDD-0] Boot` (`cdd-boot`): installed helper, but not part of the normal Master Chef routing flow.
   - `[CDD-5] Maintain` (`cdd-maintain`): installed direct maintenance helper for doc drift, codebase cleanup, `docs/INDEX.md` refresh, refactor architecture audit, archive upkeep, or local runtime cleanup review when one of those tasks is the actual next action.
   - Treat the installed `cdd-*` skills as internal Master Chef workflows, not standalone user commands during an active Master Chef run.
9. Use a managed worktree before implementation:
   - require a clean source checkout before kickoff; if dirty, stop and ask the human to stash, commit, or discard changes first
   - if this is a fresh run from a long-lived branch and no existing managed worktree is being resumed, default to recommending a descriptive feature branch first; if approved, create it in the source checkout before the per-run worktree branch
   - create a fresh per-run branch from the current branch `HEAD`
   - prefer `.cdd-runtime/worktrees/<run-id>/` as the managed worktree path
   - record `source_repo`, `source_branch`, `source_head_sha`, `source_branch_decision`, `active_worktree_path`, `worktree_branch`, and `worktree_continue_mode` in runtime state
   - the active runtime adapter either continues in-session from the managed worktree or stops with exact relaunch instructions; keep `worktree_continue_mode` explicit
   - once the managed worktree becomes active, bootstrap the repo-native environment there before Builder or `hard_gate` validation rely on it
   - record `worktree_env_status`, `worktree_env_prepared_at_utc`, and a concise `worktree_env_bootstrap_summary` in runtime state; keep detailed bootstrap commands and checks in durable evidence
10. Before implementation starts, present one selector-driven kickoff approval that covers:
   - proposed next action
   - current session model
   - current session thinking
   - effective Builder settings
   - any fresh-start feature-branch suggestion when the source checkout is still on a long-lived branch
   - the default/max run step-budget recommendation when the active TODO has a finite remaining top-level step count
   - the approved run step budget
   - whether to spawn Builder now and start the autonomous run
   - runtime initialization under `.cdd-runtime/master-chef/`
   - run lease creation
   - managed worktree creation and relaunch expectations
   - active-worktree environment bootstrap expectations before Builder or `hard_gate` validation run
   - prefer `A. approve kickoff and start the autonomous run now`, `B. approve kickoff but do not spawn Builder yet`, `C. revise the next action, Builder settings, or step budget before kickoff`
11. Spawn the Builder as a subagent with the effective `builder_model` and `builder_thinking` resolved for that run, defaulting to inherited settings when no override is active, for the first approved delegated action, tell it which internal `cdd-*` skill path to use, and require an early readiness ACK before deep work.
12. Keep one persistent Builder per active autonomous run as the normal path.
   - Each delegated Builder action still covers exactly one approved step or same-step recovery action at a time.
   - After a step passes, after QA sends the same step back for another delegated attempt, or after blocker repair yields the same or next delegated step, Master Chef must re-inspect repo state and attempt same-Builder continuation first when the active Builder remains usable.
   - Before handing a new delegated step to the active Builder, Master Chef must attempt a Builder compaction operation when the runtime exposes a supported compaction command or API.
   - If the runtime does not expose a supported compaction command or API, keep the same Builder and rely on runtime auto-compaction or native context management instead of inventing a fake compaction path.
   - Replace Builder only as recovery after explicit failure evidence, explicit runtime closure, deadlock, unusable drift, or inability to continue safely in the active worktree after compaction or direct status checks.
13. Both Master Chef and Builder must append JSONL logs with concrete evidence for Builder spawn, Builder readiness, step start, validation, blockers, completion, and reporting.
14. Use `hard_gate` and `soft_signal` validation classes:
   - `hard_gate`: failing tests, lint, typecheck, migrations, pushability, or repo-defined must-pass checks
   - `soft_signal`: discovery greps, file-presence scans, or other non-blocking heuristics
15. Use working-tree-aware discovery checks when unstaged files matter:
   - `rg --files`
   - `git ls-files --cached --others --exclude-standard`
16. After relaunch into the managed worktree, treat that worktree as the active repo root for TODO inspection, environment bootstrap, QA, commit, and push.
   - inspect repo-native manifests, runbook commands, and validation entrypoints from the active worktree
   - run the required dependency, build, install, or test-prep commands in that worktree
   - keep `worktree_env_status` at `preparing` until the worktree is ready, then move it to `env_ready`, `partial`, or `blocked` with durable evidence
   - do not let Builder or `hard_gate` validation rely on the worktree until `worktree_env_status` is `env_ready`
17. For each passed step:
   - increment `steps_completed_this_run`
   - ensure the Builder updated only the selected step in `TODO*.md`
   - verify the selected TODO step's task checklist now reflects the completed work before the step can pass
   - run Master Chef QA
   - if QA rejects the Builder result, either push concrete findings back to the active Builder when it remains usable, replace Builder only if recovery conditions require it, or fix the issue directly in Master Chef, then re-run QA before the step can pass
   - approve step-level UAT with explicit evidence
   - commit
   - push
   - advertise `STEP_PASS` with the full result, evidence, and decision trail in the current Master Chef session
   - if `run_step_budget` is a positive integer and `steps_completed_this_run` has reached it, stop cleanly with `RUN_STOPPED` and a final mission report instead of continuing automatically
   - otherwise, re-inspect TODO state and continue automatically to the next runnable step unless no runnable step remains
18. Reporting is session-native.
   - The current Master Chef session is the control plane and reporting surface for this shared skill.
   - Report lifecycle events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `BLOCKER_CLEARED`, `RUN_COMPLETE`, and explicit stops in-session.
   - Once kickoff approval lands, Master Chef owns the mission under the approved run step budget and keeps continuation, Builder restarts, blocker repair, TODO splitting, and terminal reporting in-session unless a hard technical or physical limit forces a stop.
   - Keep shared skill docs and runtime state free of extra route config.
19. When Master Chef performs a Builder check in the main session, it may:
   - inspect runtime files and logs
   - inspect Builder health
   - use direct Builder status or progress surfaces when the runtime exposes them
   - replace the Builder with a fresh subagent run only when the shared recovery conditions are met
   - report blockers or completion
20. Direct Builder checks must not create a second control loop. Recovery stays in the main session, and fresh Builder replacement is recovery-only rather than the normal step-transition path.
21. Healthy Builder checks may stay quiet, but they do not cancel in-session lifecycle reporting for events such as `START`, `STEP_PASS`, `STEP_BLOCKED`, `RUN_COMPLETE`, or an explicit stop.
22. Distinguish Builder boot/readiness from quiet work.
   - Record `builder_phase: booting` as soon as the spawn request succeeds. A returned Builder session key or spawned-agent line is not enough to prove that the Builder has started operating.
   - Keep `builder_phase: booting` until a runtime-reported child-started signal, a coherent Builder readiness ACK, or a Builder-authored `BUILDER_READY` record arrives in `builder.jsonl`.
   - Preferred boot prompt: `Hi. You are Builder <builder_session_key> for run <run_id>, step <active_step>, worktree <active_worktree_path>. Reply now with READY if you can build, or BLOCKED: <reason> if you cannot.`
   - The preferred readiness ACK confirms the active worktree path, active TODO step, and whether required tool or MCP surfaces are available or already blocked.
   - Use a short boot window before the first boot-status probe; foreground Codex and Claude flows should default to about 2 minutes.
23. If the runtime does not expose live Builder thinking or streaming partial output, report Builder state as `running` or `unknown` during quiet periods rather than guessing.
   - Do not treat a returned session key, a missing diff, an empty `builder.jsonl`, or one short wait window as proof that Builder is fully started or has died.
   - For long-thinking or otherwise high-latency Builders, choose a longer quiet-work window before the first stale probe unless direct failure evidence arrives sooner.
   - In foreground Codex and Claude flows, about 10 minutes is the default quiet-work window when the approved Builder effort is clearly high-latency; otherwise state the chosen quiet-work window explicitly at spawn time.
   - Apply the chosen quiet-work window only after `builder_phase` reaches `running`.
   - Use one direct status probe before replacement when the runtime supports it.
   - Any coherent Builder reply, including discovery-only status, is proof of life rather than proof of death.
24. If repeated Builder replacements fail without progress, stop quickly and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` rather than limping on.
25. If a TODO step is blocked by a hard blocker, ambiguous scope, being oversized for one Builder run, or repeated failed Builder replacements:
   - pause delegated implementation and report `STEP_BLOCKED` or `DEADLOCK_STOPPED` in the current Master Chef session
   - revise the situation in Master Chef before any more Builder work
   - run the same continuation review again: inspect completed work, failed proof, remaining scope, whether the active Builder is still usable after status or compaction checks, likely recovery cost for a replacement Builder, and whether the remainder now forms cleaner child steps than the parent step did
   - treat many checklist items, many touched files, or broad-looking wording as non-signals by themselves; use them only when they materially raise one-run failure risk
   - treat split as expensive because it adds Builder restart overhead, extra hard-gate reruns, extra QA cycles, extra mission time, and extra proof boundaries
   - prefer `continue_same_step` when progress is real and the remainder still forms one bounded proof boundary for the active Builder, or for one recovery replacement Builder if the active one is no longer usable
   - if a minimal TODO repair restores one-run viability without changing the true scope, repair the step in place and continue that same parent step with the active Builder when safe, otherwise with one recovery replacement Builder
   - split only the remaining work, and only when concrete evidence shows the current parent step now costs more to preserve than the split would: repeated low-forward-progress retries, recovery effort dominating completion effort, expensive hard-gate recovery loops, or proof that continuing unchanged would trigger more total hard-gate reruns than a lower-risk child-step sequence
   - clean only stale runtime/build artifacts when they are actually needed for a coherent retry, and never revert unrelated user work
   - if repair or split yields a safe autonomous next step, emit `BLOCKER_CLEARED`, preserve the active run plus remaining `run_step_budget`, do not increment `steps_completed_this_run`, and continue from the same repaired parent step or the next smaller actionable child step by reusing the active Builder first and replacing it only if recovery conditions require it
   - if a hard technical or physical limit still prevents safe autonomous continuation after repair, keep the run stopped and report the exact limit plus the decisions made before stopping
   - do not retry the same broad blocked step unchanged
26. Manage Master Chef context explicitly during long runs:
   - keep persistent Builder continuation and Master Chef context compaction as separate control-loop behaviors
   - at the beginning of each new delegated step, attempt Builder compaction when the runtime supports it; otherwise keep the same Builder and rely on runtime auto-compaction or native context management
   - before Master Chef compaction, write `run.json`, `run.lock.json`, JSONL evidence, and `.cdd-runtime/master-chef/context-summary.md`
   - compact only at safe workflow boundaries, such as after kickoff state is durable, after Builder handoff, after `STEP_PASS`, after `STEP_BLOCKED` or `DEADLOCK_STOPPED`, after Master-Chef-direct planning/refactor work, or before a known large QA/planning phase once a checkpoint is written
   - do not compact while QA, commit, push, blocker strategy, or next-action decisions exist only in the live transcript
   - after compaction, resume from runtime files, `context-summary.md`, active TODO, and git state before continuing

Canonical `run.json` fields:

- `run_id`
- `repo`
- `source_repo`
- `master_model`
- `master_thinking`
- `builder_model`
- `builder_thinking`
- `builder_settings_source`
- `builder_runtime`
- `master_session_key`
- `builder_session_key`
- `builder_phase`
- `builder_spawn_requested_at_utc`
- `builder_ready_at_utc`
- `last_builder_direct_signal_at_utc`
- `builder_last_compaction_attempted_at_utc`
- `builder_last_compaction_result`
- `builder_last_compaction_summary`
- `builder_replacement_lineage`
- `run_step_budget`
- `steps_completed_this_run`
- `active_todo_path`
- `active_step`
- `phase`
- `source_branch`
- `source_head_sha`
- `source_branch_decision`
- `active_worktree_path`
- `worktree_branch`
- `worktree_continue_mode`
- `worktree_env_status`
- `worktree_env_prepared_at_utc`
- `worktree_env_bootstrap_summary`
- `branch`
- `upstream`
- `pre_step_head_sha`
- `last_pass_head_sha`
- `last_progress_at_utc`
- `last_master_log_at_utc`
- `last_builder_log_at_utc`
- `builder_restart_count`
- `dispute_loop_count`
- `current_blocker`

Runtime-state expectations for persistent Builder continuity:

- `builder_session_key` is the active Builder identity and normally remains stable across delegated steps in the same run.
- `builder_last_compaction_attempted_at_utc`, `builder_last_compaction_result`, and `builder_last_compaction_summary` capture the latest step-boundary compaction attempt or truthful fallback result such as `unsupported`, `auto`, or `native_context_management`.
- `builder_replacement_lineage` records prior Builder identities, replacement reasons, and any parent-child handoff needed when recovery forces Builder replacement.

Report events:

- `START`
- `BUILDER_SPAWNED`
- `BUILDER_READY`
- `BUILDER_RESTARTED`
- `STEP_PASS`
- `STEP_BLOCKED`
- `BLOCKER_CLEARED`
- `RUN_STOPPED`
- `DEADLOCK_STOPPED`
- `RUN_COMPLETE`

When `BLOCKER_CLEARED` is emitted after a successful repair, record the original blocked step, the replacement step ids, the preserved remaining budget, and the next delegated action.

When the run ends with `RUN_COMPLETE`, `RUN_STOPPED`, a hard-stop `STEP_BLOCKED`, or `DEADLOCK_STOPPED`, emit a final mission report covering completed work, completed TODO step ids plus whether their task checklists are fully checked, validations and pushes, Builder restarts or blocker repairs, unresolved session-setting fields, which effective Builder settings were concrete versus `unknown`, decisions made, and remaining work or the exact stop reason.
For `RUN_COMPLETE`, append a compact closeout recommendation bundle:
- run `cdd-implementation-audit` on the completed run scope
- push only when the active branch is ahead of origin or still unpublished
- open a PR only once the branch is published and PR creation is still pending
- clean up the managed worktree only when it still exists and no immediate continuation is planned there
- return to the source checkout or parent folder after cleanup or once that worktree is no longer the active development root
For budget-stop `RUN_STOPPED`, append a compact continuation-aware recommendation bundle:
- run `cdd-implementation-audit` on the work completed so far
- name the remaining runnable work or next continuation target
- recommend push or open-PR actions only when warranted
- mention managed-worktree cleanup or return to the source checkout only when no immediate continuation is planned there

Reporting surface:

- the current Master Chef session carries full operational detail and lifecycle reporting
