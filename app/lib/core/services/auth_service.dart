import 'dart:async';

import 'package:jornadafacil/core/models/auth_session.dart';
import 'package:jornadafacil/core/models/user_model.dart';
import 'package:jornadafacil/core/network/api_client.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/current_user_service.dart';
import 'package:jornadafacil/core/services/push_notification_service.dart';
import 'package:jornadafacil/core/services/token_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final ApiClient _api = ApiClient();
  final TokenStorage _storage = const TokenStorage();
  final CurrentUserService _userService = CurrentUserService();

  AuthSession? _session;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null && !_session!.isExpired;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final json = await _api.post(
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
    ) as Map<String, dynamic>;

    final session = AuthSession.fromJson(json);
    await _storage.saveSession(session);
    _activate(session);
    return session;
  }

  Future<bool> restoreSession() async {
    final session = await _storage.readSession();
    if (session == null) return false;

    if (session.isExpired) {
      await _storage.clear();
      return false;
    }

    // Ativa já com a cópia persistida: garante uso offline e habilita o
    // Bearer token para a chamada de re-hidratação abaixo.
    _activate(session);
    return _refreshUser(session);
  }

  /// Re-hidrata o usuário via GET /auth/me para pegar permissões e
  /// tracks_journey atualizados no servidor. Retorna se a sessão continua
  /// válida: falha de rede mantém a sessão persistida (`true`); token
  /// rejeitado (401) encerra a sessão (`false`).
  Future<bool> _refreshUser(AuthSession session) async {
    try {
      final json = await _api.get('/api/v1/auth/me') as Map<String, dynamic>;
      final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
      final refreshed = AuthSession(
        token: session.token,
        expiresAt: session.expiresAt,
        user: user,
      );
      _session = refreshed;
      _userService.setUser(user);
      await _storage.saveSession(refreshed);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        return false;
      }
      // Demais falhas (rede/servidor indisponível): segue com a sessão local.
      return true;
    }
  }

  Future<void> logout() async {
    _session = null;
    _api.authToken = null;
    _userService.clear();
    await _storage.clear();
  }

  void _activate(AuthSession session) {
    _session = session;
    _api.authToken = session.token;
    _userService.setUser(session.user);
    unawaited(PushNotificationService().syncTokenWithApi());
  }
}
