import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jornadafacil/core/models/auth_session.dart';

/// Persiste a sessão autenticada (token + usuário) no armazenamento
/// seguro do aparelho (Keystore/Keychain). Falhas de armazenamento nunca
/// derrubam o app: a pior consequência é pedir login de novo.
class TokenStorage {
  static const _sessionKey = 'auth_session';

  final FlutterSecureStorage _storage;

  const TokenStorage([this._storage = const FlutterSecureStorage()]);

  Future<void> saveSession(AuthSession session) async {
    try {
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
      );
    } catch (e) {
      debugPrint('Falha ao persistir sessão: $e');
    }
  }

  Future<AuthSession?> readSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null) return null;

      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Storage indisponível ou payload antigo/corrompido: força novo login.
      debugPrint('Sessão armazenada inválida, descartando: $e');
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      debugPrint('Falha ao limpar sessão: $e');
    }
  }
}
