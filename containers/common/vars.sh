#!/usr/bin/env bash
set -euo pipefail

# ---- このファイル位置から $HOME/{app_name} を推定（最優先で確定）----
_VARS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="${APP_ROOT:-$(cd "${_VARS_DIR}/../.." && pwd)}"

# ---- ホスト専用設定（任意）を読み込む ----
HOST_ENV="${APP_ROOT}/containers/.host.env"
if [[ -f "${HOST_ENV}" ]]; then
  # shellcheck disable=SC1090
  source "${HOST_ENV}"
fi

# ---- app_name デフォルト（.host.env があればそっち優先）----
APP_NAME="${APP_NAME:-default-app}"

# ---- ホスト側ディレクトリ規約 ----
HOST_DATA_DIR="${HOST_DATA_DIR:-${APP_ROOT}/data}"
HOST_BACKUP_DIR="${HOST_BACKUP_DIR:-${APP_ROOT}/data_backup}"
HOST_REPOS_DIR="${HOST_REPOS_DIR:-${APP_ROOT}/repos/${APP_NAME}}"

# ---- イメージ名（小文字推奨）----
IMAGE_DEV="${IMAGE_DEV:-${APP_NAME}:develop}"
IMAGE_PRD="${IMAGE_PRD:-${APP_NAME}:production}"

# ---- コンテナ内ディレクトリ規約 ----
CTR_APP_DIR="/app"
CTR_DATA_DIR="/data"

# ---- ポート（必要なければ未使用でOK）----
HOST_PORT="${HOST_PORT:-8080}"
CTR_PORT="${CTR_PORT:-8000}"
