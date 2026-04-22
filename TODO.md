# TODO

## Step 01 — Make GitHub boilerplate source explicit and approval-gated

### Goal

Make `cdd-init-project` treat `https://github.com/ruphware/cdd-boilerplate` as the canonical bootstrap source when boilerplate material is needed, while keeping copy/download from that source behind explicit user approval.

### Constraints

- Preserve separate explicit approval for clone, download, remote creation, `git init`, and `git push`.
- Do not describe a local `cdd-boilerplate` checkout as the preferred default path.
- Preserve local-path fallback wording for local-only or network-restricted cases.

### Tasks

- [x] Update `skills/cdd-init-project/SKILL.md` so bootstrap-source language names `https://github.com/ruphware/cdd-boilerplate` as the canonical source in Empty-directory and Docs-seeded flows.
- [x] Rewrite bootstrap-path instructions so the skill asks for explicit approval before copying, cloning, or otherwise materializing boilerplate from that GitHub source, instead of implying that the source can be used immediately.
- [x] Keep local checkout usage as an explicit fallback or user-selected alternative rather than the preferred default.
- [x] Extend `scripts/validate_skills.py` to assert the init skill includes the direct GitHub source rule and the explicit approval rule for copying/downloading from it.

### Implementation notes

- Touch only the canonical skill source and validator unless a failing check proves another surface is required.
- Keep the existing high-impact action guardrails intact.
- The wording should make the security boundary obvious: canonical source is GitHub, execution still waits for user approval.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated init skill and confirm the default bootstrap source is `https://github.com/ruphware/cdd-boilerplate`.
- Confirm the skill still requires explicit approval before copying/downloading boilerplate from that source.
- Confirm local checkout wording remains available only as fallback or explicit choice.

## Step 02 — Require the CDD README header block with adoption confirmation

### Goal

Make `cdd-init-project` require the exact CDD README header block in initialized repos, and require explicit user confirmation before adding that block to an existing project `README.md` during CDD adoption.

### Constraints

- Preserve `README.md` as the runbook entrypoint.
- For fresh/bootstrap repos, require the exact block under the title and short project description.
- For existing-repo adoption, do not add the block unless the user explicitly confirms that README edit.
- Avoid duplicate insertion when the block or its badges already exist.

### Tasks

- [ ] Update `skills/cdd-init-project/SKILL.md` so README-drafting steps for fresh/bootstrap flows require this exact block under the title and project description:
  `[![CDD Project](https://img.shields.io/badge/CDD-Project-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-boilerplate)`
  `[![CDD Skills](https://img.shields.io/badge/CDD-Skills-ecc569?style=flat-square&labelColor=0d1a26)](https://github.com/ruphware/cdd-skills)`
  `> This repo follows the [`CDD Project`](https://github.com/ruphware/cdd-boilerplate) + [`CDD Skills`](https://github.com/ruphware/cdd-skills) workflow with the local [`AGENTS.md`](./AGENTS.md) contract.`
  `> Start with `$cdd-boot`. Use `$cdd-plan` + `$cdd-implement-todo` for feature work, `$cdd-maintain` for upkeep and drift control, and `$cdd-refactor` for structured refactors.`
- [ ] Update existing-repo adoption guidance so the skill must ask for confirmation before adding that full block to an existing `README.md`.
- [ ] Extend `scripts/validate_skills.py` to assert both the exact block requirement and the existing-README confirmation rule.

### Implementation notes

- The confirmation rule is for the full block, not just badges.
- Fresh/bootstrap flows and existing-repo adoption may need different wording in the skill; keep that distinction explicit.
- Keep the snippet placement rule precise: under title and short description, before the rest of the runbook.

### Automated checks

- `python3 scripts/validate_skills.py`

### UAT

- Read the updated init skill and confirm the exact block is present for fresh/bootstrap README generation.
- Confirm the placement rule says the block goes under the title and project description.
- Confirm existing-repo adoption now asks before modifying `README.md` with that full block.
