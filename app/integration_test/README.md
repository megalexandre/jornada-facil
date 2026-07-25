# Testes de UI — dois grupos

Estes são testes que **dirigem a UI real** do app, separados por plataforma porque
cada uma exige uma ferramenta diferente. São distintos dos testes de `test/e2e/` (que
exercitam só a camada de serviço, sem renderizar) e dos widget tests de `test/`.

```
integration_test/
├── android/   # grupo Patrol  (UI + automação NATIVA: permissões, notificações…)
└── web/       # grupo integration_test + flutter drive (Chrome real)
test_driver/
└── integration_test.dart   # driver da suíte web
```

A separação é por **subpasta + alvo explícito** no comando — um grupo nunca executa o
outro. As APIs são incompatíveis: Patrol usa `patrolTest`/`$`; a web usa `testWidgets`
com `IntegrationTestWidgetsFlutterBinding`.

## Grupo Android — Patrol

Único que controla a UI nativa. O exemplo (`android/admin_dashboard_test.dart`) loga
como admin, **concede a permissão de localização nativa** que o `MainScaffold` dispara,
e valida que cai no `DashboardPage`.

Requer: **emulador/device** + **API no ar e semeada** + `patrol_cli`.

```bash
dart pub global activate patrol_cli            # uma vez
make patrol                                    # ou:
cd app && patrol test -t integration_test/android --dart-define-from-file=config/dev.json
```

`config/dev.json` já aponta a API para `http://10.0.2.2:3000` (loopback do host visto do
emulador) e usa `APP_ENV=development`, que pula o gate de biometria.

> **Não roda em web.** A automação nativa do Patrol é só Android/iOS.

## Grupo Web — integration_test + flutter drive

Roda em **Chrome real**. O exemplo (`web/login_validation_test.dart`) reusa o fluxo do
widget test de login: apertar Entrar vazio mostra as mensagens de validação. Pumpa
`LoginScreen` direto → **sem backend**.

Requer: **Chrome + chromedriver** (já no devcontainer via `api/Dockerfile.dev`).

```bash
make e2e-web                                   # ou, manualmente:
chromedriver --port=4444 &
cd app && flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/web/login_validation_test.dart \
  -d web-server --browser-name=chrome \
  --dart-define-from-file=config/dev.json
```

## CI

- `.github/workflows/web-e2e.yml` — grupo web em Chrome headless (leve, sem backend).
- `.github/workflows/android-e2e.yml` — grupo Patrol num emulador, com Postgres+PostGIS
  + Rails semeado (o job pesado).
