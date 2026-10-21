FROM debian:bookworm

# 1. Instala NGINX e OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# 2. Copia a configuração do NGINX
COPY ./conf/default.conf /etc/nginx/sites-available/juliados.42.fr.conf


# 4. Gera os certificados SSL
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=AO/ST=Luanda/L=Luanda/O=42/OU=Inception/CN=juliados.42.fr" \
    -addext "subjectAltName=DNS:juliados.42.fr,DNS:www.juliados.42.fr"

# 5. Ativa a config e remove o default (porta 80)
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/juliados.42.fr.conf /etc/nginx/sites-enabled/juliados.42.fr.conf

EXPOSE 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]