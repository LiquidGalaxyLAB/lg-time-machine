class LogoKML {
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

  static String generateContent() {
    const String baseUrl = "http://lg1:81/logos";
    return '''
    <!-- Main Branding Overlay -->
    ${screenOverlayImage('$baseUrl/KMLs_Logo.png', 0.02, 0.01, 0.71, 0.44)}
    ''';
  }

  static String generate() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>Logos Panel</name>
    <Folder>
      <name>Images</name>
      ${generateContent()}
    </Folder>
  </Document>
</kml>''';
  }
}
