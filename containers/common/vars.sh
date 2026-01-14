#!/usr/bin/env bash
set -euo pipefail

# ---- app_name デフォルト ----
APP_NAME="${APP_NAME:-default-app}"

# ---- このファイル位置から $HOME/{app_name} を推定 ----
_VARS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="${APP_ROOT:-$(cd "${_VARS_DIR}/../.." && pwd)}"

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