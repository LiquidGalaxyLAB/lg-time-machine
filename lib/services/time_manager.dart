import 'package:flutter/material.dart';

class TimeManager {
  static final TimeManager instance = TimeManager._init();
  TimeManager._init();

  final ValueNotifier<double> timeNotifier = ValueNotifier(1.0); // 0: Past, 1: Present, 2: Future

  double get timeValue => timeNotifier.value;

  void setTime(double value) {
    timeNotifier.value = value;
  }
}
