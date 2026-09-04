.PHONY: setup up down logs trust-ca

setup:
	@echo "Configuring global infrastructure..."
	@docker network inspect global-transit-network >/dev/null 2>&1 || \
	docker network create --subnet 10.99.99.0/24 global-transit-network
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
	@echo "Instalando certificado en el sistema (requiere contraseña sudo)..."
	@sudo cp ./certs/root_ca.crt /usr/local/share/ca-certificates/step-ca.crt
	@sudo update-ca-certificates
	@echo "Instalando certificado en navegadores (Chrome/Edge/Brave)..."
	@if command -v certutil >/dev/null 2>&1; then \
		certutil -d sql:$$HOME/.pki/nssdb -D -n "step-ca" 2>/dev/null || true; \
		certutil -d sql:$$HOME/.pki/nssdb -A -t "C,," -n "step-ca" -i ./certs/root_ca.crt 2>/dev/null || true; \
		echo "✅ Certificado instalado en navegadores."; \
	else \
		echo "⚠️ No se encontró 'certutil'. Para que Chrome confíe en el certificado automáticamente en Linux, instala 'libnss3-tools'."; \
	fi

up:
	@echo "Iniciando step-ca..."
	docker compose up -d step-ca
	@echo "Esperando a que step-ca inicie..."
	@sleep 5
	@$(MAKE) trust-ca
	@echo "Iniciando el resto de los servicios..."
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f