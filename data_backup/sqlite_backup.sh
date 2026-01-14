#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは $HOME/{app_name}/data_backup/ に置く想定
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DATA_DIR="${APP_ROOT}/data"
BACKUP_DIR="${APP_ROOT}/data_backup"

# 引数1: DBファイル（省略時は data/db.sqlite3）
DB_FILE="${1:-${DATA_DIR}/db.sqlite3}"

mkdir -p "${BACKUP_DIR}"

if [[ ! -f "${DB_FILE}" ]]; then
  echo "DB file not found: ${DB_FILE}" >&2
  exit 1
fi

TS="$(date +"%Y%m%d_%H%M%S")"
BASE="$(basename "${DB_FILE}")"
OUT_FILE="${BACKUP_DIR}/${BASE%.sqlite3}_${TS}.sqlite3"

# ホットバックアップ（SQLite online backup API）
sqlite3 "${DB_FILE}" ".backup '${OUT_FILE}'"

# 軽く整合性チェック（任意：重いなら消してOK）
sqlite3 "${OUT_FILE}" "PRAGMA quick_check;" | grep -qx "ok" || {
  echo "backup integrity check failed: ${OUT_FILE}" >&2
  exit 1
}

echo "backup ok: ${OUT_FILE}"
