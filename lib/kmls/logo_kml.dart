class LogoKML {
  static String screenOverlayImage(String imageUrl, double top, double left, double width, double height) {
    final double y = 1.0 - top;
    return '''
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>$imageUrl</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="$left" y="$y" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <!-- Al usar y=0, Google Earth mantiene automáticamente el aspect ratio original de la imagen basado en el ancho (x) -->
      <size x="$width" y="0" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
    ''';
  }

  static String generate() {
    const String baseUrl = "http://lg1:81/logos";
    // Posición y tamaño ajustados: bajado un poco, desplazado a la derecha y más ancho.
    // El valor de y=0 en el overlay asegura que el aspect ratio se mantenga en cualquier resolución.
    final String content = screenOverlayImage('$baseUrl/Logos.png', 0.02, 0.01, 0.71, 0.33);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>Logos Panel</name>
    <Folder>
      <name>Images</name>
      $content
    </Folder>
  </Document>
</kml>''';
  }
}
