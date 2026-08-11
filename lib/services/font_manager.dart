import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class FontManager {
  static final FontManager instance = FontManager._init();
  FontManager._init();

  final ValueNotifier<double> fontScaleNotifier = ValueNotifier(1.0);

  Future<void> init() async {
    final savedScale = await DatabaseHelper.instance.getSetting('font_scale');
    if (savedScale != null) {
      fontScaleNotifier.value = double.tryParse(savedScale) ?? 1.0;
    }
  }

  Future<void> setFontScale(double scale) async {
    fontScaleNotifier.value = scale;
    await DatabaseHelper.instance.saveSetting('font_scale', scale.toString());
  }
}
