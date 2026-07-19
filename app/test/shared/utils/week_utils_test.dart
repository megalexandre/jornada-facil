import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/shared/utils/week_utils.dart';

void main() {
  group('WeekUtils.mondayOfWeek', () {
    test('quarta-feira retorna a segunda anterior às 00:00', () {
      // 2026-07-08 é uma quarta-feira.
      final monday = WeekUtils.mondayOfWeek(DateTime(2026, 7, 8, 15, 30));

      expect(monday, DateTime(2026, 7, 6));
    });

    test('segunda-feira retorna o mesmo dia com hora zerada', () {
      final monday = WeekUtils.mondayOfWeek(DateTime(2026, 7, 6, 23, 59));

      expect(monday, DateTime(2026, 7, 6));
    });

    test('domingo retorna a segunda 6 dias antes', () {
      // 2026-07-12 é um domingo.
      final monday = WeekUtils.mondayOfWeek(DateTime(2026, 7, 12, 8));

      expect(monday, DateTime(2026, 7, 6));
    });
  });

  group('WeekUtils.isInWeek', () {
    final weekStart = DateTime(2026, 7, 6);

    test('o próprio início da semana pertence à semana', () {
      expect(WeekUtils.isInWeek(weekStart, weekStart), isTrue);
    });

    test('domingo 23:59 pertence à semana', () {
      expect(
        WeekUtils.isInWeek(DateTime(2026, 7, 12, 23, 59), weekStart),
        isTrue,
      );
    });

    test('a segunda seguinte não pertence à semana', () {
      expect(WeekUtils.isInWeek(DateTime(2026, 7, 13), weekStart), isFalse);
    });

    test('a semana anterior não pertence à semana', () {
      expect(WeekUtils.isInWeek(DateTime(2026, 7, 5, 12), weekStart), isFalse);
    });
  });
}
