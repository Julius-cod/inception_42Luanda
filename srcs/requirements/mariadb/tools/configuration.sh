#!/bin/sh

set -eu

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
PIDFILE="/run/mysqld/mysqld.pid"

echo "MariaDB: A iniciar configuração..."

# ─────────────────────────────────────────────────────────────
# 1. Validar as variáveis obrigatórias
# ─────────────────────────────────────────────────────────────
: "${DB_DATABASE:?DB_DATABASE não definida}"
: "${DB_USER:?DB_USER não definida}"

case "$DB_DATABASE:$DB_USER" in
    *[!a-zA-Z0-9_:]*)
        echo "ERRO: DB_DATABASE ou DB_USER contém caracteres inválidos."
        exit 1
        ;;
esac

# ─────────────────────────────────────────────────────────────
# 2. Ler os secrets
# ─────────────────────────────────────────────────────────────
if [ ! -r /run/secrets/db_password ] ||
   [ ! -r /run/secrets/db_root_password ]; then
    echo "ERRO: Secret da base de dados ou de root indisponível."
    exit 1
fi

DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ -z "$DB_PASSWORD" ] || [ -z "$ROOT_PASSWORD" ]; then
    echo "ERRO: Uma das palavras-passe está vazia."
    exit 1
fi

# Escapar caracteres especiais para strings SQL.
sql_escape() {
    printf '%s' "$1" |
        sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g"
}

SQL_DB_PASSWORD=$(sql_escape "$DB_PASSWORD")
SQL_ROOT_PASSWORD=$(sql_escape "$ROOT_PASSWORD")

unset DB_PASSWORD ROOT_PASSWORD

# ─────────────────────────────────────────────────────────────
# 3. Inicializar os dados apenas quando necessário
# ─────────────────────────────────────────────────────────────
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql "$DATADIR"

if [ ! -d "$DATADIR/mysql" ]; then
    echo "MariaDB: Primeira inicialização dos dados..."
    mysql_install_db --user=mysql --datadir="$DATADIR"
fi

# ─────────────────────────────────────────────────────────────
# 4. Iniciar um servidor temporário, sem acesso pela rede
# ─────────────────────────────────────────────────────────────
echo "MariaDB: A iniciar servidor temporário..."

mysqld_safe \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --pid-file="$PIDFILE" \
    --skip-networking &
TEMP_PID=$!

# Esperar que o servidor esteja pronto
READY=0
i=0

while [ "$i" -lt 60 ]; do
    if mariadb-admin --socket="$SOCKET" -u root ping \
        --silent >/dev/null 2>&1; then
        READY=1
        break
    fi

    if mariadb-admin --socket="$SOCKET" -u root \
        -p"$SQL_ROOT_PASSWORD" ping --silent \
        >/dev/null 2>&1; then
        READY=1
        break
    fi

    if ! kill -0 "$TEMP_PID" 2>/dev/null; then
        echo "ERRO: O servidor temporário terminou inesperadamente."
        exit 1
    fi

    sleep 1
    i=$((i + 1))
done

if [ "$READY" -ne 1 ]; then
    echo "ERRO: MariaDB não ficou pronto após 60 segundos."
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# 5. Identificar o método de autenticação de root
# ─────────────────────────────────────────────────────────────
if mariadb --socket="$SOCKET" -u root \
    -e "SELECT 1;" >/dev/null 2>&1; then
    ROOT_AUTH="socket"
elif mariadb --socket="$SOCKET" -u root \
    -p"$SQL_ROOT_PASSWORD" \
    -e "SELECT 1;" >/dev/null 2>&1; then
    ROOT_AUTH="password"
else
    echo "ERRO: Não foi possível autenticar como root."
    echo "Verifica o secret db_root_password."
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# 6. Garantir a base de dados, o utilizador e as permissões
# ─────────────────────────────────────────────────────────────
echo "MariaDB: A verificar base de dados e utilizador..."

if [ "$ROOT_AUTH" = "socket" ]; then
    mariadb --socket="$SOCKET" -u root <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_DATABASE};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${SQL_DB_PASSWORD}';
ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${SQL_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
else
    mariadb --socket="$SOCKET" -u root \
        -p"$SQL_ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_DATABASE};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${SQL_DB_PASSWORD}';
ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${SQL_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
fi

echo "MariaDB: Configuração concluída."

# ─────────────────────────────────────────────────────────────
# 7. Encerrar o servidor temporário (com ROOT_AUTH correto)
# ─────────────────────────────────────────────────────────────
if [ "$ROOT_AUTH" = "socket" ]; then
    mariadb-admin --socket="$SOCKET" -u root shutdown
else
    mariadb-admin --socket="$SOCKET" -u root \
        -p"$SQL_ROOT_PASSWORD" shutdown
fi

# Limpar variáveis sensíveis antes do servidor definitivo
unset SQL_DB_PASSWORD SQL_ROOT_PASSWORD

# ─────────────────────────────────────────────────────────────
# 8. Iniciar servidor definitivo (PID 1 via exec)
# ─────────────────────────────────────────────────────────────
echo "MariaDB: A iniciar servidor definitivo..."

exec mysqld_safe \
    --datadir="$DATADIR" \
    --bind-address=0.0.0.0 \
    --user=mysql
