/// Entrance and count-up motion for the new Progress page.
/// Motion stops when reduced motion is on. (Orb and floating shapes removed
/// per Ribon's 3:29 PM IST correction: the app's background video stays.)
library;

import 'package:flutter/material.dart';

bool pgReduceMotion(BuildContext c) => MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// Fade + rise entrance; instant under reduced motion.
class PgEnter extends StatelessWidget {
  const PgEnter({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (pgReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + 90 * index),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Number that counts up to its real value once.
class PgCount extends StatelessWidget {
  const PgCount({super.key, required this.value, required this.style, this.suffix = ''});
  final int value;
  final TextStyle style;
  final String suffix;
  @override
  Widget build(BuildContext context) {
    if (pgReduceMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}
