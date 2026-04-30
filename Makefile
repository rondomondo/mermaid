REPO    := https://github.com/rondomondo/mermaid
SCRIPT  := mermaid.sh
INSTALL_DIR ?= /usr/local/bin

BOLD  := \033[1m
CYAN  := \033[36m
GREEN := \033[32m
RED   := \033[31m
RESET := \033[0m

SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help install uninstall check test pull-image doctor

help: ## Show available targets
	@printf "$(BOLD)mermaid — available targets$(RESET)\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-14s$(RESET) %s\n", $$1, $$2}'
	@echo ""

install: ## Copy mermaid.sh to INSTALL_DIR and add source line to shell profile
	@echo "Installing $(SCRIPT) → $(INSTALL_DIR)/$(SCRIPT)"
	@cp $(SCRIPT) "$(INSTALL_DIR)/$(SCRIPT)"
	@chmod 644 "$(INSTALL_DIR)/$(SCRIPT)"
	@PROFILE=""; \
	if [[ -n "$$ZSH_VERSION" ]] || [[ "$$(basename "$$SHELL")" == "zsh" ]]; then \
		PROFILE=~/.zshrc; \
	else \
		PROFILE=~/.bashrc; \
	fi; \
	LINE="source $(INSTALL_DIR)/$(SCRIPT)"; \
	if grep -qF "$$LINE" "$$PROFILE" 2>/dev/null; then \
		printf "$(CYAN)already in $$PROFILE — skipping$(RESET)\n"; \
	else \
		echo "$$LINE" >> "$$PROFILE"; \
		printf "$(GREEN)Added to $$PROFILE$(RESET)\n"; \
		printf "Run: $(BOLD)source $$PROFILE$(RESET)\n"; \
	fi

uninstall: ## Remove mermaid.sh from INSTALL_DIR and source lines from shell profiles
	@rm -f "$(INSTALL_DIR)/$(SCRIPT)"
	@for profile in ~/.zshrc ~/.bashrc ~/.bash_profile; do \
		[ -f "$$profile" ] || continue; \
		if grep -qF "$(INSTALL_DIR)/$(SCRIPT)" "$$profile"; then \
			grep -vF "$(INSTALL_DIR)/$(SCRIPT)" "$$profile" > "$$profile.tmp" && mv "$$profile.tmp" "$$profile"; \
			printf "$(CYAN)Removed source line from $$profile$(RESET)\n"; \
		fi; \
	done
	@printf "$(GREEN)Uninstalled$(RESET)\n"

check: ## Check that Docker is running and the mermaid function is available in the current shell
	@printf "Checking Docker... "
	@if docker info >/dev/null 2>&1; then \
		printf "$(GREEN)ok$(RESET)\n"; \
	else \
		printf "$(RED)Docker is not running$(RESET)\n"; exit 1; \
	fi
	@printf "Checking mermaid function... "
	@if bash -c 'source $(INSTALL_DIR)/$(SCRIPT) 2>/dev/null && type mermaid' >/dev/null 2>&1; then \
		printf "$(GREEN)ok$(RESET)\n"; \
	else \
		printf "$(RED)not found — run 'make install' first$(RESET)\n"; exit 1; \
	fi

pull-image: ## Pre-pull the minlag/mermaid-cli Docker image
	docker pull minlag/mermaid-cli

test: check ## Render data/example.md as SVG and PNG to verify the full pipeline
	@echo "--- SVG render ---"
	@bash -c 'source $(INSTALL_DIR)/$(SCRIPT) && mermaid data/example.md -f svg'
	@echo "--- PNG render ---"
	@bash -c 'source $(INSTALL_DIR)/$(SCRIPT) && mermaid data/example.md -f png --width 960 --height 640'
	@printf "$(GREEN)Test renders complete$(RESET)\n"
	@ls -lh data/example.svg.md data/example.png.md 2>/dev/null || true

doctor: ## Show environment info useful for bug reports
	@printf "$(BOLD)mermaid doctor$(RESET)\n\n"
	@printf "  Shell:        %s\n" "$$SHELL"
	@printf "  Install dir:  $(INSTALL_DIR)\n"
	@printf "  Script:       "; ls -lh "$(INSTALL_DIR)/$(SCRIPT)" 2>/dev/null || printf "$(RED)not installed$(RESET)\n"
	@printf "  Docker:       "; docker --version 2>/dev/null || printf "$(RED)not found$(RESET)\n"
	@printf "  Docker running: "; docker info >/dev/null 2>&1 && printf "$(GREEN)yes$(RESET)\n" || printf "$(RED)no$(RESET)\n"
	@printf "  mermaid-cli image: "; docker image inspect minlag/mermaid-cli --format '{{.RepoTags}} ({{.Id}})' 2>/dev/null || printf "not pulled (run make pull-image)\n"
	@echo ""
