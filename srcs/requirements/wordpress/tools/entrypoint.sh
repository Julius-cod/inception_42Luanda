#!/bin/bash

set -eu

echo "Inception: A iniciar configuração do WordPress..."

# ─────────────────────────────────────────────────────────────
# 1. Esperar MariaDB (com timeout — não é loop infinito)
# ─────────────────────────────────────────────────────────────
echo "WordPress: A aguardar ligação à base de dados (${DB_HOST})..."
i=0
while ! mariadb-admin ping -h"${DB_HOST}" -u"${DB_USER}" \
        -p"$(cat /run/secrets/db_password)" --silent >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
        echo "ERRO: MariaDB não respondeu após 120s."
        exit 1
    fi
    sleep 2
done
echo "WordPress: Conexão com o MariaDB estabelecida!"

# ─────────────────────────────────────────────────────────────
# 2. Preparar diretório do WordPress
# ─────────────────────────────────────────────────────────────
mkdir -p "$WP_PATH"
cd "$WP_PATH"

if [ ! -f "wp-load.php" ]; then
    echo "Inception: Pasta vazia. A descarregar ficheiros do WordPress..."
    wp core download --path="." --allow-root
fi

# ─────────────────────────────────────────────────────────────
# 3. Criar wp-config.php se necessário
# ─────────────────────────────────────────────────────────────
if [ ! -f "wp-config.php" ]; then
    echo "Inception: A criar wp-config.php..."
    cp wp-config-sample.php wp-config.php

    REAL_DB_PASSWORD=$(cat /run/secrets/db_password)
    REAL_WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    REAL_WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp config set DB_HOST "$DB_HOST" --allow-root --path="."
    wp config set DB_NAME "$DB_DATABASE" --allow-root --path="."
    wp config set DB_USER "$DB_USER" --allow-root --path="."
    wp config set DB_PASSWORD "$REAL_DB_PASSWORD" --allow-root --path="."
    wp config set table_prefix "$DB_TABLE_PREFIX" --allow-root --path="."
    wp config set WP_DEBUG false --raw --allow-root --path="."
    wp config set WP_DEBUG_LOG false --raw --allow-root --path="."

    wp config shuffle-salts --allow-root
    echo "wp-config.php gerado."
fi

# ─────────────────────────────────────────────────────────────
# 4. Instalar WordPress (só se ainda não estiver instalado)
# ─────────────────────────────────────────────────────────────
if ! wp core is-installed --allow-root --path="." 2>/dev/null; then
    echo "Inception: A instalar WordPress..."

    REAL_WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    REAL_WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp core install --allow-root \
        --path="." \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN" \
        --admin_password="$REAL_WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"

    wp plugin update --all --allow-root --path="."

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$REAL_WP_USER_PASSWORD" \
        --role=author \
        --porcelain \
        --allow-root --path="."

    echo "WordPress instalado."
else
    echo "WordPress já instalado."
fi

# ─────────────────────────────────────────────────────────────
# 5. Permissões para o NGINX
# ─────────────────────────────────────────────────────────────
chown -R www-data:www-data /var/www/wordpress
mkdir -p /run/php
chown -R www-data:www-data /run/php

# ─────────────────────────────────────────────────────────────
# 6. BÓNUS: Redis Cache
# ─────────────────────────────────────────────────────────────
echo "Inception: A configurar o bónus Redis Cache..."

wp config set WP_REDIS_HOST "redis" --allow-root --path="."
wp config set WP_REDIS_PORT "6379" --raw --allow-root --path="."

wp plugin install redis-cache --activate --allow-root --path="."

# Esperar Redis (com timeout — não é loop infinito)
i=0
while ! (echo > /dev/tcp/redis/6379) 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
        echo "AVISO: Redis não respondeu após 30s. Bónus pode falhar."
        break
    fi
    sleep 1
done

if wp redis enable --allow-root --path="."; then
    echo "✔ Bónus Redis Cache ativado com sucesso!"
else
    echo "AVISO: wp redis enable falhou."
fi

# ─────────────────────────────────────────────────────────────
# 7. Iniciar PHP-FPM (PID 1)
# ─────────────────────────────────────────────────────────────
echo "WordPress: A iniciar o PHP-FPM em primeiro plano..."
exec /usr/sbin/php-fpm8.2 -F