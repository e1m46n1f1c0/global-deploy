.PHONY: setup up down logs

setup:
	@echo "Configuring global infrastructure..."
	@docker network inspect global-transit-network >/dev/null 2>&1 || \
	docker network create global-transit-network
	@echo "Network 'global-transit-network' is ready to operate."
	@cp -n .env.example .env || echo "The .env file already exists."

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f