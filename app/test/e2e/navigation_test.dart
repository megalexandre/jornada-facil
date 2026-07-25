import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Roteamento pós-login: a aba inicial do MainScaffold é a primeira permitida,
/// e o gate de cada aba é `user.can(permission)` + regra de ponto
/// (`tracksJourney`). Dashboard/Revisão pedem `users:view`; Registro/Histórico
/// só aparecem para quem bate ponto. Por isso o admin (tem `users:view`, não
/// bate ponto) cai no Dashboard, e o usuário comum cai no Registro. Aqui
/// validamos a condição que decide isso, na sessão real vinda da API.
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
