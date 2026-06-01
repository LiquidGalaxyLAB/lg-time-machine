import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/poi.dart';

class POIService {
  static const String _sheetUrl = 'https://docs.google.com/spreadsheets/d/18fQdNU1iFAfc7dZ_E8nTH7ZriOgfakaxubHKqN7fwho/export?format=csv';

  Future<List<POI>> loadPOIs() async {
    try {
      // 1. Fetch CSV from Google Sheets
      final response = await http.get(Uri.parse(_sheetUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load coordinates from Google Sheets');
      }

      final csvData = response.body;
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

      if (rows.isEmpty) return [];

      // Assuming first row is header: name, latitude, longitude, altitude, heading, tilt, range, altitudeMode
      final header = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
      final dataRows = rows.sublist(1);

      List<POI> pois = [];

      // 2. Load metadata from Pois.json
      final String poisJsonString = await rootBundle.loadString('lib/services/Pois.json');
      final Map<String, dynamic> poisMetadata = json.decode(poisJsonString);

      // 3. Scan assets for image paths
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      poisMetadata.forEach((country, poiMap) {
        if (poiMap is Map) {
          poiMap.forEach((poiName, description) {
            // Find coordinate data in CSV by matching the name
            final csvRow = dataRows.firstWhere(
              (row) => row.isNotEmpty && row[0].toString().trim().toLowerCase() == poiName.toString().toLowerCase().trim(),
              orElse: () => [],
            );

            if (csvRow.isNotEmpty) {
              // Find PresentImage (supports .png and .jpg)
              final String presentImagePath = allAssets.firstWhere(
                (path) => 
                  path.toLowerCase() == 'assets/pointsofinterest/$poiName/images/present/presentimage.png'.toLowerCase() ||
                  path.toLowerCase() == 'assets/pointsofinterest/$poiName/images/present/presentimage.jpg'.toLowerCase() ||
                  path.startsWith('assets/PointsOfInterest/$poiName/Images/Present/PresentImage.jpg'),
                orElse: () => '',
              );

              final List<String> images = presentImagePath.isNotEmpty ? [presentImagePath] : [];

              // Build POI object
              Map<String, dynamic> csvMap = {};
              for (int i = 0; i < header.length; i++) {
                if (i < csvRow.length) {
                  csvMap[header[i]] = csvRow[i];
                }
              }
              
              // Ensure 'name' is in the map for POI.fromJson if it wasn't in CSV
              if (!csvMap.containsKey('name') || csvMap['name'] == null) {
                csvMap['name'] = poiName;
              }

              final metadata = {
                'country': country,
                'description': description,
              };

              // Use present images for both past and present as requested
              pois.add(POI.fromJson(csvMap, metadata, images, images));
            }
          });
        }
      });

      return pois;
    } catch (e) {
      print('Error loading POIs: $e');
      return [];
    }
  }
}
