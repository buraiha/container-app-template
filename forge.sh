#!/bin/sh
# 本リポジトリで使用しているコンテナ管理用のツリーを一括作成するスクリプトです。

APP_NAME=default-app
BASE="$HOME/$APP_NAME"

# ディレクトリ一式
mkdir -p "$BASE"/{data,data_backup,containers/{common,develop,production},repos/"$APP_NAME"}

# 空ファイル一式（中身は後で埋める）
touch \
  "$BASE/data_backup/sqlite_backup.sh" \
  "$BASE/containers/common/vars.sh" \
  "$BASE/containers/common/engine.sh" \
  "$BASE/containers/develop/.gitignore" \
  "$BASE/containers/develop/Dockerfile" \
  "$BASE/containers/develop/build.sh" \
  "$BASE/containers/develop/run.sh" \
  "$BASE/containers/develop/shell.sh" \
  "$BASE/containers/develop/ENVIRONMENTS" \
  "$BASE/containers/production/.gitignore" \
  "$BASE/containers/production/Dockerfile" \
  "$BASE/containers/production/build.sh" \
  "$BASE/containers/production/run.sh" \
  "$BASE/containers/production/shell.sh" \
  "$BASE/containers/production/ENVIRONMENTS"

# ひとまず実行ビットだけ付けとく（スクリプト系）
chmod +x \
  "$BASE/data_backup/sqlite_backup.sh" \
  "$BASE/containers/common/vars.sh" \
  "$BASE/containers/common/engine.sh" \
  "$BASE/containers/develop/build.sh" \
  "$BASE/containers/develop/run.sh" \
  "$BASE/containers/develop/shell.sh" \
  "$BASE/containers/production/build.sh" \
  "$BASE/containers/production/run.sh" \
  "$BASE/containers/production/shell.sh"
