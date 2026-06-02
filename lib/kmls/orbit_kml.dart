import '../models/poi.dart';

class OrbitKML {
  static String generate(POI poi, [int rigCount = 1]) {
    String content = '';
    double heading = poi.heading;
    double range = poi.range;

    // Applying the same range logic as LookAtKML
    if (rigCount > 0) {
      range = range / rigCount;
    }

    // We create a sequence of LookAt points that rotate around the heading
    // while maintaining the same latitude and longitude.
    // This creates an orbit effect around the point.
    for (int i = 0; i <= 360; i += 15) {
      content +=
          '''
        <gx:FlyTo>
          <gx:duration>1.5</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
            <longitude>${poi.longitude}</longitude>
            <latitude>${poi.latitude}</latitude>
            <altitude>0</altitude>
            <heading>${(heading + i) % 360}</heading>
            <tilt>${poi.tilt}</tilt>
            <range>$range</range>
            <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
      ''';
    }

    return content;
  }
}
