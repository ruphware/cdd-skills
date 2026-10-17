# Mode C — Index

Fully rebuild `docs/INDEX.md` (and `docs/index/**` siblings when INDEX split is active) after approval.

## Split detection
- Treat INDEX split as **active** when any of the following holds:
  - `docs/index/` already exists with at least one `*.md` sibling.
  - Current `docs/INDEX.md` exceeds ~300 lines.
  - A single inventory section is on track to grow unboundedly with the codebase (e.g. app source rows that strictly increase with every regen).
- Treat INDEX split as **not active** otherwise; default to single-file emission.
- Once split is detected, keep it active. Do not collapse back to single-file in this mode.

## Write scope
- In single-file mode, write only `docs/INDEX.md`.
- In split-file mode, write only `docs/INDEX.md` plus the `docs/index/**` siblings required by the repo-local INDEX contract. If no repo-local contract names them, default to `DIAGRAMS.md`, `INVENTORY-source.md`, `INVENTORY-tests.md`, and `INVENTORY-other.md` (omit `INVENTORY-other.md` when there is no third-tier inventory worth tracking). New siblings may be created when the split layout calls for them; existing siblings are rewritten in place.
- Never modify `README.md`, `AGENTS.md`, `TODO*.md`, `docs/prompts/*`, `docs/specs/*`, application code, configs, or manifests as part of `index` mode.
- If refreshing the index appears to require a broader doc or code change, stop and ask whether to switch to `doc drift + upkeep`, `source cleanup`, `refactor`, or `cdd-plan`.

## Generation discipline
- If `docs/prompts/PROMPT-INDEX.md` exists, use it as the repo-local INDEX contract.
- Use it for entrypoint, layout, sibling naming, thresholds, and validation when it stays within Mode C write scope.
- Fall back to this skill's default INDEX contract only when the prompt is missing, silent on a point, or clearly stale/broken; report the fallback.
- Treat `docs/INDEX.md` and every `docs/index/**` sibling as output-only. Do not reuse prior prose, diagrams, inventories, or summaries from them as semantic input.
- Rebuild from a fresh, tool-driven scan of tracked source, tests, configs, manifests, entrypoints, and relevant support docs.
- When present, use `README.md`, `TODO.md`, adjacent `TODO*.md`, `docs/specs/blueprint.md`, and project metadata such as `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `mix.exs`, and `requirements*.txt` as repo signals for framework, dependency, and architecture context.
- If `docs/specs/*` or project metadata are missing, continue with the available signals and report the gaps rather than failing or inventing content.
- Read only the project content needed to:
  - understand the repo from `README.md`, `TODO.md`, `TODO-*.md`, and `docs/specs/blueprint.md`
  - enumerate tracked files with repo-local tools
  - identify languages, frameworks, and dependency files
  - map the codebase and tests
  - count LOC, build the file inventory, and extract per-file keywords, symbols, names, and concise meaning
  - apply repo-local LOC tagging rules from `docs/prompts/PROMPT-INDEX.md` when present; otherwise tag files over 760 LOC as `refactor-candidate`
  - derive 2-4 GitHub-safe mermaid diagrams from the rebuilt repo model when useful

## Split-file emission rules
- `docs/INDEX.md` stays slim (≤ ~300 lines): Executive Summary, Project Snapshot, **Layout** pointer block listing each diagram H3 and each sibling inventory, Dependency Map (full mermaid), Glossary, Last Generated footer.
- `docs/index/DIAGRAMS.md` carries every architecture / flow / component mermaid diagram, one H3 per diagram with the same title used in the Layout pointer. Starts with the one-line back-pointer `> Body of [docs/INDEX.md](../INDEX.md) — architecture, flow, and component diagrams.`
- `docs/index/INVENTORY-<area>.md` carries the file & API inventory split by area. Use repo-local sibling names when the INDEX contract defines them; otherwise default to `INVENTORY-source.md`, `INVENTORY-tests.md`, and `INVENTORY-other.md` as appropriate. Each sibling starts with its own back-pointer.
- Do not duplicate any inventory row across siblings — each path belongs in exactly one sibling. Dependency Map and Glossary stay in `docs/INDEX.md`. Only `docs/INDEX.md` carries the `## Last Generated` footer.

## Preflight
- Before proposing the write, emit a concise preflight checklist covering:
  - detected mode (`single-file` or `split-file`) with the trigger that decided it
  - intended changes per file (`docs/INDEX.md` in single mode; `docs/INDEX.md` plus each touched `docs/index/**` sibling in split mode)
  - source files and repo signals used
  - exact validation commands (repo-local commands from `docs/prompts/PROMPT-INDEX.md` when present; otherwise the fallback recipe below)
  - explicit confirmation that no file outside the declared write scope will be modified
- Gate before asking for approval: every preflight item is present; revise the draft until it is. Gate after approval: the mode's validation commands pass.
- Approval surface: the INDEX update.

## Validation

### Single-file mode (fallback)
After approval, if `docs/prompts/PROMPT-INDEX.md` does not define replacement validation commands, run only these fixed validation commands:
- `test -f docs/INDEX.md`
- `rg -n '^# Context for ' docs/INDEX.md`
- `rg -n '^## (Executive Summary|Project Snapshot|Diagrams|File & API Inventory|Dependency Map|Glossary|Last Generated)$' docs/INDEX.md`
- `rg -c '^```mermaid$' docs/INDEX.md`
- `rg -n 'refactor-candidate|\| Path \| Role \| LOC \| Key Tags, Symbols, Names \|' docs/INDEX.md`

### Split-file mode (fallback)
After approval, if `docs/prompts/PROMPT-INDEX.md` does not define replacement validation commands, run only these fixed validation commands:
- `test -f docs/INDEX.md && test -d docs/index && test -f docs/index/DIAGRAMS.md`
- `rg -n '^# Context for ' docs/INDEX.md`
- `rg -n '^## (Executive Summary|Project Snapshot|Layout|Dependency Map|Glossary|Last Generated)$' docs/INDEX.md`
- `rg -c '^```mermaid$' docs/index/DIAGRAMS.md`
- `rg -n 'refactor-candidate|\| Path \| Role \| LOC \| Key Tags, Symbols, Names \|' docs/index/INVENTORY-*.md`
- `rg -nE '^> Body of \[docs/INDEX\.md\]' docs/index/DIAGRAMS.md docs/index/INVENTORY-*.md`
