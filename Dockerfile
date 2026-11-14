# 同一份 Dockerfile。CPU 由构建时的 --platform 决定：
#   docker build --platform linux/amd64 .
#   docker build --platform linux/arm64 .
FROM rust:1-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .
RUN chmod +x scripts/build.sh scripts/run.sh \
    && ./scripts/build.sh \
    && ./scripts/run.sh

CMD ["./scripts/run.sh"]
