/// One place for the user app's motion and glass: the springs, the
/// durations and the glass looks every shared widget reads. Change a
/// number here and the bubbles, cards, sheets, dialogs, tabs and toasts
/// all move together.
///
/// The widgets that use these live in `widgets/glass_motion.dart`.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'liquid_glass_theme.dart' show NwsbEffects;

/// The springs. Mass 1 throughout; stiffness sets speed, damping sets bounce.
abstract final class NwsbSprings {
  /// Press and release of buttons, chips, cards and tabs. Quick, a hint of give.
  static const press = SpringDescription(mass: 1, stiffness: 520, damping: 26);

  /// Bubbles popping in. Bouncy on purpose: overshoots, wobbles, settles.
  static const pop = SpringDescription(mass: 1, stiffness: 340, damping: 13);

  /// Cards expanding into a sheet. Firm, a small overshoot.
  static const morph = SpringDescription(mass: 1, stiffness: 230, damping: 22);

  /// Dialogs and sheets arriving. Calm.
  static const settle = SpringDescription(mass: 1, stiffness: 300, damping: 26);

  /// Collapsing back. Critically damped (2 * sqrt(stiffness)): no bounce.
  static const collapse = SpringDescription(mass: 1, stiffness: 260, damping: 32.3);
}

/// Durations. Spring curves use these as their window, so pick one long
/// enough for the spring to come to rest.
abstract final class NwsbDurations {
  static const fade = Duration(milliseconds: 180);
  static const press = Duration(milliseconds: 260);
  static const pop = Duration(milliseconds: 900);
  static const morph = Duration(milliseconds: 620);
  static const collapse = Duration(milliseconds: 420);
  static const sheet = Duration(milliseconds: 460);
  static const dialog = Duration(milliseconds: 420);
  static const toast = Duration(milliseconds: 380);
}

/// A [Curve] that follows a spring from 0 to 1 over [duration]. It may pass
/// 1 (that's the bounce) and is pinned to exactly 1 at the end, so it can
/// drive an ordinary route or [AnimationController].
class SpringCurve extends Curve {
  const SpringCurve(this.spring, this.duration);

  final SpringDescription spring;
  final Duration duration;

  @override
  double transformInternal(double t) {
    final secs = duration.inMicroseconds / Duration.microsecondsPerSecond;
    return SpringSimulation(spring, 0, 1, 0).x(t * secs);
  }
}

/// The ready-made spring curves.
abstract final class NwsbSpringCurves {
  static const pop = SpringCurve(NwsbSprings.pop, NwsbDurations.pop);
  static const morph = SpringCurve(NwsbSprings.morph, NwsbDurations.morph);
  static const collapse = SpringCurve(NwsbSprings.collapse, NwsbDurations.collapse);
  static const settle = SpringCurve(NwsbSprings.settle, NwsbDurations.dialog);
  static const sheet = SpringCurve(NwsbSprings.settle, NwsbDurations.sheet);
}

/// One glass look: how much the backdrop blurs, the tint over it, the
/// hairline round the edge, and the corner radius.
@immutable
class NwsbGlassStyle {
  const NwsbGlassStyle({
    this.blur = 12,
    this.tint = const Color(0xB80B0B12),
    this.border = const Color(0x33FFFFFF),
    this.radius = 22,
    this.highlight = const Color(0x1FFFFFFF),
  });

  /// Backdrop blur sigma. Always read through [sigma], which caps it.
  final double blur;
  final Color tint;
  final Color border;
  final double radius;

  /// The soft sheen across the top edge.
  final Color highlight;

  /// The blur actually used: capped at [NwsbGlass.maxBlur], and lower when
  /// the app has dropped to reduced effects on a slow phone.
  double get sigma {
    final capped = math.min(blur, NwsbGlass.maxBlur);
    return NwsbEffects.instance.reduced ? capped * 0.5 : capped;
  }

  NwsbGlassStyle copyWith({double? blur, Color? tint, Color? border, double? radius, Color? highlight}) => NwsbGlassStyle(
        blur: blur ?? this.blur,
        tint: tint ?? this.tint,
        border: border ?? this.border,
        radius: radius ?? this.radius,
        highlight: highlight ?? this.highlight,
      );
}

/// The glass looks, and whether the real liquid-glass renderer can run.
abstract final class NwsbGlass {
  /// No glass in the app blurs harder than this. Big sigmas cost a lot on
  /// low-end GPUs and look muddy anyway.
  static const double maxBlur = 14;

  /// Quote and notification bubbles: dark, so gold and white copy stays legible.
  static const bubble = NwsbGlassStyle(blur: 12, tint: Color(0xC40B0B12), radius: 22);

  /// Cards and expanded cards.
  static const card = NwsbGlassStyle(blur: 14, tint: Color(0xCC0B0B12), radius: 24);

  /// Sheets and dialogs.
  static const sheet = NwsbGlassStyle(blur: 14, tint: Color(0xD90D0C14), radius: 28);

  /// Toasts / snack bars.
  static const toast = NwsbGlassStyle(blur: 10, tint: Color(0xE6141418), radius: 18);

  /// Tests set this: true or false forces the renderer on or off, null asks
  /// the engine.
  @visibleForTesting
  static bool? debugRendererOverride;

  /// True when liquid_glass_renderer can draw real refraction: Impeller
  /// (shader image filters), not web, and the app hasn't dropped to reduced
  /// effects. Otherwise the widgets use a plain BackdropFilter blur + tint.
  static bool get rendererAvailable {
    final forced = debugRendererOverride;
    if (forced != null) return forced;
    if (kIsWeb) return false;
    // Widget tests run without Impeller; never try the shader there.
    if (_inTest) return false;
    return ui.ImageFilter.isShaderFilterSupported && !NwsbEffects.instance.reduced;
  }

  static bool get _inTest {
    var test = false;
    assert(() {
      test = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      return true;
    }());
    return test;
  }
}

/// True when the user asked for less motion: Android's "remove
/// animations" or an accessibility service driving the screen. Shared
/// widgets then swap springs, scales and wobbles for a simple fade.
bool nwsbReduceMotion(BuildContext context) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);

/// The same springs and looks, reachable from the theme for anything that
/// prefers `Theme.of(context).extension<NwsbMotionTheme>()`.
@immutable
class NwsbMotionTheme extends ThemeExtension<NwsbMotionTheme> {
  const NwsbMotionTheme({
    this.press = NwsbSprings.press,
    this.pop = NwsbSprings.pop,
    this.morph = NwsbSprings.morph,
    this.bubble = NwsbGlass.bubble,
    this.card = NwsbGlass.card,
    this.sheet = NwsbGlass.sheet,
    this.toast = NwsbGlass.toast,
    this.pressScale = 0.96,
  });

  final SpringDescription press;
  final SpringDescription pop;
  final SpringDescription morph;
  final NwsbGlassStyle bubble;
  final NwsbGlassStyle card;
  final NwsbGlassStyle sheet;
  final NwsbGlassStyle toast;

  /// How far a pressed button, chip or card sinks.
  final double pressScale;

  static NwsbMotionTheme of(BuildContext context) =>
      Theme.of(context).extension<NwsbMotionTheme>() ?? const NwsbMotionTheme();

  @override
  NwsbMotionTheme copyWith({
    SpringDescription? press,
    SpringDescription? pop,
    SpringDescription? morph,
    NwsbGlassStyle? bubble,
    NwsbGlassStyle? card,
    NwsbGlassStyle? sheet,
    NwsbGlassStyle? toast,
    double? pressScale,
  }) =>
      NwsbMotionTheme(
        press: press ?? this.press,
        pop: pop ?? this.pop,
        morph: morph ?? this.morph,
        bubble: bubble ?? this.bubble,
        card: card ?? this.card,
        sheet: sheet ?? this.sheet,
        toast: toast ?? this.toast,
        pressScale: pressScale ?? this.pressScale,
      );

  @override
  NwsbMotionTheme lerp(ThemeExtension<NwsbMotionTheme>? other, double t) => t < 0.5 ? this : (other as NwsbMotionTheme? ?? this);
}
