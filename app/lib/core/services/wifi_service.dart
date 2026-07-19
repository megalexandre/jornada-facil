class WifiService {
  static final WifiService _instance = WifiService._internal();

  factory WifiService() => _instance;

  WifiService._internal();

  // WiFi atualmente conectado (mockado)
  String _currentWifi = 'Lize';

  // Lista de WiFis registrados
  final Set<String> _registeredWifis = {
    'Lize',
  };

  bool isConnectedToRegisteredWifi() {
    return _registeredWifis.contains(_currentWifi);
  }

  void setCurrentWifi(String wifiName) {
    _currentWifi = wifiName;
  }

  String get currentWifi => _currentWifi;

  Set<String> get registeredWifis => _registeredWifis;

  void registerWifi(String wifiName) {
    _registeredWifis.add(wifiName);
  }

  void unregisterWifi(String wifiName) {
    _registeredWifis.remove(wifiName);
  }
}
