import 'dart:js_interop';

// Bind em globalThis.API_BASE_URL (window.API_BASE_URL), definido pelo config.js
// gerado em runtime pelo container (ver docker/40-generate-config.sh).
@JS('API_BASE_URL')
external JSString? get _apiBaseUrl;

/// URL da API definida em runtime (Coolify → config.js), ou null se ausente/vazia.
String? runtimeApiBaseUrl() {
  final raw = _apiBaseUrl?.toDart;
  if (raw == null || raw.isEmpty) return null;
  return raw;
}
