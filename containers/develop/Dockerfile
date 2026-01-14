FROM python:3.9.25-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libsqlite3-dev \
      zlib1g-dev \
      libssl-dev \
      ca-certificates \
      locales \
      tzdata \
    && sed -i 's/^# *\(ja_JP.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# 互換：アプリが /app/data を見るなら /data に寄せる
RUN mkdir -p /data && ln -snf /data /app/data

# 依存はイメージに固定（build context は repos/{app_name}）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

CMD ["bash"]
