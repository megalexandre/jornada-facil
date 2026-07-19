import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/app/app.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Sem mock, a chamada ao canal do flutter_secure_storage nunca resolve
  // dentro do FakeAsync do testWidgets e o app fica preso no splash.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async => null,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('App launches and displays the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // pumpAndSettle não converge aqui: o TimerNotifier agenda frames
    // continuamente. Pumps fixos bastam para o restore da sessão terminar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Jornada Fácil'), findsOneWidget);
    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
