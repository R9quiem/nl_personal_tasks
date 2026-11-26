FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends erlang-base \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY main.escript .
ENTRYPOINT ["escript", "main.escript"]
