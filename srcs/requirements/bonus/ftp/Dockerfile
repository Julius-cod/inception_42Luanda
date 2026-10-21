FROM debian:bookworm

# 1. Instala o servidor FTP vsftpd
RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*


COPY --chmod=0755 ./tools/ftp-setup.sh /usr/local/bin/ftp-setup.sh

# Porta de comando FTP e intervalo de portas passivas 
# para o modo passivo (essencial no Docker)
EXPOSE 21 21100-21105


ENTRYPOINT ["/usr/local/bin/ftp-setup.sh"]

