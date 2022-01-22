#######################################################################
##@ [Standard Targets for Users 🎯 ]
#######################################################################

## https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html#Standard-Targets

.PHONY: all
all: ## Run all targets
	@printf "$(COLOR_YELLOW)[WARNING] $(COLOR_RED)%s\n$(COLOR_RESET)" "Run all targets..."

.PHONY: install
install: ## Run install targets
	@printf "$(COLOR_YELLOW)[WARNING] $(COLOR_RED)%s\n$(COLOR_RESET)" "Checking the programs required for the build are installed..."

.PHONY: test
test: ## Run test targets
	@printf "$(COLOR_YELLOW)[WARNING] $(COLOR_RED)%s\n$(COLOR_RESET)" "Run test targets..."

.PHONY: clean
clean: ## Run targets targets
	@printf "$(COLOR_YELLOW)[WARNING] $(COLOR_RED)%s\n$(COLOR_RESET)" "Run clean targets..."
	@#rm -rf $(PROJECT_DIR)/var/cache/*
	@#rm -rf $(PROJECT_DIR)/var/log/*
	@#docker system prune --volumes
