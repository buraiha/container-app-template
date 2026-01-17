#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/vars.sh"
ENGINE="$("${SCRIPT_DIR}/../common/engine.sh")"

# 既存コンテナがいたら止めて削除（残したいなら rename 運用）
if "${ENGINE}" ps -a --format '{{.Names}}' | grep -qx "${APP_NAME}-prd"; then
  echo "container exists: ${APP_NAME}-prd" >&2
  echo "remove it first (or rename it) before running." >&2
  exit 1
fi

if [[ ! -d "${HOST_DATA_DIR}" ]]; then
  echo "data dir not found: ${HOST_DATA_DIR}" >&2
  exit 1
fi

# CMDはアプリごとに起動処理のカスタマイズが必要となる
# 以下はサンプルとして./runserer.shという起動スクリプトを指定している。
CMD=( "./runserver.sh" )
if [[ "${1:-}" == "bash" ]]; then
  CMD=( "bash" )
fi

ENV_FILE="${SCRIPT_DIR}/ENVIRONMENTS"
ENV_OPT=()
if [[ -f "${ENV_FILE}" ]]; then
  ENV_OPT=( --env-file "${ENV_FILE}" )
fi

exec "${ENGINE}" run -it \
  --name "${APP_NAME}-prd" \
  -p "${HOST_PORT}:${CTR_PORT}" \
  "${ENV_OPT[@]}" \
  -v "${HOST_DATA_DIR}:${CTR_DATA_DIR}" \
  -w "${CTR_APP_DIR}" \
  "${IMAGE_PRD}" \
  "${CMD[@]}"
  