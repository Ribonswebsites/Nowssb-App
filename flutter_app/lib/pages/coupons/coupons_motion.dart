/// Calm motion for the Coupons page: staggered entrances, press-scale.
/// Static when [animate] is false or the OS asks for reduced motion.
library;

import 'package:flutter/material.dart';

/// Staggered fade + rise for list items, and a gentle press-scale.
class CalmEntrance extends StatelessWidget {
  const CalmEntrance({super.key, required this.index, required this.child, this.animate = true});
  final int index;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + 70 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: ch)),
      child: child,
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 140), curve: Curves.easeOut, child: widget.child),
      );
}
