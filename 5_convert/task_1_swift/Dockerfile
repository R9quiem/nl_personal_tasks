FROM swift:5.10.1-slim
RUN apt-get update && apt-get install -y --no-install-recommends libsqlite3-0 libxml2 libncurses6 libc6-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY main.swift .
ENTRYPOINT ["/toolchain/usr/bin/swift", "/app/main.swift"]
