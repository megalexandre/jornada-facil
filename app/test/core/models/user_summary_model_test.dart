import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/user_summary_model.dart';

void main() {
  group('UserSummaryModel.fromJson', () {
    test('desserializa o contrato de GET /api/v1/users', () {
      final user = UserSummaryModel.fromJson({
        'id': 'f26cb4d5-13e5-430b-9236-9094e2b94bee',
        'name': 'Alexandre Queiroz',
      });

      expect(user.id, 'f26cb4d5-13e5-430b-9236-9094e2b94bee');
      expect(user.name, 'Alexandre Queiroz');
    });

    test('tolera name ausente', () {
      final user = UserSummaryModel.fromJson({'id': 'abc'});

      expect(user.name, '');
    });
  });

  group('UserSummaryModel.initials', () {
    UserSummaryModel named(String name) =>
        UserSummaryModel(id: 'abc', name: name);

    test('duas primeiras iniciais em maiúsculas', () {
      expect(named('Alexandre Queiroz').initials, 'AQ');
      expect(named('ana beatriz costa').initials, 'AB');
    });

    test('nome único vira uma inicial', () {
      expect(named('Admin').initials, 'A');
    });

    test('ignora espaços extras', () {
      expect(named('  Maria   Silva ').initials, 'MS');
    });
  });
}
