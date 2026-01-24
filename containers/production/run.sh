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
# 以下はサンプルとしてアプリのentrypoint.shという起動スクリプトを指定している。
CMD=( "./OGIMS/entrypoint.sh" )
EXEC_OPS="-d"
if [[ "${1:-}" == "bash" ]]; then
  CMD=( "bash" )
  EXEC_OPS="-it"
fi

# コンテナに渡す環境変数の読み込み
ENV_FILE="${SCRIPT_DIR}/ENVIRONMENTS"
ENV_OPT=()
if [[ -f "${ENV_FILE}" ]]; then
  ENV_OPT=( --env-file "${ENV_FILE}" )
fi

# bash起動の時はENTRYPOINTをbashに変更する。さらにコンテナ終了時はrm。
if [[ "${1:-}" == "bash" ]]; then
  exec "${ENGINE}" run --rm -it \
    --name "${APP_NAME}-prd" \
    --entrypoint bash \
    -p "${HOST_PORT}:${CTR_PORT}" \
    "${ENV_OPT[@]}" \
    -v "${HOST_DATA_DIR}:${CTR_DATA_DIR}" \
    -w "${CTR_APP_DIR}" \
    "${IMAGE_PRD}"
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

# ライブチェックのURLもアプリに合わせる。
CHECK_URL="http://localhost:${HOST_PORT}/"
for i in {1..30}; do
  if curl -fsS -o /dev/null "$CHECK_URL"; then
    echo "サーバーは問題なく起動しています"
    exit 0
  fi
  sleep 1
done

echo "サーバーが起動していません（30秒待ったけどNG）"
exit 1
