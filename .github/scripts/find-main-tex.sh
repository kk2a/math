#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

find_main_tex_dirs() {
  cd "${REPO_ROOT}"

  find . \
    -path './.git' -prune -o \
    -path './.github' -prune -o \
    -path './_my_style' -prune -o \
    -path '*/fig' -prune -o \
    -type f -name 'main.tex' -print \
    | sed 's#^./##' \
    | sort \
    | xargs -r -n1 dirname
}

find_main_tex_dirs
