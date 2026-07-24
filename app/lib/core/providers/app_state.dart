import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jornadafacil/core/models/user_model.dart';
import 'package:jornadafacil/core/services/location_stream_service.dart';
import 'package:jornadafacil/core/services/current_user_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  String _coordinates = '';
  String _locationStatus = 'Fora da FJ-Telecom';
  String _error = '';
  String _distance = '';
  bool _isInsideGeofence = false;
  bool _isLoading = true;
  double? _latitude;
  double? _longitude;
  StreamSubscription<LocationData>? _locationSubscription;
  late LocationStreamService _locationStreamService;
  late CurrentUserService _userService;

  /// Última posição conhecida; `null` enquanto não houver fix do GPS.
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get coordinates => _coordinates;
  String get locationStatus => _locationStatus;
  String get error => _error;
  String get distance => _distance;
  bool get isInsideGeofence => _isInsideGeofence;
  bool get isLoading => _isLoading;
  UserModel get currentUser => _userService.getCurrentUser();

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);

    _userService = CurrentUserService();

    _locationStreamService = LocationStreamService();
    await _locationStreamService.initialize();

    final hasPermission = await _checkAndRequestPermission();
    if (hasPermission) {
      _startLocationStream();
    } else {
      _error = 'Permissão de localização negada';
      notifyListeners();
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationStreamService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startLocationStream();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _locationSubscription?.cancel();
        break;
      case AppLifecycleState.hidden:
        _locationSubscription?.cancel();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _startLocationStream() {
    _locationSubscription = _locationStreamService.startLocationStream().listen(
      (LocationData data) {
        _error = '';
        _latitude = data.latitude;
        _longitude = data.longitude;
        _coordinates = data.coordinates;
        _isInsideGeofence = data.isInsideGeofence;
        _locationStatus = data.locationStatus;
        _distance = data.distance;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'GPS Error: $e';
        notifyListeners();
      },
    );
  }
}
