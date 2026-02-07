#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは $HOME/{app_name}/data_backup/ に置く想定
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DATA_DIR="${APP_ROOT}/data"
BACKUP_DIR="${APP_ROOT}/data_backup"
ARCHIVE_DIR="${BACKUP_DIR}/archive"

# 引数1: DBファイル フルパスで指定（省略時は data/db.sqlite3）
DB_FILE="${1:-${DATA_DIR}/db.sqlite3}"

mkdir -p "${BACKUP_DIR}" "${ARCHIVE_DIR}"

if [[ ! -f "${DB_FILE}" ]]; then
  echo "DB file not found: ${DB_FILE}" >&2
  exit 1
fi

TS="$(date +"%Y%m%d_%H%M%S")"
TODAY="$(date +"%Y%m%d")"

BASE="$(basename "${DB_FILE}")"          # 例: db.sqlite3
NAME_BASE="${BASE%.sqlite3}"             # 例: db
PREFIX="${NAME_BASE}_"                   # 例: db_

OUT_FILE="${BACKUP_DIR}/${NAME_BASE}_${TS}.sqlite3"

# ホットバックアップ（SQLite online backup API）
sqlite3 "${DB_FILE}" ".backup '${OUT_FILE}'"

# 軽く整合性チェック（任意：重いなら消してOK）
sqlite3 "${OUT_FILE}" "PRAGMA quick_check;" | grep -qx "ok" || {
  echo "backup integrity check failed: ${OUT_FILE}" >&2
  exit 1
}

echo "backup ok: ${OUT_FILE}"

# ----------------------------
# 昨日以前の *.sqlite3 を tar.gz で固める
#  - ファイル名は ${NAME_BASE}_YYYYMMDD_HHMMSS.sqlite3 を想定
#  - 今日(TODAY)の分は残す
#  - 日付(YYYYMMDD)単位で archive/ に固め、元ファイルは削除
# ----------------------------
(
  cd "${BACKUP_DIR}"

  shopt -s nullglob

  # バックアップ名から YYYYMMDD を抽出して日付の一覧を作る
  mapfile -t dates < <(
    find . -maxdepth 1 -type f -name "${NAME_BASE}_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9].sqlite3" -printf '%f\n' \
      | sed -n "s/^${PREFIX}\([0-9]\{8\}\)_.*/\1/p" \
      | sort -u
  )

  for d in "${dates[@]}"; do
    [[ "${d}" == "${TODAY}" ]] && continue

    files=( "${NAME_BASE}_${d}"_*.sqlite3 )
    (( ${#files[@]} == 0 )) && continue

    out="${ARCHIVE_DIR}/${NAME_BASE}_${d}.tar.gz"
    if [[ -e "${out}" ]]; then
      # 既存がある場合は上書き事故防止で別名にする
      out="${ARCHIVE_DIR}/${NAME_BASE}_${d}_extra_${TS}.tar.gz"
    fi

    tmp="$(mktemp -p "${ARCHIVE_DIR}" ".${NAME_BASE}_${d}.tar.gz.tmp.XXXXXX")"
    tar -czf "${tmp}" -- "${files[@]}"
    mv -f "${tmp}" "${out}"

    rm -f -- "${files[@]}"

    echo "archived: ${out} (removed ${#files[@]} sqlite3 files)"
  done
)
