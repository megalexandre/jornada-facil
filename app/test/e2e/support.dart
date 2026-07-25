import 'dart:io';

import 'package:jornadafacil/core/models/auth_session.dart';
import 'package:jornadafacil/core/network/api_client.dart';
import 'package:jornadafacil/core/services/journey_service.dart';

void useRealApi() {
  HttpOverrides.global = null;
  ApiClient().baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}

Future<AuthSession> loginAs({
  required String username, String? password ,
}) async {
  final json = await ApiClient().post(
    '/api/v1/auth/login', body: {'username': username, 'password': password},
  ) as Map<String, dynamic>;
  final session = AuthSession.fromJson(json);
  ApiClient().authToken = session.token;
  return session;
}

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
