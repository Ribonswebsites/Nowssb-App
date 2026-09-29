/// One glass look for the whole app.
///
/// `flutter_liquid_glass_plus` 0.0.7 (`LiquidGlassSettings`, `LGQuality`).
/// Dark charcoal base, soft white/silver highlights. Blur, tint and thickness
/// live here so screens do not invent their own.
///
/// [LGQuality.standard] is the scroll-safe backdrop path from the package.
/// [LGQuality.premium] is the shader path and is only used on fixed chrome
/// while [NwsbEffects.reduced] is false.
///
/// Screens that pick this up (nothing skipped that already uses shared chrome):
/// - Home Fashion, Home Normal — GlassWrap sections, nav, drawer
/// - Practice, Sound Library, Store, Profile — nav + GlassWrap / HeavyGlassPanel
/// - Practice player (Now Playing) — stage, chips, slider, icon buttons
/// - Player settings, sound settings, quick tools
/// - Earn, Gifts, Rewards, Bazaar, Vault, Wordprint, Echo wall
/// - Reader, sentence builder, subscriptions, app settings
/// - Notifications sheet and inbox
/// - Login / auth gate overlays that sit on GlassWrap
/// - Menu drawer — LGAppBar + HeavyGlassPanel groups
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

class NwsbGlassTheme {
  NwsbGlassTheme._();

  /// Charcoal glass. Thickness and blur are the app-wide defaults.
  static const settings = LiquidGlassSettings(
    thickness: 28,
    blur: 18,
    glassColor: Color(0x14FFFFFF),
    lightIntensity: 0.45,
    refractiveIndex: 1.18,
    saturation: 1.15,
    chromaticAberration: 0.02,
    ambientStrength: 0.08,
  );

  static const reducedSettings = LiquidGlassSettings(
    thickness: 8,
    blur: 6,
    glassColor: Color(0x10FFFFFF),
    lightIntensity: 0.2,
    refractiveIndex: 1.05,
    saturation: 1,
    chromaticAberration: 0,
  );

  static LiquidGlassSettings liveSettings(bool reduced) =>
      reduced ? reducedSettings : settings;

  static LGQuality qualityFor({required bool reduced, bool fixed = false}) {
    if (reduced || !fixed) return LGQuality.standard;
    return LGQuality.premium;
  }
}

/// Drops shader glass, the Siri orb and extra rings when frames get slow.
class NwsbEffects extends ChangeNotifier {
  NwsbEffects._();
  static final NwsbEffects instance = NwsbEffects._();

  bool reduced = false;
  int _slowFrames = 0;
  bool _bound = false;

  void bind() {
    if (_bound) return;
    _bound = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (reduced) return;
    var slow = 0;
    for (final t in timings) {
      final ms = t.totalSpan.inMicroseconds / 1000.0;
      if (ms > 28) slow++;
    }
    if (slow > 0) {
      _slowFrames += slow;
    } else {
      _slowFrames = _slowFrames > 0 ? _slowFrames - 1 : 0;
    }
    if (_slowFrames < 36) return;
    reduced = true;
    notifyListeners();
    debugPrint('NowssB: reduced effects — frames were above 28ms');
  }
}
