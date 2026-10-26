import 'package:flutter/painting.dart';

/// The home greeting's text styles ('Good Evening,' / 'Healer' / subline),
/// shared so every home heading and subline uses the very same objects.
/// Giant poster words (TEJAS / AARO / GYA) keep their serif on purpose.
abstract final class HomeText {
  /// 'Good Evening,'
  static const hello = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    color: Color(0xA6FFFFFF),
    height: 1.15,
  );

  /// 'Healer': the heading style.
  static const heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: Color(0xFFFFFFFF),
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// "Ready for today's healing practice?"
  static const subline = TextStyle(fontSize: 13.5, color: Color(0x8CFFFFFF));
}
