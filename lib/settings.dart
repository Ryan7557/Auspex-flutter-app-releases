import 'package:flutter/material.dart';

class NotificationSettings {
  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibration;
  final TimeOfDay checkTime;

  const NotificationSettings({
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.checkTime = const TimeOfDay(hour: 9, minute: 0),
  });
}
