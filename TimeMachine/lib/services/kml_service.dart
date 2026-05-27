import '../models/poi.dart';

class KMLService {
  /// Generates a ScreenOverlay for an image.
  static String screenOverlayImage(String imageUrl, double top, double left, double width, double height) {
    return '''
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>$imageUrl</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="$left" y="${1.0 - top}" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="$width" y="$height" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
    ''';
  }

  static String lookAt(POI poi) {
    return '<LookAt>'
        '<longitude>${poi.longitude}</longitude>'
        '<latitude>${poi.latitude}</latitude>'
        '<altitude>${poi.altitude}</altitude>'
        '<heading>${poi.heading}</heading>'
        '<tilt>${poi.tilt}</tilt>'
        '<range>${poi.range}</range>'
        '<gx:altitudeMode>${poi.altitudeMode}</gx:altitudeMode>'
        '</LookAt>';
  }

  static String getLogosKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Logos Panel</name>
    ${getLogosKMLContent()}
  </Document>
</kml>''';
  }

  static String getLogosKMLContent() {
    const String baseUrl = "http://lg1:81/logos"; 
    return '''
    <!-- Background Box (Curvy Dark Blue) -->
    ${screenOverlayImage('$baseUrl/bg_box.png', 0.05, 0.02, 0.22, 0.45)}
    
    <!-- Main App Logo (Top, Large) -->
     ${screenOverlayImage('$baseUrl/LiquidGalaxyTimeMachine_Logo.png', 0.08, 0.04, 0.18, 0.15)}
    
    <!-- Partner Logos (Row below, Smaller) -->
    ${screenOverlayImage('$baseUrl/LiquidGalaxy_Logo.png', 0.28, 0.04, 0.05, 0.05)}
    ${screenOverlayImage('$baseUrl/GoogleSummerOfCode_Logo.png', 0.28, 0.10, 0.05, 0.05)}
    ${screenOverlayImage('$baseUrl/LaboratorisTIC_Logo.png', 0.28, 0.16, 0.05, 0.05)}
    ''';
  }

  static String orbit(POI poi) {
    String content = '';
    for (int i = 0; i <= 360; i += 10) {
      content += '''
        <gx:FlyTo>
          <gx:duration>2.0</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
            <longitude>${poi.longitude}</longitude>
            <latitude>${poi.latitude}</latitude>
            <altitude>${poi.altitude}</altitude>
            <heading>${(poi.heading + i) % 360}</heading>
            <tilt>${poi.tilt}</tilt>
            <range>${poi.range}</range>
            <gx:altitudeMode>${poi.altitudeMode}</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
      ''';
    }

    return '''
      <gx:Tour>
        <name>Orbit</name>
        <gx:Playlist>
          $content
        </gx:Playlist>
      </gx:Tour>
    ''';
  }

  static String buildKML(POI poi, String content, {bool includeLogos = false}) {
    String logos = includeLogos ? getLogosKMLContent() : '';
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>${poi.name}</name>
    ${lookAt(poi)}
    $logos
    $content
  </Document>
</kml>''';
  }
}
