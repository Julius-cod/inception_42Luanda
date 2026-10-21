*This project has been created as part of the 42 curriculum by juliados.*

# Inception

## Description

**Inception** is a system administration project from the 42 curriculum. The goal is to build a small, secure, and reproducible infrastructure using **Docker** and **Docker Compose**, running inside a virtual machine.

The infrastructure is composed of **three mandatory services**, each in its own dedicated container:

- **NGINX** — the only entrypoint, serving HTTPS on port `443` with TLSv1.2/TLSv1.3.
- **WordPress + PHP-FPM** — the website, without any web server.
- **MariaDB** — the database, without any web server.

Additionally, the project includes **bonus services**:

- **Redis** — object cache for WordPress.
- **Adminer** — lightweight database management UI.
- **FTP (vsftpd)** — access to the WordPress volume.
- **cAdvisor** — container monitoring.
- **Static website** — a simple showcase site served by its own container.

All images are **built from scratch** using custom `Dockerfile`s, based on the penultimate stable version of **Debian** (`bookworm`). No ready-made images from Docker Hub are used (except the Debian base).

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed.
- `make` installed.
- `sudo` privileges (for `/etc/hosts` configuration and volume cleanup).
- The domain `juliados.42.fr` must resolve to `127.0.0.1`.

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repo-url> inception
   cd inception
   ```

2. **Create the secrets** (never committed to Git):
   ```bash
   mkdir -p secrets
   openssl rand -base64 32 | tr -d '/+=' | cut -c1-24 > secrets/db_password.txt
   openssl rand -base64 32 | tr -d '/+=' | cut -c1-24 > secrets/db_root_password.txt
   openssl rand -base64 32 | tr -d '/+=' | cut -c1-24 > secrets/wp_admin_password.txt
   openssl rand -base64 32 | tr -d '/+=' | cut -c1-24 > secrets/wp_user_password.txt
   openssl rand -base64 32 | tr -d '/+=' | cut -c1-24 > secrets/ftp_password.txt
   chmod 600 secrets/*.txt
   ```

3. **Configure the environment** (`srcs/.env`):
   ```bash
   DOMAIN_NAME=juliados.42.fr
   DB_HOST=mariadb
   DB_DATABASE=wordpress_db
   DB_USER=wp_user
   DB_TABLE_PREFIX=wp_
   WP_PATH=/var/www/wordpress
   WP_TITLE=Inception Juliados
   WP_ADMIN=juliados
   WP_ADMIN_EMAIL=juliados@42.fr
   WP_USER=colaborador42
   WP_USER_EMAIL=user@42.fr
   REDIS_HOST=redis
   REDIS_PORT=6379
   FTP_USER=ftpuser
   FTP_ROOT=/var/www/wordpress
   ADMINER_DEFAULT_SERVER=mariadb
   ```

4. **Build and start**:
   ```bash
   make
   ```

5. **Access**:
   - Website: `https://juliados.42.fr`
   - Admin panel: `https://juliados.42.fr/wp-admin`
   - Adminer: `https://juliados.42.fr/adminer/`
   - cAdvisor: `http://localhost:8080`
   - Static site: `https://juliados.42.fr/static/`
   - FTP: `ftp://juliados.42.fr:21`

### Useful commands

| Command | Description |
|---------|-------------|
| `make` | Build and start the infrastructure |
| `make stop` | Stop containers |
| `make start` | Start stopped containers |
| `make down` | Remove containers and networks |
| `make clean` | Remove containers and orphan networks |
| `make fclean` | Remove everything (volumes, data, secrets) |
| `make re` | `fclean` + `build` |
| `make ps` | Show container status |
| `make logs` | Follow logs |
| `make images` | List Docker images |
| `make network` | List Docker networks |
| `make volume` | List Docker volumes |

---

## Project description

### Design choices

- **Debian Bookworm** as the base image for all services (penultimate stable version at the time of writing).
- **One `Dockerfile` per service**, as required by the subject.
- **Docker named volumes** (not bind mounts) for persistent data, mapped to `/home/juliados/data/` on the host via `driver_opts`.
- **Docker secrets** for all credentials (database passwords, WordPress admin/user passwords, FTP password).
- **A custom bridge network** (`inception-network`) connecting all containers.
- **NGINX as the only entrypoint**, with TLSv1.2/TLSv1.3 on port `443`.
- **PHP-FPM** for WordPress, communicating with NGINX via FastCGI.
- **Reverse proxy** in NGINX for bonus services (Adminer, cAdvisor, static site).

### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker |
|--------|-----------------|--------|
| **Isolation** | Full OS isolation (hypervisor) | Process-level isolation (namespaces + cgroups) |
| **Boot time** | Minutes | Seconds |
| **Resource usage** | Heavy (full OS per VM) | Light (shared kernel) |
| **Portability** | Limited (hypervisor-dependent) | High (runs anywhere Docker runs) |
| **Security** | Strong (hardware isolation) | Good (kernel shared, but namespaces isolate) |
| **Use case** | Full OS testing, legacy apps | Microservices, reproducible environments |

**In this project**, Docker is used because the goal is to orchestrate **lightweight, reproducible services** that communicate over a network — not to emulate full operating systems.

### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Storage** | Mounted as files in `/run/secrets/` | Stored in `.env` or `docker-compose.yml` |
| **Visibility** | Only accessible to the container that needs it | Visible in `docker inspect`, process list, etc. |
| **Git safety** | Never committed | Must be `.gitignore`d |
| **Use case** | Passwords, API keys, certificates | Non-sensitive config (domain, DB name, paths) |

**In this project**, all **passwords** are stored as **Docker secrets** (files in `/run/secrets/`), while **non-sensitive configuration** (domain, DB name, paths) is stored in **environment variables** (`.env`).

### Docker Network vs Host Network

| Aspect | Docker Network (bridge) | Host Network |
|--------|-------------------------|--------------|
| **Isolation** | Containers isolated from host | Containers share host's network |
| **DNS** | Automatic (service names) | Manual |
| **Security** | Better (isolated) | Worse (exposed to host) |
| **Port conflicts** | Avoided | Possible |
| **Use case** | Multi-container apps | Performance-critical apps |

**In this project**, a **custom bridge network** (`inception-network`) is used. Containers communicate via **service names** (e.g., `wordpress:9000`, `mariadb:3306`), and **only NGINX** exposes a port to the host (`443`). `network: host` and `--link` are **forbidden** by the subject.

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|----------------|-------------|
| **Management** | Docker-managed | Host-managed |
| **Portability** | High (Docker handles paths) | Low (host-path dependent) |
| **Backup** | Easy (`docker volume`) | Manual |
| **Performance** | Good | Good (native) |
| **Use case** | Persistent data | Development, config files |

**In this project**, **Docker named volumes** are used for persistent data (WordPress files and MariaDB database). The volumes are configured with `driver_opts` to store data in `/home/juliados/data/` on the host, as required by the subject. **Bind mounts are not used** for these volumes.

---

## Resources

### Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [Redis Documentation](https://redis.io/docs/)
- [vsftpd Documentation](https://security.appspot.com/vsftpd.html)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Adminer Documentation](https://www.adminer.org/)

### Tutorials and articles

- [Docker Curriculum](https://docker-curriculum.com/)
- [NGINX as Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [WordPress Hardening](https://wordpress.org/support/article/hardening-wordpress/)

### AI usage

AI was used in this project for:

- **Debugging**: identifying issues in `Dockerfile`s, `docker-compose.yml`, and shell scripts (e.g., `pasv_address` in FTP, `ROOT_AUTH` in MariaDB, `sub_filter` in NGINX).
- **Documentation**: drafting this `README.md` and the `USER_DOC.md`/`DEV_DOC.md`, ensuring they meet the 42 subject requirements.
- **Best practices**: reviewing security (secrets vs env vars), performance (Redis `maxmemory`), and architecture (SSL termination, reverse proxy).
- **Code review**: line-by-line review of all scripts, suggesting corrections and improvements.

All AI-generated content was **reviewed, tested, and adapted** to the project's specific context. The author is responsible for the final code.

---

## Author

- **juliados** — 42 student
```

