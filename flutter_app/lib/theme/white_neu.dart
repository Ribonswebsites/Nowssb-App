import 'package:flutter/material.dart';

import '../widgets/home_skin.dart';
import 'tokens.dart';

/// Ribon's rule: the Normal home is all white neumorphism.
/// [onNormal] is true when a widget is painted inside the Normal home.
bool onNormal(BuildContext context) => HomeSkinScope.of(context) == HomeSkin.normal;

/// White raised neumorphic surface used for pills, plates and cards.
const wnSurface = NwsbColors.surface;
const wnInk = NwsbColors.ink;
const wnShadow = <BoxShadow>[
  BoxShadow(color: Color(0x26000000), offset: Offset(5, 5), blurRadius: 12),
  BoxShadow(color: Color(0xFAFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
];
const wnShadowDown = <BoxShadow>[
  BoxShadow(color: Color(0x1F000000), offset: Offset(2, 2), blurRadius: 4),
  BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-2, -2), blurRadius: 4),
];

BoxDecoration wnBox({double radius = 20, bool down = false}) => BoxDecoration(
      color: wnSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xB3FFFFFF)),
      boxShadow: down ? wnShadowDown : wnShadow,
    );
