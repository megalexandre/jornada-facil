import 'package:flutter/foundation.dart' show kIsWeb;

import 'runtime_config_stub.dart'
    if (dart.library.js_interop) 'runtime_config_web.dart';

class AppEnvironment {
  // String.fromEnvironment precisa ser const para funcionar em todas as
  // plataformas (em especial web/dart2js).
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const bool isDevelopment = appEnv == 'development';
  static const bool isProduction = appEnv == 'production';

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Base da API (sem barra final).
  ///
  /// Na web, um valor de runtime injetado pelo container (Coolify → config.js →
  /// window.API_BASE_URL) tem prioridade, para que a MESMA imagem Docker sirva
  /// ambientes diferentes sem rebuild. Sem runtime (mobile, ou web sem config.js)
  /// cai no valor compile-time (--dart-define). 10.0.2.2 é o loopback do host
  /// visto de dentro do emulador Android; no navegador o equivalente é localhost.
  static String get apiBaseUrl {
    final runtime = runtimeApiBaseUrl();
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return kIsWeb
        ? _rawApiBaseUrl.replaceFirst('//10.0.2.2', '//localhost')
        : _rawApiBaseUrl;
  }

  // Identificação do build, injetada no CI via --dart-define. 'dev' em builds
  // locais. Serve para conferir, na própria tela, qual código está no ar depois
  // de um deploy.
  static const String buildSha = String.fromEnvironment(
    'BUILD_SHA',
    defaultValue: 'dev',
  );
  static const String buildTime = String.fromEnvironment(
    'BUILD_TIME',
    defaultValue: '',
  );

  /// Valor curto de versão do app para a UI. Ex.: "a1b2c3d · 2026-07-11 08:30 UTC".
  /// O rótulo ("app version:") vem da tela.
  static String get buildLabel {
    final when = buildTime.isEmpty ? '' : ' · $buildTime';
    return '$buildSha$when';
  }
}
