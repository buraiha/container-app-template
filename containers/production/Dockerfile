# ===== build stage: wheel 作成 =====
FROM python:3.9.25-slim AS builder
WORKDIR /build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libsqlite3-dev \
      zlib1g-dev \
      libssl-dev \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# build context は repos/{app_name} を想定（build.sh 参照）
COPY requirements.txt .
RUN pip wheel --no-cache-dir -r requirements.txt -w /wheels


# ===== runtime stage: 実行最小 =====
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
      libsqlite3-0 \
      ca-certificates \
      locales \
      tzdata \
    && sed -i 's/^# *\(ja_JP.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# wheel install
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache-dir /wheels/* \
 && rm -rf /wheels

# アプリ本体を /app に固める（build context = repos/{app_name}）
COPY . /app

CMD ["bash"]
