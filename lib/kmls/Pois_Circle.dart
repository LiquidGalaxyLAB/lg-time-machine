import 'dart:math';
import '../models/poi.dart';

class PoisCircleKML {
  static String generate(POI poi) {
    double radius = _getRadiusForPoi(poi.name);
    String color = _getColorForCountry(poi.country);

    // Create the points for the circle
    int segments = 50;
    List<String> coordinates = [];

    for (int i = 0; i <= segments; i++) {
      double angle = 2 * pi * i / segments;
      double dx = radius * cos(angle);
      double dy = radius * sin(angle);

      // Approximate translation in degrees
      double lat = poi.latitude + (dy / 111320);
      double lon = poi.longitude + (dx / (111320 * cos(poi.latitude * pi / 180)));

      // We use altitude 100 so it's clearly visible as a 3D cylinder
      coordinates.add('$lon,$lat,100');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>POI Circle - ${poi.name}</name>
    <Style id="circleStyle">
      <LineStyle>
        <color>$color</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>$color</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>${poi.name} Boundary</name>
      <styleUrl>#circleStyle</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              ${coordinates.join('\n              ')}
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
  }

  static double _getRadiusForPoi(String name) {
    name = name.toLowerCase();
    // Smaller landmarks
    if (name.contains('liberty') || name.contains('libertad') ||
        name.contains('eiffel') ||
        name.contains('ben') ||
        name.contains('tokyo') || name.contains('tokio') ||
        name.contains('cn tower') ||
        name.contains('buckingham')) {
      return 150.0;
    }
    // Larger areas
    else if (name.contains('gate') ||
        name.contains('canyon') || name.contains('cañón') ||
        name.contains('yellowstone') ||
        name.contains('stonehenge') ||
        name.contains('pyramid') || name.contains('pirámide') ||
        name.contains('wall') || name.contains('muralla') ||
        name.contains('falls') || name.contains('iguazú') ||
        name.contains('uluru') ||
        name.contains('apostles') || name.contains('apóstoles')) {
      return 500.0;
    }
    // Medium structures
    else if (name.contains('sagrada') ||
        name.contains('louvre') ||
        name.contains('versailles') || name.contains('versalles') ||
        name.contains('notre-dame') ||
        name.contains('taj mahal') ||
        name.contains('parthenon') || name.contains('partenón') ||
        name.contains('alhambra')) {
      return 250.0;
    }
    // Squares and archaeological sites
    else if (name.contains('plaza') ||
        name.contains('machu picchu') ||
        name.contains('teotihuacán') || name.contains('teotihuacan') ||
        name.contains('chichén itzá') || name.contains('chichen itza') ||
        name.contains('pompeii') || name.contains('pompeya')) {
      return 350.0;
    }
    return 150.0;
  }

  static String _getColorForCountry(String country) {
    // KML color format: aabbggrr (hex)
    switch (country) {
      case 'United States':
        return '800000ff'; // Red (Semi-transparent)
      case 'Spain':
        return '8000a5ff'; // Orange
      case 'France':
        return '80ff0000'; // Blue
      case 'Italy':
        return '80008000'; // Green
      case 'United Kingdom':
        return '80800080'; // Purple
      case 'Germany':
        return '8000ffff'; // Yellow
      case 'Greece':
        return '80ffff00'; // Cyan
      case 'Egypt':
        return '8000458b'; // Brown/Sienna
      case 'China':
        return '800000aa'; // Dark Red
      case 'Japan':
        return '80b3b3ff'; // Light Pink
      case 'India':
        return '800080ff'; // Saffron
      case 'Brazil':
        return '8000cc00'; // Bright Green
      case 'Australia':
        return '8000d7ff'; // Gold
      case 'Mexico':
        return '80006600'; // Dark Green
      case 'Peru':
        return '800000cc'; // Crimson
      case 'Canada':
        return '800000ff'; // Red
      default:
        return '80ffffff'; // White
    }
  }
}
