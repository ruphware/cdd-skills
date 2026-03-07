---
name: cdd-index
description: "Regenerate docs/INDEX.md using docs/prompts/PROMPT-INDEX.md (explicit-only)."
disable-model-invocation: true
---

# CDD Index (explicit-only)

Use `docs/prompts/PROMPT-INDEX.md` as the sole source of truth.

## Flow
1) Read `docs/prompts/PROMPT-INDEX.md` and follow it verbatim.
2) Draft what you will run/change, then ask approval to update `docs/INDEX.md`.
3) Update `docs/INDEX.md` according to PROMPT-INDEX.
