import 'package:flutter/material.dart';
import 'screens/initial_splash_screen.dart';
import 'services/language_manager.dart';
import 'services/font_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.instance.init();
  await FontManager.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: FontManager.instance.fontScaleNotifier,
      builder: (context, fontScale, child) {
        return MaterialApp(
          title: 'Liquid Galaxy Time Machine',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(fontScale)),
              child: child!,
            );
          },
          home: const InitialSplashScreen(),
        );
      },
    );
  }
}
