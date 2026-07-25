import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/network/api_exception.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  test('login válido retorna sessão com o usuário e as permissões', () async {
    final session = await loginAs(username: 'usuario', password: 'Senha123');

    expect(session.token, isNotEmpty);
    expect(session.isExpired, isFalse);
    expect(session.user.username, 'usuario');

    expect(session.user.can('journey:create'), isTrue);
  });

  test('login sem password é recusado pela API', () async {
    expect(
      () => loginAs(username: 'usuario', password: ''),
      throwsA(isA<ApiException>()),
    );
  });
}
