import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/network/api_client.dart';

/// Consome os endpoints de jornada do usuário autenticado.
/// Falhas sobem como [ApiException] com a mensagem da API
/// (ex.: 422 quando já existe jornada aberta ou já finalizada).
class JourneyService {
  static final JourneyService _instance = JourneyService._internal();

  factory JourneyService() => _instance;

  JourneyService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/v1/journeys — jornadas do usuário, mais recentes primeiro.
  Future<List<JourneyModel>> listJourneys() async {
    final json = await _api.get('/api/v1/journeys') as List<dynamic>;
    return json
        .map((item) => JourneyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/journeys — abre uma jornada no relógio do servidor,
  /// registrando onde o usuário estava quando há posição disponível.
  Future<JourneyModel> openJourney({double? latitude, double? longitude}) async {
    final json = await _api.post(
      '/api/v1/journeys',
      body: _locationBody(latitude, longitude),
    ) as Map<String, dynamic>;
    return JourneyModel.fromJson(json);
  }

  /// PATCH /api/v1/journeys/:id/finish — encerra a jornada aberta,
  /// registrando onde o usuário estava quando há posição disponível.
  Future<JourneyModel> finishJourney(
    String id, {
    double? latitude,
    double? longitude,
  }) async {
    final json = await _api.patch(
      '/api/v1/journeys/$id/finish',
      body: _locationBody(latitude, longitude),
    ) as Map<String, dynamic>;
    return JourneyModel.fromJson(json);
  }

  /// A API exige latitude e longitude juntas; sem fix do GPS não envia corpo.
  Map<String, double>? _locationBody(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    return {'latitude': latitude, 'longitude': longitude};
  }

  /// Jornada aberta do usuário, ou `null` se não houver.
  Future<JourneyModel?> findOpenJourney() async {
    final journeys = await listJourneys();
    for (final journey in journeys) {
      if (journey.isOpen) return journey;
    }
    return null;
  }
}
