---
name: rails-integration-test
description: >-
  Cria, ajusta e roda testes de integração (request specs RSpec) da API Rails
  deste projeto, seguindo as convenções do repo. Use quando o pedido envolver
  escrever/atualizar/rodar specs de um endpoint, controller, rota ou fluxo HTTP
  (spec/requests/...), cobrir os cenários de autenticação, RBAC e validação de
  um endpoint, ou "escreve/faz os testes desse controller". NÃO use para specs
  puros de model, service ou contract (esses seguem outros padrões).
---

# Testes de integração (request specs) — API jornada

Nesta API, "teste de integração" = **request spec** em `spec/requests/`, com
`type: :request`. Sobe a stack HTTP inteira (rota → controller → concerns de
auth/RBAC → service → model → banco) e faz assert sobre status, JSON e estado
persistido. É o padrão do repo — não use `type: :controller` nem `test/`.

## Fluxo ao escrever um spec novo

1. **Ache a rota e o controller.** Confirme verbo + path em `config/routes.rb`
   e leia a action-alvo pra saber: permissão exigida, params aceitos, forma da
   resposta de sucesso e erros de validação possíveis.
2. **Crie o arquivo no caminho que espelha a rota**, um por action:
   `spec/requests/api/v1/<recurso>/<ação>_spec.rb`
   (ex.: `POST /api/v1/journeys` → `spec/requests/api/v1/journeys/create_spec.rb`).
3. **Preencha os 4 cenários canônicos** (abaixo). Todo endpoint autenticado com
   RBAC cobre: happy path → 422 validação → 403 sem permissão → 401 sem token.
4. **Rode só o arquivo** e itere até verde (ver "Rodando").

## Esqueleto canônico

Base pra um endpoint autenticado + protegido por permissão. Ajuste recurso,
ação, params e a forma do JSON à action real.

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Journeys Create", type: :request do
  describe "POST /api/v1/journeys" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the journey:create permission" do
      before { grant("journey", "create") }

      it "opens a journey and returns 201" do
        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:created)
        journey = user.journeys.sole
        expect(json_response).to eq(
          "id" => journey.id,
          "started_at" => journey.started_at.iso8601,
          "finished_at" => nil
        )
      end

      it "returns 422 when the payload is invalid" do
        post "/api/v1/journeys",
             params: { latitude: -23.55 }, # longitude faltando de propósito
             headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Longitude can't be blank")
        expect(user.journeys).to be_empty # nada foi persistido
      end
    end

    context "without the journey:create permission" do
      it "returns 403 forbidden" do
        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/journeys"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
```

## Convenções obrigatórias

- **`require "rails_helper"`** no topo; `# frozen_string_literal: true` na 1ª linha.
- **Describe** externo = `"Api::V1::<Recurso> <Ação>"`, `type: :request`. Interno
  = `"VERBO /path/exato"`. Cenários em `context "with/without ..."`.
- **Um arquivo por action.** Não junte create/finish/index no mesmo spec.
- **Textos em inglês** (describe/it/context), como o resto do repo. A prosa que
  você escreve pro usuário pode ser PT; o código do spec é EN.

### Autenticação (JWT)
Token real via `JsonWebToken.encode(user_id: user.id)`, mandado como
`Authorization: Bearer <token>`. Não faça stub do `current_user` — deixe o
concern `Authenticatable` autenticar de verdade. Endpoint sem `headers:` deve
cair no **401** com `{ "error" => "Unauthorized" }`.

### RBAC (permissões)
A autorização é por par `resource:action` (concern `Authorizable`). Use o helper
`grant(resource, action)` pra dar a permissão no `before`. Sem a permissão →
**403** com `{ "error" => "Forbidden" }`. O `grant` cria role+permission via
factory e anexa ao `user`; copie-o pro arquivo (ver nota de DRY no fim).

### Asserções
- **Status por símbolo:** `:created` (201), `:ok` (200), `:unprocessable_content`
  (422, Rails 8 — *não* `:unprocessable_entity`), `:forbidden` (403),
  `:unauthorized` (401). Sempre `have_http_status(...)`.
- **JSON exato** com `json_response` (helper `JSON.parse(response.body)`):
  - Corpo estável e pequeno → `eq(hash_completo)` (pega campos a mais/a menos).
  - Valores dinâmicos (token, timestamps gerados) → `include(...)` +
    matchers: `"token" => be_a(String)`. Cheque as chaves com
    `expect(json_response.keys).to match_array(%w[...])`.
  - Erros sempre no formato `{ "error" => "mensagem" }` (concern `ErrorHandler`);
    afirme a mensagem exata (ela vem do `full_messages` do contract/model).
  - Datas serializam como `.iso8601`.
- **Estado no banco:** confirme o efeito colateral, não só o JSON —
  `user.journeys.sole`, `DeviceToken.count`, `expect(...).to be_empty`. Em erro
  de validação, afirme que **nada** foi persistido.

### Factories
`config.include FactoryBot::Syntax::Methods` já está no `rails_helper` — chame
`create`/`build` direto. Em request spec use **`create`** (precisa estar no
banco). Factories relevantes: `:user`, `:journey` (trait `:finished`), `:role`,
`:permission` (aceitam `resource:`/`action:`), `:device_token`, `:weekly_review`.
Deixe os defaults do Faker preencherem tudo; **sobrescreva só o que o teste
afirma** (ex.: `create(:user, username: "johndoe", password: "Password123!")`).
Precisa de setup novo e recorrente? Adicione um `trait` na factory, não monte à
mão no spec.

## Cobertura mínima por endpoint

- **Happy path** — status de sucesso + JSON exato + efeito no banco.
- **Validação (422)** — para cada regra do contract/model, um `it` com a
  mensagem exata e assert de que nada persistiu. Cubra também params faltando.
- **403** — autenticado, sem a permissão exigida.
- **401** — sem `headers`.
- **Regras da action** — casos específicos (idempotência, "já existe jornada
  aberta", re-vínculo de recurso de outro user, escopo de dados por role etc.).
  Leia a action e o service pra não perder ramo.

## Rodando

```bash
bundle exec rspec spec/requests/api/v1/journeys/create_spec.rb   # só o arquivo
bundle exec rspec spec/requests/api/v1/journeys/create_spec.rb:20 # uma linha
bundle exec rspec spec/requests                                   # toda integração
```
Itere até verde. Rode a suíte inteira (`bundle exec rspec`) antes de dar por
pronto se mexeu em factory/helper compartilhado.

## Nota de DRY (dívida conhecida)

Hoje `def json_response` está copiado em ~14 specs e `def grant` em ~11 — não há
`spec/support/`. **Ao criar specs novos, siga a convenção atual** (helpers no
próprio arquivo) pra manter consistência. Se o usuário pedir pra limpar isso,
extraia pra `spec/support/request_helpers.rb` como um módulo incluído via
`config.include ..., type: :request` e habilite o autoload de
`spec/support/**/*.rb` no `rails_helper` (a linha do glob está lá, comentada).
Não faça esse refactor sem pedirem — é mudança ampla e fora do escopo de "criar
um teste".
