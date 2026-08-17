import 'package:flutter_test/flutter_test.dart';
import 'package:timemachine/services/lg_service.dart';

void main() {
  test('generatePOIBoundaryKML produces valid circular wall KML', () {
    final kml = LGService.instance.generatePOIBoundaryKML(
      latitude: 40.9649549,
      longitude: -5.6639800,
      sizeMeters: 200.0,
      heightMeters: 15.0,
      country: 'Spain',
    );

    expect(kml, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
    // Cortina (LineString extruido): solo la pared, sin tapa ni cara superior.
    expect(kml, contains('<LineString>'));
    expect(kml, isNot(contains('<Polygon>')));
    expect(kml, isNot(contains('<MultiGeometry>')));
    // 48 puntos + el cierre = 49 coordenadas, todas a la altura del muro
    // (ninguna a 0: no hay borde inferior dibujado).
    final ring = kml.substring(
      kml.indexOf('<coordinates>'),
      kml.indexOf('</coordinates>'),
    );
    final points = ring
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.contains('<coordinates>'))
        .length;
    expect('$points', '49');
    expect(ring, isNot(contains(',0\n')));
    expect(ring, contains(',15.0'));
    expect(kml, contains('<extrude>1</extrude>'));
    expect(kml, contains('<tessellate>1</tessellate>'));
    expect(kml, contains('<color>9900FFFF</color>')); // amarillo 60% (pared)
    expect(kml, contains('<color>FF00FFFF</color>')); // amarillo opaco (borde)
    expect(kml, contains('relativeToGround'));
  });

  test('United States uses blue', () {
    final kml = LGService.instance.generatePOIBoundaryKML(
      latitude: 40.6892,
      longitude: -74.0445,
      country: 'United States',
    );
    // ABGR: '0000FF' (azul) -> AA=99, BB=FF, GG=00, RR=00
    expect(kml, contains('<color>99FF0000</color>'));
    expect(kml, contains('<color>FFFF0000</color>'));
  });

  test('unknown country falls back to teal', () {
    final kml = LGService.instance.generatePOIBoundaryKML(
      latitude: 0,
      longitude: 0,
      country: 'Atlantis',
    );
    // ABGR: '008080' (teal) -> AA=99, BB=80, GG=80, RR=00
    expect(kml, contains('<color>99808000</color>'));
  });

  test(
    'boundary scales with camera range so bigger landmarks get bigger circles',
    () {
      expect(LGService.boundarySizeMeters(1000.0), 200.0);
      expect(LGService.boundarySizeMeters(2000.0), 400.0);
      expect(LGService.boundarySizeMeters(5000.0), 1000.0);
      expect(LGService.boundarySizeMeters(10000.0), 2000.0);
      // Valores extremos se limitan (clamp): 500 m -> 100 m sube a 150 m
      expect(LGService.boundarySizeMeters(500.0), 150.0);
      expect(LGService.boundarySizeMeters(100000.0), 3000.0);

      expect(LGService.boundaryHeightMeters(1000.0), 15.0);
      expect(LGService.boundaryHeightMeters(2000.0), 30.0);
      expect(LGService.boundaryHeightMeters(500.0), 12.0);
      expect(LGService.boundaryHeightMeters(10000.0), 60.0);
    },
  );
}
