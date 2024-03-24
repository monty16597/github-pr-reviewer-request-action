# Container image that runs your code
FROM debian:stable-slim
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]