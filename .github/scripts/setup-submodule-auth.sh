#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SSH_DIR="${RUNNER_TEMP:-/tmp}/submodule-ssh"

configure_ssh() {
  local key_file="${SSH_DIR}/deploy_key"
  local known_hosts_file="${SSH_DIR}/known_hosts"

  rm -rf "${SSH_DIR}"
  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"

  printf '%s\n' "${SUBMODULE_DEPLOY_KEY}" > "${key_file}"
  chmod 600 "${key_file}"

  ssh-keyscan -t rsa,ecdsa,ed25519 github.com 2>/dev/null | sort -u > "${known_hosts_file}"
  [ -s "${known_hosts_file}" ] || die "Failed to collect GitHub SSH host keys."
  chmod 644 "${known_hosts_file}"

  {
    echo "GIT_SSH_COMMAND=ssh -i ${key_file} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${known_hosts_file}"
  } >> "${GITHUB_ENV}"

  log "Configured SSH authentication for private submodules."
}

configure_https() {
  git config --global --add url."https://github.com/".insteadOf "git@github.com:"
  git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
  log "Configured HTTPS rewrite for public submodules."
}

main() {
  if [ -n "${SUBMODULE_DEPLOY_KEY:-}" ]; then
    require_command ssh
    require_command ssh-keyscan
    configure_ssh
  else
    configure_https
  fi
}

main "$@"
