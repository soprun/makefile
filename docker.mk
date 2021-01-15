#######################################################################
##@ [Docker] Build / Infrastructure
#######################################################################

DOCKER_COMPOSE := docker-compose \
	--project-name $(PROJECT_NAME) \
	--file $(PWD)/docker-compose.yml

.PHONY: docker-config
docker-config: ## Validate and view the Compose file.
	$(DOCKER_COMPOSE) config