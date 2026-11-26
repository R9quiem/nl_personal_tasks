FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ghc \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Main.hs .
RUN ghc -Wall -Werror -O2 Main.hs -o partitions
ENTRYPOINT ["/app/partitions"]
