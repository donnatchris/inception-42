SHELL := /bin/bash

COMPOSE_PATH := srcs/docker-compose.yml
ENV_PATH := srcs/.env

all: check_env setup_dirs setup_hosts up

# Check if .env file exists in srcs/
check_env:
	@echo "📄 Checking if $(ENV_PATH) exists..."
	@if [ ! -f $(ENV_PATH) ]; then \
		echo "❌ Error: $(ENV_PATH) file not found. Please create it before running make."; \
		exit 1; \
	else \
		echo "✅ $(ENV_PATH) file found."; \
	fi

# Create ~/data/wordpress and ~/data/mariadb if they don't exist
setup_dirs:
	@echo "📁 Checking ~/data/wordpress and ~/data/mariadb directories..."
	@if [ ! -d "$$HOME/data/wordpress" ]; then \
		echo "➡️  Creating $$HOME/data/wordpress directory"; \
		mkdir -p "$$HOME/data/wordpress"; \
	fi
	@if [ ! -d "$$HOME/data/mariadb" ]; then \
		echo "➡️  Creating $$HOME/data/mariadb directory"; \
		mkdir -p "$$HOME/data/mariadb"; \
	fi

# Add 127.0.0.1 chdonnat.42.fr to /etc/hosts if missing
setup_hosts:
	@echo "🔍 Checking /etc/hosts entry..."
	@if ! grep -q "127.0.0.1 chdonnat.42.fr" /etc/hosts; then \
		echo "📝 Adding '127.0.0.1 chdonnat.42.fr' to /etc/hosts (sudo required)"; \
		echo "127.0.0.1 chdonnat.42.fr" | sudo tee -a /etc/hosts > /dev/null; \
	else \
		echo "✅ /etc/hosts already contains the entry"; \
	fi

# Run docker compose up using the config in srcs/
up:
	@echo "🐳 Starting docker compose using $(COMPOSE_PATH)..."
	docker compose --env-file $(ENV_PATH) -f $(COMPOSE_PATH) up -d

# Stop containers without deleting volumes
down:
	@echo "🛑 Stopping containers and removing images (data preserved)..."
	docker compose -f srcs/docker-compose.yml down

# Full reset: stop, remove containers & volumes, delete local data
reset:
	@echo "⚠️  WARNING: This will stop containers, remove volumes, and delete local data in ~/data"
	@read -p "Are you sure you want to continue? [y/N] " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "❌ Reset aborted."; \
		exit 1; \
	fi
	@echo "🔥 Proceeding with full reset..."
	docker compose -f srcs/docker-compose.yml down -v
	@echo "🗑️  Deleting local data directories..."
	sudo rm -rf $$HOME/data/wordpress $$HOME/data/mariadb

