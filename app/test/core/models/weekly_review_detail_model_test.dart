import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';

void main() {
  Map<String, dynamic> detailJson({Map<String, dynamic>? review}) {
    return {
      'user': {'id': 'abc', 'name': 'Ana Souza'},
      'week_start': '2026-07-06',
      'week_end': '2026-07-12',
      'total_minutes': 2910,
      'standard_minutes': 2400,
      'overtime_minutes': 510,
      'expected_minutes': 2400,
      'absences': 1,
      'review': review,
      'days': [
        {
          'date': '2026-07-06',
          'weekend': false,
          'worked_minutes': 480,
          'overtime_minutes': 0,
          'absence': false,
          'status': 'pending',
          'intervals': [
            {
              'start': '08:00',
              'end': '12:00',
              'start_location': {'latitude': -12.930, 'longitude': -38.432},
              'end_location': {'latitude': -12.931, 'longitude': -38.433},
            },
            {'start': '13:00', 'end': '17:00'},
          ],
        },
        {
          'date': '2026-07-11',
          'weekend': true,
          'worked_minutes': 120,
          'overtime_minutes': 120,
          'absence': false,
          'status': 'overtime',
          'intervals': [
            {'start': '09:00', 'end': null},
          ],
        },
      ],
    };
  }

  group('WeeklyReviewDetailModel.fromJson', () {
    test('desserializa o contrato de GET /api/v1/users/:id/weekly_review', () {
      final detail = WeeklyReviewDetailModel.fromJson(detailJson());

      expect(detail.userId, 'abc');
      expect(detail.userName, 'Ana Souza');
      expect(detail.weekStart, DateTime.parse('2026-07-06'));
      expect(detail.totalMinutes, 2910);
      expect(detail.standardMinutes, 2400);
      expect(detail.overtimeMinutes, 510);
      expect(detail.absences, 1);
      expect(detail.review, isNull);
      expect(detail.days, hasLength(2));

      final monday = detail.days.first;
      expect(monday.status, WeeklyDayStatus.pending);
      expect(monday.intervals, hasLength(2));
      expect(monday.intervals.first.start, '08:00');
      expect(monday.intervals.first.end, '12:00');
      expect(monday.intervals.first.startLocation?.latitude, -12.930);
      expect(monday.intervals.first.startLocation?.longitude, -38.432);
      expect(monday.intervals.first.endLocation?.latitude, -12.931);
      expect(monday.intervals.last.startLocation, isNull);
      expect(monday.intervals.last.endLocation, isNull);
    });

    test('intervalo aberto tem end nulo', () {
      final detail = WeeklyReviewDetailModel.fromJson(detailJson());

      expect(detail.days.last.intervals.single.end, isNull);
    });

    test('desserializa a review quando presente', () {
      final detail = WeeklyReviewDetailModel.fromJson(detailJson(review: {
        'id': 'rev-1',
        'status': 'rejected',
        'comment': 'Rever horas extras',
        'week_start': '2026-07-06',
        'reviewer_name': 'Admin',
        'reviewed_at': '2026-07-07T12:00:00Z',
      }));

      final review = detail.review!;
      expect(review.status, WeeklyReviewStatus.rejected);
      expect(review.comment, 'Rever horas extras');
      expect(review.reviewerName, 'Admin');
    });

    test('status de dia desconhecido cai em pending', () {
      expect(WeeklyDayStatus.fromApi('whatever'), WeeklyDayStatus.pending);
      expect(WeeklyDayStatus.fromApi('rest'), WeeklyDayStatus.rest);
    });
  });

  group('derivados de fim de semana', () {
    test('separa dias úteis e soma extra do fim de semana', () {
      final detail = WeeklyReviewDetailModel.fromJson(detailJson());

      expect(detail.weekdays, hasLength(1));
      expect(detail.weekendDays, hasLength(1));
      expect(detail.weekendOvertimeMinutes, 120);
    });
  });
}
