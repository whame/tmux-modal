SHELL := /usr/bin/env bash -o pipefail

CONF_FILE := keybindings.conf
SCRIPT := tmux-modal.tmux

.PHONY: all
all:

.PHONY: test
test: all
	./$(SCRIPT)

.PHONY: clean
clean:
