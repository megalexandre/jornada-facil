# Atalhos do dev container do monorepo. Rode `make` para ver a ajuda.
.DEFAULT_GOAL := help
.PHONY: help up rails down logs seed bdd bdd-wip shell console ps

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

bdd: ## roda a suíte Cucumber da raiz (perfil default)
	docker compose --profile bdd run --rm tests

bdd-wip: ## roda só os cenários @wip (esqueletos)
	docker compose --profile bdd run --rm tests \
	  bash -lc "(bundle check || bundle install) && bundle exec cucumber -p wip"

shell: ## abre um shell no container da API
	docker compose exec api bash

console: ## abre o rails console na API
	docker compose exec api bin/rails console
