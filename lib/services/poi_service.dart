import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/poi.dart';

class POIService {
  // Datos exportados directamente desde el CSV de Google Sheets para uso offline/local
  static const List<Map<String, dynamic>> _localPoisData = [
    {
      "backendName": "Plaza_Mayor_de_Salamanca",
      "longitude": -5.6639222,
      "latitude": 40.9650099,
      "altitude": 797.1768325,
      "heading": 107.6300761,
      "tilt": 40.0227249,
      "range": 188.5190025,
      "altitudeMode": "relativeToGround"
    },
    {
      "backendName": "Sagrada_Familia",
      "longitude": 2.1739006,
      "latitude": 41.4034299,
      "altitude": 95.6508464,
      "heading": 9.5377605,
      "tilt": 59.4242461,
      "range": 551.3130864,
      "altitudeMode": "relativeToGround"
    },
    {
      "backendName": "Cathedral_of_Santiago_de_Compostela",
      "longitude": -8.5446961,
      "latitude": 42.8807417,
      "altitude": 278.4591306,
      "heading": 54.1152332,
      "tilt": 64.9304054,
      "range": 428.6393375,
      "altitudeMode": "relativeToGround"
    }
  ];

  Future<List<POI>> loadPOIs() async {
    try {
      // 1. Cargar metadata (nombres y descripciones) de Pois.json
      final String poisJsonString = await rootBundle.loadString('lib/services/Pois.json');
      final Map<String, dynamic> poisMetadata = json.decode(poisJsonString);

      List<POI> pois = [];

      for (var countryEntry in poisMetadata.entries) {
        final country = countryEntry.key;
        final poiMap = countryEntry.value;

        if (poiMap is Map) {
          for (var poiEntry in poiMap.entries) {
            final backendName = poiEntry.key;
            final poiData = poiEntry.value as Map<String, dynamic>;
            final displayName = poiData['name'] ?? backendName;
            final description = poiData['description'] ?? '';

            // Buscar coordenadas en los datos locales por backendName
            final localData = _localPoisData.firstWhere(
              (data) => data['backendName'] == backendName,
              orElse: () => {},
            );

            if (localData.isNotEmpty) {
              final String folderName = backendName.trim();
              final String presentImagePath = 'assets/images/PointsOfInterest/$folderName/PresentImage.jpg';
              
              final List<String> images = [presentImagePath];

              Map<String, dynamic> combinedData = {
                'name': displayName,
                'longitude': localData['longitude'],
                'latitude': localData['latitude'],
                'altitude': localData['altitude'],
                'heading': localData['heading'],
                'tilt': localData['tilt'],
                'range': localData['range'],
                'altitudeMode': localData['altitudeMode'],
              };

              final metadata = {
                'country': country,
                'description': description,
              };

              pois.add(POI.fromJson(combinedData, metadata, images, images));
            }
          }
        }
      }

      return pois;
    } catch (e) {
      print('Error loading POIs: $e');
      return [];
    }
  }
}
