import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/journey_model.dart';

void main() {
  group('JourneyModel.fromJson', () {
    test('desserializa uma jornada aberta (finished_at null)', () {
      // Payload real de GET /api/v1/users/:id/journeys.
      final journey = JourneyModel.fromJson({
        'id': '3f2c8a10-9d4b-4a51-8e7f-1c2d3e4f5a6b',
        'started_at': '2026-07-06T08:00:00Z',
        'finished_at': null,
      });

      expect(journey.id, '3f2c8a10-9d4b-4a51-8e7f-1c2d3e4f5a6b');
      expect(journey.startedAt, DateTime.utc(2026, 7, 6, 8));
      expect(journey.finishedAt, isNull);
      expect(journey.isOpen, isTrue);
    });

    test('desserializa uma jornada finalizada', () {
      final journey = JourneyModel.fromJson({
        'id': '3f2c8a10-9d4b-4a51-8e7f-1c2d3e4f5a6b',
        'started_at': '2026-07-06T08:00:00Z',
        'finished_at': '2026-07-06T17:30:00Z',
      });

      expect(journey.startedAt, DateTime.utc(2026, 7, 6, 8));
      expect(journey.finishedAt, DateTime.utc(2026, 7, 6, 17, 30));
      expect(journey.isOpen, isFalse);
    });

    test('desserializa as localizações quando presentes', () {
      final journey = JourneyModel.fromJson({
        'id': '3f2c8a10-9d4b-4a51-8e7f-1c2d3e4f5a6b',
        'started_at': '2026-07-06T08:00:00Z',
        'finished_at': '2026-07-06T17:30:00Z',
        'started_location': {'latitude': -23.55052, 'longitude': -46.633308},
        'finished_location': {'latitude': -23.5507, 'longitude': -46.6334},
      });

      expect(journey.startedLocation?.latitude, -23.55052);
      expect(journey.startedLocation?.longitude, -46.633308);
      expect(journey.finishedLocation?.latitude, -23.5507);
      expect(journey.finishedLocation?.longitude, -46.6334);
    });

    test('localizações ausentes ou nulas viram null', () {
      final journey = JourneyModel.fromJson({
        'id': '3f2c8a10-9d4b-4a51-8e7f-1c2d3e4f5a6b',
        'started_at': '2026-07-06T08:00:00Z',
        'finished_at': null,
        'started_location': null,
      });

      expect(journey.startedLocation, isNull);
      expect(journey.finishedLocation, isNull);
    });
  });
}
