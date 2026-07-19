import 'package:vibration/vibration.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();

  factory VibrationService() => _instance;

  VibrationService._internal();

  Future<void> vibrate({int duration = 100}) => Vibration.vibrate(duration: duration);
}
