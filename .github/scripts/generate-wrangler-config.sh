#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEPLOY_DIR="${1:-${REPO_ROOT}/dist}"
PUBLIC_DIR="${PUBLIC_DIR:-public}"
WORKER_NAME="${WORKER_NAME:-math}"
WORKER_COMPATIBILITY_DATE="${WORKER_COMPATIBILITY_DATE:-2026-07-01}"

main() {
  mkdir -p "${DEPLOY_DIR}"

  cat > "${DEPLOY_DIR}/wrangler.toml" <<EOF
name = "${WORKER_NAME}"
compatibility_date = "${WORKER_COMPATIBILITY_DATE}"

[assets]
directory = "./${PUBLIC_DIR}/"
EOF

  log "Generated Workers config: ${DEPLOY_DIR}/wrangler.toml"
}

main "$@"
