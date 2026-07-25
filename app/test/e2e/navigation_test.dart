import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  test('admin cai no Dashboard após o login', () async {
    final session = await loginAs(username: 'admin', password: 'Senha123');

    expect(session.user.can('users:view'), isTrue);
    expect(session.user.tracksJourney, isFalse);
  });

  test('usuário comum não vê o Dashboard e cai no Registro', () async {
    final session = await loginAs(username: 'usuario', password: 'Senha123');

    expect(session.user.can('users:view'), isFalse);
    expect(session.user.tracksJourney, isTrue);
  });
}
