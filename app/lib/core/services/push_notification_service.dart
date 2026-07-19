import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:jornadafacil/core/network/api_client.dart';
import 'package:jornadafacil/core/services/device_token_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  // Lazy: na web o Firebase não é inicializado (guarda em main.dart), então
  // o singleton pode ser criado sem tocar em FirebaseMessaging.instance.
  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?>? _tokenFuture;

  /// Token FCM da instalação. Na web resolve para `null`.
  Future<String?> get fcmToken {
    if (kIsWeb) return Future.value(null);
    return _tokenFuture ??= _messaging.getToken();
  }

  Future<void> init() async {
    await _messaging.requestPermission();

    final token = await fcmToken;
    debugPrint('FCM token: $token');

    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token atualizado: $token');
      _tokenFuture = Future.value(token);
      unawaited(syncTokenWithApi());
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Push recebido em primeiro plano: ${message.notification?.title}');
    });
  }

  /// Envia o token FCM atual para a API. Fire-and-forget: sem sessão ativa,
  /// sem token ou em caso de falha, apenas retorna/loga — nunca lança.
  Future<void> syncTokenWithApi() async {
    if (kIsWeb) return;
    try {
      final token = await fcmToken;
      if (token == null || ApiClient().authToken == null) return;
      await DeviceTokenService().registerToken(token);
    } catch (e) {
      debugPrint('Falha ao registrar token FCM: $e');
    }
  }
}
