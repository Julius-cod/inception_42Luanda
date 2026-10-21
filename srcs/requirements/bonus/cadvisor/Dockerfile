FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG CADVISOR_VERSION=0.60.6

RUN ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then \
        CADVISOR_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        CADVISOR_ARCH="arm64"; \
    else \
        echo "Arquitetura não suportada: $ARCH" && exit 1; \
    fi && \
    curl -fL --retry 3 \
        -o /usr/local/bin/cadvisor \
        "https://github.com/google/cadvisor/releases/download/v${CADVISOR_VERSION}/cadvisor-v${CADVISOR_VERSION}-linux-${CADVISOR_ARCH}" && \
    chmod +x /usr/local/bin/cadvisor

EXPOSE 8080

CMD ["/usr/local/bin/cadvisor", \
     "-logtostderr", \
     "-docker_only=true", \
     "-housekeeping_interval=30s"]