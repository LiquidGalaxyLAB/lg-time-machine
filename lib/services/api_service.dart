import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';

class APIService {
  static final APIService instance = APIService._init();
  APIService._init();

  Future<Map<String, String?>> generateFutureEstimation(
    String poiName,
    String lang, {
    String? additivePrompt,
  }) async {
    final apiKey = await DatabaseHelper.instance.getSetting(
      'imageGenerationApiKey',
    );
    String model =
        await DatabaseHelper.instance.getSetting('imageGenerationModel') ??
        'sana';

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key not found in Settings');
    }

    // We run both generations in parallel to wait for both to finish
    final results = await Future.wait([
      _generateImage(poiName, model, apiKey, additivePrompt: additivePrompt),
      _generateText(poiName, apiKey, model, lang),
    ]);

    final imagePath = results[0];
    final statisticsText = results[1];

    if (statisticsText != null) {
      await saveFutureText(poiName, statisticsText, lang);
    }

    return {'imagePath': imagePath, 'statisticsText': statisticsText};
  }

  Future<String?> _generateImage(
    String poiName,
    String model,
    String apiKey, {
    String? additivePrompt,
  }) async {
    String prompt =
        "A high-quality architectural and environmental estimation of $poiName in the year 2100. Futuristic atmosphere, cinematic lighting, 8k resolution, aspect ratio 4:3, hyper-realistic, no text.";
    if (additivePrompt != null && additivePrompt.trim().isNotEmpty) {
      prompt += " Additional details: $additivePrompt";
    }
    final encodedPrompt = Uri.encodeComponent(prompt);
    final seed = Random().nextInt(1000000);

    bool isOpenAI = model.toLowerCase().contains('dall-e');

    if (!isOpenAI) {
      // Use Pollinations.ai for the specified models and others (flux, zimage, etc.)
      final encodedModel = Uri.encodeComponent(model);
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?model=$encodedModel&width=1024&height=768&seed=$seed&nologo=true';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        return await _saveImageBytesToCache(response.bodyBytes, poiName);
      } else {
        throw Exception(
          'Failed to generate image (Provider Status: ${response.statusCode})',
        );
      }
    } else {
      // OpenAI / DALL-E implementation
      try {
        final openAIModel = model.toLowerCase().contains('dall-e-2')
            ? 'dall-e-2'
            : 'dall-e-3';
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': openAIModel,
            'prompt': prompt,
            'n': 1,
            'size': '1024x1024',
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data['data'][0]['url'];
          final imageRes = await http.get(Uri.parse(imageUrl));
          return await _saveImageBytesToCache(imageRes.bodyBytes, poiName);
        } else {
          throw Exception(
            'API Error: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        throw Exception('Failed to connect to image API: $e');
      }
    }
  }

  Future<String?> _generateText(
    String poiName,
    String apiKey,
    String model,
    String lang,
  ) async {
    String languageName = "English";
    if (lang == 'es') languageName = "Spanish";
    if (lang == 'ca') languageName = "Catalan";

    final prompt =
        "Generate exactly 5 futuristic facts or statistics about $poiName in the year 2100 in $languageName. Format: list with dashes. Example:\n-Opened: 1893\n-Fact: description\nKeep it very concise. No conversational text.";

    bool isOpenAI =
        (model.toLowerCase().contains('gpt') &&
            !model.toLowerCase().contains('image')) ||
        model.toLowerCase().contains('dall-e');

    if (!isOpenAI) {
      try {
        final response = await http.post(
          Uri.parse('https://text.pollinations.ai/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'model':
                model, // Use the selected model name (e.g., flux, nano-banana)
            'seed': Random().nextInt(1000000),
          }),
        );
        if (response.statusCode == 200) {
          return response.body.trim();
        }
      } catch (_) {}
    } else {
      try {
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model.contains('gpt') ? model : 'gpt-4o-mini',
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'].trim();
        }
      } catch (_) {}
    }

    // Fallback if APIs fail
    if (lang == 'es') {
      return "-Estado en 2100: Preservación Avanzada\n-Energía: 100% Solar Cuántica\n-Estructura: Reforzada con nanotecnología\n-Medio ambiente: Bio-integrado\n-Acceso: Compatible con Realidad Virtual";
    } else if (lang == 'ca') {
      return "-Estat el 2100: Preservació Avançada\n-Energia: 100% Solar Quàntica\n-Estructura: Reforçada amb nanotecnologia\n-Medi ambient: Bio-integrat\n-Accés: Compatible amb Realitat Virtual";
    }
    return "-Status in 2100: Advanced Preservation\n-Energy: 100% Quantum Solar\n-Structure: Nanotech-reinforced\n-Environment: Bio-integrated\n-Access: Virtual Reality compatible";
  }

  Future<String?> _saveImageBytesToCache(
    List<int> bytes,
    String poiName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'future_${poiName.replaceAll(' ', '_').toLowerCase()}.jpg';
      final path = '${directory.path}/$fileName';
      final file = File(path);

      // Clear image cache from memory to force reload if the file is replaced
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (await file.exists()) {
        await file.delete();
        debugPrint('APIService: Deleted old image at $path');
      }

      await file.writeAsBytes(bytes);
      debugPrint('APIService: Saved new image at $path');
      return path;
    } catch (e) {
      debugPrint('Error saving image to cache: $e');
    }
    return null;
  }

  Future<void> saveFutureText(String poiName, String text, String lang) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'future_${poiName.replaceAll(' ', '_').toLowerCase()}_$lang.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(text);
  }

  Future<String?> getCachedFutureText(String poiName, String lang) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'future_${poiName.replaceAll(' ', '_').toLowerCase()}_$lang.txt';
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  Future<String?> getCachedFutureImage(String poiName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'future_${poiName.replaceAll(' ', '_').toLowerCase()}.jpg';
    final path = '${directory.path}/$fileName';
    final file = File(path);
    if (await file.exists()) {
      return path;
    }
    return null;
  }
}
