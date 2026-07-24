import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/journey_service.dart';

import 'support.dart';

/// E2E de registro de ponto: Flutter (JourneyService) → Rails → DB.
/// Requer a API no ar e semeada (make rails + make seed).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  test('funcionário inicia a jornada', () async {
    await loginAs('usuario', 'Senha123');
    await ensureNoOpenJourney();

    final journey = await JourneyService().openJourney(
      latitude: -23.5,
      longitude: -46.6,
    );

    expect(journey.isOpen, isTrue);
  });

  test('administrador não registra jornada', () async {
    await loginAs('admin', 'Senha123');

    expect(
      () => JourneyService().openJourney(latitude: -23.5, longitude: -46.6),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Usuário não registra jornada',
        ),
      ),
    );
  });

  test('funcionário abre e finaliza o ponto', () async {
    await loginAs('usuario', 'Senha123');
    await ensureNoOpenJourney();

    final open = await JourneyService().openJourney(
      latitude: -23.5,
      longitude: -46.6,
    );
    expect(open.isOpen, isTrue);

    final finished = await JourneyService().finishJourney(
      open.id,
      latitude: -23.5,
      longitude: -46.6,
    );
    expect(finished.isOpen, isFalse);
    expect(finished.finishedAt, isNotNull);
  });
}
