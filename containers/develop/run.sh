#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/vars.sh"
ENGINE="$("${SCRIPT_DIR}/../common/engine.sh")"

if [[ ! -d "${HOST_REPOS_DIR}" ]]; then
  echo "repos dir not found: ${HOST_REPOS_DIR}" >&2
  echo "例: git clone したリポジトリを ${HOST_REPOS_DIR} に置いてください。" >&2
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

# ログ調査等を行う必要があれば、--rmは除く
exec "${ENGINE}" run --rm -it \
  --name "${APP_NAME}-dev" \
  -p "${HOST_PORT}:${CTR_PORT}" \
  "${ENV_OPT[@]}" \
  -v "${HOST_REPOS_DIR}:${CTR_APP_DIR}" \
  -v "${HOST_DATA_DIR}:${CTR_DATA_DIR}" \
  -w "${CTR_APP_DIR}" \
  "${IMAGE_DEV}" \
  "${CMD[@]}"
