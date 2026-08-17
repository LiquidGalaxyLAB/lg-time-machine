import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timemachine/models/country.dart';
import 'package:timemachine/screens/poi_screen.dart';
import 'package:timemachine/services/poi_service.dart';
import 'package:timemachine/services/language_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('POIService loads POIs', () async {
    POIService.clearCache();
    final pois = await POIService().loadPOIs();
    // ignore: avoid_print
    print('TOTAL POIs: ${pois.length}');
    expect(pois, isNotEmpty);
  });

  test('POIService loads POIs in Spanish', () async {
    LanguageManager.instance.languageNotifier.value = 'es';
    POIService.clearCache();
    final pois = await POIService().loadPOIs();
    // ignore: avoid_print
    print('TOTAL POIs (es): ${pois.length}');
    expect(pois, isNotEmpty);
  });

  testWidgets('POIScreen renders POIs for Spain', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    LanguageManager.instance.languageNotifier.value = 'en';
    POIService.clearCache();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: POIScreen(
            country: Country(name: 'Spain', flag: '🇪🇸'),
            isConnected: false,
          ),
        ),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
    });
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Sagrada'), findsWidgets);
  });
}
