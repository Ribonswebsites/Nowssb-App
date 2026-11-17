/// One door for every buzz in the app.
///
/// A haptic only goes out for a real finger action — a button tap, or a
/// swipe that settles on a new page. Timers, auto-advance, scroll ticks
/// and rebuilds stay quiet. At most one buzz every 150 ms, and none at
/// all when Profile > Sound Feedback is off.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppHaptics {
  AppHaptics._();

  static const Duration throttle = Duration(milliseconds: 150);

  /// The Profile > Sound Feedback preference. Same key the practice
  /// completion click uses.
  static const String soundPrefKey = 'nowssb_sound';

  static DateTime? _last;
  static bool? _debugEnabled;
  static SharedPreferences? _prefs;

  /// Load the Sound Feedback preference so later calls have a real answer.
  static Future<void> preload() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}
  }

  /// Keep the cache in step when the Profile toggle moves.
  static void syncFromPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Test hook. `null` goes back to reading the preference.
  @visibleForTesting
  static void debugEnabled(bool? value) => _debugEnabled = value;

  @visibleForTesting
  static void debugReset() {
    _last = null;
    _debugEnabled = null;
  }

  static bool get soundOn {
    if (_debugEnabled != null) return _debugEnabled!;
    if (_prefs == null) unawaited(preload());
    return _prefs?.getString(soundPrefKey) != 'off';
  }

  static bool _gate() {
    if (!soundOn) return false;
    final now = DateTime.now();
    final last = _last;
    if (last != null && now.difference(last) < throttle) return false;
    _last = now;
    return true;
  }

  static Future<void> selection() async {
    if (!_gate()) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> light() async {
    if (!_gate()) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!_gate()) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    if (!_gate()) return;
    await HapticFeedback.heavyImpact();
  }
}

/// Tells [onPageChanged] whether the current move was started by a finger.
///
/// [ScrollStartNotification.dragDetails] is set only for a drag, not for
/// [PageController.animateToPage] or [PageController.jumpToPage], so an
/// auto-rotating carousel can settle on a new page without buzzing.
class UserPageHapticGate {
  var _fromFinger = false;

  bool onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification) {
      _fromFinger = n.dragDetails != null;
    }
    return false;
  }

  void onPageChanged() {
    if (_fromFinger) AppHaptics.selection();
  }
}
