import 'package:jornadafacil/core/network/api_client.dart';

/// Busca a versão do backend no endpoint público GET /api/v1/version, para
/// exibir na tela ao lado da versão do app.
class VersionService {
  final ApiClient _api = ApiClient();

  /// Versão do backend formatada (`sha · hora`), ou null se indisponível
  /// (API fora do ar / CORS) — a tela degrada sem quebrar.
  Future<String?> fetchServerVersion() async {
    try {
      final json = await _api.get('/api/v1/version') as Map<String, dynamic>;
      final version = (json['version'] as String?) ?? '';
      final time = (json['build_time'] as String?) ?? '';
      if (version.isEmpty) return null;
      return time.isEmpty ? version : '$version · $time';
    } catch (_) {
      return null;
    }
  }
}
