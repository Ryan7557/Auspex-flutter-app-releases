import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  bool _enableNotifications = true;
  bool _enableSound = true;
  bool _enableVibration = true;
  TimeOfDay _checkTime = const TimeOfDay(hour: 9, minute: 0);

  bool get enableNotifications => _enableNotifications;
  bool get enableSound => _enableSound;
  bool get enableVibration => _enableVibration;
  TimeOfDay get checkTime => _checkTime;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    _enableSound = prefs.getBool('enableSound') ?? true;
    _enableVibration = prefs.getBool('enableVibration') ?? true;
    final hour = prefs.getInt('checkTimeHour') ?? 9;
    final minute = prefs.getInt('checkTimeMinute') ?? 0;
    _checkTime = TimeOfDay(hour: hour, minute: minute);
    notifyListeners();
  }

  Future<void> updateSettings({
    bool? enableNotifications,
    bool? enableSound,
    bool? enableVibration,
    TimeOfDay? checkTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (enableNotifications != null) {
      _enableNotifications = enableNotifications;
      await prefs.setBool('enableNotifications', enableNotifications);
    }

    if (enableSound != null) {
      _enableSound = enableSound;
      await prefs.setBool('enableSound', enableSound);
    }

    if (enableVibration != null) {
      _enableVibration = enableVibration;
      await prefs.setBool('enableVibration', enableVibration);
    }

    if (checkTime != null) {
      _checkTime = checkTime;
      await prefs.setInt('checkTimeHour', checkTime.hour);
      await prefs.setInt('checkTimeMinute', checkTime.minute);
    }

    notifyListeners();
  }
}
