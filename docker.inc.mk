
docker_bin := $(shell command -v docker 2> /dev/null)

docker-version: ## vert
	$(docker_bin) version