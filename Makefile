#############################################################
#                                                           #
#   ⣿⣿⣿  INCEPTION  ⣿⣿⣿                                  #
#   Docker Infrastructure Orchestration                     #
#                                                           #
#############################################################

NAME            := inception
DOCKER-COMPOSE  := ./srcs/docker-compose.yml
ENV_FILE        := ./srcs/.env
VOLUMES_DIR     := /home/juliados/data
SECRETS_DIR     := ./secrets
SETUP_SCRIPT    := ./srcs/tools/setup.sh

# ─── Cores ANSI ────────────────────────────────────────────
OR  := \033[1;38;5;214m
PK  := \033[1;95;185;55m
GR  := \033[1;32m
RD  := \033[1;31m
CY  := \033[1;36m
RES := \033[0m

# ─── Alvo padrão ───────────────────────────────────────────
all: build

# ─── Construção completa ───────────────────────────────────
build: setup
	@echo -e "$(OR)"
	@echo -e "  ⣿⣿⣿  INCEPTION : A iniciar a infraestrutura  ⣿⣿⣿"
	@echo -e "$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) up -d --build
	@echo -e "$(GR)  ✔ Infraestrutura online.$(RES)"

# ─── Ciclo de vida ─────────────────────────────────────────
start:
	@echo -e "$(CY)  ⏵  A acordar contentores...$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) start

stop:
	@echo -e "$(CY)  ⏸  A parar contentores...$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) stop

down:
	@echo -e "$(CY)  ⏹  A remover contentores e redes...$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) down

ps:
	@echo -e "$(OR)  ⣿  Estado dos contentores:$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) ps

# ─── Limpeza ───────────────────────────────────────────────
clean: stop
	@echo -e "$(CY)  ⌫  A remover contentores e redes órfãs...$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) down --remove-orphans

fclean: clean
	@echo -e "$(RD)  ⚠  Inception: Limpeza profunda (fclean)...$(RES)"
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) down --volumes --remove-orphans
	@echo -e "$(CY)  ⌫  A remover diretório de dados do host...$(RES)"
	sudo rm -rf $(VOLUMES_DIR)
	@echo -e "$(GR)  ✔ Infraestrutura, volumes e segredos removidos.$(RES)"

re: fclean build

# ─── Inspeção ──────────────────────────────────────────────
images:
	@echo -e "$(OR)  ⣿  Imagens Docker:$(RES)"
	docker images

network:
	@echo -e "$(OR)  ⣿  Redes Docker:$(RES)"
	docker network ls

volume:
	@echo -e "$(OR)  ⣿  Volumes Docker:$(RES)"
	docker volume ls

logs:
	docker compose -f $(DOCKER-COMPOSE) --env-file $(ENV_FILE) logs -f

# ─── Preparação do ambiente ────────────────────────────────
setup:
	@echo -e "$(OR)  ⣿  Inception: A preparar ambiente local...$(RES)"
	@mkdir -p $(VOLUMES_DIR)/website
	@mkdir -p $(VOLUMES_DIR)/database
	@mkdir -p $(SECRETS_DIR)
	@# Validação: secrets devem existir (criados manualmente pelo utilizador)
	@if [ ! -f $(SECRETS_DIR)/db_password.txt ] || \
	    [ ! -f $(SECRETS_DIR)/db_root_password.txt ] || \
	    [ ! -f $(SECRETS_DIR)/wp_admin_password.txt ] || \
	    [ ! -f $(SECRETS_DIR)/wp_user_password.txt ]; then \
		echo -e "$(RD)  ✘  Segredos em falta em $(SECRETS_DIR)/$(RES)"; \
		echo -e "$(CY)     Crie os ficheiros: db_password.txt, db_root_password.txt,$(RES)"; \
		echo -e "$(CY)     wp_admin_password.txt, wp_user_password.txt$(RES)"; \
		exit 1; \
	fi
	@echo -e "$(GR)  ✔ Diretórios e segredos verificados.$(RES)"
	@sudo bash $(SETUP_SCRIPT)

# ─── Ajuda ─────────────────────────────────────────────────
help:
	@echo -e "$(OR)"
	@echo -e "  ⣿⣿⣿  INCEPTION : Comandos disponíveis  ⣿⣿⣿"
	@echo -e "$(RES)"
	@echo -e "$(PK)  make build   $(RES) → Prepara ambiente e sobe a infraestrutura"
	@echo -e "$(PK)  make start   $(RES) → Reinicia contentores parados"
	@echo -e "$(PK)  make stop    $(RES) → Para os serviços sem apagar dados"
	@echo -e "$(PK)  make down    $(RES) → Remove contentores e redes"
	@echo -e "$(PK)  make clean   $(RES) → Remove contentores e redes órfãs"
	@echo -e "$(PK)  make fclean  $(RES) → Remove tudo (volumes, dados, segredos)"
	@echo -e "$(PK)  make re      $(RES) → fclean + build"
	@echo -e "$(PK)  make ps      $(RES) → Estado dos contentores"
	@echo -e "$(PK)  make logs    $(RES) → Logs em tempo real"
	@echo -e "$(PK)  make images  $(RES) → Lista imagens Docker"
	@echo -e "$(PK)  make network $(RES) → Lista redes Docker"
	@echo -e "$(PK)  make volume  $(RES) → Lista volumes Docker"
	@echo -e "$(PK)  make help    $(RES) → Mostra esta ajuda"
	@echo -e "$(PK)  make access    $(RES) → Mostra endpoints base do projeto"

access:
	@echo -e "$(OR)"
	@echo -e "  ⣿⣿⣿  INCEPTION : Links de acesso  ⣿⣿⣿"
	@echo -e "$(RES)"
	@echo -e "$(GR)  Website        $(RES)→ $(CY)https://juliados.42.fr$(RES)"
	@echo -e "$(GR)  Admin panel    $(RES)→ $(CY)https://juliados.42.fr/wp-admin$(RES)"
	@echo -e "$(GR)  Adminer        $(RES)→ $(CY)https://juliados.42.fr/adminer/$(RES)"
	@echo -e "$(GR)  Static site    $(RES)→ $(CY)https://juliados.42.fr/static/$(RES)"
	@echo -e "$(GR)  cAdvisor       $(RES)→ $(CY)http://localhost:8080$(RES)"
	@echo -e "$(GR)  FTP            $(RES)→ $(CY)acesso pelo FileZile $(RES)"
	@echo -e "$(RES)"
	@echo -e "$(YL)  ⚠  SSL self-signed: aceita o aviso do navegador.$(RES)"
	@echo -e "$(YL)  ⚠  WP admin: 'juliados' (pass em secrets/wp_admin_password.txt).$(RES)"
	@echo -e "$(YL)  ⚠  Adminer: server 'mariadb', user 'wp_user' (pass em secrets/db_password.txt).$(RES)"
	@echo -e "$(RES)"

.PHONY: all build start stop down ps clean fclean re \
        images network volume logs setup help access