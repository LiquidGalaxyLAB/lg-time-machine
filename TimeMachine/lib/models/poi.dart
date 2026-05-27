class POI {
  final int? id;
  final int countryId;
  final String name;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading;
  final double tilt;
  final double range;
  final String altitudeMode;

  POI({
    this.id,
    required this.countryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.heading = 0.0,
    this.tilt = 0.0,
    this.range = 1000.0,
    this.altitudeMode = 'relativeToGround',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryId': countryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'heading': heading,
      'tilt': tilt,
      'range': range,
      'altitudeMode': altitudeMode,
    };
  }

  factory POI.fromMap(Map<String, dynamic> map) {
    return POI(
      id: map['id'],
      countryId: map['countryId'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      altitude: (map['altitude'] ?? 0.0).toDouble(),
      heading: (map['heading'] ?? 0.0).toDouble(),
      tilt: (map['tilt'] ?? 0.0).toDouble(),
      range: (map['range'] ?? 1000.0).toDouble(),
      altitudeMode: map['altitudeMode'] ?? 'relativeToGround',
    );
  }
}
