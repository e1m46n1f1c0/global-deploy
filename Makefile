.PHONY: setup up down logs trust-ca

setup:
	@echo "Configuring global infrastructure..."
	@docker network inspect global-transit-network >/dev/null 2>&1 || \
	docker network create global-transit-network
	@echo "Network 'global-transit-network' is ready to operate."
	@[ -f .env ] && echo "The .env file already exists." || cp .env.example .env
	@grep -q "INFISICAL_ENCRYPTION_KEY=" .env || echo "INFISICAL_ENCRYPTION_KEY=$$(openssl rand -hex 16)" >> .env
	@grep -q "INFISICAL_AUTH_SECRET=" .env || echo "INFISICAL_AUTH_SECRET=$$(openssl rand -base64 32)" >> .env
	@grep -q "INFISICAL_DB_PASSWORD=" .env || echo "INFISICAL_DB_PASSWORD=$$(openssl rand -hex 16)" >> .env
	@echo "Infisical secrets configured in .env."
	@mkdir -p certs
	@touch dynamic-conf.yml

trust-ca:
	@echo "Exportando la Autoridad Certificadora (Root CA) de step-ca a ./certs/root_ca.crt..."
	@mkdir -p certs
	@docker cp global-step-ca:/home/step/certs/root_ca.crt ./certs/root_ca.crt 2>/dev/null || true
	@echo "✅ Certificado raíz exportado en ./certs/root_ca.crt"
	@echo "Para confiar en la CA en Ubuntu/Debian:"
	@echo "  sudo cp ./certs/root_ca.crt /usr/local/share/ca-certificates/step-ca.crt && sudo update-ca-certificates"

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f