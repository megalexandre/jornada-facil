# AGENTS.md — API Jornada Fácil

Backend Rails da **Jornada Fácil** (fjtelecom): API JSON que registra jornadas de
trabalho em campo, com autenticação JWT, autorização RBAC, push (FCM), geolocalização
(PostGIS) e revisão semanal. Consumida por um app Flutter (fora deste diretório).

**Stack:** Rails 8.1 · Ruby 3.2.0 · Postgres + PostGIS · RSpec.

## ⚠️ Guardrails (leia antes de rodar qualquer coisa)

- **DEV APONTA PRA PRODUÇÃO.** O projeto usa `dotenv-rails`: `rails s`,
  `rails console` e `rails db:*` crus carregam `.env`/`.env.local` e conectam no
  **Postgres de PRODUÇÃO** (`85.31.230.47:5440`, banco `api_production`). Nunca rode
  migração, seed ou console "de dev" sem confirmar o banco-alvo. Para produção
  deliberada use `bin/remote` + `.env.remote`.
- **Testes RSpec usam o banco `test` local — seguros.** É o modo padrão de validar
  mudanças. Prefira testes a subir um console contra o banco.
- Nunca commite `.env`, `.env.local`, `.env.remote` nem credenciais FCM.
- Timezone da aplicação é `America/Sao_Paulo` — considere isso em specs com datas.

## Arquitetura

Fluxo de uma request: **controller (fino) → contract → service → serializer**, com
erros de domínio traduzidos centralmente. Controllers ficam na happy path; validação,
regra de negócio e forma da resposta moram em camadas dedicadas.

- **Controllers** (`app/controllers/api/v1/`): só orquestram. Autenticam com
  `authenticate_user!` e autorizam **inline** com `verify "recurso:ação"`
  (ex.: `verify "journey:create"`). Não coloque regra de negócio aqui.
- **Concerns** (`app/controllers/concerns/`): `Authenticatable` (JWT → `current_user`),
  `Authorizable` (`verify`, levanta `Auth::Forbidden` → 403), `ErrorHandler`
  (`rescue_from ApplicationError` → `{ "error" => msg }` + status). Todos incluídos no
  `ApplicationController` (que herda de `ActionController::API`).
- **Contracts** (`app/contracts/`): validam a *forma* do input na borda via ActiveModel
  (`from_params`/`validate!`). Input inválido levanta `InvalidParameters` (422). Herdam
  de `ApplicationContract` e declaram entradas com `attribute` — isso também faz o
  strong-params, então o controller não repete a lista de chaves.
- **Services** (`app/services/`): regra de negócio, interface `.call(...)` (com um
  `self.call` que instancia e chama). Levantam erros de domínio de `app/errors/` em vez
  de renderizar. Ex.: `Journeys::OpenJourneyService`, `Rbac::CheckPermissionService`,
  `Notifications::SendPushService`.
- **Serializers** (`app/serializers/`): forma explícita do JSON de saída (um por
  recurso/visão).
- **Errors** (`app/errors/`): hierarquia sob `ApplicationError` (que carrega `status`).
  `InvalidParameters` (422), `RecordNotFound` (404), `Auth::Forbidden` (403), etc.
- **Models** (`app/models/`): Postgres + PostGIS (localização como `st_point`, ex.
  `started_location`/`finished_location` nas journeys). Também `jobs/`, `mailers/`,
  `serializers/`, `lib/` (ex. `JsonWebToken`).

**Autorização é por par `recurso:ação`** (RBAC: users → roles → permissions). Ao criar
um endpoint novo, defina a permissão e chame `verify` no início da action.

## Testes

RSpec em `spec/`, com `factory_bot`, `faker`, `shoulda-matchers` (config em
`spec/rails_helper.rb`). Layout por camada:

- `spec/requests/` — **testes de integração** (request specs, `type: :request`): sobem
  rota → controller → concerns → service → banco. É o padrão para cobrir endpoints.
- `spec/services/`, `spec/models/`, `spec/contracts/` — unitários por camada.
- `spec/factories/` — factories (`:user`, `:journey` [trait `:finished`], `:role`,
  `:permission`, `:device_token`, `:weekly_review`).

Ao escrever request specs, **use a skill do Claude `rails-integration-test`**
(`.claude/skills/`) — ela tem as convenções exatas do repo (auth JWT via
`JsonWebToken`, helper `grant(resource, action)`, os cenários canônicos
happy/422/403/401, asserções de JSON e de estado no banco).

## Comandos

```bash
bin/setup                                   # dependências e preparo inicial
bundle exec rspec                           # suíte completa (banco test local)
bundle exec rspec spec/requests/.../x_spec.rb[:LINHA]   # um arquivo/linha
bundle exec rubocop                         # lint (regras em .rubocop.yml)
bin/brakeman && bin/bundler-audit           # análise de segurança / CVEs
bin/ci                                      # tudo que a CI roda
bin/remote                                  # rails apontado pra produção (cuidado)
```

Rode `bundle exec rspec` (e `rubocop`) antes de considerar uma mudança pronta.

## Convenções

- Código, nomes de teste e comentários em **inglês**; conversas do time em PT-BR.
- Status HTTP por símbolo; note o Rails 8: **`:unprocessable_content`** (não
  `:unprocessable_entity`).
- Novo endpoint = controller fino + contract + service + serializer + `verify` da
  permissão + request spec cobrindo os 4 cenários.
- O contrato da API é compartilhado com o app Flutter (JWT `Bearer`, permissões
  `resource:action`). Mudou payload ou permissão, alinhe o app.
- Não adicione gem/dependência sem necessidade clara.

## Deploy

Imagem Docker publicada via `../infra/build-and-push.sh`; deploy no **Coolify** contra
o Postgres externo de produção. Config sensível chega por env no container (não em
build-time) — variável faltando no runtime aparece como erro de auth no banco.
