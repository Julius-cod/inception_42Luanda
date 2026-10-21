#!/bin/sh
set -eu

echo "Inception: A iniciar o script de configuração do FTP..."

mkdir -p /var/run/vsftpd/empty

# Obter IP do host na rede Docker (para modo passivo)
PASV_IP=$(ip route | awk '/default/ { print $3 }')

cat << EOF > /etc/vsftpd.conf
listen=YES
listen_ipv6=NO
background=NO

anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022

chroot_local_user=YES
allow_writeable_chroot=YES

pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21105
pasv_address=$PASV_IP
secure_chroot_dir=/var/run/vsftpd/empty

# Para debug (opcional)
log_ftp_protocol=YES
xferlog_enable=YES
EOF

# Criar utilizador se não existir
if ! id "$WP_USER" >/dev/null 2>&1; then
    echo "Inception: A criar utilizador FTP: $WP_USER"
    useradd -m -d /var/www/wordpress -s /bin/bash "$WP_USER"
    chown -R "$WP_USER":www-data /var/www/wordpress
fi

FTP_PASSWORD=$(cat /run/secrets/wp_user_password)
echo "$WP_USER:$FTP_PASSWORD" | chpasswd

echo "✔ Servidor FTP configurado. A iniciar o serviço..."
exec vsftpd /etc/vsftpd.conf