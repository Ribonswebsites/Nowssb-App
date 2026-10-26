/// The one choice chip for dark/photo backdrops (Fashion Plus Background and
/// Start art, Vault word picker).
///
/// Root cause of the white-on-white chips: the app runs the LIGHT Material 3
/// theme, and an M3 [ChoiceChip] paints its own Material in the theme surface
/// (#F0F2F7) *under* `backgroundColor`. A translucent fill such as
/// `Color(0x1FFFFFFF)` was therefore composited on near-white, and the white
/// label vanished. This chip sets an OPAQUE fill through `color` for every
/// state, so nothing from the theme shows through, and its colour pairs are
/// checked for ≥ 4.5:1 contrast in test/nwsb_choice_chip_test.dart.
library;

import 'package:flutter/material.dart';

import '../theme/contrast.dart';
import '../theme/tokens.dart';

export '../theme/contrast.dart';

class NwsbChoiceChip extends StatelessWidget {
  const NwsbChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.showCheckmark = true,
    this.fontSize = 11,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showCheckmark;
  final double fontSize;

  /// Opaque fills and their text colours.
  static const unselectedFill = Color(0xFF1C1828);
  static const unselectedText = Colors.white;
  static const selectedFill = NwsbColors.goldLight;
  static const selectedText = NwsbColors.deep;
  static const border = Color(0x66E4C56A);

  static Color fill(bool selected) => selected ? selectedFill : unselectedFill;
  static Color text(bool selected) => selected ? selectedText : unselectedText;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
        showCheckmark: showCheckmark,
        checkmarkColor: selectedText,
        color: WidgetStateProperty.resolveWith(
            (s) => fill(s.contains(WidgetState.selected))),
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: text(selected),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      );
}
