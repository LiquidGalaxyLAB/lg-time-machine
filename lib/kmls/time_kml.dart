class TimeKML {
  static String generate(double timeValue) {
    // timeValue: 0 (Past), 1 (Present), 2 (Future)
    String timeString;
    if (timeValue < 0.5) {
      timeString = '1940-01-01'; // Simulated past date
    } else if (timeValue < 1.5) {
      timeString = '2024-01-01'; // Simulated present date
    } else {
      timeString = '2075-01-01'; // Simulated future date
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>Time State</name>
    <TimeStamp>
      <when>$timeString</when>
    </TimeStamp>
  </Document>
</kml>''';
  }
}
