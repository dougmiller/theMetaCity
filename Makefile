# theMetaCity — podman workflow.
COMPOSE ?= podman-compose
PROD    := -f podman-compose.prod.yml

.PHONY: build up down rebuild logs ps certs up-prod down-prod rebuild-prod logs-prod ps-prod

# ---- dev stack (unchanged) ----
build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

rebuild:
	$(COMPOSE) build --no-cache

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# ---- mTLS certs ----
certs:
	./scripts/gen-certs.sh

# ---- prod stack (TLS + mTLS); do not run alongside dev ----
up-prod:
	$(COMPOSE) $(PROD) up -d

down-prod:
	$(COMPOSE) $(PROD) down

rebuild-prod:
	$(COMPOSE) $(PROD) build --no-cache

logs-prod:
	$(COMPOSE) $(PROD) logs -f

ps-prod:
	$(COMPOSE) $(PROD) ps
