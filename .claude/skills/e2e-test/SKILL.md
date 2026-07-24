---
name: e2e-test
description: >-
  Cria, ajusta e roda os testes E2E do app (`flutter_test` puro) que passam pela
  camada de serviços REAL do Flutter contra Rails+DB (Flutter → Rails → DB), em
  `app/test/e2e/`. Use quando o pedido envolver escrever/atualizar/rodar um teste
  de fluxo de ponta a ponta (login, jornada, revisão) exercitando os
  serviços/modelos do app contra a API real. NÃO use para request specs RSpec da
  API (skill rails-integration-test) nem para widget tests puros de um componente.
---

# Testes E2E do app (Flutter → Rails → DB)

A suíte E2E vive em **`app/test/e2e/`**. São testes `flutter_test` **normais**
(`group`/`test`, não `testWidgets`) cujos passos chamam os **serviços reais do
app** (`ApiClient`, `JourneyService`, `AuthService`, modelos, `rbac.can`) contra um
**Rails+DB reais**. Diferente de um teste de API em Ruby, isto exercita o código do
app — pega divergência de contrato app↔API (parsing de modelo, mapeamento de erro,
RBAC).

```
app/test/e2e/
├── support.dart            # useRealApi(), loginAs(), ensureNoOpenJourney()
├── autenticacao_test.dart  # login → sessão + permissões
└── jornada_test.dart       # abrir / admin não registra / abrir+finalizar
```

## Fluxo ao escrever um teste novo

1. **Ache o endpoint** em `api/config/routes.rb` e leia a action (permissão, params,
   sucesso, erros). Ex.: `POST /api/v1/journeys` → `journey:create`.
2. **Escreva o teste** num `*_test.dart` de `app/test/e2e/`, reusando `support.dart`
   (login, limpeza) e chamando o serviço do app.
3. **Rode e itere** (ver "Rodando"). Rode **2×** — a suíte não limpa o banco; o teste
   tem que ser idempotente.

## Esqueleto

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/services/journey_service.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  test('funcionário inicia a jornada', () async {
    await loginAs('usuario', 'Senha123');
    await ensureNoOpenJourney();                 // idempotência
    final journey = await JourneyService().openJourney(latitude: -23.5, longitude: -46.6);
    expect(journey.isOpen, isTrue);
  });
}
```

Helpers em `support.dart`:
- `useRealApi()` — chame no `setUpAll`. Zera `HttpOverrides.global` e aponta `baseUrl`.
- `loginAs(username, password)` — loga via `ApiClient` + `AuthSession.fromJson`,
  ativa o Bearer token, devolve a sessão.
- `ensureNoOpenJourney()` — finaliza jornada aberta (só uma por vez na API).

## Convenções obrigatórias (e as armadilhas que elas evitam)

- **`test()`, não `testWidgets`.** `testWidgets` roda em FakeAsync onde HTTP real
  **nunca resolve** (trava). Com `test()` puro a I/O real funciona.
- **`useRealApi()` no `setUpAll`.** O binding de teste instala um HttpClient falso
  (retorna 400); `useRealApi` faz `HttpOverrides.global = null` para liberar sockets
  reais e seta `ApiClient().baseUrl` (default `http://localhost:3000`, override por
  `--dart-define=API_BASE_URL`).
- **Nunca construa `ApiClient()`/`JourneyService()` no corpo do `main`** (nem em
  `final` de topo) — só **dentro** dos testes. Fora de um teste, o mock HTTP do
  binding lança `Bad state: There is no current invoker`.
- **Login sem plugins:** use `loginAs()` (ApiClient + modelo), não `AuthService.login`
  — este arrasta `flutter_secure_storage` + FCM.
- **Idempotência:** só uma jornada aberta por vez (`AlreadyOpen`). Comece com
  `ensureNoOpenJourney()`. Sempre valide rodando 2×.
- **Asserções** sobre o resultado dos serviços: `JourneyModel.isOpen/finishedAt`,
  `AuthSession.user.can(...)`, ou `throwsA(isA<ApiException>().having((e) => e.message, ...))`.

## Gotchas do repo

- **Credenciais do seed:** `admin` / `usuario`, senha **`Senha123`**. Login por
  `username`. `admin` (não bate ponto) → abrir jornada lança `ApiException`
  "Usuário não registra jornada".
- **Ambiente:** exige Rails+DB no ar e semeado (`make rails` + `make seed`). Não roda
  sozinho. A API **não** aplica geofence (só `tracks_journey`) — não precisa mock de GPS.
- **`environment.sdk`** no pubspec é `>=3.12.1 <4.0.0` (casa com o Dart 3.12.1 local);
  não volte para `^3.12.2` senão o `flutter pub get` quebra.

## Rodando

```bash
make e2e                                        # via Makefile (dentro do container da API)
cd app && flutter test --no-pub test/e2e/       # a suíte toda
cd app && flutter test --no-pub test/e2e/jornada_test.dart   # um arquivo
```

No VS Code, a extensão Dart/Flutter põe botões **Run | Debug** em cima de cada
`test(...)`. Itere até **`All tests passed!`**; rode 2× pra provar idempotência.
Se mexeu no `support.dart`, rode a suíte inteira antes de dar por pronto.
