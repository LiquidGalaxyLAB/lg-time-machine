import '../models/poi.dart';

class LookAtKML {
  double longitude;
  double latitude;
  double altitude;
  String range;
  String tilt;
  String heading;
  String altitudeMode;

  LookAtKML(
    this.longitude,
    this.latitude,
    this.range,
    this.tilt,
    this.heading, [
    this.altitude = 0.0,
    this.altitudeMode = 'relativeToGround',
  ]);

  String generateLinearString() {
    return '<LookAt>'
        '<longitude>$longitude</longitude>'
        '<latitude>$latitude</latitude>'
        '<altitude>$altitude</altitude>'
        '<heading>$heading</heading>'
        '<tilt>$tilt</tilt>'
        '<range>$range</range>'
        '<gx:altitudeMode>$altitudeMode</gx:altitudeMode>'
        '</LookAt>';
  }

  static String generate(POI poi, [int rigCount = 1]) {
    double range = poi.range;

    // Applying the logic from the user snippet: range = value / rigCount
    if (rigCount > 0) {
      range = range / rigCount;
    }

    return LookAtKML(
      poi.longitude,
      poi.latitude,
      range.toString(),
      poi.tilt.toString(),
      poi.heading.toString(),
      0.0, // Altitude set to 0 to ensure camera stays relative to the ground surface
      poi.altitudeMode,
    ).generateLinearString();
  }
}
