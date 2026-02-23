.PHONY: test install clean

INSTALL_DIR ?= $(HOME)/.local
INSTALL_BIN ?= $(INSTALL_DIR)/bin
INSTALL_LIB ?= $(INSTALL_DIR)/lib

test:
	@for t in tests/test-*.sh; do echo "--- $$t ---"; bash "$$t"; done

install:
	@mkdir -p $(INSTALL_BIN) $(INSTALL_LIB)
	@cp bin/wp bin/wp-search bin/wp-stats bin/wp-undo $(INSTALL_BIN)/
	@cp bin/spell/wp-spell $(INSTALL_BIN)/
	@cp lib/wp-common.sh $(INSTALL_LIB)/
	@echo "Installed to $(INSTALL_DIR)"

clean:
	@rm -rf session/
