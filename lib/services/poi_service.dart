import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/poi.dart';
import 'language_manager.dart';

class POIService {
  static List<POI>? _cachedPois;

  /// Carga los POIs combinando la metadata de Pois.json y las coordenadas de PointsOfInterestCords.csv
  Future<List<POI>> loadPOIs() async {
    final String lang = LanguageManager.instance.currentLanguage;
    
    // Si ya tenemos cache, devolverla
    if (_cachedPois != null) {
      return _cachedPois!;
    }

    try {
      // 1. Cargar y parsear el archivo CSV de coordenadas local
      final String csvString = await rootBundle.loadString(
        'lib/services/PointsOfInterestCords.csv',
      );
      
      List<List<dynamic>> csvRows = const CsvToListConverter().convert(csvString);
      if (csvRows.isEmpty) return [];

      // Create a map for faster lookup: ID -> Row
      final Map<String, List<dynamic>> csvMap = {};
      
      // El ID siempre está en la primera columna según el formato observado
      final dataRows = csvRows.length > 1 ? csvRows.sublist(1) : <List<dynamic>>[];
      
      for (var row in dataRows) {
        if (row.isNotEmpty && row[0] != null && row[0].toString().isNotEmpty) {
          final String id = row[0].toString().trim().toLowerCase();
          csvMap[id] = row;
        }
      }

      // 2. Cargar metadata maestra (English) para estructura y datos base
      final String masterJsonString = await rootBundle.loadString(
        'lib/services/Pois.json',
      );
      final Map<String, dynamic> masterMetadata = json.decode(masterJsonString);

      // 3. Cargar metadata localizada si existe y no es inglés (solo para name y description)
      Map<String, dynamic>? localizedMetadata;
      if (lang != 'en') {
        try {
          String localizedFileName = 'Pois_$lang.json';
          final String localizedJsonString = await rootBundle.loadString(
            'lib/services/$localizedFileName',
          );
          localizedMetadata = json.decode(localizedJsonString);
        } catch (e) {
          print('Localized POI file not found for $lang, using English strings.');
        }
      }

      List<POI> pois = [];

      for (var countryEntry in masterMetadata.entries) {
        final englishCountryName = countryEntry.key; // e.g., "United States"
        final poiMap = countryEntry.value;

        if (poiMap is Map) {
          for (var poiEntry in poiMap.entries) {
            final backendId = poiEntry.key; // e.g., Statue_of_Liberty
            final masterPoiData = poiEntry.value as Map<String, dynamic>;
            
            // Intentar obtener datos localizados (solo name y description)
            Map<String, dynamic>? localizedPoiData;
            if (localizedMetadata != null) {
              var localizedCountryMap = localizedMetadata[englishCountryName];
              if (localizedCountryMap is Map) {
                localizedPoiData = localizedCountryMap[backendId] as Map<String, dynamic>?;
              }
            }

            final displayName = localizedPoiData?['name'] ?? masterPoiData['name'] ?? backendId;
            final description = localizedPoiData?['description'] ?? masterPoiData['description'] ?? '';

            // 4. Buscar la fila en el CSV que coincida con este POI
            final lookupKey = backendId.trim().toLowerCase();
            final alternateKey1 = lookupKey.replaceAll('_', ' ');
            final alternateKey2 = displayName.toString().trim().toLowerCase();
            final alternateKey3 = (masterPoiData['name'] ?? '').toString().trim().toLowerCase();

            List<dynamic>? csvRow = csvMap[lookupKey] ?? 
                                    csvMap[alternateKey1] ?? 
                                    csvMap[alternateKey2] ??
                                    csvMap[alternateKey3];

            if (csvRow != null) {
              final String fileNameBase = backendId.trim();

              final String presentImagePath =
                  'assets/images/PointsOfInterest/${fileNameBase}_Present.jpg';
              final String pastImagePath =
                  'assets/images/PointsOfInterest/${fileNameBase}_Past.jpg';

              final List<String> presentImages = [presentImagePath];
              final List<String> pastImages = [pastImagePath];

              double parseCsvNumber(dynamic value, double defaultValue) {
                if (value == null) return defaultValue;
                if (value is num) return value.toDouble();
                String cleanValue = value.toString().replaceAll(',', '.').trim();
                return double.tryParse(cleanValue) ?? defaultValue;
              }

              // Basado en el CSV: ID=0, Lon=1, Lat=2, Alt=3, Head=4, Tilt=5, Range=6, Mode=7
              Map<String, dynamic> combinedData = {
                'name': displayName,
                'longitude': parseCsvNumber(csvRow.length > 1 ? csvRow[1] : 0.0, 0.0),
                'latitude': parseCsvNumber(csvRow.length > 2 ? csvRow[2] : 0.0, 0.0),
                'altitude': parseCsvNumber(csvRow.length > 3 ? csvRow[3] : 0.0, 0.0),
                'heading': parseCsvNumber(csvRow.length > 4 ? csvRow[4] : 0.0, 0.0),
                'tilt': parseCsvNumber(csvRow.length > 5 ? csvRow[5] : 0.0, 0.0),
                'range': parseCsvNumber(csvRow.length > 6 ? csvRow[6] : 1000.0, 1000.0),
                'altitudeMode': csvRow.length > 7
                    ? csvRow[7].toString().trim()
                    : 'relativeToGround',
              };

              final metadata = {
                'country': englishCountryName, // Siempre usamos el nombre en inglés para lógica interna
                'description': description,
                'statistics_text_present': masterPoiData['statistics_text_present'] ?? '',
                'statistics_text_past': masterPoiData['statistics_text_past'] ?? '',
                'past_comparison_summary': masterPoiData['past_comparison_summary'] ?? '',
              };

              pois.add(
                POI.fromJson(combinedData, metadata, pastImages, presentImages),
              );
            }
          }
        }
      }

      _cachedPois = pois;
      return pois;
    } catch (e) {
      print('Error loading POIs in POIService: $e');
      return [];
    }
  }

  /// Limpia el cache si es necesario
  static void clearCache() {
    _cachedPois = null;
  }
}
