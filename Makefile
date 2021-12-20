BASE  := $${HOME}/projects/chromium
SRC   := $(BASE)/src

TOOLS := $(BASE)/depot_tools

BUILD_ROOT  := $(BASE)/out

PATH  := $(PATH):$(TOOLS)
SHELL := env PATH=$(PATH) /bin/bash

RED := '\033[0;31m'
NC := '\033[0m'

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
  PACK := pack_macos.sh
  BUILD_ARGS := build_args_macos.gn
else ifeq ($(UNAME), Linux)
  PACK := pack_linux.sh
  BUILD_ARGS := build_args_linux.gn
else
  PACK := pack_windows.cmd
  BUILD_ARGS := build_args_windows.gn
endif


package: check
	@echo "== package"
	@PATH=$(PATH) bash $(PACK) $(BUILD_ROOT) $(SRC)

build: check
	@echo "== configure"
	@cd $(SRC) && PATH=$(PATH) gn gen $(BUILD_ROOT)
	@cp $(BUILD_ARGS) $(BUILD_ROOT)/args.gn
	@cd $(SRC) && PATH=$(PATH) gn gen $(BUILD_ROOT)
	@echo "== build"
	@cd $(SRC) && PATH=$(PATH) autoninja -C $(BUILD_ROOT) chrome

clean: check
	@cd $(SRC)
	@rm -fR $(BUILD_ROOT)

check:
	@test -d $(BASE) || (echo "$(RED)-----> please ssh to build node and run: make bootstrap-linux or make bootstrap-macos$(NC)" && exit -1)

prepare-linux:
	@echo "== Install build dependecies"
	@mkdir -p $(BASE)
	@echo $(PATH)
	@sudo apt install -y git
	@git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $(TOOLS) || echo "Already cloned"
	@cd $(BASE) && PATH=$(PATH) fetch --nohooks chromium || echo "fetch is used only to get new checkouts. Use"
	# patch dependeciescies
	# https://stackoverflow.com/questions/65978703/missing-libappindicator3-1-installing-slack
	@sed -i -e 's/libappindicator3/libayatana-appindicator3/g' $(SRC)/build/install-build-deps.sh
	@test -f $(BASE)/.build_deps_installed || cd $(SRC) && bash build/install-build-deps.sh --no-prompt && touch $(BASE)/.buildd_deps_installed
	@cd $(SRC) && PATH=$(PATH) gclient runhooks

bootstrap-macos:
	@echo "== Install build dependecies"
	@brew install zsh tmux htop java11 mercurial wget
