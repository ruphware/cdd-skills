#!/usr/bin/env bash
set -euo pipefail

# Unified local smoke-test + remote audit + heuristic explanation workflow.
#
# Examples:
#   bash scripts/test-skill-audit.sh
#   bash scripts/test-skill-audit.sh --skip-local --only-flagged
#   bash scripts/test-skill-audit.sh --source ruphware/cdd-skills --keep-sandbox

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE=""
SKIP_LOCAL=0
SKIP_REMOTE=0
ONLY_FLAGGED=0
KEEP_SANDBOX=0
LOCAL_SANDBOX_ROOT=""

usage() {
  cat <<'EOF'
Usage: bash scripts/test-skill-audit.sh [options]

Run the local install smoke test, fetch the live remote skill audit, and print
local heuristic explanations for flagged results.

Options:
  --source owner/repo  Override the GitHub source repo used for the remote audit
  --skip-local         Skip the local install smoke test
  --skip-remote        Skip the remote audit fetch and explanation
  --only-flagged       Show only non-safe/non-low findings in remote output and explanation
  --keep-sandbox       Preserve the local smoke-test sandbox directory
  -h, --help           Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --skip-local)
      SKIP_LOCAL=1
      shift
      ;;
    --skip-remote)
      SKIP_REMOTE=1
      shift
      ;;
    --only-flagged)
      ONLY_FLAGGED=1
      shift
      ;;
    --keep-sandbox)
      KEEP_SANDBOX=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "Missing required command: python3" >&2
  exit 1
fi

AUDIT_URL="${SKILLS_AUDIT_URL:-https://add-skill.vercel.sh/audit}"
TIMEOUT_SECONDS="${SKILLS_AUDIT_TIMEOUT:-10}"

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || {
    echo "Missing expected path: $path" >&2
    exit 1
  }
}

infer_source_from_origin() {
  local remote_url
  remote_url="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote_url" ]] || return 1

  case "$remote_url" in
    git@github.com:*)
      remote_url="${remote_url#git@github.com:}"
      remote_url="${remote_url%.git}"
      ;;
    ssh://git@github.com/*)
      remote_url="${remote_url#ssh://git@github.com/}"
      remote_url="${remote_url%.git}"
      ;;
    https://github.com/*|http://github.com/*)
      remote_url="${remote_url#https://github.com/}"
      remote_url="${remote_url#http://github.com/}"
      remote_url="${remote_url%.git}"
      ;;
    *)
      return 1
      ;;
  esac

  if [[ "$remote_url" == */* && "$remote_url" != */*/* ]]; then
    printf '%s\n' "$remote_url"
    return 0
  fi

  return 1
}

collect_skill_names_csv() {
  local names=()
  local skill_dir

  for skill_dir in "$ROOT_DIR"/skills/*; do
    [[ -d "$skill_dir" ]] || continue
    [[ -f "$skill_dir/SKILL.md" ]] || continue

    local name
    name="$(
      awk '
        BEGIN { in_frontmatter = 0 }
        /^---[[:space:]]*$/ {
          if (in_frontmatter == 0) {
            in_frontmatter = 1
            next
          }
          exit
        }
        in_frontmatter == 1 && /^name:[[:space:]]*/ {
          sub(/^name:[[:space:]]*/, "", $0)
          gsub(/^["'"'"'"'"'"'"'"'"']|["'"'"'"'"'"'"'"'"']$/, "", $0)
          print $0
          exit
        }
      ' "$skill_dir/SKILL.md"
    )"

    if [[ -z "$name" ]]; then
      name="$(basename "$skill_dir")"
    fi

    names+=("$name")
  done

  if [[ ${#names[@]} -eq 0 ]]; then
    echo "No skills found under: $ROOT_DIR/skills" >&2
    exit 1
  fi

  local IFS=,
  printf '%s\n' "${names[*]}"
}

cleanup_local_sandbox() {
  [[ -n "$LOCAL_SANDBOX_ROOT" ]] || return 0

  if [[ $KEEP_SANDBOX -eq 1 ]]; then
    echo "[LocalInstall] INFO SandboxPreserved root={$LOCAL_SANDBOX_ROOT}"
    echo "[LocalInstall] INFO CleanupCommand cmd={rm -rf $LOCAL_SANDBOX_ROOT}"
  else
    rm -rf "$LOCAL_SANDBOX_ROOT"
  fi
}

run_local_smoke_test() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "Missing required command: npx" >&2
    exit 1
  fi

  local sandbox_root
  sandbox_root="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skills-local-install.XXXXXX")"
  LOCAL_SANDBOX_ROOT="$sandbox_root"

  local home_dir="$sandbox_root/home"
  local xdg_config_home="$sandbox_root/xdg-config"
  local codex_home="$sandbox_root/codex-home"
  local claude_config_dir="$sandbox_root/claude-home"
  local run_dir="$sandbox_root/run"
  local npm_cache_dir="$sandbox_root/npm-cache"
  local universal_skills_dir="$home_dir/.agents/skills"
  local claude_skills_dir="$claude_config_dir/skills"

  mkdir -p "$home_dir" "$xdg_config_home" "$codex_home" "$claude_config_dir" "$run_dir" "$npm_cache_dir"

  local skills=()
  local skill_dir
  for skill_dir in "$ROOT_DIR"/skills/*; do
    [[ -d "$skill_dir" ]] || continue
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skills+=("$(basename "$skill_dir")")
  done

  if [[ ${#skills[@]} -eq 0 ]]; then
    echo "No skills found under: $ROOT_DIR/skills" >&2
    exit 1
  fi

  echo "[LocalInstall] INFO SandboxCreated root={$sandbox_root}"
  echo "[LocalInstall] INFO SkillSource root={$ROOT_DIR/skills} count={${#skills[@]}}"
  echo "[LocalInstall] INFO AuditMode mode={skipped} reason={local path source does not request remote audit}"

  local install_cmd=(
    npx
    --yes
    skills
    add
    "$ROOT_DIR/skills"
    --skill
    "*"
    --agent
    codex
    claude-code
    gemini-cli
    --global
    --yes
    --copy
  )

  (
    cd "$run_dir"
    HOME="$home_dir" \
    XDG_CONFIG_HOME="$xdg_config_home" \
    CODEX_HOME="$codex_home" \
    CLAUDE_CONFIG_DIR="$claude_config_dir" \
    NPM_CONFIG_CACHE="$npm_cache_dir" \
    "${install_cmd[@]}"
  )

  local skill
  for skill in "${skills[@]}"; do
    assert_exists "$universal_skills_dir/$skill/SKILL.md"
    assert_exists "$claude_skills_dir/$skill/SKILL.md"
    echo "[LocalInstall] INFO InstalledSkill name={$skill}"
  done

  echo "[LocalInstall] INFO AgentRoot agent={codex} path={$universal_skills_dir}"
  echo "[LocalInstall] INFO AgentRoot agent={claude-code} path={$claude_skills_dir}"
  echo "[LocalInstall] INFO AgentRoot agent={gemini-cli} path={$universal_skills_dir}"
  echo "[LocalInstall] INFO InstallVerified skills={${#skills[@]}} agents={3}"
}

echo "[SkillAudit] INFO Repo root={$ROOT_DIR}"
if [[ -n "$SOURCE" ]]; then
  echo "[SkillAudit] INFO Remote source override={$SOURCE}"
else
  echo "[SkillAudit] INFO Remote source override={none}"
fi
echo "[SkillAudit] INFO Caveat note={local smoke tests validate installability; remote audit reflects pushed GitHub repo state only}"

if [[ $SKIP_LOCAL -eq 0 ]]; then
  echo
  echo "[SkillAudit] INFO Phase name={local-smoke-test}"
  run_local_smoke_test
fi

if [[ $SKIP_REMOTE -eq 1 ]]; then
  echo
  echo "[SkillAudit] INFO Phase name={remote-audit} status={skipped}"
  exit 0
fi

if [[ -z "$SOURCE" ]]; then
  SOURCE="$(infer_source_from_origin || true)"
fi

if [[ -z "$SOURCE" ]]; then
  echo "Could not infer GitHub owner/repo from git remote 'origin'. Use --source owner/repo." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Missing required command: curl" >&2
  exit 1
fi

SKILLS_CSV="$(collect_skill_names_csv)"
SKILL_COUNT="$(awk -F, '{ print NF }' <<<"$SKILLS_CSV")"

echo
echo "[SkillAudit] INFO Phase name={remote-audit}"
echo "[SkillAudit] INFO Remote source repo={$SOURCE}"
echo "[SkillAudit] INFO Remote scope mode={remote} note={uses pushed repo state only; local-only edits are ignored}"
echo "[SkillAudit] INFO Remote skills count={$SKILL_COUNT}"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cdd-skill-audit.XXXXXX")"
AUDIT_JSON="$TMP_DIR/audit.json"
cleanup() {
  cleanup_local_sandbox
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

curl -sSf --get --max-time "$TIMEOUT_SECONDS" \
  --data-urlencode "source=$SOURCE" \
  --data-urlencode "skills=$SKILLS_CSV" \
  "$AUDIT_URL" >"$AUDIT_JSON"

python3 - "$AUDIT_JSON" "$ONLY_FLAGGED" "$ROOT_DIR" "$SOURCE" <<'PY'
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

audit_json = Path(sys.argv[1])
only_flagged = sys.argv[2] == "1"
root = Path(sys.argv[3])
source = sys.argv[4]
payload = json.loads(audit_json.read_text())


@dataclass(frozen=True)
class Match:
    scanner: str
    rule: str
    line_no: int
    line_text: str


def label(entry):
    if not entry:
        return "--"
    risk = entry.get("risk")
    if risk == "safe":
        return "Safe"
    if risk == "low":
        return "Low Risk"
    if risk == "medium":
        return "Med Risk"
    if risk == "high":
        return "High Risk"
    if risk == "critical":
        return "Critical Risk"
    return "--"


def socket_label(entry):
    if not entry:
        return "--"
    alerts = entry.get("alerts", 0)
    if alerts == 1:
        return "1 alert"
    return f"{alerts} alerts"


def is_flagged(entry):
    if not entry:
        return False
    ath = entry.get("ath", {})
    snyk = entry.get("snyk", {})
    socket = entry.get("socket", {})
    return (
        ath.get("risk") not in (None, "safe", "low")
        or snyk.get("risk") not in (None, "safe", "low")
        or socket.get("alerts", 0) > 0
    )


GEN_PATTERNS = [
    (
        "Explicit no-approval mutation language",
        [
            r"\bdo not ask for approval\b",
            r"\bupdate .* immediately\b",
            r"\bapply .* immediately\b",
            r"\brewrite .* immediately\b",
        ],
    ),
    (
        "Broad write authority",
        [
            r"\bupdate `[^`]+`.*\bupdate `[^`]+`",
            r"\bupdate .*README\.md\b",
            r"\bupdate .*AGENTS\.md\b",
            r"\breorganize docs\b",
            r"\bmove/normalize .*docs\b",
        ],
    ),
    (
        "Destructive or strong mutation verbs",
        [
            r"\bdelete\b",
            r"\bremove\b",
            r"\bmove\b",
            r"\boverwrite\b",
            r"\barchive\b",
            r"\bprune\b",
        ],
    ),
]

SNYK_PATTERNS = [
    (
        "Repo-admin or networked actions",
        [
            r"\bclone\b",
            r"\bdownload\b",
            r"\bcreate (?:a )?github repo\b",
            r"\bcreate (?:the )?remote\b",
            r"\bgit init\b",
            r"\bgit push\b",
            r"\bgithub-backed repo\b",
        ],
    ),
    (
        "User-content relocation",
        [
            r"\bstage discovered .*documents\b",
            r"\brestore .*documents\b",
            r"\bmove/normalize .*docs\b",
            r"\brestore .* under `docs/source-material/`\b",
        ],
    ),
    (
        "Bootstrap or migration workflow",
        [
            r"\bbootstrap `cdd-boilerplate`\b",
            r"\bmigration plan\b",
            r"\badopt the CDD contract\b",
            r"\bmaterialize the boilerplate\b",
        ],
    ),
]


def compile_patterns(rules):
    return [(rule_name, [re.compile(pattern, re.IGNORECASE) for pattern in patterns]) for rule_name, patterns in rules]


COMPILED_GEN = compile_patterns(GEN_PATTERNS)
COMPILED_SNYK = compile_patterns(SNYK_PATTERNS)


def read_skill_name(skill_md: Path) -> str:
    in_frontmatter = False
    for raw_line in skill_md.read_text().splitlines():
        if raw_line.strip() == "---":
            if not in_frontmatter:
                in_frontmatter = True
                continue
            break
        if in_frontmatter and raw_line.startswith("name:"):
            return raw_line.split(":", 1)[1].strip().strip("\"'")
    return skill_md.parent.name


def scan_lines(lines, scanner):
    rules = COMPILED_GEN if scanner == "Gen" else COMPILED_SNYK
    matches = []
    for line_no, raw_line in enumerate(lines, start=1):
        line = raw_line.rstrip()
        for rule_name, patterns in rules:
            if any(pattern.search(line) for pattern in patterns):
                matches.append(Match(scanner=scanner, rule=rule_name, line_no=line_no, line_text=line))
                break
    return matches


def print_explainer():
    skill_map = {}
    for skill_md in sorted((root / "skills").glob("*/SKILL.md")):
        skill_map[read_skill_name(skill_md)] = skill_md

    flagged_names = [name for name in sorted(payload) if is_flagged(payload.get(name))]
    if only_flagged:
        names = flagged_names
    else:
        names = flagged_names

    print()
    print("[SkillAudit] INFO Phase name={local-explainer}")
    if not names:
        print("No flagged skills with local explanations.")
        return

    print("# Likely Local Triggers")
    print()
    for index, skill_name in enumerate(names):
        if index > 0:
            print()
        entry = payload.get(skill_name, {})
        skill_md = skill_map.get(skill_name)
        print(f"## {skill_name}")
        if skill_md is None:
            print("- File: missing local SKILL.md for this skill name.")
            continue
        print(f"- File: {skill_md}")
        print(
            "- Remote result: "
            f"Gen={label(entry.get('ath'))}, "
            f"Socket={socket_label(entry.get('socket'))}, "
            f"Snyk={label(entry.get('snyk'))}"
        )
        print("- Likely local triggers: heuristic only; not the scanner's exact reasoning.")
        lines = skill_md.read_text().splitlines()
        for scanner, remote_key in (("Gen", "ath"), ("Snyk", "snyk")):
            remote_entry = entry.get(remote_key, {})
            if remote_entry.get("risk") in (None, "safe", "low"):
                continue
            matches = scan_lines(lines, scanner)
            print(f"- {scanner} likely triggers:")
            if not matches:
                print("  - No local heuristic matches found in `SKILL.md`.")
                continue
            seen = set()
            for match in matches:
                key = (match.rule, match.line_no)
                if key in seen:
                    continue
                seen.add(key)
                print(
                    f"  - {match.rule}: "
                    f"[{skill_md.name}]({skill_md}:{match.line_no}) "
                    f"`{match.line_text.strip()}`"
                )


rows = []
for skill_name in sorted(payload):
    entry = payload[skill_name]
    if only_flagged and not is_flagged(entry):
        continue
    rows.append((skill_name, label(entry.get("ath")), socket_label(entry.get("socket")), label(entry.get("snyk"))))

if only_flagged and not rows:
    print("No flagged skills in remote audit output.")
    sys.exit(0)

name_width = max(len("Skill"), *(len(row[0]) for row in rows))
gen_width = max(len("Gen"), *(len(row[1]) for row in rows))
socket_width = max(len("Socket"), *(len(row[2]) for row in rows))
snyk_width = max(len("Snyk"), *(len(row[3]) for row in rows))

header = f"{'Skill':<{name_width}}  {'Gen':<{gen_width}}  {'Socket':<{socket_width}}  {'Snyk':<{snyk_width}}"
print(header)
print("-" * len(header))
for row in rows:
    print(f"{row[0]:<{name_width}}  {row[1]:<{gen_width}}  {row[2]:<{socket_width}}  {row[3]:<{snyk_width}}")
print()
print(f"Details: https://skills.sh/{source}")
print_explainer()
PY
