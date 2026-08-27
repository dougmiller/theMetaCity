# theMetaCity — podman workflow.
COMPOSE ?= podman-compose

.PHONY: build up down rebuild logs ps

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
