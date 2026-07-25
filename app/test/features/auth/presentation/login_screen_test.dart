import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/features/auth/presentation/login_screen.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, {VoidCallback? onSuccess}) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onSuccess: onSuccess ?? () {})),
    );
    await tester.pump();
  }

  group('LoginScreen', () {
    testWidgets('Entrar sem valores mostra os dois erros e não faz login', (tester) async {
      var succeeded = false;
      await pumpLogin(tester, onSuccess: () => succeeded = true);

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe o usuário'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
      expect(succeeded, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('só usuário preenchido pede a senha', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Usuário'), 'joao');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe o usuário'), findsNothing);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('erro some quando os campos passam a ser válidos', (tester) async {
      await pumpLogin(tester);

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Informe o usuário'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Usuário'), 'joao');
      await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'segredo');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe o usuário'), findsNothing);
      expect(find.text('Informe a senha'), findsNothing);
    });

    testWidgets('olho alterna a visibilidade da senha', (tester) async {
      await pumpLogin(tester);

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
