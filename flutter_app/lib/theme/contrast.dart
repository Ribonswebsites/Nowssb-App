import 'dart:ui' show Color;

/// WCAG 2.x contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [want] when it reads at >= 4.5:1 on [on], else [fallback].
Color legibleOr(Color want, Color on, Color fallback) =>
    contrastRatio(Color.alphaBlend(want, on), on) >= 4.5 ? want : fallback;
