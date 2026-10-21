FROM debian:bookworm

# 1. Instala PHP e ferramentas
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        php-fpm \
        php-mysql \
        php-redis \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# 2. Instala WP-CLI
RUN curl -fsSL \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /tmp/wp-cli.phar && \
    chmod 755 /tmp/wp-cli.phar && \
    mv /tmp/wp-cli.phar /usr/local/bin/wp

# 3. Prepara a pasta dos processos PHP
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

# 4. Copia configurações
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY --chmod=0755 ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]