FROM debian:bookworm

# 1. Instala PHP e utilitários
RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-cli \
    php8.2-mysql \
    php8.2-mbstring \
    php8.2-zip \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Baixa o Adminer (arquivo PHP oficial)
RUN mkdir -p /var/www/adminer && \
    wget "https://www.adminer.org/latest.php" -O /var/www/adminer/index.php && \
    chown -R www-data:www-data /var/www/adminer

EXPOSE 8080

# 3. Inicia o PHP built-in server (PID 1)
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]