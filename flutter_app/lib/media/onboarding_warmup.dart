/// Decodes the setup / onboarding pictures before the screens that show
/// them are on screen, so the Player Guide and Player Intro open with their
/// photograph and orb badge already painted instead of a blank navy plate.
///
/// Everything here is a bundled asset (assets/player/guide/ and
/// assets/player/intro/), sized at build time to what the screens draw —
/// the slides at their native 1024px width, the orb badges at 256px for a
/// 58dp circle — so warming them costs a decode, never a download.
///
/// The keys are plain [AssetImage]s: exactly what [NwsbImage] asks the
/// image cache for, so a warmed picture is a synchronous hit on first build.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/player_guide.dart';
import '../screens/player_intro.dart';

class OnboardingWarmup {
  OnboardingWarmup._();

  static bool _started = false;

  /// Called once while the splash plays. Warms only what a first-run user
  /// is about to meet: the whole Player Guide if it has not been seen, and
  /// the one Player Intro painting that screen will pick next.
  static Future<void> atLaunch(BuildContext context) async {
    if (_started) return;
    _started = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!context.mounted) return;
      final guideSeen = prefs.getBool(kPlayerGuideSeenKey) ?? false;
      final introSeen = prefs.getBool(kPlayerIntroSeenKey) ?? false;
      if (!guideSeen) unawaited(playerGuide(context));
      if (!introSeen) {
        unawaited(_warm(context, [playerIntroNextArt(prefs)]));
      }
    } catch (_) {
      // Warming is an optimisation; a failure here only means the screen
      // decodes its own picture, as it always did.
    }
  }

  /// The first slide and every orb badge first — that is the opening frame
  /// — then the remaining slides behind them.
  static Future<void> playerGuide(BuildContext context,
      {bool firstOnly = false}) async {
    final slides = kPlayerGuideSlides;
    if (slides.isEmpty) return;
    final icons = {for (final s in slides) s.icon}.toList();
    await _warm(context, [slides.first.img, ...icons]);
    if (firstOnly || !context.mounted) return;
    await _warm(context, [for (final s in slides.skip(1)) s.img]);
  }

  /// The Player Intro painting the next open will show.
  static Future<void> playerIntro(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!context.mounted) return;
      await _warm(context, [playerIntroNextArt(prefs)]);
    } catch (_) {}
  }

  static Future<void> _warm(BuildContext context, List<String> assets) {
    return Future.wait([
      for (final a in assets)
        if (context.mounted)
          precacheImage(AssetImage(a), context, onError: (_, __) {}),
    ]);
  }
}
