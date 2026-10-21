FROM debian:bookworm

# 1. Instala o MariaDB
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 2. Prepara a pasta de runtime (socket/PID)
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# 3. Copia o script de configuração
COPY --chmod=0755 ./tools/configuration.sh /usr/local/bin/configuration.sh

ENTRYPOINT ["/usr/local/bin/configuration.sh"]