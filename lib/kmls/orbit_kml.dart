import '../models/poi.dart';

class OrbitKML {
  static String generate(POI poi) {
    String content = '';
    double heading = poi.heading;
    for (int i = 0; i <= 360; i += 10) {
      content += '''
        <gx:FlyTo>
          <gx:duration>2.0</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
            <longitude>${poi.longitude}</longitude>
            <latitude>${poi.latitude}</latitude>
            <altitude>${poi.altitude}</altitude>
            <heading>${(heading + i) % 360}</heading>
            <tilt>${poi.tilt}</tilt>
            <range>${poi.range}</range>
            <gx:altitudeMode>${poi.altitudeMode}</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
      ''';
    }

    return content;
  }
}
