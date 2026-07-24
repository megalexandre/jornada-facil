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

  group('GeofenceService (polígono da FJ-Telecom)', () {
    // Centroide dos 4 vértices de assets/geofence.geojson.
    test('detecta ponto dentro do polígono', () {
      expect(service.isPointInPolygon(-11.0533474, -40.7818845), isTrue);
    });

    test('detecta ponto fora do polígono (perto, mas fora)', () {
      // Logo ao sul do vértice mais ao sul.
      expect(service.isPointInPolygon(-11.0537000, -40.7818845), isFalse);
      // Logo a leste do vértice mais a leste.
      expect(service.isPointInPolygon(-11.0533474, -40.7815000), isFalse);
    }, skip: skipOutsideChecks);

    test('calcula texto de distância para ponto distante', () {
      final text = service.calculateDistanceText(-11.10, -40.80);
      expect(text, contains('de distância'));
    });
  });
}
