# Container image that runs your code
FROM debian:stable-slim
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]