/// Drop v4 type ramp — copies the normal-home greeting (sections_top.dart):
/// greet 19/w300 (light grey "Good Evening"), title 26/w800 ("Healer"),
/// sub 12.5/w400 (soft grey subline). Same DM Sans theme font, no italics.
/// On dark surfaces the same sizes/weights use light equivalents.
/// Giant poster words use Anton.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/home_text.dart';

class V4Type {
  // The shared home greeting styles (HomeText); light surfaces only swap
  // the colour.
  static TextStyle greet({bool dark = true}) =>
      dark ? HomeText.hello : HomeText.hello.copyWith(color: NwsbColors.inkSoft);
  static TextStyle title({bool dark = true}) =>
      dark ? HomeText.heading : HomeText.heading.copyWith(color: NwsbColors.ink);
  static TextStyle sub({bool dark = true}) =>
      dark ? HomeText.subline : HomeText.subline.copyWith(color: NwsbColors.inkFaint);
  /// sub size, bold — for action words (underlined, never a chip).
  static TextStyle action({bool dark = true}) => sub(dark: dark).copyWith(
      fontWeight: FontWeight.w800,
      color: dark ? Colors.white : NwsbColors.ink,
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFC8A96E),
      decorationThickness: 2);
}
