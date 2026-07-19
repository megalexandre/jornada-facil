import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Push notifications: apenas Android por enquanto (web exigiria
  // firebase_options + service worker).
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await PushNotificationService().init();
  }

  runApp(const MyApp());
}
