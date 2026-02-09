#!/usr/bin/env bash
set -euo pipefail

read -r file_path || exit 0

if [ -z "${file_path}" ] || [ "${file_path}" = "null" ]; then
  exit 0
fi

if [[ "${file_path}" != /* ]]; then
  file_path="${PWD}/${file_path}"
fi

if [[ "${file_path}" == *.rs ]]; then
  if command -v ruff >/dev/null 2>&1; then
    ruff format "${file_path}"
  fi
  exit 0
fi

search_dir="$(dirname "${file_path}")"
package_dir=""
while true; do
  if [ -f "${search_dir}/package.json" ]; then
    package_dir="${search_dir}"
    break
  fi
  if [ "${search_dir}" = "/" ]; then
    break
  fi
  search_dir="$(dirname "${search_dir}")"
done

if [ -n "${package_dir}" ]; then
  if [ -x "${package_dir}/node_modules/.bin/nr" ]; then
    (cd "${package_dir}" && "${package_dir}/node_modules/.bin/nr" format)
  elif command -v nr >/dev/null 2>&1; then
    (cd "${package_dir}" && nr format)
  elif command -v pnpm >/dev/null 2>&1; then
    (cd "${package_dir}" && pnpm format)
  fi
fi
