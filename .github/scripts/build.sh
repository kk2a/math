#!/usr/bin/env bash

set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_command latexmk

STYLE_DIR="${REPO_ROOT}/_my_style"

compile_tex() {
  local tex_file="$1"
  local work_dir
  local base_name
  work_dir="$(dirname "${tex_file}")"
  base_name="$(basename "${tex_file}")"

  log "Compiling ${tex_file}"
  (
    cd "${work_dir}"
    TEXINPUTS="${STYLE_DIR}//:${TEXINPUTS:-}" \
      latexmk -lualatex -interaction=nonstopmode -halt-on-error "${base_name}"
  )
}

build_figures() {
  local project_dir="$1"
  local fig_dir="${project_dir}/fig"

  [ -d "${fig_dir}" ] || return 0

  local fig_tex
  while IFS= read -r fig_tex; do
    [ -n "${fig_tex}" ] || continue
    compile_tex "${fig_tex}"
  done < <(find "${fig_dir}" -maxdepth 1 -type f -name '*.tex' | sort)
}

build_project() {
  local project_dir="$1"

  log "Building project: ${project_dir}"
  build_figures "${project_dir}"
  compile_tex "${project_dir}/main.tex"
}

main() {
  cd "${REPO_ROOT}"

  local project_dirs
  project_dirs="$("${SCRIPT_DIR}/find-main-tex.sh")"

  if [ -z "${project_dirs}" ]; then
    warn "No project directories with main.tex were found."
    return 0
  fi

  local project_dir
  while IFS= read -r project_dir; do
    [ -n "${project_dir}" ] || continue
    build_project "${project_dir}"
  done <<< "${project_dirs}"

  log "All projects compiled successfully."
}

main "$@"
