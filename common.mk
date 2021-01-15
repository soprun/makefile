SHELL := /bin/bash

USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

#-include .env
#-include .env.local

$(error 'PWD: $(PWD)')

#ifeq ($(APP_HOST),)
#$(error 'You need to set the APP_HOST environment variable')
#endif

# export $(shell sed 's/=.*//' $(docker_env_file))

# If the first argument is one of the supported commands...
SUPPORTED_COMMANDS := \
	build \
	down \
	exec \
	console \
	composer \
	shellcheck

SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  # use the rest as arguments for the command
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(COMMAND_ARGS):;@:)
endif

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.DEFAULT_GOAL := help
.PHONY: help

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

#######################################################################
##@ [Docker] Build / Infrastructure
#######################################################################

# Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
#DOCKER_LOG_LEVEL = info
#DOCKER_PROJECT_DIRECTORY = ./
#DOCKER_COMPOSE_FILE = ./docker-compose.yml
#DOCKER_ENV_FILE = .env
#DOCKER_COMPOSE := docker-compose \
#	--file $(DOCKER_COMPOSE_FILE) \
#	--project-name $(PROJECT_NAME) \
#	--project-directory $(DOCKER_PROJECT_DIRECTORY)

DOCKER_COMPOSE := docker-compose \
	--project-name $(PROJECT_NAME) \
	--file $(PWD)/docker-compose.yml

DOCKER_COMPOSE_EXEC := $(DOCKER_COMPOSE) exec --user $(USER_ID):$(GROUP_ID)

DEFAULT_CONTAINER := php-fpm
DEFAULT_CONTAINER_EXEC := $(DOCKER_COMPOSE_EXEC) $(DEFAULT_CONTAINER)

.PHONY: docker-config
docker-config: ## Validate and view the Compose file.
	$(DOCKER_COMPOSE) config

.PHONY: pull
pull: ## Pull service images and run service
	$(DOCKER_COMPOSE) pull && \
	$(DOCKER_COMPOSE) up --detach $(COMMAND_ARGS)

GIT_TAG=$(shell git describe --tags `git rev-list --tags --max-count=1`)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT_SHA=$(shell git rev-parse HEAD)
GIT_COMMIT_ID=$(shell git rev-parse --short=7 HEAD)

build-labels:
	@echo APP_ENV=$(APP_ENV)
	@echo APP_SECRET=$(shell openssl rand -base64 32)
	@echo APP_RELEASE=$(GIT_TAG)
	@echo APP_RELEASE_BRANCH=$(GIT_BRANCH)
	@echo APP_RELEASE_COMMIT=$(GIT_COMMIT_ID)

.PHONY: build
build: ## Build all docker images. To only stop one container, usage: make docker-build <container_id>
	$(DOCKER_COMPOSE) build --progress tty \
	--build-arg APP_ENV=$(APP_ENV) \
	--build-arg APP_SECRET=$(shell openssl rand -base64 32) \
	--build-arg APP_RELEASE=$(GIT_TAG) \
	--build-arg APP_RELEASE_BRANCH=$(GIT_BRANCH) \
	--build-arg APP_RELEASE_COMMIT=$(GIT_COMMIT_ID) \
	$(COMMAND_ARGS) && \
	$(DOCKER_COMPOSE) up --detach --force-recreate --remove-orphans $(COMMAND_ARGS)

.PHONY: up
up: ## Build all docker images. To only stop one container, usage: make docker-build <container_id>
	$(DOCKER_COMPOSE) up --detach $(COMMAND_ARGS)

.PHONY: down
down: ## Stop all docker containers. To only stop one container, usage: make docker-down <container_id>
	$(DOCKER_COMPOSE) down --volumes --remove-orphans --rmi local $(COMMAND_ARGS)
	docker volume prune --force
	docker network prune --force

.PHONY: exec
exec: ## Execute a command in a running default container
	$(DEFAULT_CONTAINER_EXEC) bash $(COMMAND_ARGS)

#######################################################################
##@ [Application]
#######################################################################

.PHONY: console
console: ## Run console in DEFAULT_CONTAINER=php-fpm
	$(DEFAULT_CONTAINER_EXEC) bin/console $(COMMAND_ARGS)

.PHONY: env
env: ## Displays all environment variables of the Docker container.
	$(DEFAULT_CONTAINER_EXEC) printenv | sort

.PHONY: env-vars
env-vars: ## Displays all environment variables used by the Symfony container
	$(DEFAULT_CONTAINER_EXEC) bin/console debug:container --env-vars

.PHONY: database-update
database-update: ## schema-update
	$(DEFAULT_CONTAINER_EXEC) bin/console doctrine:schema:update --force

.PHONY: database-setup
database-setup: ## Run setup
	cat $(PWD)/docker/mysql/backup.sql | $(DOCKER_COMPOSE) exec -T $(MYSQL_HOST) \
	/usr/bin/mysql \
	--user=$(MYSQL_ROOT_USER) \
	--password=$(MYSQL_ROOT_PASSWORD) \
	$(MYSQL_DATABASE)

shellcheck: ## Run shellcheck
	for file in $(shell file $(shell find $(PWD)/docker -type f -print) | grep 'shell script' | cut -d: -f1 | sort -u ) ; do \
		shellcheck --check-sourced --external-sources $$file ; \
	done

.PHONY: phpstan
phpstan: ## PHP Stan: https://phpstan.org
	$(DEFAULT_CONTAINER_EXEC) phpstan analyse \
	--configuration $(PROJECT_PATH_CONTAINER)/phpstan.neon \
	--xdebug

.PHONY: phpmetrics
phpmetrics: ## PhpMetrics: https://phpmetrics.github.io/PhpMetrics
	$(DEFAULT_CONTAINER_EXEC) phpmetrics \
	--report-html="$(PROJECT_PATH_CONTAINER)/public/report" \
	$(PROJECT_PATH_CONTAINER)/src

composer: ## Run composer in DEFAULT_CONTAINER=php-fpm
	$(DEFAULT_CONTAINER_EXEC) composer $(COMMAND_ARGS)

.PHONY: project-clean
project-clean: ## Deletes all working and cache files
	#rm -rf $(PWD)/app/bin/.phpunit
	#rm -rf $(PWD)/app/vendor/*
	#rm -rf $(PWD)/app/var/cache/*
	#rm -rf $(PWD)/docker/nginx/ssl/
	#rm -rf $(PWD)/docker/sphinx/data
	#rm -rf $(PWD)/docker/mysql/data

.PHONY: project-install
project-install: ## Run install project
ifeq ($(APP_HOST),)
	$(error 'You need to set the APP_HOST environment variable')
endif

	rm -rf $(PWD)/docker/nginx/ssl/*
	mkdir -p $(PWD)/docker/nginx/ssl

	# Locally trusted development certificates
	mkcert \
	-key-file $(PWD)/docker/nginx/ssl/key.pem \
	-cert-file $(PWD)/docker/nginx/ssl/cert.pem \
	$(APP_HOST) \
	*.$(APP_HOST) \
	localhost

	# Generate Diffie-Hellman keys
	openssl dhparam -out $(PWD)/docker/nginx/ssl/dhparam.pem 2048
