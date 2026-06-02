import 'package:flutter/material.dart';
import '../kmls/time_kml.dart';
import '../database/db_helper.dart';
import 'lg_service.dart';

class TimeManager {
  static final TimeManager instance = TimeManager._init();
  TimeManager._init();

  final ValueNotifier<double> timeNotifier = ValueNotifier(
    1.0,
  ); // 0: Past, 1: Present, 2: Future

  double get timeValue => timeNotifier.value;

  String getTimeState() {
    if (timeValue == 0) return 'past';
    if (timeValue == 1) return 'present';
    return 'future';
  }

  void setTime(double value) {
    timeNotifier.value = value;
    _saveTimeState(value);
    _updateLGTime(value);
  }

  Future<void> _saveTimeState(double value) async {
    String state = 'present';
    if (value == 0)
      state = 'past';
    else if (value == 2)
      state = 'future';

    await DatabaseHelper.instance.saveSetting('time_state', state);
  }

  Future<void> _updateLGTime(double value) async {
    if (LGService.instance.isConnected) {
      final kml = TimeKML.generate(value);
      await LGService.instance.sendTimeKML(kml);
    }
  }
}
