import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/auth_session.dart';
import 'package:jornadafacil/core/models/user_model.dart';

void main() {
  group('AuthSession.fromJson', () {
    // Payload real de POST /api/v1/auth/login.
    final loginJson = {
      'token': 'eyJhbGciOiJIUzI1NiJ9.payload.assinatura',
      'expires_at': '2026-07-07T11:24:01Z',
      'user': {
        'id': 'f26cb4d5-13e5-430b-9236-9094e2b94bee',
        'username': 'admin',
        'name': 'Admin',
        'email': 'admin@example.com',
        'tracks_journey': false,
        'permissions': ['*'],
        'imageBase64': null,
      },
    };

    test('desserializa o contrato da API de login', () {
      final session = AuthSession.fromJson(loginJson);

      expect(session.token, startsWith('eyJ'));
      expect(session.expiresAt, DateTime.utc(2026, 7, 7, 11, 24, 1));
      expect(session.user.id, 'f26cb4d5-13e5-430b-9236-9094e2b94bee');
      expect(session.user.username, 'admin');
      expect(session.user.name, 'Admin');
      expect(session.user.email, 'admin@example.com');
      expect(session.user.tracksJourney, isFalse);
      expect(session.user.permissions, ['*']);
      expect(session.user.imageBase64, isNull);
    });

    test('tracks_journey ausente assume true (sessão persistida antiga)', () {
      final user = Map<String, dynamic>.from(loginJson['user'] as Map)
        ..remove('tracks_journey');
      final session = AuthSession.fromJson({...loginJson, 'user': user});

      expect(session.user.tracksJourney, isTrue);
    });

    test('sobrevive a um round-trip toJson/fromJson', () {
      final session = AuthSession.fromJson(loginJson);
      final restored = AuthSession.fromJson(session.toJson());

      expect(restored.token, session.token);
      expect(restored.expiresAt, session.expiresAt);
      expect(restored.user.id, session.user.id);
      expect(restored.user.tracksJourney, session.user.tracksJourney);
      expect(restored.user.permissions, session.user.permissions);
    });

    test('isExpired reflete expires_at', () {
      final valid = AuthSession.fromJson({
        ...loginJson,
        'expires_at':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      });
      final expired = AuthSession.fromJson({
        ...loginJson,
        'expires_at': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      });

      expect(valid.isExpired, isFalse);
      expect(expired.isExpired, isTrue);
    });
  });

  group('UserModel.can', () {
    UserModel userWith(List<String> permissions) => UserModel(
          name: 'Teste',
          email: 'teste@example.com',
          permissions: permissions,
        );

    test('"*" concede qualquer permissão de domínio', () {
      final admin = userWith(['*']);

      expect(admin.can('journey:view'), isTrue);
      expect(admin.can('history:delete'), isTrue);
    });

    test('"resource:*" concede todas as ações do resource', () {
      final user = userWith(['journey:*', 'history:view']);

      expect(user.can('journey:create'), isTrue);
      expect(user.can('journey:delete'), isTrue);
      expect(user.can('history:view'), isTrue);
      expect(user.can('history:delete'), isFalse);
    });

    test('permissão exata funciona sem wildcard', () {
      final user = userWith(['profile:view']);

      expect(user.can('profile:view'), isTrue);
      expect(user.can('profile:update'), isFalse);
    });

    test('tokens admin (users:view/users:*) gateiam a aba de administração', () {
      expect(userWith(['users:view']).can('users:view'), isTrue);
      expect(userWith(['users:*']).can('users:view'), isTrue);
      expect(userWith(['*']).can('users:view'), isTrue);
      expect(userWith(['journey:view']).can('users:view'), isFalse);
    });
  });
}
