#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEPLOY_DIR="${1:-${REPO_ROOT}/dist}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-deploy}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-Deploy built PDFs}"

main() {
  [ -d "${DEPLOY_DIR}" ] || die "Deploy directory does not exist: ${DEPLOY_DIR}"
  DEPLOY_DIR="$(cd "${DEPLOY_DIR}" && pwd)"

  cd "${REPO_ROOT}"

  git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
  git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

  local worktree_dir
  worktree_dir="$(mktemp -d)"
  trap 'git worktree remove --force "${worktree_dir}" >/dev/null 2>&1 || true; rm -rf "${worktree_dir}"' EXIT

  if git ls-remote --exit-code --heads origin "${DEPLOY_BRANCH}" >/dev/null 2>&1; then
    log "Checking out existing deploy branch: ${DEPLOY_BRANCH}"
    git fetch --depth=1 origin "${DEPLOY_BRANCH}"
    git worktree add "${worktree_dir}" "FETCH_HEAD"
  else
    log "Creating orphan deploy branch: ${DEPLOY_BRANCH}"
    git worktree add --detach "${worktree_dir}" HEAD
    (
      cd "${worktree_dir}"
      git checkout --orphan "${DEPLOY_BRANCH}"
      git rm -rf . >/dev/null 2>&1 || true
    )
  fi

  (
    cd "${worktree_dir}"
    find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    cp -a "${DEPLOY_DIR}/." .
    touch .nojekyll

    git add -A
    if git diff --cached --quiet; then
      log "No deploy changes to push."
      exit 0
    fi

    git commit -m "${COMMIT_MESSAGE}"
    git push origin "HEAD:${DEPLOY_BRANCH}"
  )
}

main "$@"
