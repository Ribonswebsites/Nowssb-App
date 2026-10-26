/// The slice of the designer's door_kit.dart (door-screens 4c46c88) that
/// [FilmDial] uses — copied verbatim so the dial ships without the rest of
/// the door screens.
library;

import 'package:flutter/material.dart';

const doorGold = Color(0xFFC8A96E);
const doorGoldSoft = Color(0xFFE8D5A3);
const doorInk = Color(0xFF14100A);
const doorViolet = Color(0xFF7C4DDB);

/// Display type for giant words and numbers: Anton (condensed sans, upright).
TextStyle doorDisplay(double size, {Color color = Colors.white, double ls = -1}) => TextStyle(
    fontFamily: 'Anton', fontWeight: FontWeight.w400, fontSize: size, height: 1.0, color: color, letterSpacing: ls * .15);

TextStyle doorBody(double size, {Color color = Colors.white, FontWeight w = FontWeight.w600, double ls = 0}) =>
    TextStyle(fontFamily: 'DM Sans', fontSize: size, color: color, fontWeight: w, letterSpacing: ls, height: 1.25);
