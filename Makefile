.DEFAULT_GOAL := help
.PHONY: help up down logs ps test lint fmt typecheck check

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

up: ## Start the stack in the background
	docker compose up -d --build

down: ## Stop the stack
	docker compose down

logs: ## Follow logs for all services
	docker compose logs -f --tail=100

ps: ## Show container status and health
	docker compose ps

test: ## Run the Python tests
	pytest

lint: ## Lint Python with ruff
	ruff check .

fmt: ## Format Python with ruff
	ruff format .

typecheck: ## Type-check Python with mypy
	mypy services

check: lint typecheck test ## Everything CI runs
