/// Drop v4 type ramp — copies the normal-home greeting (sections_top.dart):
/// greet 19/w300 (light grey "Good Evening"), title 26/w800 ("Healer"),
/// sub 12.5/w400 (soft grey subline). Same DM Sans theme font, no italics.
/// On dark surfaces the same sizes/weights use light equivalents.
/// Only giant poster words keep the poster serif.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class V4Type {
  static TextStyle greet({bool dark = true}) =>
      TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: dark ? const Color(0xB3FFFFFF) : NwsbColors.inkSoft);
  static TextStyle title({bool dark = true}) =>
      TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dark ? Colors.white : NwsbColors.ink, height: 1.1);
  static TextStyle sub({bool dark = true}) =>
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: dark ? const Color(0xA6FFFFFF) : NwsbColors.inkFaint, height: 1.3);
  /// sub size, bold — for action words (underlined, never a chip).
  static TextStyle action({bool dark = true}) => sub(dark: dark).copyWith(
      fontWeight: FontWeight.w800,
      color: dark ? Colors.white : NwsbColors.ink,
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFC8A96E),
      decorationThickness: 2);
}
