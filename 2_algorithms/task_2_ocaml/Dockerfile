FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ocaml-nox \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY main.ml .
COPY examples examples
RUN ocamlc -w +a-70 -warn-error +a-70 -o bridges main.ml
ENTRYPOINT ["/app/bridges"]
