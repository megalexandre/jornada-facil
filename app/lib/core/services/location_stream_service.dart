import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:jornadafacil/core/services/geofence_service.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String coordinates;
  final String locationStatus;
  final String distance;
  final bool isInsideGeofence;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.coordinates,
    required this.locationStatus,
    required this.distance,
    required this.isInsideGeofence,
  });
}

class LocationStreamService {
  static final LocationStreamService _instance = LocationStreamService._internal();

  factory LocationStreamService() => _instance;

  LocationStreamService._internal();

  late GeofenceService _geofenceService;
  StreamSubscription<Position>? _positionStream;

  Future<void> initialize() async {
    _geofenceService = GeofenceService();
    await _geofenceService.loadGeofence();
  }

  Stream<LocationData> startLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).map((Position position) => _processPosition(position));
  }

  LocationData _processPosition(Position position) {
    final lat = double.parse(position.latitude.toStringAsFixed(5));
    final lng = double.parse(position.longitude.toStringAsFixed(5));

    final coordinates = '$lat, $lng';
    final isInsideGeofence = _geofenceService.isPointInPolygon(lat, lng);
    final locationStatus = isInsideGeofence
        ? 'Estamos na casa de Denise'
        : 'Fora da casa de Denise';
    final distance = isInsideGeofence
        ? ''
        : _geofenceService.calculateDistanceText(lat, lng);

    return LocationData(
      latitude: lat,
      longitude: lng,
      coordinates: coordinates,
      locationStatus: locationStatus,
      distance: distance,
      isInsideGeofence: isInsideGeofence,
    );
  }

  void stopLocationStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void dispose() {
    stopLocationStream();
  }
}
