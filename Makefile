.PHONY: test install clean

INSTALL_DIR ?= $(HOME)/.local/bin

test:
	@for t in tests/test-*.sh; do echo "--- $$t ---"; bash "$$t"; done

install:
	@mkdir -p $(INSTALL_DIR)
	@cp bin/wp bin/wp-search bin/wp-stats bin/wp-undo $(INSTALL_DIR)/
	@cp bin/spell/wp-spell $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)"

clean:
	@rm -rf session/
