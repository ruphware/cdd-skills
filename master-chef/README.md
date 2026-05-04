# CDD Master Chef

This directory is the shared source of truth for the multi-runtime `cdd-master-chef` workflow.

Use these files as the canonical contract surfaces:

- `CONTRACT.md` — runtime-agnostic Master Chef behavior
- `RUNTIME-CAPABILITIES.md` — capability boundaries for OpenClaw, Codex, and Claude Code

Runtime adapters consume that shared contract and define how a specific runtime realizes it:

- `openclaw/` — current installable adapter package and runtime-specific docs
- Codex adapter rules — tracked in the shared capability matrix now; detailed adapter contract follows in later repo work
- Claude Code adapter rules — tracked in the shared capability matrix now; detailed adapter contract follows in later repo work

Relationship to the rest of the repo:

- `skills/` remains the canonical Builder workflow source for the `cdd-*` skills.
- `openclaw/` is no longer the only Master Chef source of truth; it is the OpenClaw adapter over the shared contract defined here.
- Packaging and installer unification are separate follow-on work. This directory defines the shared behavior first so adapter and packaging work can follow a stable contract.
