class StatisticsKML {
  static String generate({
    required String imageUrl,
    double screenX = 0,
    double overlayX = 0,
    double sizeX = 2.9,
    double sizeY = 0.7,
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>Statistics Overlay</name>
      <Icon>
        <href>$imageUrl</href>
      </Icon>
      <overlayXY x="$overlayX" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="$screenX" y="0.85" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="$sizeX" y="$sizeY" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }
}
