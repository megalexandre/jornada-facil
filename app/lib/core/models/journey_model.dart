/// Ponto geográfico como serializado pela API: { latitude, longitude }.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Jornada como serializada pela API (JourneySerializer):
/// { id, started_at, finished_at, started_location, finished_location }
/// com timestamps iso8601 em UTC e localizações opcionais.
class JourneyModel {
  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final GeoPoint? startedLocation;
  final GeoPoint? finishedLocation;

  const JourneyModel({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    this.startedLocation,
    this.finishedLocation,
  });

  bool get isOpen => finishedAt == null;

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      startedLocation: json['started_location'] == null
          ? null
          : GeoPoint.fromJson(json['started_location'] as Map<String, dynamic>),
      finishedLocation: json['finished_location'] == null
          ? null
          : GeoPoint.fromJson(
              json['finished_location'] as Map<String, dynamic>),
    );
  }
}
