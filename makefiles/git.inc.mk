# Git
# https://www.codegrepper.com/code-examples/shell/git+submodule+update
# https://devconnected.com/how-to-add-and-update-git-submodules/

git-submodule-update: ## to update
	@#git pull origin main
	git submodule update --init

git-submodule-update-all: git-submodule-update ## to update with submodules' update out of this repository
	git submodule foreach git pull origin main
