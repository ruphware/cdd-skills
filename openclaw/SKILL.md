---
name: cdd-master-chef
description: Orchestrate the OpenClaw Master Chef development loop with ACP Codex as the Builder and CDD-first execution.
user-invocable: true
disable-model-invocation: true
homepage: https://github.com/ruphware/cdd-skills
metadata: {"openclaw":{"requires":{"bins":["codex","git"],"config":["acp.enabled"]}}}
---

# CDD Master Chef

Use this skill for the OpenClaw-driven development process described in:

- `{baseDir}/README.md`
- `{baseDir}/MASTER-CHEF-RUNBOOK.md`
- `{baseDir}/MASTER-CHEF-TEST-HARNESS.md`

Operating contract:

1. OpenClaw is the Master Chef: plan, delegate, verify, and decide pass/fail for one approved step at a time.
2. The Builder runtime is ACP `codex`. Do not switch harnesses unless the user explicitly changes the process contract.
3. The Builder must use the separate `cdd-*` skill pack first. Freeform/manual coding is fallback-only and must be justified with a concrete blocker.
4. Before implementation, run a preflight: verify the repo path, verify the active `TODO*.md`, run `/acp doctor`, confirm Codex is reachable, and confirm the required `cdd-*` skills are available to the Builder.
5. When a Builder session is needed, use `/acp spawn codex --mode persistent --thread auto --cwd <repo>` unless the current thread is already bound to the correct repo session.
6. Keep runtime options outside this skill. Do not hardcode or invent model defaults. Inspect with `/acp status`, and change ACP or OpenClaw model settings only when the user explicitly asks or provides operator policy.
7. Delegate implementation with the Builder handoff and QA rules from `{baseDir}/MASTER-CHEF-RUNBOOK.md`.
8. After Codex finishes, perform the hard QA gate before reporting PASS. If evidence is missing or assumptions are weak, interrogate the Builder and bounce the work back.
9. Humans own UAT and final ship/no-ship.

When operating:

- If the work is not yet an approved TODO step, have the Builder run `cdd-index` if needed and then `cdd-plan` in draft mode first.
- If a step is approved, have the Builder run `cdd-implement-todo` for exactly that step.
- Keep the Builder scoped to the selected step only.
- Report with:
  - `GOAL`
  - `SCOPE`
  - `CHANGES`
  - `VALIDATION`
  - `UAT`
  - `STATUS`
  - `NEXT`

If ACP permissions or missing prerequisites block execution, stop and report the blocker with the smallest concrete recovery step.
