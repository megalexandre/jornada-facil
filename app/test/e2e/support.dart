import 'dart:io';

import 'package:jornadafacil/core/models/auth_session.dart';
import 'package:jornadafacil/core/network/api_client.dart';
import 'package:jornadafacil/core/services/journey_service.dart';

/// Habilita HTTP real e aponta a API. Chame em `setUpAll`.
///
/// O binding de teste instala um HttpClient falso (retorna 400); zerar o
/// override devolve o cliente real. Como usamos `test()` puro (não
/// `testWidgets`), não há FakeAsync — a I/O real resolve normalmente.
/// Sobrescreva a URL com `--dart-define=API_BASE_URL` (ex.: http://api:3000).
void useRealApi() {
  HttpOverrides.global = null;
  ApiClient().baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}

/// Loga pela `ApiClient` real, parseia com `AuthSession.fromJson` (modelo do
/// app) e ativa o Bearer token. Devolve a sessão.
Future<AuthSession> loginAs(String username, String password) async {
  final json = await ApiClient().post(
    '/api/v1/auth/login',
    body: {'username': username, 'password': password},
  ) as Map<String, dynamic>;
  final session = AuthSession.fromJson(json);
  ApiClient().authToken = session.token;
  return session;
}

/// Idempotência: só uma jornada pode ficar aberta por vez; finaliza qualquer
/// aberta para o teste poder abrir uma nova e ser re-executável.
Future<void> ensureNoOpenJourney() async {
  final open = await JourneyService().findOpenJourney();
  if (open != null) {
    await JourneyService().finishJourney(
      open.id,
      latitude: -23.5,
      longitude: -46.6,
    );
  }
}
