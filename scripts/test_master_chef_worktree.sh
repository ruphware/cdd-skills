#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cdd-master-chef-worktree.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "$1" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "Missing expected path: $path"
}

assert_contains() {
  local path="$1"
  local text="$2"
  grep -F "$text" "$path" >/dev/null || fail "Expected '$text' in $path"
}

assert_matches() {
  local path="$1"
  local pattern="$2"
  grep -E -- "$pattern" "$path" >/dev/null || fail "Expected regex '$pattern' in $path"
}

assert_clean_checkout() {
  local repo="$1"
  [[ -z "$(git -C "$repo" status --short)" ]]
}

create_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.name "CDD Test"
  git -C "$repo" config user.email "cdd@example.com"
  echo "base" >"$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -qm "init"
  git -C "$repo" branch -M main
}

echo "[MasterChefWorktree] INFO TestStart root={$TMP_ROOT}"

clean_repo="$TMP_ROOT/clean-repo"
create_repo "$clean_repo"

echo "[MasterChefWorktree] INFO CleanRepoPrepared repo={$clean_repo}"
assert_clean_checkout "$clean_repo"

run_id="run-001"
worktree_branch="master-chef/$run_id"
worktree_path="$clean_repo/.cdd-runtime/worktrees/$run_id"

git -C "$clean_repo" worktree add "$worktree_path" -b "$worktree_branch" HEAD >/dev/null
assert_exists "$worktree_path/.git"

current_worktree_branch="$(git -C "$worktree_path" branch --show-current)"
[[ "$current_worktree_branch" == "$worktree_branch" ]] || fail "Unexpected worktree branch: $current_worktree_branch"

source_branch="$(git -C "$clean_repo" branch --show-current)"
[[ "$source_branch" == "main" ]] || fail "Unexpected source branch after worktree creation: $source_branch"

source_head="$(git -C "$clean_repo" rev-parse HEAD)"
worktree_head="$(git -C "$worktree_path" rev-parse HEAD)"
[[ "$source_head" == "$worktree_head" ]] || fail "Worktree HEAD does not match source HEAD"

echo "[MasterChefWorktree] INFO WorktreeCreated branch={$worktree_branch} path={$worktree_path}"

second_path="$clean_repo/.cdd-runtime/worktrees/run-002"
if git -C "$clean_repo" worktree add "$second_path" "$worktree_branch" >/dev/null 2>&1; then
  fail "Expected same-branch second worktree creation to fail"
fi

echo "[MasterChefWorktree] INFO SameBranchReuseRejected branch={$worktree_branch}"

dirty_repo="$TMP_ROOT/dirty-repo"
create_repo "$dirty_repo"
echo "dirty" >>"$dirty_repo/file.txt"
if assert_clean_checkout "$dirty_repo"; then
  fail "Expected dirty repo preflight to fail"
fi

echo "[MasterChefWorktree] INFO DirtyPreflightRejected repo={$dirty_repo}"

assert_matches "$ROOT_DIR/cdd-master-chef/CONTRACT.md" "source checkout must be clean|Before kickoff.*clean"
assert_contains "$ROOT_DIR/cdd-master-chef/CONTRACT.md" "active_worktree_path"
assert_contains "$ROOT_DIR/cdd-master-chef/CONTRACT.md" ".cdd-runtime/worktrees/<run-id>/"
assert_matches "$ROOT_DIR/cdd-master-chef/RUNBOOK.md" "stop with exact relaunch instructions|exact relaunch instructions"
assert_contains "$ROOT_DIR/cdd-master-chef/RUNBOOK.md" "<source-repo>/.cdd-runtime/worktrees/<run-id>/"
assert_matches "$ROOT_DIR/cdd-master-chef/openclaw/README.md" "After relaunch.*managed worktree.*active repo root|managed worktree.*active repo root"
assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/README.md" ".cdd-runtime/worktrees/<run-id>/"
assert_contains "$ROOT_DIR/cdd-master-chef/openclaw/MASTER-CHEF-RUNBOOK.md" "worktree_continue_mode"
assert_contains "$ROOT_DIR/.gitignore" ".cdd-runtime/"

echo "[MasterChefWorktree] INFO ContractDocsVerified root={$ROOT_DIR}"
echo "[MasterChefWorktree] INFO TestPassed root={$TMP_ROOT}"
