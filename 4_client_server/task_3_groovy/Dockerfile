FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends groovy default-jre-headless \
    && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/default-java
WORKDIR /app
COPY main.groovy .
ENTRYPOINT ["groovy", "main.groovy"]
