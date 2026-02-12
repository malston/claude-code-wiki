.PHONY: help server build clean lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

server: ## Start Hugo development server with live reload
	hugo server

build: ## Build static site to public/ directory
	hugo

clean: ## Remove generated files
	rm -rf public/

lint: ## Run style checks on all content
	bash scripts/check-style.sh content/
