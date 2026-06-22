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

  final String statisticsTextPresent;
  final String statisticsTextPast;
  final String comparisonSummary;

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
    this.statisticsTextPresent = '',
    this.statisticsTextPast = '',
    this.comparisonSummary = '',
  });

  /// Devuelve la imagen correspondiente según el estado del tiempo (0: Past, 1: Present)
  String getCurrentImage(double timeValue) {
    if (timeValue == 0 && pastImages.isNotEmpty) {
      return pastImages.first;
    }
    return presentImages.isNotEmpty ? presentImages.first : '';
  }

  // Helper para el thumbnail inicial
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
      statisticsTextPresent: metadata['statistics_text_present'] ?? '',
      statisticsTextPast: metadata['statistics_text_past'] ?? '',
      comparisonSummary: metadata['past_comparison_summary'] ?? '',
    );
  }
}
