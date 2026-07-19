import 'package:jornadafacil/core/services/geofence_service.dart';
import 'package:jornadafacil/core/services/wifi_service.dart';

class RegistrationJourneyPolicy {
  final GeofenceService _geofenceService;
  final WifiService _wifiService;

  RegistrationJourneyPolicy({
    required this._geofenceService,
    required this._wifiService,
  });

  bool canRegisterPoint(double lat, double lng) {
    final isInsideGeofence = _geofenceService.isPointInPolygon(lat, lng);

    return isInsideGeofence ;
  }

  String getReasonIfCannotRegister(double lat, double lng) {
    final isInsideGeofence = _geofenceService.isPointInPolygon(lat, lng);
    final isConnectedToRegisteredWifi = _wifiService.isConnectedToRegisteredWifi();

    if (isInsideGeofence || isConnectedToRegisteredWifi) {
      return '';
    }

    if (!isConnectedToRegisteredWifi) {
      return 'WiFi não registrado';
    }

    return 'Você precisa estar na casa de Denise ou conectado a um WiFi registrado';
  }
}
