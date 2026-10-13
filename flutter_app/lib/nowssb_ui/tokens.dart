// NowssB glass design tokens (meditation-glass language).
// Drop into lib/theme/ and extend NwsbGlassTheme instead of hardcoding.
import 'package:flutter/material.dart';

class NTokens {
  NTokens._();
  // Background (deep indigo-violet)
  static const bgTop = Color(0xFF2A1B6B);
  static const bgMid = Color(0xFF3B2A9A);
  static const bgBottom = Color(0xFF120B3A);
  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF4B2A9E), bgMid, bgBottom],
  );
  // Glass
  static const glassTop = Color(0x38FFFFFF); // 22%
  static const glassBottom = Color(0x0FFFFFFF); // 6%
  static const glassLiteTop = Color(0x47FFFFFF); // lite = more opaque
  static const glassLiteBottom = Color(0x1AFFFFFF);
  static const border = Color(0x45FFFFFF); // ~27%
  static const highlight = Color(0x66FFFFFF);
  static const violetTint = Color(0x339C7BFF);
  // Accents
  static const violet = Color(0xFF8B5CF6);
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

  static List<BoxShadow> glow(Color accent, [double e = 1]) => [
        BoxShadow(color: accent.withValues(alpha: .35 * e), blurRadius: 30 * e, spreadRadius: -4),
        // Soft, inset-spread drop shadow so it never shows as a dark band through translucent glass.
        BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 28, spreadRadius: -10, offset: const Offset(0, 12)),
      ];
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
