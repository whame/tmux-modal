SHELL := /usr/bin/env bash -o pipefail

CONF_FILE := keybindings.conf
SCRIPT := tmux-modal.tmux

.PHONY: all
all: $(CONF_FILE)

$(CONF_FILE): $(SCRIPT)
	@lineNr=$$(wc -l $< | cut -d ' ' -f 1); \
		grep "^# START KEYBINDINGS" -A $${lineNr} $< | tail -n +2 | \
		grep "^# END KEYBINDINGS" -B $${lineNr} | head -n -1 > $@
	@echo "Created ${CONF_FILE}"

.PHONY: test
test: all
	./$(SCRIPT)

.PHONY: clean
clean:
	$(RM) $(CONF_FILE)
