import 'package:jornadafacil/core/network/api_client.dart';

/// Registra o token FCM do aparelho na API, vinculando-o ao usuário
/// autenticado. Falhas sobem como [ApiException].
class DeviceTokenService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();

  factory DeviceTokenService() => _instance;

  DeviceTokenService._internal();

  final ApiClient _api = ApiClient();

  /// POST /api/v1/device_tokens — upsert idempotente: o token identifica a
  /// instalação e é re-vinculado ao último usuário logado no aparelho.
  Future<void> registerToken(String token) async {
    await _api.post(
      '/api/v1/device_tokens',
      body: {'token': token, 'platform': 'android'},
    );
  }
}
