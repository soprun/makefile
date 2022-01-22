#######################################################################
## [Docker variables]
#######################################################################

docker_bin := $(shell command -v docker 2> /dev/null)

docker_compose := \
	$(docker_bin) compose \
	--project-name $(PROJECT_NAME) \
	--project-directory $(PROJECT_DIR) \
	--file $(PROJECT_DIR)/docker-compose.yml

ifeq ($(shell test -e $(PROJECT_DIR)/docker-compose.override.yml && echo -n yes),yes)
	docker_compose += --file $(PROJECT_DIR)/docker-compose.override.yml
endif

docker-version: ## vert
	$(docker_bin) version