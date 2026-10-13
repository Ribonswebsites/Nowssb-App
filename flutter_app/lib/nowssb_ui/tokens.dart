// NowssB glass design tokens (meditation-glass language).
// Drop into lib/theme/ and extend NwsbGlassTheme instead of hardcoding.
import 'package:flutter/material.dart';

class NTokens {
  NTokens._();
  // Background: neutral. Pages show the app's original AppBackdrop video.
  static const bgTop = Color(0xFF101114);
  static const bgMid = Color(0xFF0C0D10);
  static const bgBottom = Color(0xFF08090B);
  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
  );
  /// Card/panel tokens measured from card-reference-exact.png (W = card width).
  static const panelTop = Color(0x3DFFFFFF); // inner panel 24%
  static const panelBottom = Color(0x1FFFFFFF); // 12%
  static const cardBlur = 26.0;
  static const ink = Color(0xFF1A1630);
  static const bodyGrey = Color(0xA6FFFFFF); // 65%
  // Glass
  static const glassTop = Color(0x2EFFFFFF); // 18% (measured from card-reference-exact)
  static const glassBottom = Color(0x17FFFFFF); // 9%
  static const glassLiteTop = Color(0x40FFFFFF); // lite = more opaque (25%)
  static const glassLiteBottom = Color(0x26FFFFFF); // 15%
  static const border = Color(0x5CFFFFFF); // 36% soft white 1px
  static const highlight = Color(0x66FFFFFF);
  static const violetTint = Color(0x339C7BFF);
  // Accents
  static const violet = Color(0xFF8B5CF6);
  /// Neutral default accent for kit glass (no violet cast).
  static const neutral = Color(0xFFFFFFFF);
  static const indigoBtn = Color(0xFF6D4CFF);
  static const pink = Color(0xFFE879F9); // torus
  static const mint = Color(0xFF7FE7D6); // pill shape
  static const gold = Color(0xFFF5C451);
  static const coral = Color(0xFFFF8A7A);
  static const textHi = Colors.white;
  static const textLo = Color(0xB3FFFFFF);
  // Rarity accents
  static const common = Color(0xFF9FB4D8);
  static const rare = Color(0xFF4FD8F0);
  static const epic = Color(0xFFC05CF6);
  static const legendary = Color(0xFFF5B83D);
  // Gift tiles
  static const giftPink = Color(0xFFF472B6);
  static const giftViolet = Color(0xFF8B5CF6);
  static const giftAmber = Color(0xFFF59E0B);
  // Radii
  static const rHero = 30.0, rCard = 24.0, rBox = 18.0, rPill = 999.0;
  static const rPopupOuter = 36.0, rPopupInner = 28.0;
  // Blur sigmas
  static const blurLarge = 24.0, blurSheet = 28.0, blurBar = 18.0;
  // Motion
  static const press = 0.97;
  static const popIn = Duration(milliseconds: 220);
  static const popOut = Duration(milliseconds: 160);

  /// No shadows under glass: any shadow behind a translucent panel shows
  /// through as a dark inner band (seen in the renders). Glass reads from the
  /// border + fill + blur alone, like card-reference-exact.png.
  static List<BoxShadow> glow(Color accent, [double e = 1]) => const [];
}

enum Rarity { common, rare, epic, legendary }

extension RarityX on Rarity {
  Color get color => switch (this) {
        Rarity.common => NTokens.common,
        Rarity.rare => NTokens.rare,
        Rarity.epic => NTokens.epic,
        Rarity.legendary => NTokens.legendary,
      };
}
