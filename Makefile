BASE  := $${HOME}/chromium
SRC   := $(BASE)/src
TOOLS := $(BASE)/depot_tools
BUILD_ROOT  := $${HOME}/tmpfs/
BUILD_DIST := $(BUILD_ROOT)/chromium

PATH  := $(PATH):$(TOOLS)
SHELL := env PATH=$(PATH) /bin/bash

RED := '\033[0;31m'
NC := '\033[0m'

package: check
	@echo "== package"
	@cd $(SRC) && PATH=$(PATH) autoninja -C $(BUILD_DIST) "chrome/installer/linux:unstable_deb"

build: check
	@mount | grep "jenkins\/tmpfs" || sudo mount -t tmpfs -o size=40G,nr_inodes=500k,mode=1777,noatime tmpfs $(BUILD_ROOT)
	@echo "== configure"
	@cd $(SRC) && PATH=$(PATH) gn gen $(BUILD_DIST)
	@echo "# config"                            > $(BUILD_DIST)/args.gn
	@echo "is_component_build=false"           >> $(BUILD_DIST)/args.gn
	@echo "remove_webcore_debug_symbols=true"  >> $(BUILD_DIST)/args.gn
	@echo "is_debug=false"                     >> $(BUILD_DIST)/args.gn
	@echo "symbol_level=1"                     >> $(BUILD_DIST)/args.gn
	@echo "blink_symbol_level=0"               >> $(BUILD_DIST)/args.gn
	@echo "v8_symbol_level=0"                  >> $(BUILD_DIST)/args.gn
	@echo "enable_linux_installer=true"        >> $(BUILD_DIST)/args.gn
	@echo "== config: args.gn:"
	@cat $(BUILD_DIST)/args.gn
	@echo "== build"
	@cd $(SRC) && PATH=$(PATH) EDITOR=cat gn args $(BUILD_DIST)  < $(BUILD_DIST)/args.gn
	@echo "is_component_build=false"  >> $(BUILD_DIST)/args.gn
	@cd $(SRC) && PATH=$(PATH) autoninja -C $(BUILD_DIST) chrome

clean: check
	@cd $(SRC)
	@rm -fR $(BUILD_DIST)

check:
	@test -d $(BASE) || (echo "$(RED)-----> please ssh to build node and run: make bootstrap-linux or make bootstrap-macos$(NC)" && exit -1)

bootstrap-linux:
	@echo "== Install build dependecies"
	@mkdir -p $(BASE)
	@echo $(PATH)
	@sudo apt install -y git
	@git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $(TOOLS) || echo "Already cloned"
	#@mount | grep "jenkins\/tmpfs" || sudo mount -t tmpfs -o size=40G,mode=1777,nr_inodes=500k,noatime tmpfs $(BUILD_ROOT)
	@cd $(BASE) && PATH=$(PATH) fetch --nohooks chromium || echo "fetch is used only to get new checkouts. Use"
	# patch dependeciescies
	# https://stackoverflow.com/questions/65978703/missing-libappindicator3-1-installing-slack
	@sed -i -e 's/libappindicator3/libayatana-appindicator3/g' $(SRC)/build/install-build-deps.sh
	@test -f $(BASE)/.build_deps_installed || cd $(SRC) && bash build/install-build-deps.sh --no-prompt && touch $(BASE)/.buildd_deps_installed
	@cd $(SRC) && PATH=$(PATH) gclient runhooks

bootstrap-macos:
	@echo "== Install build dependecies"
