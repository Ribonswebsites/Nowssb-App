/// UD-0: spacing, radius and type tokens for the minimal / meditative pass
/// (brief 2026-10-12). Values only — colours come from [NwsbColors] and
/// [GlassWrap]; the font family is inherited from the app theme (DM Sans via
/// `NwsbTheme`), so these styles carry no `fontFamily` of their own.
library;

import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Spacing scale: 4 / 8 / 12 / 16 / 24 / 32.
abstract final class UiSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. [card] matches `kGlassRadius` (18) so new wrappers sit
/// beside existing glass panels without a visible change in rhythm.
abstract final class UiRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double card = 18;
  static const double lg = 24;
  static const double pill = 999;
}

/// Text styles derived from the current theme sizes/weights.
abstract final class UiType {
  /// Page / hero title (matches PageShell's 28/w800).
  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: Color(0xFFFFFFFF),
  );

  /// Section header inside a card or above a row.
  static const sectionHeader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
    color: NwsbColors.goldLight,
  );

  /// Body copy on dark.
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xCCFFFFFF),
  );

  /// Caption / eyebrow-sized secondary copy.
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
    color: Color(0x99FFFFFF),
  );
}
