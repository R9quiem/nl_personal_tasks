FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends nim gcc libc6-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY main.nim .
RUN nim c -d:release --out:semver main.nim
ENTRYPOINT ["/app/semver"]
