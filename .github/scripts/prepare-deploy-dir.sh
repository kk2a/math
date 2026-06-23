#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEPLOY_DIR="${1:-${REPO_ROOT}/dist}"

main() {
  cd "${REPO_ROOT}"

  rm -rf "${DEPLOY_DIR}"
  mkdir -p "${DEPLOY_DIR}"

  if [ -f index.html ]; then
    cp index.html "${DEPLOY_DIR}/index.html"
  else
    die "Root index.html does not exist. Run generate-index.py first."
  fi

  local pdf
  while IFS= read -r pdf; do
    [ -n "${pdf}" ] || continue

    local project_dir
    project_dir="$(dirname "${pdf}")"
    mkdir -p "${DEPLOY_DIR}/${project_dir}"
    cp "${pdf}" "${DEPLOY_DIR}/${pdf}"

    if [ -f "${project_dir}/index.html" ]; then
      cp "${project_dir}/index.html" "${DEPLOY_DIR}/${project_dir}/index.html"
    else
      warn "Missing ${project_dir}/index.html"
    fi
  done < <(find . \
    -path './.git' -prune -o \
    -path './.github' -prune -o \
    -path './_my_style' -prune -o \
    -type f -path '*/main.pdf' ! -path '*/fig/*' -print \
    | sed 's#^./##' \
    | sort)

  log "Prepared deploy directory: ${DEPLOY_DIR}"
}

main "$@"
