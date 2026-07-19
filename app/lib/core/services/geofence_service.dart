import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Geofence circular: ponto central + raio em metros.
class _CircleGeofence {
  final LatLng center;
  final double radiusMeters;

  const _CircleGeofence(this.center, this.radiusMeters);
}

/// Geofence poligonal: lista de vértices (anel externo do GeoJSON).
class _PolygonGeofence {
  final List<LatLng> vertices;
  final LatLng centroid;

  _PolygonGeofence(this.vertices)
      : centroid = LatLng(
          vertices.map((v) => v.latitude).reduce((a, b) => a + b) /
              vertices.length,
          vertices.map((v) => v.longitude).reduce((a, b) => a + b) /
              vertices.length,
        );
}

class GeofenceService {
  /// Chave de desenvolvimento: com `false`, a validação geográfica é
  /// desativada e [isPointInPolygon] retorna sempre `true` (registro de
  /// ponto liberado em qualquer lugar).
  static const bool validateGeofence = false;

  static final GeofenceService _instance = GeofenceService._internal();

  factory GeofenceService() => _instance;

  GeofenceService._internal();

  final List<_CircleGeofence> _circles = [];
  final List<_PolygonGeofence> _polygons = [];
  bool _isLoaded = false;
  static const double _radiusMeters = 20.0;

  static const List<String> _geofenceAssets = [
    'assets/casa_denise.geojson',
    'assets/casa_alexandre.geojson',
  ];

  Future<void> loadGeofence() async {
    if (_isLoaded) return;

    for (final asset in _geofenceAssets) {
      final jsonString = await rootBundle.loadString(asset);
      _parseGeoJSON(jsonString);
    }
    _isLoaded = true;
  }

  bool isPointInPolygon(double lat, double lng) {
    if (!validateGeofence) return true;
    if (!_isLoaded) return false;

    for (final circle in _circles) {
      final distanceInMeters = _haversineDistance(
        lat,
        lng,
        circle.center.latitude,
        circle.center.longitude,
      );
      if (distanceInMeters <= circle.radiusMeters) return true;
    }

    for (final polygon in _polygons) {
      if (_isInsidePolygon(lat, lng, polygon.vertices)) return true;
    }

    return false;
  }

  String calculateDistanceText(double lat, double lng) {
    if (!_isLoaded) return '';

    double? nearest;
    for (final circle in _circles) {
      final d = _haversineDistance(
        lat,
        lng,
        circle.center.latitude,
        circle.center.longitude,
      );
      if (nearest == null || d < nearest) nearest = d;
    }
    for (final polygon in _polygons) {
      final d = _haversineDistance(
        lat,
        lng,
        polygon.centroid.latitude,
        polygon.centroid.longitude,
      );
      if (nearest == null || d < nearest) nearest = d;
    }

    if (nearest == null) return '';

    if (nearest < 1000) {
      return '${nearest.toStringAsFixed(0)}m de distância';
    } else {
      final distanceInKm = nearest / 1000;
      return '${distanceInKm.toStringAsFixed(2)}km de distância';
    }
  }

  /// Ray casting: conta quantas arestas o raio horizontal a partir do ponto
  /// cruza; ímpar = dentro.
  bool _isInsidePolygon(double lat, double lng, List<LatLng> vertices) {
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final vi = vertices[i];
      final vj = vertices[j];
      final intersects = ((vi.latitude > lat) != (vj.latitude > lat)) &&
          (lng <
              (vj.longitude - vi.longitude) *
                      (lat - vi.latitude) /
                      (vj.latitude - vi.latitude) +
                  vi.longitude);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void _parseGeoJSON(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final features = data['features'] as List;

    for (final rawFeature in features) {
      final feature = rawFeature as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final coordinates = geometry['coordinates'] as List;

      if (type == 'Point') {
        final center = LatLng(
          (coordinates[1] as num).toDouble(),
          (coordinates[0] as num).toDouble(),
        );
        _circles.add(_CircleGeofence(center, _radiusMeters));
      } else if (type == 'Polygon') {
        final ring = coordinates.first as List;
        final vertices = ring
            .map((c) => LatLng(
                  ((c as List)[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ))
            .toList();
        _polygons.add(_PolygonGeofence(vertices));
      }
    }
  }
}
