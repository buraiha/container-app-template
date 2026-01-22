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
# 以下はサンプルとしてKTRKNというアプリのentrypoint.shという起動スクリプトを指定している。
CMD=( "./KTRKN/entrypoint.sh" )
EXEC_OPS="-d"
if [[ "${1:-}" == "bash" ]]; then
  CMD=( "bash" )
  EXEC_OPS="-it"
fi

if [[ "${EXEC_OPS}" == "-it" ]]; then
  # develop/対話用：ここでプロセス置き換え（以降の処理は走らない）
  exec "${ENGINE}" run -it \
    --name "${APP_NAME}-prd" \
    -p "${HOST_PORT}:${CTR_PORT}" \
    "${ENV_OPT[@]}" \
    -v "${HOST_DATA_DIR}:${CTR_DATA_DIR}" \
    -w "${CTR_APP_DIR}" \
    "${IMAGE_PRD}" \
    "${CMD[@]}"
fi

# production：detachで起動してシェルに戻る（起動チェック可能）
"${ENGINE}" run -d \
  --name "${APP_NAME}-prd" \
  -p "${HOST_PORT}:${CTR_PORT}" \
  "${ENV_OPT[@]}" \
  -v "${HOST_DATA_DIR}:${CTR_DATA_DIR}" \
  -w "${CTR_APP_DIR}" \
  "${IMAGE_PRD}" \
  "${CMD[@]}"

echo "check....."

CHECK_URL="http://localhost:${HOST_PORT}/ktrkn/"
for i in {1..30}; do
  if curl -fsS -o /dev/null "$CHECK_URL"; then
    echo "サーバーは問題なく起動しています"
    exit 0
  fi
  sleep 1
done

echo "サーバーが起動していません（30秒待ったけどNG）"
exit 1
