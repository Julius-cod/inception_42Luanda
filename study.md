Aqui está o **guião de defesa completo** em formato `.md`, organizado **exatamente na ordem da folha de avaliação oficial**. Podes copiar para `DEFENSE.md` ou usar como cola mental.

---

```markdown
# 🎯 INCEPTION — Guião de Defesa

> Documento de apoio para a defesa do projeto Inception (42).
> Segue a ordem da folha de avaliação oficial.
> **Diz o quê, quando, e como demonstrar.**

---

## 📋 PRELIMINARES (eliminatórias)

### O que o avaliador vai fazer

1. **Clonar o repositório** na estação dele.
2. **Verificar credenciais** — não podem estar no Git fora do `.env`.
3. **Correr a limpeza total**:
   ```bash
   docker stop $(docker ps -qa); docker rm $(docker ps -qa); \
   docker rmi -f $(docker images -qa); \
   docker volume rm $(docker volume ls -q); \
   docker network rm $(docker network ls -q) 2>/dev/null
   ```

### O que deves mostrar

| Verificação | Como demonstrar |
|-------------|-----------------|
| `srcs/` na raiz | `ls srcs/` |
| `Makefile` na raiz | `ls Makefile` |
| Sem `network: host` ou `links:` | `grep -E "network: host\|links:" srcs/docker-compose.yml` → vazio |
| `network(s)` presente | `grep "networks:" srcs/docker-compose.yml` |
| Sem `--link` | `grep -r "\-\-link" Makefile srcs/` → vazio |
| Sem `tail -f` / `bash &` no `ENTRYPOINT` | `grep -E "tail -f\|bash &" srcs/requirements/*/Dockerfile` → vazio |
| Sem loops infinitos | `grep -rE "sleep infinity\|while true\|tail -f /dev/null" srcs/` → vazio |
| `make` funciona | `make` (do zero) |

### 💬 O que dizer

> *"O projeto está estruturado com `srcs/` na raiz, `Makefile` na raiz, e todos os serviços orquestrados via `docker compose`. Não usamos `network: host`, `links:` ou `--link`. Os entrypoints são scripts que terminam com `exec` para serem PID 1, sem loops infinitos — os loops de espera têm timeout de 60 tentativas."*

---

## 🐳 PROJECT OVERVIEW (teoria)

### O avaliador vai perguntar

1. **Como Docker e docker compose funcionam?**
2. **Diferença entre imagem com/sem compose?**
3. **Benefício do Docker vs VMs?**
4. **Pertinência da estrutura de diretórios?**

### 💬 Respostas prontas

**Docker vs docker compose:**
> *"Docker é a engine que corre containers — processos isolados via namespaces e cgroups. Docker Compose é uma ferramenta de orquestração que define múltiplos serviços num `docker-compose.yml`, com redes, volumes e dependências. O compose simplifica subir 8 containers com um `make`."*

**Imagem com/sem compose:**
> *"Sem compose, constróis e corres cada container manualmente (`docker build`, `docker run`, `docker network create`, etc.). Com compose, defines tudo declarativamente no `.yml` e o `docker compose up` trata de build, rede, volumes e dependências."*

**Docker vs VMs:**
> *"VMs emulam hardware completo com um OS por VM — pesadas, boot de minutos. Docker partilha o kernel do host — leve, boot de segundos. Para microserviços, Docker é mais eficiente e portátil."*

**Estrutura de diretórios:**
> *"`srcs/` contém o `docker-compose.yml`, o `.env` e `requirements/` com um Dockerfile por serviço. Isto segue o subject e separa configuração (srcs) de segredos (secrets/) e documentação (raiz)."*

---

## 🌐 SIMPLE SETUP

### O avaliador vai fazer

1. **Abrir `https://juliados.42.fr`** — deve mostrar WordPress (não instalação).
2. **Tentar `http://juliados.42.fr`** — deve falhar.
3. **Verificar certificado SSL** — self-signed, aviso ok.

### 💬 O que dizer

> *"O `/etc/hosts` resolve `juliados.42.fr` para `127.0.0.1` via `setup.sh`. O NGINX só escuta na 443 com TLS 1.2/1.3. O `http://` falha porque não há `listen 80` — o `sites-enabled/default` foi removido no Dockerfile. O certificado é self-signed, gerado no Dockerfile com `openssl`, e o navegador avisa mas aceita."*

### 🛠️ Comandos de apoio

```bash
curl -k -I https://juliados.42.fr | head -1        # HTTP/1.1 200
curl -I http://juliados.42.fr 2>&1 | head -1       # connection refused
openssl s_client -connect juliados.42.fr:443 -tls1_2 </dev/null 2>&1 | grep "Protocol"
openssl s_client -connect juliados.42.fr:443 -tls1_3 </dev/null 2>&1 | grep "Protocol"
```

---

## 🐋 DOCKER BASICS

### O avaliador vai verificar

| Verificação | Comando |
|-------------|---------|
| 1 Dockerfile por serviço | `ls srcs/requirements/*/Dockerfile` |
| Dockerfiles não vazios | `wc -l srcs/requirements/*/Dockerfile` |
| Imagens construídas pelo aluno | `docker images` (nomes = serviços) |
| Base Debian/Alpine | `head -1 srcs/requirements/*/Dockerfile` → `FROM debian:bookworm` |
| Imagens com nome do serviço | `docker images --format "{{.Repository}}"` |

### 💬 O que dizer

> *"Cada serviço tem o seu Dockerfile em `srcs/requirements/<serviço>/Dockerfile`. Todos usam `FROM debian:bookworm` (penúltima estável). As imagens são construídas localmente via `build:` no compose — não usamos imagens prontas do Docker Hub. Os nomes das imagens coincidem com os serviços: `mariadb`, `wordpress`, `nginx`, `redis`, `adminer`, `ftp`, `cadvisor`, `static`."*

---

## 🌐 DOCKER NETWORK

### O avaliador vai verificar

```bash
grep -A3 "networks:" srcs/docker-compose.yml
docker network ls | grep inception
```

### 💬 O que dizer

> *"Usamos uma rede bridge customizada `inception-network`. Os containers comunicam por nome de serviço — o Docker tem DNS interno que resolve `wordpress`, `mariadb`, etc. O `network: host` e `--link` são proibidos pelo subject e não usamos. Só o NGINX expõe porta ao host (443); os outros serviços só são acessíveis na rede interna."*

---

## 🔒 NGINX with SSL/TLS

### O avaliador vai verificar

| Verificação | Comando |
|-------------|---------|
| Dockerfile existe | `ls srcs/requirements/nginx/Dockerfile` |
| Container criado | `docker compose ps nginx` |
| HTTP (80) falha | `curl http://juliados.42.fr` → connection refused |
| HTTPS funciona | `curl -k https://juliados.42.fr` → 200 |
| TLS 1.2/1.3 | `openssl s_client -tls1_2` e `-tls1_3` |

### 💬 O que dizer

> *"O NGINX é o único entrypoint, na 443 com TLS 1.2/1.3. O certificado é self-signed, gerado no Dockerfile com `openssl req -x509`. O `default.conf` tem `listen 443 ssl`, `ssl_certificate`, `ssl_certificate_key` e `ssl_protocols TLSv1.2 TLSv1.3`. O `sites-enabled/default` foi removido para não haver `listen 80`."*

### 🛠️ Demonstração

```bash
docker compose ps nginx
curl -k -I https://juliados.42.fr | head -1
openssl s_client -connect juliados.42.fr:443 -tls1_2 </dev/null 2>&1 | grep "Protocol"
openssl s_client -connect juliados.42.fr:443 -tls1_3 </dev/null 2>&1 | grep "Protocol"
```

---

## 📝 WordPress with php-fpm and its volume

### O avaliador vai verificar

| Verificação | Comando |
|-------------|---------|
| Dockerfile existe | `ls srcs/requirements/wordpress/Dockerfile` |
| **Sem NGINX** | `grep -i nginx srcs/requirements/wordpress/Dockerfile` → vazio |
| Container criado | `docker compose ps wordpress` |
| Volume existe | `docker volume ls` → `inception_website` |
| Volume aponta para `/home/juliados/data/` | `docker volume inspect inception_website` |
| Comentário com user comum | Login `colaborador42` → comentar |
| Admin sem "admin" no nome | Login `juliados` → dashboard |
| Editar página e ver no site | Dashboard → Páginas → editar → ver |

### 💬 O que dizer

> *"O container WordPress tem PHP-FPM + WP-CLI, sem NGINX. O `entrypoint.sh` espera pelo MariaDB (com timeout de 60 tentativas), cria o `wp-config.php` lendo os secrets de `/run/secrets/`, instala o WordPress (`wp core install`) com admin `juliados`, e cria o user `colaborador42` com role author. O volume `inception_website` mapeia para `/home/juliados/data/website` via `driver_opts`. O PHP-FPM escuta na 9000, e o NGINX faz `fastcgi_pass wordpress:9000`."*

### 🛠️ Demonstração

```bash
docker volume inspect inception_website | grep /home/juliados/data/
docker exec -it wordpress wp user list --allow-root --path=/var/www/wordpress
docker exec -it wordpress wp core is-installed --allow-root --path=/var/www/wordpress && echo OK
```

---

## 🗄️ MariaDB and its volume

### O avaliador vai verificar

| Verificação | Comando |
|-------------|---------|
| Dockerfile existe | `ls srcs/requirements/mariadb/Dockerfile` |
| **Sem NGINX** | `grep -i nginx srcs/requirements/mariadb/Dockerfile` → vazio |
| Container criado | `docker compose ps mariadb` |
| Volume existe | `docker volume ls` → `inception_database` |
| Volume aponta para `/home/juliados/data/` | `docker volume inspect inception_database` |
| DB não vazia | `mariadb -u wp_user -p... -e "SHOW TABLES;"` |

### 💬 O que dizer

> *"O container MariaDB tem só o MariaDB, sem NGINX. O `configuration.sh` lê os secrets, inicializa a DB na primeira execução, cria o `wordpress_db` e o `wp_user`, e usa `ROOT_AUTH` para detetar se o root já tem password (idempotente). O volume `inception_database` mapeia para `/home/juliados/data/database`. O servidor final corre `mysqld_safe` com `--user=mysql`."*

### 🛠️ Demonstração

```bash
docker volume inspect inception_database | grep /home/juliados/data/
docker exec -it mariadb mariadb -u wp_user -p"$(cat secrets/db_password.txt)" -e "SHOW TABLES;" wordpress_db
```

---

## 🔄 PERSISTENCE!

### O avaliador vai fazer

1. **Reboot da VM**.
2. **`make`** novamente.
3. **Verificar que os dados persistem** (posts, páginas, users).

### 💬 O que dizer

> *"Os volumes são Docker named volumes, mapeados para `/home/juliados/data/` via `driver_opts`. Sobrevivem a `docker compose down` e a reboot da VM. Só são apagados com `make fclean`, que corre `docker compose down --volumes` e `rm -rf /home/juliados/data/`."*

### 🛠️ Demonstração (antes do reboot)

```bash
# Cria um post de teste
docker exec -it wordpress wp post create --post_title="Teste Persistência" --post_status=publish --allow-root --path=/var/www/wordpress

# Reboot
sudo reboot

# Após reboot
make
docker exec -it wordpress wp post list --allow-root --path=/var/www/wordpress | grep "Teste Persistência"
```

✅ **Esperado**: o post aparece.

---

## 🎁 BÓNUS (5/5)

### Bônus 1 — Redis Cache

| Verificação | Comando |
|-------------|---------|
| Container Up | `docker ps \| grep redis` |
| `PING` → `PONG` | `docker exec -it redis redis-cli ping` |
| WordPress conectado | `docker exec -it wordpress wp redis status --allow-root --path=/var/www/wordpress` |
| Cache a funcionar | `docker exec -it redis redis-cli DBSIZE` > 0 |

**💬 O que dizer:**
> *"O Redis é o object cache do WordPress. O `entrypoint.sh` do WordPress instala o plugin `redis-cache`, configura `WP_REDIS_HOST=redis` e `WP_REDIS_PORT=6379`, e ativa com `wp redis enable`. O `DBSIZE` mostra 19 chaves em cache."*

---

### Bônus 2 — Adminer

| Verificação | Comando |
|-------------|---------|
| Container Up | `docker ps \| grep adminer` |
| Acessível via NGINX | `curl -k https://juliados.42.fr/adminer/` → `200` |
| Login funciona | Navegador → `mariadb` / `wp_user` / `secrets/db_password.txt` |

**💬 O que dizer:**
> *"O Adminer corre em PHP built-in server na 8080, sem porta publicada no host. O NGINX faz proxy reverso em `/adminer/` com `proxy_pass http://adminer:8080/`. O login usa `mariadb` como server, `wp_user` como user."*

---

### Bônus 3 — cAdvisor

| Verificação | Comando |
|-------------|---------|
| Container Up | `docker ps \| grep cadvisor` |
| `privileged: true` | `docker inspect cadvisor \| grep Privileged` |
| Acessível | `curl http://localhost:8080/` → `307` |
| Via NGINX | `curl -k https://juliados.42.fr/cadvisor/` → `307` |

**💬 O que dizer:**
> *"O cAdvisor monitoriza os containers. Precisa de `privileged: true` e volumes do host (`/var/run`, `/var/lib/docker`, `/sys`) para aceder ao Docker daemon. O NGINX faz proxy reverso em `/cadvisor/` com `sub_filter` para reescrever links absolutos. O `307` é o redirect normal para `/containers/`."*

---

### Bônus 4 — FTP

| Verificação | Comando |
|-------------|---------|
| Container Up | `docker ps \| grep ftp` |
| Secret montado | `docker exec -it ftp ls /run/secrets/` |
| `pasv_address` correto | `docker exec -it ftp cat /etc/vsftpd.conf \| grep pasv_address` |
| FileZilla conecta | `colaborador42` + `secrets/wp_user_password.txt` |

**💬 O que dizer:**
> *"O FTP usa `vsftpd`. O `ftp-setup.sh` obtém o IP do gateway Docker via `ip route` e configura `pasv_address` para esse IP. O utilizador `colaborador42` é criado com shell `/bin/bash` e a password é lida do secret `wp_user_password`. O `exec vsftpd` garante PID 1. Os navegadores modernos não suportam FTP, por isso usamos FileZilla em modo passivo."*

---

### Bônus 5 — Site Estático

| Verificação | Comando |
|-------------|---------|
| Container Up | `docker ps \| grep static` |
| Acessível via NGINX | `curl -k https://juliados.42.fr/static/` → `200` |
| HTML correto | `curl -k https://juliados.42.fr/static/ \| head` |
| CSS/JS carregam | `curl -k -o /dev/null -w "%{http_code}" https://juliados.42.fr/static/css/styles.css` |

**💬 O que dizer:**
> *"O site estático é um serviço próprio — container `static` com NGINX dedicado na 8080. O NGINX principal faz proxy reverso em `/static/` com `proxy_pass http://static:8080/`. É um showcase do projeto, em HTML/CSS/JS (não PHP, como o subject exige)."*

---

## 🎤 DICAS FINAIS PARA A DEFESA

### Frases-chave

| Pergunta | Resposta |
|----------|----------|
| *"Por que `privileged: true` no cAdvisor?"* | *"O cAdvisor precisa de acesso ao Docker daemon e ao `/dev/kmsg` para monitorizar o host. A documentação oficial recomenda `privileged: true`."* |
| *"Por que `http://` no `proxy_pass` se o NGINX é HTTPS?"* | *"O `listen 443 ssl` protege cliente ↔ NGINX. Dentro da rede Docker, os serviços não têm TLS e a rede é isolada. O NGINX termina o TLS (SSL termination) e passa HTTP puro internamente."* |
| *"Por que `pasv_address` no FTP?"* | *"Sem `pasv_address`, o vsftpd anuncia `127.0.0.1` ao cliente, que tenta conectar a si mesmo. Com o IP do gateway Docker (`172.18.0.1`), o FileZilla conecta ao container correto."* |
| *"O que é o `/etc/hosts`?"* | *"É um DNS local de prioridade máxima. O `setup.sh` adiciona `127.0.0.1 juliados.42.fr`, então o navegador resolve o domínio para localhost. O subject exige `login.42.fr`, não `localhost`."* |
| *"Como a porta 443 é definida?"* | *"Três camadas: o navegador vê `https://` e assume 443 (padrão IANA); o `ports: - "443:443"` mapeia host→container via iptables; o `listen 443 ssl` faz o NGINX escutar na 443 com TLS."* |

### O que NÃO dizer

- ❌ *"Usei `latest`"* — proibido pelo subject.
- ❌ *"Copiei do Docker Hub"* — proibido (exceto Debian base).
- ❌ *"Não sei como funciona"* — sê honesto, mas tenta explicar.
- ❌ *"O `tail -f` é para manter o container vivo"* — proibido.

### Ordem de demonstração sugerida

1. **`make fclean && make`** (do zero) → 8 containers.
2. **`docker ps`** → 8 Up.
3. **`docker volume ls`** → 2 volumes.
4. **`docker network ls`** → `inception-network`.
5. **`https://juliados.42.fr`** → WordPress.
6. **`https://juliados.42.fr/wp-admin`** → login `juliados`.
7. **`https://juliados.42.fr/adminer/`** → login `wp_user`.
8. **`http://localhost:8080`** → cAdvisor.
9. **`https://juliados.42.fr/static/`** → site estático.
10. **FileZilla** → `colaborador42`.
11. **Reboot** → `make` → persistência.

---

## ✅ CHECKLIST FINAL DA DEFESA

- [ ] `make fclean && make` funciona do zero
- [ ] 8 containers Up
- [ ] 8 imagens construídas
- [ ] 2 volumes nomeados
- [ ] 1 rede `inception-network`
- [ ] `https://juliados.42.fr` → WordPress
- [ ] `http://juliados.42.fr` → falha
- [ ] TLS 1.2 e 1.3 funcionam
- [ ] Admin `juliados` (sem "admin")
- [ ] User `colaborador42` (author)
- [ ] Volume `inception_website` → `/home/juliados/data/`
- [ ] Volume `inception_database` → `/home/juliados/data/`
- [ ] DB não vazia
- [ ] Reboot + `make` → dados persistem
- [ ] Redis `Connected`
- [ ] Adminer `200`
- [ ] cAdvisor `307` + `privileged: true`
- [ ] FTP `pasv_address=172.18.0.1` + FileZilla
- [ ] Site estático `200`
- [ ] `README.md` com primeira linha em itálico
- [ ] `USER_DOC.md` e `DEV_DOC.md` existem
- [ ] `secrets/` e `.env` no `.gitignore`
- [ ] Sem senhas hardcoded

---

## 🚀 BOA SORTE!

> *"O projeto está a 100% obrigatório e 125% com bônus. Todos os testes passaram. Prepara a explicação teórica, demonstra com confiança, e sê honesto se algo falhar — o avaliador valoriza quem entende o que fez."*
```

---

## ✅ O que este guião cobre

- ✅ **Preliminares** (o que o avaliador faz primeiro)
- ✅ **Project overview** (teoria Docker)
- ✅ **Simple setup** (NGINX + SSL)
- ✅ **Docker Basics** (Dockerfiles, imagens)
- ✅ **Docker Network**
- ✅ **NGINX SSL/TLS**
- ✅ **WordPress + volume**
- ✅ **MariaDB + volume**
- ✅ **Persistence** (reboot)
- ✅ **Bônus 1-5** (Redis, Adminer, cAdvisor, FTP, Static)
- ✅ **Frases-chave** para perguntas comuns
- ✅ **O que NÃO dizer**
- ✅ **Ordem de demonstração**
- ✅ **Checklist final**

---

## 👉 Próximo passo

Queres que eu prepare também um **`USER_DOC.md`** e **`DEV_DOC.md`** completos (Capítulo VII) no mesmo formato, ou preferes focar noutra parte da defesa? 🚀