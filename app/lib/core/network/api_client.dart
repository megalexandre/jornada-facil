import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jornadafacil/core/config/app_config.dart';
import 'package:jornadafacil/core/network/api_exception.dart';

/// Cliente HTTP único do app. Envia/recebe JSON e anexa o Bearer token
/// (definido pelo AuthService) em toda request quando presente.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  static const _timeout = Duration(seconds: 15);

  final http.Client _http = http.Client();
  String _baseUrl = AppEnvironment.apiBaseUrl;
  String? authToken;

  set baseUrl(String value) => _baseUrl = value;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri);

    request.headers['Accept'] = 'application/json';
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(_timeout),
      );
    } on TimeoutException {
      throw const ApiException('Tempo de conexão esgotado. Tente novamente.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar ao servidor.');
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // A API responde erros como { "error": "mensagem" }.
    final message = body is Map<String, dynamic>
        ? (body['error'] as String? ?? 'Erro inesperado (${response.statusCode})')
        : 'Erro inesperado (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
