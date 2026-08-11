import '../models/poi.dart';

class StatisticsOverlayKML {
  static String generate({
    required POI poi,
    required String statisticsText,
    required String viewType, // e.g., "PRESENT VIEW", "PAST VIEW", "FUTURE VIEW"
  }) {
    // Ensure space after hyphens and handle newlines for HTML
    final String formattedStats = statisticsText
        .split('\n')
        .map((line) => line.trim().startsWith('-')
            ? '- ${line.trim().substring(1).trim()}'
            : line)
        .join('<br/>');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document id="stats_doc">
    <name>Statistics Balloon</name>
    <Style id="stats_style">
      <BalloonStyle>
        <text>
          <![CDATA[
            <div style="width: 850px; font-family: 'Arial', sans-serif; background-color: white; padding: 0; margin: 0; border-radius: 25px; overflow: hidden;">
              <div style="padding: 50px; color: #333;">
                <h0 style="margin: 0 0 10px 0; font-size: 72px; color: #3498db; font-weight: bold; text-transform: uppercase; display: block;">$viewType</h0>
                <h1 style="margin: 0 0 25px 0; font-size: 56px; color: #2c3e50; border-bottom: 7px solid #3498db; padding-bottom: 12px; text-transform: uppercase;">${poi.name}</h1>
                <div style="font-size: 38px; line-height: 1.6; color: #444;">
                  $formattedStats
                </div>
              </div>
            </div>
          ]]>
        </text>
        <bgColor>ffffffff</bgColor>
      </BalloonStyle>
      <IconStyle>
        <scale>0</scale>
      </IconStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
    </Style>

    <Placemark id="stats_placemark">
      <name>${poi.name}</name>
      <styleUrl>#stats_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>${poi.longitude},${poi.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }
}
