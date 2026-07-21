# AGENTS.md — Jornada Fácil

**Monorepo** da Jornada Fácil (fjtelecom): registro de jornada de trabalho em campo,
com autenticação JWT, autorização RBAC, push (FCM), geolocalização (PostGIS) e revisão
semanal. 
Duas frentes versionadas juntas 
**API Rails** (`api/`)  
**app Flutter**(`app/`) 

mais uma suíte BDD de ponta a ponta na raiz (`features/`).

## Stack

| Camada        | Tecnologia                                                          |
| ------------- | -------------------------------------------------------------------- |
| **API**       | **Rails 8.1** · Ruby 3.4.10 · **Postgres 16 + PostGIS 3.4** (`activerecord-postgis-adapter`) · Puma · RSpec |
| **App**       | **Flutter** (channel stable) · Dart, `sdk: ^3.12.2` · `http` (sem dio) · `flutter_secure_storage` |
| **BDD raiz**  | Cucumber (Ruby) — caixa-preta sobre a API via HTTP (`features/`)     |

Autenticação e RBAC são um **contrato único** entre API e app 
(JWT `Bearer`, permissões `resource:action`) - mudou payload ou permissão de um lado, alinhe o outro.

## Estrutura do monorepo

```
jornada/
├── api/                 # API Rails (JSON) — Postgres+PostGIS
├── app/                 # App Flutter (mobile Android + web)
├── features/            # Suíte BDD Cucumber (raiz), roda contra a api/ via HTTP
├── infra/                # Infra local avulsa (Postgres+PostGIS standalone, fora do devcontainer)
├── .devcontainer/        # Devcontainer único do monorepo (ver abaixo)
├── docker-compose.yml    # db + api (+ tests, profile "bdd")
├── Makefile              # atalhos (make up/down/logs/seed/bdd/shell/console)
└── .github/workflows/    # CI só do app (Build APK / Build Web); API sem CI
```

Cada subprojeto tem seu próprio `README.md` com detalhes pontuais; 
este arquivo é a referência para o monorepo como um todo.

## Devcontainer

Um único devcontainer para o monorepo, definido em `.devcontainer/devcontainer.json`
sobre o `docker-compose.yml` da raiz:

- **`"service": "api"`** é o único ao qual o VS Code se anexa (`runServices:
  ["db", "api"]`). Por isso a imagem do serviço `api` (`api/Dockerfile.dev`) tem
  **Ruby 3.4.10 E o SDK do Flutter** instalados juntos: tanto as extensões do
  editor (Ruby LSP, Dart/Flutter) quanto o próprio app rodam onde o VS Code
  anexou, não em containers irmãos.
- **Rails e Flutter são iniciados por você, não automaticamente.** O `db` sobe
  sozinho; o container `api` só prepara o banco (migrate + seed) e fica vivo
  (`sleep infinity`) — o servidor sobe pela task **"Rails: server"**
  (`.vscode/tasks.json`) ou `make rails`, com logs num terminal próprio.
- **O app Flutter web roda no próprio devcontainer, via F5** (config
  "Flutter Web (dev)" em `.vscode/launch.json`: `flutter run -d web-server` na
  8080, com hot reload ao salvar, DevTools e inspector pela extensão), ou pela
  task **"Flutter: web"** (mesmo comando, sem o debugger). Não há serviço `web`
  no compose — o `flutter run` dele ficava inalcançável para hot reload, preso
  num container irmão. Fallback por terminal: `cd app && flutter run -d
  web-server --web-port 8080 --dart-define-from-file=config/dev.json`.
- Portas encaminhadas: `3000` (API Rails), `8080` (Flutter web), `5432` (Postgres).
- `postCreateCommand`: `bundle install` (em `api/` e na raiz, para a suíte BDD) +
  `flutter pub get` (em `app/`).
- Volumes nomeados isolam gems (`bundle`) e cache de pacotes Flutter (`pub_cache`)
  do host.

- Gotcha conhecido: o Flutter é instalado em `/opt/flutter` (fora do PATH padrão do
  Debian); um script em `/etc/profile.d/flutter-path.sh` garante que ele apareça
  mesmo quando o VS Code sonda o ambiente com shell de login.

Atalhos via `Makefile` (rode `make` sem argumento para a lista completa):

```bash
make up        # sobe Postgres + o container da API (Rails/Flutter iniciam no editor)
make rails     # inicia o servidor Rails na API (não sobe sozinho)
make down      # derruba o stack (mantém volumes)
make logs      # segue logs da api
make shell     # shell no container da api
make console   # rails console na api
make seed      # rails db:seed
make bdd       # suíte Cucumber da raiz (perfil default, ignora @wip)
make bdd-wip   # só os cenários @wip
```

## ⚠️ Guardrails (leia antes de rodar qualquer coisa)

- **Testes RSpec usam o banco `test` local — sempre seguros.** É o modo padrão de
  validar mudanças na API.
- Nunca commite `.env`, `.env.local`, `.env.remote` nem credenciais FCM/Coolify.
- Timezone da aplicação é `America/Sao_Paulo` — considere isso em specs com datas.

## API (`api/`) — Rails + PostGIS

Fluxo de uma request: **controller (fino) → contract → service → serializer**, com
erros de domínio traduzidos centralmente.

- **Controllers** (`app/controllers/api/v1/`): só orquestram — autenticam com
  `authenticate_user!` e autorizam **inline** com `verify "recurso:ação"`
  (ex.: `verify "journey:create"`). Sem regra de negócio aqui.
- **Concerns** (`app/controllers/concerns/`): `Authenticatable` (JWT → `current_user`),
  `Authorizable` (`verify` → levanta `Auth::Forbidden`/403), `ErrorHandler`
  (`rescue_from ApplicationError` → `{ "error" => msg }` + status).
- **Contracts** (`app/contracts/`): validam a *forma* do input na borda (ActiveModel,
  `from_params`/`validate!`); inválido levanta `InvalidParameters` (422).
- **Services** (`app/services/`): regra de negócio, interface `.call(...)`. Levantam
  erros de domínio de `app/errors/`. Ex.: `Journeys::OpenJourneyService`,
  `Rbac::CheckPermissionService`, `Notifications::SendPushService`.
- **Serializers** (`app/serializers/`): forma explícita do JSON de saída.
- **Models** (`app/models/`): Postgres + PostGIS — localização como `st_point`
  (`started_location`/`finished_location` nas journeys).

Autorização é por par **`recurso:ação`** (RBAC: users → roles → permissions). Endpoint
novo = definir a permissão e chamar `verify` no início da action.

**Testes:** RSpec em `spec/` (`factory_bot`, `faker`, `shoulda-matchers`). Layout por
camada: `spec/requests/` (integração — padrão para cobrir endpoints), `spec/services/`,
`spec/models/`, `spec/contracts/`. Ao escrever request specs use a skill
`rails-integration-test` (convenções de auth JWT, helper `grant(resource, action)`,
cenários happy/422/403/401).

```bash
cd api
bin/setup                                                # dependências e preparo inicial
bundle exec rspec                                        # suíte completa (banco test local)
bundle exec rspec spec/requests/.../x_spec.rb[:LINHA]     # um arquivo/linha
bundle exec rubocop                                       # lint
bin/brakeman && bin/bundler-audit                         # segurança / CVEs
bin/ci                                                    # tudo que a CI roda
```

## App (`app/`) — Flutter

```
lib/
├── app/            # bootstrap / MaterialApp
├── core/           # config, constants, models, network (api_client), providers, services, theme
├── features/       # admin, auth, history, profile, register — cada um com presentation/
└── shared/         # widgets (buttons, cards, layouts, maps) e utils reutilizáveis
```

- `core/network/api_client.dart`: cliente HTTP singleton, Bearer token mutável, erros
  `{error:}` da API viram `ApiException`.
- `core/services/auth_service.dart`: login/restauração de sessão (`GET /auth/me` na
  restauração)/logout.
- `core/models/rbac.dart`: `can(x:y)` local espelha o RBAC da API (wildcard `"*"` /
  `"resource:*"` / exato).
- Ambientes via `--dart-define-from-file` (`config/dev.json`, `lan.json`, `prod.json`).
- Mapa é offline (flutter_map + tiles empacotados em `assets/maps/`) — sem chamada
  externa de tiles.

** Versão do Flutter:** o SDK instalado (`~/flutter`, canal stable) é **3.44.1 /
Dart 3.12.1**, um patch abaixo do `sdk: ^3.12.2` do `pubspec.yaml` — `flutter
analyze`/`flutter test` cru falham no `pub get` ("version solving failed"). Contorne
sem tocar no SDK reaproveitando o `.dart_tool/package_config.json` já resolvido:

```bash
cd app
dart analyze <arquivos>       # em vez de `flutter analyze`
flutter test --no-pub         # em vez de `flutter test`
flutter build apk --debug --dart-define-from-file=config/prod.json
```

CI (`.github/workflows/android-build.yml`, `web-build.yml`) usa Flutter `stable` via
`subosito/flutter-action`, sem esse problema de patch local.

## Convenções gerais

- Código, nomes de teste e comentários em **inglês**;
- Contrato API↔app é único e deliberado: mudou payload, permissão ou shape de erro,
  alinhe os dois lados na mesma sessão de trabalho.
- Não adicione gem/pacote sem necessidade clara.
- Rode a suíte relevante (`bundle exec rspec` / `flutter test --no-pub`) antes de
  considerar uma mudança pronta.

