import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/poi.dart';

class POIService {
  /// Carga los POIs combinando la metadata de Pois.json y las coordenadas de PointsOfInterestCords.csv
  Future<List<POI>> loadPOIs() async {
    try {
      // 1. Cargar y parsear el archivo CSV de coordenadas local
      final String csvString = await rootBundle.loadString('lib/services/PointsOfInterestCords.csv');
      List<List<dynamic>> csvRows = const CsvToListConverter().convert(csvString);
      
      if (csvRows.isEmpty) return [];
      final dataRows = csvRows.sublist(1); // Omitir cabecera

      // 2. Cargar metadata (nombres y descripciones) de Pois.json
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

            // 3. Buscar la fila en el CSV que coincida con este POI
            final csvRow = dataRows.firstWhere(
              (row) => row.isNotEmpty && 
                      (row[0].toString().trim().toLowerCase() == backendName.toLowerCase().replaceFirst('_', ' ') ||
                       row[0].toString().trim().toLowerCase() == displayName.toLowerCase().trim() ||
                       row[0].toString().trim() == backendName),
              orElse: () => [],
            );

            if (csvRow.isNotEmpty) {
              final String folderName = backendName.trim();
              
              // Definimos las rutas para ambas imágenes
              final String presentImagePath = 'assets/images/PointsOfInterest/$folderName/PresentImage.jpg';
              final String pastImagePath = 'assets/images/PointsOfInterest/$folderName/PastImage.jpg';
              
              final List<String> presentImages = [presentImagePath];
              final List<String> pastImages = [pastImagePath];

              // Función auxiliar para limpiar números
              double parseCsvNumber(dynamic value, double defaultValue) {
                if (value == null) return defaultValue;
                String cleanValue = value.toString().replaceAll(',', '.').trim();
                return double.tryParse(cleanValue) ?? defaultValue;
              }

              Map<String, dynamic> combinedData = {
                'name': displayName,
                'longitude': parseCsvNumber(csvRow.length > 1 ? csvRow[1] : 0.0, 0.0),
                'latitude': parseCsvNumber(csvRow.length > 2 ? csvRow[2] : 0.0, 0.0),
                'altitude': parseCsvNumber(csvRow.length > 3 ? csvRow[3] : 0.0, 0.0),
                'heading': parseCsvNumber(csvRow.length > 4 ? csvRow[4] : 0.0, 0.0),
                'tilt': parseCsvNumber(csvRow.length > 5 ? csvRow[5] : 0.0, 0.0),
                'range': parseCsvNumber(csvRow.length > 6 ? csvRow[6] : 1000.0, 1000.0),
                'altitudeMode': csvRow.length > 7 ? csvRow[7].toString().trim() : 'relativeToGround',
              };

              final metadata = {
                'country': country,
                'description': description,
              };

              // Ahora pasamos listas diferentes para pasado y presente
              pois.add(POI.fromJson(combinedData, metadata, pastImages, presentImages));
            }
          }
        }
      }

      return pois;
    } catch (e) {
      print('Error loading POIs from local CSV: $e');
      return [];
    }
  }
}
