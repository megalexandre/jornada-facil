# Jornada Fácil — monorepo de desenvolvimento

Ambiente único que sobe **Postgres + API Rails + Flutter web** em containers e traz
uma suíte **BDD (Cucumber)** na raiz para escrever `.feature` dirigindo a API real.

```
jornada/
├── docker-compose.yml     # db + api + web + tests(bdd)
├── .devcontainer/         # dev container do VS Code (anexa ao serviço api)
├── Makefile               # atalhos (make up / make bdd / make logs ...)
├── Gemfile, cucumber.yml  # suíte BDD (Ruby)
├── features/              # .feature (pt-BR) + steps + support
├── api/                   # repositório da API Rails (git próprio)
└── app/                   # repositório do app Flutter (git próprio)
```

## Subir o stack

```bash
make up          # docker compose up -d db api web
```

- **API**: http://localhost:3000 (health em `/up`)
- **Flutter web**: http://localhost:8080  (primeiro build leva alguns minutos)
- **Postgres**: localhost:5432 (`postgres`/`postgres`, banco `api_development`)

Login de desenvolvimento (semeado pela API): **`admin` / `Password123!`**.

> **Isolamento do banco.** O serviço `api` fixa `DATABASE_HOST=db` (e demais
> `DATABASE_*`) no `docker-compose.yml`. Como o `dotenv-rails` não sobrescreve ENV
> já definida, isso **vence o `api/.env`** e garante que o dev container jamais
> fale com o banco de produção. Confira com:
> ```bash
> docker compose exec api bin/rails runner 'puts ActiveRecord::Base.connection_db_config.host'
> # => db
> ```

## Rodar os testes BDD

```bash
make bdd         # perfil default: cenários prontos, em modo --strict
make bdd-wip     # só os esqueletos @wip (pending em amarelo)
```

A suíte roda no serviço `tests` (Ruby), caixa-preta sobre a API em `http://api:3000`.
Fora do compose, aponte com `API_BASE_URL` (default `http://localhost:3000`).

## Dev container (VS Code)

`Reopen in Container` → o VS Code anexa ao serviço `api` (Ruby 3.4.10) com a raiz
inteira montada em `/workspaces/jornada`. No terminal integrado:

```bash
cd api && bundle exec rspec          # specs da API
bundle exec cucumber                 # suíte BDD da raiz (API_BASE_URL=http://localhost:3000)
```

## Escrevendo novos cenários

1. Crie/edite um `.feature` em [features/](features/) (Gherkin em pt-BR, `# language: pt`).
2. Implemente os steps em [features/step_definitions/](features/step_definitions/)
   usando o helper `api` (cliente HTTP) e `login_as` do World
   ([features/support/env.rb](features/support/env.rb)).
3. `make bdd`.

Cenários que exigem mais dados (funcionário com `tracks_journey=true`, semana
registrada) estão marcados `@wip` — pulados no default. Semeie os dados em
`api/db/seeds.rb` e remova a tag para ligá-los.

## Novo monorepo (opcional)

Para versionar só a orquestração (sem tocar nos repos `api/` e `app/`):

```bash
git init            # o .gitignore já exclui api/ e app/
git add .
git commit -m "chore: dev container do monorepo + esqueleto BDD"
```
