import '../models/poi.dart';
import '../services/language_manager.dart';

class ComparisonOverlayKML {
  static String generate({
    required POI poi,
    String? futureStats,
    bool isFuture = false,
  }) {
    final String pastStatsLabel = isFuture
        ? LanguageManager.instance.translate('estimation_in_2100').toUpperCase()
        : LanguageManager.instance.translate('past').toUpperCase();
    final String presentLabel =
        LanguageManager.instance.translate('present').toUpperCase();
    final String summaryLabel =
        LanguageManager.instance.translate('summary').toUpperCase();

    String formatList(String text) {
      return text
          .split('\n')
          .map((line) => line.trim().startsWith('-')
              ? '- ${line.trim().substring(1).trim()}'
              : line)
          .join('<br/>');
    }

    final String escapedPastStats =
        formatList(isFuture ? (futureStats ?? '') : poi.statisticsTextPast);
    final String escapedPresentStats = formatList(poi.statisticsTextPresent);
    final String summary = formatList(poi.comparisonSummary);

    final String comparisonTitle = isFuture
        ? LanguageManager.instance.translate('future_present_comparison')
        : LanguageManager.instance.translate('past_present_comparison');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document id="comp_doc">
    <name>Comparison Balloon</name>
    <Style id="comp_style">
      <BalloonStyle>
        <text>
          <![CDATA[
            <div style="width: 800px; font-family: 'Arial', sans-serif; background-color: white; padding: 40px; margin: 0; border-radius: 25px; overflow: hidden;">
              <h3 style="margin: 0; font-size: 32px; color: #7f8c8d; text-align: center; text-transform: uppercase; letter-spacing: 2px;">$comparisonTitle</h3>
              <h1 style="margin: 10px 0 25px 0; font-size: 56px; color: #2c3e50; border-bottom: 7px solid #3498db; padding-bottom: 12px; text-transform: uppercase; text-align: center;">${poi.name}</h1>
              
              <div style="display: flex; justify-content: space-between; margin-bottom: 30px;">
                <div style="width: 47%;">
                  <h2 style="font-size: 36px; color: #e67e22; margin-bottom: 15px; text-align: center; border-bottom: 3px solid #eee;">$pastStatsLabel</h2>
                  <div style="font-size: 26px; line-height: 1.6; color: #555;">
                    $escapedPastStats
                  </div>
                </div>
                
                <div style="width: 3px; background-color: #ddd; margin: 0 20px;"></div>
                
                <div style="width: 47%;">
                  <h2 style="font-size: 36px; color: #27ae60; margin-bottom: 15px; text-align: center; border-bottom: 3px solid #eee;">$presentLabel</h2>
                  <div style="font-size: 26px; line-height: 1.6; color: #555;">
                    $escapedPresentStats
                  </div>
                </div>
              </div>

              <div style="margin-top: 30px; padding-top: 20px; border-top: 4px solid #3498db;">
                <h2 style="font-size: 36px; color: #2c3e50; margin-bottom: 15px; text-align: center;">$summaryLabel</h2>
                <div style="font-size: 32px; line-height: 1.6; color: #333; text-align: justify; font-style: italic;">
                  $summary
                </div>
              </div>
            </div>
          ]]>
        </text>
        <bgColor>ffffffff</bgColor>
      </BalloonStyle>
      <IconStyle><scale>0</scale></IconStyle>
      <LabelStyle><scale>0</scale></LabelStyle>
    </Style>

    <Placemark id="comp_placemark">
      <name>${poi.name} Comparison</name>
      <styleUrl>#comp_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>${poi.longitude},${poi.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }
}
