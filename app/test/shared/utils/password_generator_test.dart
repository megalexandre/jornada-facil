import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/shared/utils/password_generator.dart';

void main() {
  group('generateStrongPassword', () {
    test('honra o comprimento pedido (default >= 12)', () {
      expect(generateStrongPassword().length, 16);
      expect(generateStrongPassword(length: 20).length, 20);
    });

    test('contém as quatro classes de caractere', () {
      for (var i = 0; i < 50; i++) {
        final password = generateStrongPassword();
        expect(RegExp(r'[A-Z]').hasMatch(password), isTrue, reason: password);
        expect(RegExp(r'[a-z]').hasMatch(password), isTrue, reason: password);
        expect(RegExp(r'[0-9]').hasMatch(password), isTrue, reason: password);
        expect(RegExp(r'[!@#\$%&*?]').hasMatch(password), isTrue, reason: password);
      }
    });

    test('gera valores distintos entre chamadas', () {
      final values = List.generate(20, (_) => generateStrongPassword()).toSet();
      expect(values.length, 20);
    });
  });
}
