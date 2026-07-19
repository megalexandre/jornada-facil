import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/shared/widgets/cards/week_locations_card.dart';
import 'package:jornadafacil/shared/widgets/maps/geo_map.dart';

void main() {
  // Semana de 06 a 12 de julho de 2026.
  final weekStart = DateTime(2026, 7, 6);

  Future<void> pumpCard(
    WidgetTester tester, {
    List<({GeoPoint point, DateTime date})> entries = const [],
    List<({GeoPoint point, DateTime date})> exits = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeekLocationsCard(
            weekStart: weekStart,
            entries: entries,
            exits: exits,
          ),
        ),
      ),
    );
  }

  group('WeekLocationsCard', () {
    testWidgets('exibe mapa, legenda e período com pontos na semana',
        (tester) async {
      await pumpCard(
        tester,
        entries: [
          (point: const GeoPoint(latitude: -12.930, longitude: -38.432), date: weekStart),
        ],
        exits: [
          (point: const GeoPoint(latitude: -12.931, longitude: -38.433), date: weekStart),
        ],
      );

      expect(find.text('LOCALIZAÇÕES DA SEMANA'), findsOneWidget);
      expect(find.text('06 a 12 de julho'), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Saída'), findsOneWidget);
      expect(find.byType(GeoMap), findsOneWidget);
    });

    testWidgets('só com entradas ainda mostra o mapa', (tester) async {
      await pumpCard(
        tester,
        entries: [
          (point: const GeoPoint(latitude: -12.930, longitude: -38.432), date: weekStart),
        ],
      );

      expect(find.byType(GeoMap), findsOneWidget);
    });

    testWidgets('sem pontos mostra o estado vazio', (tester) async {
      await pumpCard(tester);

      expect(
        find.text('Sem registros com localização nesta semana'),
        findsOneWidget,
      );
      expect(find.byType(GeoMap), findsNothing);
    });
  });
}
