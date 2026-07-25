# Atalhos do dev container do monorepo. Rode `make` para ver a ajuda.
.DEFAULT_GOAL := help
.PHONY: help up rails down logs seed e2e e2e-web patrol shell console ps

help: ## mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## sobe Postgres + o container da API (Rails/Flutter iniciam no editor: task/F5)
	docker compose up -d db api

rails: ## inicia o servidor Rails na API (server não sobe sozinho; ver AGENTS.md)
	docker compose exec api bin/rails server -b 0.0.0.0 -p 3000

down: ## derruba o stack (mantém os volumes)
	docker compose down

logs: ## acompanha os logs da api
	docker compose logs -f api

ps: ## status dos serviços
	docker compose ps

seed: ## roda o seed do Rails na API
	docker compose exec api bin/rails db:seed

e2e: ## roda a suíte E2E do app (Flutter → Rails → DB); requer a API no ar (make rails)
	docker compose exec api bash -lc "cd /workspaces/jornada/app && flutter test --no-pub test/e2e/"

e2e-web: ## grupo WEB dos testes de UI (integration_test + flutter drive em Chrome headless)
	docker compose exec api bash -lc "cd /workspaces/jornada/app && chromedriver --port=4444 & sleep 2 && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/web/login_validation_test.dart -d web-server --browser-name=chrome --web-browser-flag=--headless=new --web-browser-flag=--no-sandbox --dart-define-from-file=config/dev.json"

patrol: ## grupo ANDROID dos testes de UI (Patrol; requer emulador/device + API no ar)
	docker compose exec api bash -lc "cd /workspaces/jornada/app && patrol test -t integration_test/android --dart-define-from-file=config/dev.json"

shell: ## abre um shell no container da API
	docker compose exec api bash

console: ## abre o rails console na API
	docker compose exec api bin/rails console
