/// Phone flags the settings screen can actually change.
library;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceFlags {
  DeviceFlags._();

  static const _channel = MethodChannel('com.nowssb.app/update');

  static Future<void> keepAwake(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepAwake', {'on': on});
    } catch (_) {}
  }

  static Future<void> applySaved() async {
    final prefs = await SharedPreferences.getInstance();
    await keepAwake(prefs.getBool('ss_screen_wake') ?? true);
  }
}
