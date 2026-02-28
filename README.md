# cdd-skills

Distribution repo for **explicit-only** CDD (Chat-Driven Development) skills.

These skills are packaged using the open Agent Skills standard and the Codex/Codex-CLI layout (`.agents/skills`).

## Install (recommended: copy)

```bash
git clone git@github.com:ruphware/cdd-skills.git ~/Workspace/cdd-skills
cd ~/Workspace/cdd-skills
./scripts/install.sh
```

By default this **copies** skill folders into `~/.agents/skills/`.

Options:
- `--target <dir>` (repeatable) to install into additional skill roots
- `--force` to overwrite existing installed skill dirs
- `--link` to symlink instead of copy (not recommended; some tools may not reliably discover symlinked skills)

## Install via `$skill-installer` (Codex)

In Codex, you can install a skill from a GitHub URL. Examples:

```text
$skill-installer install https://github.com/ruphware/cdd-skills/tree/main/.agents/skills/cdd-ship-step
$skill-installer install https://github.com/ruphware/cdd-skills/tree/main/.agents/skills/cdd-refresh-index
```

(If newly installed skills don’t appear immediately, restart Codex.)

## Skills

Planning (approval-gated, explicit-only):
- `cdd-write-prd`
- `cdd-write-blueprint`
- `cdd-prd-to-todo`
- `cdd-plan-feature`
- `cdd-plan-refactor`
- `cdd-audit-to-plan`

Execution (explicit-only):
- `cdd-ship-step`

Index maintenance (explicit-only):
- `cdd-refresh-index`

All skills disable implicit invocation; use explicit `$cdd-...` invocation.
