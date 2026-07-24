import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// E2E de autenticação: Flutter (ApiClient + AuthSession + RBAC) → Rails → DB.
/// Requer a API no ar e semeada (make rails + make seed).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  test('login válido retorna sessão com o usuário e as permissões', () async {
    final session = await loginAs('usuario', 'Senha123');

    expect(session.token, isNotEmpty);
    expect(session.isExpired, isFalse);
    expect(session.user.username, 'usuario');
    // RBAC local do app (espelho do RBAC da API).
    expect(session.user.can('journey:create'), isTrue);
  });
}
