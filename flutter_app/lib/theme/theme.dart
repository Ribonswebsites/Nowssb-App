/// The two surfaces this app has, as ThemeData.
///
/// The website carries both at once — #home-nm is the light neumorphic
/// surface, everything else is the deep navy — and it switches between them
/// per screen rather than per app. Flutter's Theme does the same job, so
/// each screen picks the one it belongs to instead of the app having a
/// single global mode.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class NwsbTheme {
  NwsbTheme._();

  /// DM Sans, which is what every screen on the website asks for
  /// (`font-family: 'DM Sans', sans-serif`, loaded from Google Fonts).
  static TextTheme _text(Color ink, Color soft) => GoogleFonts.dmSansTextTheme(
        TextTheme(
          // .nmh-greet-name — "Healer"
          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ink,
            height: 1.15,
          ),
          // .nmh-streak-heading, .nmh-practice-word
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ink,
            height: 1.2,
          ),
          // .nmh-tile-title
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          // body copy — .nmh-practice-meaning, .nmh-tile-sub
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: soft,
            height: 1.55,
          ),
          // the gold eyebrow — .nmh-practice-label
          labelSmall: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: NwsbColors.gold,
          ),
        ),
      );

  /// The Normal home. Light, neumorphic, ink on #f0f2f7.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: NwsbColors.surface,
        colorScheme: const ColorScheme.light(
          primary: NwsbColors.gold,
          surface: NwsbColors.surface,
          onSurface: NwsbColors.ink,
        ),
        textTheme: _text(NwsbColors.ink, NwsbColors.inkSoft),
        cardTheme: const CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))),
        dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)))),
        bottomSheetTheme: const BottomSheetThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
        splashFactory: NoSplash.splashFactory,
      );

  /// Everything else. Deep navy, pale copy, gold accents.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: NwsbColors.deep,
        colorScheme: const ColorScheme.dark(
          primary: NwsbColors.goldLight,
          surface: NwsbColors.deep,
          onSurface: Colors.white,
        ),
        textTheme: _text(Colors.white, const Color(0xB3C8E8F5)),
        cardTheme: const CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))),
        dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)))),
        bottomSheetTheme: const BottomSheetThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
        splashFactory: NoSplash.splashFactory,
      );
}
