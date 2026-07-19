import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerNotifier extends ChangeNotifier {
  late DateTime _currentTime;
  late Timer _timer;

  DateTime get currentTime => _currentTime;

  void init() {
    _currentTime = DateTime.now();
    _startClock();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }
}
