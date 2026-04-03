#!/usr/bin/env bash
set -euo pipefail

: "${MY_NAME:?MY_NAME is required}"
: "${MY_EMAIL:?MY_EMAIL is required}"
: "${DEFAULT_NAME:?DEFAULT_NAME is required}"
: "${DEFAULT_EMAIL:?DEFAULT_EMAIL is required}"
: "${REPO_B_URL:?REPO_B_URL is required}"
: "${TARGET_BRANCH:?TARGET_BRANCH is required}"
: "${BEFORE_SHA:?BEFORE_SHA is required}"
: "${AFTER_SHA:?AFTER_SHA is required}"

NAME="${MY_NAME}"
EMAIL="${MY_EMAIL}"
DEFAULT_COMMIT_NAME="${DEFAULT_NAME}"
DEFAULT_COMMIT_EMAIL="${DEFAULT_EMAIL}"
REPO_B="${REPO_B_URL}"
TGT_BRANCH="${TARGET_BRANCH}"
BEFORE="${BEFORE_SHA}"
AFTER="${AFTER_SHA}"
REPO_A_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

read -r -a EXCLUDE_LIST <<< "${EXCLUDES:-}"

log() { echo "[mirror] $*"; }

wipe_worktree() {
  git rm -rf --ignore-unmatch . >/dev/null 2>&1 || true
  git clean -fdx >/dev/null 2>&1 || true
}

remove_excluded_path() {
  local item="$1"

  [[ -n "$item" ]] || return 0

  rm -rf -- "$WORK_DIR/repo-b/$item"
  git rm -rf --cached --ignore-unmatch -- "$item" >/dev/null 2>&1 || true
}

apply_repo_b_overrides() {
  local override_root="$REPO_A_DIR/mirror-overrides"
  local github_pages_workflow="$override_root/github-pages.workflow.yml"

  if [[ -f "$github_pages_workflow" ]]; then
    mkdir -p "$WORK_DIR/repo-b/.github/workflows"
    cp "$github_pages_workflow" "$WORK_DIR/repo-b/.github/workflows/github-pages.yml"
    git add .github/workflows/github-pages.yml
  fi
}

extract_github_username() {
  local email="$1"

  if [[ "$email" =~ ^[0-9]+\+([^@]+)@users\.noreply\.github\.com$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi

  if [[ "$email" =~ ^([^@]+)@users\.noreply\.github\.com$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

resolve_commit_identity() {
  local sha="$1"
  local author_name author_email github_username map_source map_name map_email

  author_name="$(git -C "$REPO_A_DIR" log -1 --format="%an" "$sha")"
  author_email="$(git -C "$REPO_A_DIR" log -1 --format="%ae" "$sha")"
  github_username="$(extract_github_username "$author_email" || true)"

  while IFS='|' read -r map_source map_name map_email; do
    [[ -n "$map_source" ]] || continue

    if [[ "$map_source" == "$github_username" || "$map_source" == "$author_name" ]]; then
      printf '%s|%s\n' "$map_name" "$map_email"
      return 0
    fi
  done <<< "${IDENTITY_MAP:-}"

  printf '%s|%s\n' "$DEFAULT_COMMIT_NAME" "$DEFAULT_COMMIT_EMAIL"
}

git config user.name "$NAME"
git config user.email "$EMAIL"

if [[ "$BEFORE" =~ ^0+$ ]]; then
  mapfile -t COMMITS < <(git -C "$REPO_A_DIR" log --reverse --format="%H" "$AFTER")
else
  mapfile -t COMMITS < <(git -C "$REPO_A_DIR" log --reverse --format="%H" "${BEFORE}..${AFTER}")
fi

if [[ ${#COMMITS[@]} -eq 0 ]]; then
  log "Nothing to mirror."
  exit 0
fi

log "Commits to replay: ${#COMMITS[@]}"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

log "Cloning repo-b ..."
git clone --no-local "$REPO_B" "$WORK_DIR/repo-b" >/dev/null 2>&1

cd "$WORK_DIR/repo-b"
git config user.name "$NAME"
git config user.email "$EMAIL"

if git ls-remote --exit-code --heads origin "$TGT_BRANCH" >/dev/null 2>&1; then
  git fetch origin "$TGT_BRANCH" >/dev/null 2>&1
  git checkout -B "$TGT_BRANCH" "origin/$TGT_BRANCH" >/dev/null 2>&1
else
  git checkout --orphan "$TGT_BRANCH" >/dev/null 2>&1
  wipe_worktree
fi

for SHA in "${COMMITS[@]}"; do
  log "Replaying $SHA ..."

  ORIG_MSG=$(git -C "$REPO_A_DIR" log -1 --format="%B" "$SHA")
  ORIG_DATE=$(git -C "$REPO_A_DIR" log -1 --format="%aI" "$SHA")
  IFS='|' read -r COMMIT_NAME COMMIT_EMAIL < <(resolve_commit_identity "$SHA")

  wipe_worktree
  git -C "$REPO_A_DIR" archive "$SHA" | tar -x -C "$WORK_DIR/repo-b"
  git add -A

  for item in "${EXCLUDE_LIST[@]}"; do
    remove_excluded_path "$item"
  done

  apply_repo_b_overrides

  if git diff --cached --quiet; then
    log "  -> skipping (no changes outside excluded paths)"
    continue
  fi

  GIT_AUTHOR_NAME="$COMMIT_NAME" \
  GIT_AUTHOR_EMAIL="$COMMIT_EMAIL" \
  GIT_AUTHOR_DATE="$ORIG_DATE" \
  GIT_COMMITTER_NAME="$COMMIT_NAME" \
  GIT_COMMITTER_EMAIL="$COMMIT_EMAIL" \
  GIT_COMMITTER_DATE="$ORIG_DATE" \
    git commit -m "$ORIG_MSG" >/dev/null
done

log "Pushing to repo-b branch $TGT_BRANCH ..."
git push origin "$TGT_BRANCH" >/dev/null 2>&1

log "Done"
