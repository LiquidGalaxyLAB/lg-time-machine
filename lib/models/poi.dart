class POI {
  final String name;
  final String country;
  final String description;
  final List<String> pastImages;
  final List<String> presentImages;
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading;
  final double tilt;
  final double range;
  final String altitudeMode;

  POI({
    required this.name,
    required this.country,
    required this.description,
    required this.pastImages,
    required this.presentImages,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.heading = 0.0,
    this.tilt = 0.0,
    this.range = 1000.0,
    this.altitudeMode = 'relativeToGround',
  });

  // Helper to get the main thumbnail image (e.g., first present image)
  String get thumbnail => presentImages.isNotEmpty
      ? presentImages.first
      : (pastImages.isNotEmpty ? pastImages.first : '');

  factory POI.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> metadata,
    List<String> pastImages,
    List<String> presentImages,
  ) {
    return POI(
      name: json['name'] ?? '',
      country: metadata['country'] ?? '',
      description: metadata['description'] ?? '',
      pastImages: pastImages,
      presentImages: presentImages,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      altitude: double.tryParse(json['altitude']?.toString() ?? '0.0') ?? 0.0,
      heading: double.tryParse(json['heading']?.toString() ?? '0.0') ?? 0.0,
      tilt: double.tryParse(json['tilt']?.toString() ?? '0.0') ?? 0.0,
      range: double.tryParse(json['range']?.toString() ?? '1000.0') ?? 1000.0,
      altitudeMode: json['altitudeMode'] ?? 'relativeToGround',
    );
  }
}
