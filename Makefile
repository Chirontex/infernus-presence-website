.PHONY: help up down restart logs build pull install migrate seed test coverage lint format clean

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Infernus Presence Website - Docker Management$(NC)"
	@echo "$(BLUE)============================================$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

up: ## Start all services
	@echo "$(BLUE)Starting services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "$(BLUE)Frontend:$(NC) http://infernus-presence.local"
	@echo "$(BLUE)Backend API:$(NC) http://infernus-presence.local/api"
	@echo "$(BLUE)Admin Panel:$(NC) http://infernus-presence.local/admin"

down: ## Stop all services
	@echo "$(BLUE)Stopping services...$(NC)"
	docker compose down
	@echo "$(GREEN)Services stopped!$(NC)"

restart: down up ## Restart all services

build: ## Build Docker images
	@echo "$(BLUE)Building images...$(NC)"
	docker compose build --no-cache
	@echo "$(GREEN)Images built!$(NC)"

pull: ## Pull base images
	@echo "$(BLUE)Pulling images...$(NC)"
	docker compose pull
	@echo "$(GREEN)Images pulled!$(NC)"

logs: ## Show logs from all services
	docker compose logs -f

logs-backend: ## Show backend logs
	docker compose logs -f backend

logs-frontend: ## Show frontend logs
	docker compose logs -f frontend

logs-nginx: ## Show nginx logs
	docker compose logs -f nginx

logs-database: ## Show database logs
	docker compose logs -f database

shell-backend: ## Open backend shell
	docker compose exec backend sh

shell-frontend: ## Open frontend shell
	docker compose exec frontend sh

shell-database: ## Open database shell
	docker compose exec database mariadb -u infernus_user -p

install: ## Install all dependencies
	@echo "$(BLUE)Installing backend dependencies...$(NC)"
	docker compose exec backend composer install
	@echo "$(BLUE)Installing frontend dependencies...$(NC)"
	docker compose exec frontend npm install
	@echo "$(GREEN)Dependencies installed!$(NC)"

composer-install: ## Install PHP dependencies
	docker compose exec backend composer install

composer-update: ## Update PHP dependencies
	docker compose exec backend composer update

npm-install: ## Install Node.js dependencies
	docker compose exec frontend npm install

npm-update: ## Update Node.js dependencies
	docker compose exec frontend npm update

migrate: ## Run database migrations
	@echo "$(BLUE)Running migrations...$(NC)"
	docker compose exec backend php bin/console doctrine:migrations:migrate -n
	@echo "$(GREEN)Migrations completed!$(NC)"

migrate-create: ## Create a new migration
	@echo "Enter migration name:"
	@read name; \
	docker compose exec backend php bin/console doctrine:migrations:generate $$name

seed: ## Seed database with sample data
	@echo "$(BLUE)Seeding database...$(NC)"
	docker compose exec backend php bin/console doctrine:fixtures:load -n
	@echo "$(GREEN)Database seeded!$(NC)"

cache-clear: ## Clear application cache
	@echo "$(BLUE)Clearing cache...$(NC)"
	docker compose exec backend php bin/console cache:clear
	@echo "$(GREEN)Cache cleared!$(NC)"

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	docker compose exec backend php bin/phpunit
	docker compose exec frontend npm run test
	@echo "$(GREEN)Tests completed!$(NC)"

test-backend: ## Run backend tests
	docker compose exec backend php bin/phpunit

test-frontend: ## Run frontend tests
	docker compose exec frontend npm run test

coverage: ## Generate test coverage report
	@echo "$(BLUE)Generating coverage reports...$(NC)"
	docker compose exec backend php bin/phpunit --coverage-html coverage/backend
	docker compose exec frontend npm run coverage
	@echo "$(GREEN)Coverage reports generated!$(NC)"

lint: ## Run linters
	@echo "$(BLUE)Running linters...$(NC)"
	docker compose exec backend php bin/console lint:yaml config/
	docker compose exec backend vendor/bin/php-cs-fixer fix --dry-run
	docker compose exec frontend npm run lint
	@echo "$(GREEN)Linting completed!$(NC)"

lint-fix: ## Fix linting issues
	@echo "$(BLUE)Fixing linting issues...$(NC)"
	docker compose exec backend vendor/bin/php-cs-fixer fix
	docker compose exec frontend npm run lint:fix
	@echo "$(GREEN)Linting issues fixed!$(NC)"

format: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	docker compose exec backend vendor/bin/php-cs-fixer fix
	docker compose exec frontend npm run format
	@echo "$(GREEN)Code formatted!$(NC)"

validate: ## Validate configurations
	@echo "$(BLUE)Validating configurations...$(NC)"
	docker compose config --quiet
	docker compose exec backend php bin/console lint:yaml config/
	docker compose exec backend composer validate
	@echo "$(GREEN)Validations passed!$(NC)"

clean: ## Clean up temporary files and volumes
	@echo "$(BLUE)Cleaning up...$(NC)"
	docker compose down -v
	rm -rf backend/var/cache/* backend/var/log/*
	rm -rf frontend/.nuxt frontend/.output frontend/node_modules
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-full: ## Full cleanup (removes all containers, volumes, and images)
	@echo "$(RED)WARNING: This will remove all containers, volumes, and images!$(NC)"
	@read -p "Are you sure? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker compose down -v --rmi all; \
		rm -rf backend/var backend/public/uploads frontend/node_modules frontend/.nuxt frontend/.output; \
		echo "$(GREEN)Full cleanup completed!$(NC)"; \
	else \
		echo "Cleanup cancelled"; \
	fi

status: ## Show service status
	@docker compose ps

env-setup: ## Setup environment files from examples
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN).env file created from .env.example$(NC)"; \
		echo "$(BLUE)Please update .env with your configuration$(NC)"; \
	else \
		echo "$(BLUE).env file already exists$(NC)"; \
	fi

ps: ## Show running containers
	docker compose ps

stats: ## Show container statistics
	docker compose stats

config: ## Validate docker-compose config
	docker compose config
