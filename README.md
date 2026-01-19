# コンテナ運用ノウハウ（README）

このドキュメントは、アプリごとに `develop / production` のコンテナ運用を統一するためのルールです。  
ホスト側のディレクトリ規約と、コンテナのビルド・起動・保全・バックアップ手順をまとめます。

> **注意（サンプルについて）**
> このリポジトリはサンプルとして、古い Django 3.2 を動かすために、Python 3.9 をインストールしたコンテナイメージをビルドするように作成されています。
> 実際の `Dockerfile` や `requirements.txt` 等は、ご自分のアプリに即したものに修正してください。

## 目的

- 開発と本番で同じ思想のディレクトリ構成に揃える
- `develop` は **ホストのリポジトリをマウントして開発**できるようにする
- `production` は **アプリ本体をイメージに固めて運用**する
- DB（sqlite等）の実体ファイルは **ホスト側で管理**し、コンテナへマウントする
- 障害調査のために、本番コンテナは **原則 `--rm` しない**

## 前提

- コンテナエンジンは `podman` または `docker`
- アプリのリポジトリはホスト側に `git clone` して配置する
- 環境変数（シークレット含む）は `ENVIRONMENTS` ファイルで渡す（Git管理しない）

## テンプレートとして使うときのガイド

この仕組みは **ディレクトリ管理と運用ルールを標準化するためのテンプレート**です。  
各アプリは利用者がカスタマイズして使います。

### ダウンロード

基本的には.git以下のローカルリポジトリは不要なはずなので、下記のコマンドでブランチのデータだけを取得してお使いください。

```sh
git clone --depth 1 --single-branch --branch main https://github.com/buraiha/container-app-template.git {APP_NAME}
```

### 原則触らない場所（規約の核）

- ディレクトリ構成（`data/`, `data_backup/`, `containers/`, `repos/`）
- `containers/common/vars.sh` の思想（`APP_ROOT` を起点に相対で解決する）

### アプリ側の前提（アプリが満たすべきこと）

- DBファイルの置き場（例：`/data/db.sqlite3` または `/app/data` 互換）
- ログは stdout に出す（`podman logs` / `docker logs` で追えるようにする）

### カスタマイズ手順（3分で適用）

- [ ] `APP_NAME` を決めてディレクトリ作成（`$HOME/{app_name}/`）
- [ ] `containers/.hosts.env` に決定した `APP_NAME` を記載する
  - ここに設定した `APP_NAME` が全体のアプリ名となります。
- [ ] `repos/{app_name}` に `git clone`
- [ ] `requirements.txt` / `Dockerfile` をアプリに合わせて調整
- [ ] `ENVIRONMENTS` を作成（シークレットはGit管理しない）
  - ファイル内容は `KEY=VALUE` 形式とし、VALUEは""や''等でクオートしない。"や'文字もシークレットとして扱われる可能性があるため。
- [ ] `build.sh` → `run.sh` で起動確認

#### カスタマイズするファイル（ここは必要であればアプリごとに変更する）

- [ ] `containers/*/Dockerfile`
- [ ] `containers/*/ENVIRONMENTS`
- [ ] `containers/*/run.sh` の `CMD`（例：`./runserver.sh` の部分）
- [ ] （必要なら）`HOST_PORT` / `CTR_PORT`

## ディレクトリ構成（ホスト側）

アプリごとに `"$HOME/{app_name}/"` をルートディレクトリとして運用します。

```
$HOME/{app_name}/
  data/                 # DBなど実体ファイル（sqlite等）
  data_backup/          # DBバックアップ格納
    sqlite_backup.sh    # sqliteホットバックアップ用
  containers/           # コンテナ関連（共通/開発/本番）
    common/
      vars.sh           # 共通変数（APP_ROOT/ポート/イメージ名 等）
      engine.sh         # podman/docker 自動判定
    develop/
      .gitignore
      Dockerfile
      build.sh          # developイメージ作成
      run.sh            # develop起動（reposを /app にマウント）
      shell.sh          # developにbashで入る
      ENVIRONMENTS      # develop用環境変数（Git管理しない）
    production/
      .gitignore
      Dockerfile
      build.sh          # productionイメージ作成
      run.sh            # production起動（--rmしない）
      shell.sh          # productionにbashで入る
      ENVIRONMENTS      # production用環境変数（Git管理しない）
  repos/
    {app_name}/         # git clone したアプリのリポジトリ
    ※repos直下にアプリのリポジトリを配置しないのは、例えばapp_ver1とapp_ver2のリポジトリのコンテナを切り替える運用が発生することを見込んで。
```

## コンテナ内ディレクトリ規約

### develop（開発用）

- `/app` : `repos/{app_name}` を **マウント**して開発
- `/data`: `data/` を **マウント**してDB実体を共有

### production（本番用）

- `/app` : アプリ本体は **イメージにCOPY**
- `/data`: `data/` を **マウント**してDB実体を共有

## 運用手順

### 1) リポジトリ配置

`repos/{app_name}` 配下にアプリリポジトリを `git clone` します。

### 2) develop のビルド・起動

- `containers/develop/build.sh` で develop イメージを作成
- `containers/develop/run.sh` で起動（デフォルトでは `./runserver.sh` を起動）
- `containers/develop/shell.sh` で bash でコンテナに入る

### 3) production のビルド・起動

- `containers/production/build.sh` で production イメージを作成
- `containers/production/run.sh` で起動
  - **障害調査の可能性があるため `--rm` は付けない**
  - 既存の同名コンテナがある場合は、事前に削除するか、リネームして残す

## 環境変数（ENVIRONMENTS）

- `containers/develop/ENVIRONMENTS` / `containers/production/ENVIRONMENTS` を使用
- 形式：`KEY=VALUE`（1行1変数）
- シークレットが含まれるため **Git管理しない**
- `OGIMS_MODE` など、アプリ側が期待する設定はここで切り替える

例（サンプル）

- develop：`OGIMS_MODE=develop`
- production：`OGIMS_MODE=production`

## DBバックアップ（sqlite）

- DB実体は `data/` に置く
- バックアップは `data_backup/` に出力する
- `data_backup/sqlite_backup.sh` により sqlite の **ホットバックアップ**を行う
- ホストに `sqlite3` が必要（Ubuntuなら `apt-get install sqlite3`）

## 障害調査

### ログ

- 原則：アプリは **stdout へログ出力**
- 収集：ホスト側で `podman logs` / `docker logs` で閲覧する

### コンテナ保全（production想定）

- production はコンテナを残す運用のため、以下が実施できる
  - `inspect`（設定・環境変数・マウント確認）
  - `commit`（状態をイメージとして凍結）
  - `diff`（変更点の把握）
  - 必要に応じて `rename` して保全し、新規起動する

## .gitignore 推奨（develop / production 共通）

最低限、以下をGit管理から除外する：

- `ENVIRONMENTS`（シークレット）
- ローカルの一時ファイル、エディタ生成物
