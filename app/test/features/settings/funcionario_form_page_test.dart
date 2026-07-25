import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/employee_model.dart';
import 'package:jornadafacil/features/settings/presentation/widgets/funcionario_form_page.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester, {EmployeeModel? employee}) async {
    await tester.pumpWidget(
      MaterialApp(home: FuncionarioFormPage(employee: employee)),
    );
    await tester.pump();
  }

  EditableText passwordField(WidgetTester tester) {
    return tester.widgetList<EditableText>(find.byType(EditableText)).last;
  }

  group('FuncionarioFormPage', () {
    testWidgets('criar vazio mostra os erros e não sai da tela', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('Criar'));
      await tester.pump();

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(find.text('Informe o usuário'), findsOneWidget);
      expect(find.text('Informe o e-mail'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('e-mail inválido é rejeitado', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'invalido');
      await tester.tap(find.text('Criar'));
      await tester.pump();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('o ícone gera uma senha e revela o campo', (tester) async {
      await pumpForm(tester);

      expect(passwordField(tester).controller.text, isEmpty);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.casino_outlined));
      await tester.pump();

      expect(passwordField(tester).controller.text.length, 16);
      // Revelado: o toggle passa a oferecer "ocultar".
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('em edição a senha é opcional (label muda, sem erro vazio)',
        (tester) async {
      await pumpForm(
        tester,
        employee: const EmployeeModel(
          id: '1',
          name: 'Ana',
          username: 'ana',
          email: 'ana@example.com',
          tracksJourney: true,
          active: true,
        ),
      );

      expect(find.text('Nova senha (opcional)'), findsOneWidget);
      expect(find.text('Informe a senha'), findsNothing);
    });
  });
}
