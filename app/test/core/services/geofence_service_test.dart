import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/services/geofence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeofenceService service;

  // Com a validação desativada, isPointInPolygon retorna sempre true;
  // os testes de "fora da geofence" só valem com a chave ligada.
  const skipOutsideChecks = GeofenceService.validateGeofence
      ? false
      : 'validateGeofence está desativado (sempre dentro)';

  setUpAll(() async {
    service = GeofenceService();
    await service.loadGeofence();
  });

  group('GeofenceService', () {
    test('detecta ponto dentro da casa de alexandre (polígono)', () {
      // Centro aproximado do retângulo do casa_alexandre.geojson.
      expect(service.isPointInPolygon(-12.931265, -38.431647), isTrue);
    });

    test('detecta ponto na borda interna do polígono', () {
      expect(service.isPointInPolygon(-12.930400, -38.431200), isTrue);
    });

    test('detecta ponto fora do polígono (perto, mas fora)', () {
      expect(service.isPointInPolygon(-12.930200, -38.431647), isFalse);
      expect(service.isPointInPolygon(-12.931265, -38.430900), isFalse);
    }, skip: skipOutsideChecks);

    test('detecta ponto dentro da casa de denise (círculo de 20m)', () {
      expect(service.isPointInPolygon(-11.2588, -40.9406), isTrue);
    });

    test('detecta ponto fora da casa de denise', () {
      expect(service.isPointInPolygon(-11.2600, -40.9406), isFalse);
    }, skip: skipOutsideChecks);

    test('calcula texto de distância para ponto distante', () {
      final text = service.calculateDistanceText(-12.94, -38.44);
      expect(text, contains('de distância'));
    });
  });
}
