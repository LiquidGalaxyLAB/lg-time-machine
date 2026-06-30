import 'package:flutter/material.dart';
import 'screens/initial_splash_screen.dart';
import 'services/language_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Galaxy Time Machine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InitialSplashScreen(),
    );
  }
}
