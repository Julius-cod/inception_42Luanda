FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    && rm -rf /var/lib/apt/lists/*

COPY ./html/ /var/www/static/

# Configuração mínima do NGINX para servir o site estático
RUN printf '%s\n' \
    'server {' \
    '    listen 8080;' \
    '    root /var/www/static;' \
    '    index index.html;' \
    '    location / {' \
    '        try_files $uri $uri/ =404;' \
    '    }' \
    '}' > /etc/nginx/sites-available/static.conf && \
    rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/static.conf /etc/nginx/sites-enabled/static.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]