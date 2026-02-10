#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${FORMAT_HOOK_LOG:-${HOME}/.claude/hooks/format-hook.log}"
mkdir -p "$(dirname "${LOG_FILE}")"
exec >>"${LOG_FILE}" 2>&1

log() {
  printf '[format.sh] %s\n' "$*"
}

read -r file_path || exit 0

if [ -z "${file_path}" ] || [ "${file_path}" = "null" ]; then
  log "empty or null file_path; exiting"
  exit 0
fi

log "raw file_path=${file_path}"

if [[ "${file_path}" != /* ]]; then
  file_path="${PWD}/${file_path}"
fi

log "normalized file_path=${file_path}"

if [[ "${file_path}" == *.rs ]]; then
  if command -v ruff >/dev/null 2>&1; then
    log "ruff format ${file_path}"
    if ! ruff format "${file_path}"; then
      log "ruff format failed (exit=$?)"
    fi
  else
    log "ruff not found; skipping"
  fi
  exit 0
fi

search_dir="$(dirname "${file_path}")"
package_dir=""
workspace_dir=""
log "searching for package.json/pnpm-workspace.yaml from ${search_dir}"
while true; do
  if [ -f "${search_dir}/pnpm-workspace.yaml" ]; then
    workspace_dir="${search_dir}"
  fi
  if [ -f "${search_dir}/package.json" ]; then
    package_dir="${search_dir}"
    if [ -n "${workspace_dir}" ]; then
      break
    fi
  fi
  if [ "${search_dir}" = "/" ]; then
    break
  fi
  search_dir="$(dirname "${search_dir}")"
done

if [ -n "${workspace_dir}" ] && command -v pnpm >/dev/null 2>&1; then
  log "workspace_dir=${workspace_dir}"
  log "running pnpm -w format"
  if (cd "${workspace_dir}" && pnpm -w format); then
    exit 0
  else
    status=$?
    log "pnpm -w format failed (exit=${status})"
  fi
fi

if [ -n "${package_dir}" ]; then
  log "package_dir=${package_dir}"
  if [ -x "${package_dir}/node_modules/.bin/nr" ]; then
    log "running ${package_dir}/node_modules/.bin/nr format"
    if (cd "${package_dir}" && "${package_dir}/node_modules/.bin/nr" format); then
      :
    else
      status=$?
      log "nr format failed (exit=${status})"
    fi
  elif command -v nr >/dev/null 2>&1; then
    log "running nr format"
    if (cd "${package_dir}" && nr format); then
      :
    else
      status=$?
      log "nr format failed (exit=${status})"
    fi
  elif command -v pnpm >/dev/null 2>&1; then
    log "running pnpm format"
    if (cd "${package_dir}" && pnpm format); then
      :
    else
      status=$?
      log "pnpm format failed (exit=${status})"
    fi
  else
    log "no formatter command found"
  fi
else
  log "package_dir not found; skipping"
fi
