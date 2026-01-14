#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/vars.sh"
ENGINE="$("${SCRIPT_DIR}/../common/engine.sh")"

if [[ ! -d "${HOST_REPOS_DIR}" ]]; then
  echo "repos dir not found: ${HOST_REPOS_DIR}" >&2
  exit 1
fi

exec "${ENGINE}" build \
  -t "${IMAGE_DEV}" \
  -f "${SCRIPT_DIR}/Dockerfile" \
  "${HOST_REPOS_DIR}"
