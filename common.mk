SHELL := /bin/bash
USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)
UNAME := $(shell uname -m -s)
OS = $(word 1, $(UNAME))
OS_ARCH = $(word 2, $(UNAME))

ifeq ($(shell echo $(OS) | egrep -c 'Darwin|FreeBSD|OpenBSD|DragonFly'),1)
CPUS := $(shell sysctl -n hw.ncpu)
else
CPUS := $(shell nproc)
endif

GIT_TAG=$(shell git describe --tags --abbrev=0 >/dev/null 2>&1 | sed -e 's/^v//')
GIT_LATEST_TAG=$(shell git -c versionsort.prereleaseSuffix="-rc" -c versionsort.prereleaseSuffix="-RC" tag --sort=-version:refname -l "v*.*.*" | awk '!/rc/' | sed -e 's/^v//' | head -n 1)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD | sed -e 's/^feature\///' | tr A-Z a-z || echo 'n/a')
GIT_COMMIT_ID=$(shell git rev-parse --short HEAD || echo 'n/a')
GIT_COMMIT_SHA=$(shell git rev-parse HEAD)

#VERSION := $(shell git describe --exact-match --tags $(git log -n1 --pretty='%h') 2> /dev/null | sed 's/^v//')
#
#ifndef VERSION
#    VERSION = dev
#endif
#
#GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD || echo 'n/a')
#GIT_REVISION :=	$(shell git rev-parse --short HEAD || echo 'n/a')

PROJECT_DIR = $(shell cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
MAKEFILE_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Load environment variables from .env
-include "$(PROJECT_DIR)/.env"
-include "$(PROJECT_DIR)/.env.local"

ifndef PROJECT_NAME
#PROJECT_NAME = $(shell basename $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) | tr '[:upper:]' '[:lower:]')
PROJECT_NAME = $(shell basename $(PROJECT_DIR) | tr '[:upper:]' '[:lower:]')
endif

#ifndef APP_ENV
#$(error The env:APP_ENV variable is missing.)
#endif
#
#ifeq ($(filter $(APP_ENV),test dev prod),)
#$(error The env:APP_ENV variable is invalid.)
#endif
#
#ifeq ($(APP_VERSION),)
##$(warning The env:APP_VERSION is unknown!)
#	APP_VERSION = unknown
#endif
#
#ifeq ($(APP_VERSION), unknown)
#    APP_VERSION = $(GIT_TAG)
#endif
#
#ifeq ($(APP_VERSION),)
##$(warning The env:APP_VERSION set this git correct branch.)
#	APP_VERSION = $(GIT_BRANCH)
#endif

# Allows to pass arguments into make, eg. make TASK some args. Credits: https://stackoverflow.com/a/6273809
ARGS = $(filter-out $@,$(MAKECMDGOALS))

COLOR_RESET := \033[0m
COLOR_RED := \033[0;31m
COLOR_YELLOW := \033[0;33m
COLOR_GREEN := \033[0;32m
COLOR_BLUE := \033[0;34m

#ifeq ($(shell ! test -f "$(PROJECT_DIR)/docker-compose.yml" && echo -n yes),yes)
#$(shell cp "$(PROJECT_DIR)/docker-compose.yml.dist" "$(PROJECT_DIR)/docker-compose.yml")
#$(info The root ./docker-compose.yml file was copied from ./docker-compose.yml.dist)
#endif

# ref: https://stackoverflow.com/questions/6273608/how-to-pass-argument-to-makefile-from-command-line
%: # do not change - this is useful for passing args to make
	@: # do not change - this is useful for passing args to make

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(COLOR_YELLOW)<target>$(COLOR_RESET)\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  $(COLOR_GREEN)%-27s$(COLOR_RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s$(COLOR_RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# include Makefile.local if it exists
# -include Makefile.local

envs:
	@echo "PROJECT_DIR:$(PROJECT_DIR)"
	@echo "MAKEFILE_DIR:$(MAKEFILE_DIR)"
	@echo "PROJECT_NAME:$(PROJECT_NAME)"
	@echo "USER_ID:$(USER_ID)"
	@echo "GROUP_ID:$(GROUP_ID)"
	@echo "OS:$(OS)"
	@echo "ARCH:$(ARCH)"
	@echo "CPUS:$(CPUS)"
	@echo "GIT_TAG:$(GIT_TAG)"
	@echo "GIT_LATEST_TAG:$(GIT_LATEST_TAG)"
	@echo "GIT_BRANCH:$(GIT_BRANCH)"
	@echo "GIT_COMMIT_ID:$(GIT_COMMIT_ID)"
	@echo "GIT_COMMIT_SHA:$(GIT_COMMIT_SHA)"
	@echo "VERSION:$(VERSION)"
	@echo "GIT_REVISION:$(GIT_REVISION)"
	@echo "APP_VERSION:$(APP_VERSION)"

include $(MAKEFILE_DIR)/makefiles/standard.inc.mk
include $(MAKEFILE_DIR)/makefiles/git.inc.mk
include $(MAKEFILE_DIR)/makefiles/docker.inc.mk
