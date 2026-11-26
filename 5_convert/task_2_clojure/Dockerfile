FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends clojure \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY main.clj .
ENTRYPOINT ["clojure", "main.clj"]
