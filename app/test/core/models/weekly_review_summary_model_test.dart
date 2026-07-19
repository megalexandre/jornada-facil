import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';

void main() {
  group('formatMinutes', () {
    test('horas cheias sem resto', () {
      expect(formatMinutes(2400), '40h');
      expect(formatMinutes(0), '0h');
    });

    test('horas com minutos', () {
      expect(formatMinutes(510), '8h 30m');
      expect(formatMinutes(65), '1h 05m');
    });
  });

  group('WeeklyReviewStatus.fromApi', () {
    test('mapeia os status conhecidos', () {
      expect(WeeklyReviewStatus.fromApi('alert'), WeeklyReviewStatus.alert);
      expect(WeeklyReviewStatus.fromApi('approved'),
          WeeklyReviewStatus.approved);
      expect(WeeklyReviewStatus.fromApi('rejected'),
          WeeklyReviewStatus.rejected);
    });

    test('status desconhecido ou nulo cai em pending', () {
      expect(WeeklyReviewStatus.fromApi('whatever'),
          WeeklyReviewStatus.pending);
      expect(WeeklyReviewStatus.fromApi(null), WeeklyReviewStatus.pending);
    });
  });

  group('WeeklyReviewSummaryModel.fromJson', () {
    final json = {
      'week_start': '2026-07-06',
      'week_end': '2026-07-12',
      'compliance_rate': 75,
      'previous_compliance_rate': 80,
      'users': [
        {
          'id': 'abc',
          'name': 'Ana Souza',
          'status': 'alert',
          'worked_minutes': 2910,
          'expected_minutes': 2400,
          'overtime_minutes': 510,
          'absences': 1,
        },
      ],
    };

    test('desserializa o contrato de GET /api/v1/weekly_reviews', () {
      final summary = WeeklyReviewSummaryModel.fromJson(json);

      expect(summary.weekStart, DateTime.parse('2026-07-06'));
      expect(summary.weekEnd, DateTime.parse('2026-07-12'));
      expect(summary.complianceRate, 75);
      expect(summary.previousComplianceRate, 80);
      expect(summary.complianceDelta, -5);
      expect(summary.users, hasLength(1));

      final row = summary.users.first;
      expect(row.id, 'abc');
      expect(row.name, 'Ana Souza');
      expect(row.status, WeeklyReviewStatus.alert);
      expect(row.workedMinutes, 2910);
      expect(row.absences, 1);
    });

    test('tolera previous_compliance_rate nulo', () {
      final summary = WeeklyReviewSummaryModel.fromJson({
        ...json,
        'previous_compliance_rate': null,
      });

      expect(summary.previousComplianceRate, isNull);
      expect(summary.complianceDelta, isNull);
    });
  });

  group('WeeklyReviewUserRowModel derivados', () {
    WeeklyReviewUserRowModel row({
      int worked = 2400,
      int expected = 2400,
    }) {
      return WeeklyReviewUserRowModel(
        id: 'abc',
        name: 'Ana Souza',
        status: WeeklyReviewStatus.pending,
        workedMinutes: worked,
        expectedMinutes: expected,
        overtimeMinutes: 0,
        absences: 0,
      );
    }

    test('workedLabel formata trabalhado vs esperado', () {
      expect(row(worked: 2910).workedLabel, '48h 30m / 40h');
    });

    test('progress limitado a 1.0 e protege divisão por zero', () {
      expect(row(worked: 1200).progress, 0.5);
      expect(row(worked: 4800).progress, 1.0);
      expect(row(expected: 0).progress, 0);
    });

    test('isOverExpected apenas acima do esperado', () {
      expect(row(worked: 2400).isOverExpected, isFalse);
      expect(row(worked: 2401).isOverExpected, isTrue);
    });

    test('initials com duas primeiras iniciais', () {
      expect(row().initials, 'AS');
    });
  });
}
