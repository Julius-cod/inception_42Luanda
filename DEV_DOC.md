# DEV_DOC.md — Developer Documentation

This document describes the technical architecture of the **Inception** project and provides instructions for developers to set up, build, and manage the environment from scratch.

---

## 1. Prerequisites and Environment Setup
To replicate this environment, the host machine must meet the following prerequisites:
*   **Operating System:** Linux (Debian Bullseye or Ubuntu recommended) running inside a Virtual Machine.
*   **Tools Installed:** `docker` (v20+), `docker-compose-plugin`, and `make`.

### Configuration Files Structure
The project must follow this exact repository structure:
```text
├── Makefile
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                # Generated automatically, ignored by Git
└── srcs/
    ├── .env                # Global environment variables
    ├── docker-compose.yml  # Main orchestrator
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

### Secrets and Environment Variables
*   **`.env` File:** Stores non-sensitive configuration data (database names, domain syntax, container paths).
*   **Docker Secrets:** Sensitive credentials are saved in individual files under `./secrets/*.txt`. These files are mapped into the container's RAM filesystem under `/run/secrets/` and are excluded from version control via `.gitignore`.

---

## 2. Building and Launching the Project
The build pipeline is fully automated. When a developer triggers the build, `make` runs a local configuration script (`setup.sh`) to patch `/etc/hosts` and instantiate local secrets before compilation.

To build the images from scratch and run the containers:
```bash
make build
```
This forces Docker Compose to build custom images based on clean **Debian Bullseye** layers instead of pulling pre-built application stacks from DockerHub, complying with 42 constraints.

---

## 3. Container and Volume Management Commands
Developers can manage the lifecycle using the following custom Makefile targets:

*   **`make ps`**: Inspects active containers, exposed ports, and uptimes.
*   **`make logs`**: Tails standard output and standard error from all microservices simultaneously.
*   **`make clean`**: Safely stops the environment and deletes the network interface.
*   **`make fclean`**: Performs a deep clean. It purges containers, networks, **Docker named volumes**, local data storage, and the `secrets/` folder.
*   **`make re`**: Triggers a clean re-build (`make fclean && make build`).

---

## 4. Data Storage and Persistence Strategy
Data persistence is handled via **Docker Named Volumes** configured with a local driver bind option. This matches the 42 requirement of keeping data intact after container disposal while forcing the physical assets into a specific path on the host.

*   **WordPress Files Storage:** Mapped to `/home/juliados42/data/website`. Inside the container, it mounts to `/var/www/wordpress`.
*   **MariaDB Database Engines:** Mapped to `/home/juliados42/data/database`. Inside the container, it mounts to `/var/lib/mysql`.

### Data Lifecycle
When a container crashes or is stopped via `make stop` / `make down`, the data remains untouched on the host machine. The files are only deleted if a developer explicitly calls `make fclean`, which triggers the destruction of the persistent named volumes.
