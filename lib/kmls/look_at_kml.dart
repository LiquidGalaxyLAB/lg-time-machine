import '../models/poi.dart';

class LookAtKML {
  static String generate(POI poi) {
    return '''
    <LookAt>
      <longitude>${poi.longitude}</longitude>
      <latitude>${poi.latitude}</latitude>
      <altitude>${poi.altitude}</altitude>
      <heading>${poi.heading}</heading>
      <tilt>${poi.tilt}</tilt>
      <range>${poi.range}</range>
      <gx:altitudeMode>${poi.altitudeMode}</gx:altitudeMode>
    </LookAt>''';
  }
}
