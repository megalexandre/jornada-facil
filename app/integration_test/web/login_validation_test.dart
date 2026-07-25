import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jornadafacil/features/auth/presentation/login_screen.dart';

/// Grupo WEB (integration_test + flutter drive, Chrome real). Reusa o fluxo do
/// widget test `test/features/auth/presentation/login_screen_test.dart`: apertar
/// Entrar com os campos vazios mostra as mensagens de validação. A validação
/// corta antes da API, então não precisa de backend — roda em Chrome puro.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login vazio mostra as mensagens de erro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onSuccess: () {})),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o usuário'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });
}
