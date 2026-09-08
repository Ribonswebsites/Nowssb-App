/// Colours and shared chrome for My Progress (Glass Orb).
library;

import 'package:flutter/material.dart';

class MpColors {
  MpColors._();
  static const bg = Color(0xFF020304);
  static const white = Color(0xFFF5F5F3);
  static const muted = Color(0xFF9B9D9E);
  static const gold = Color(0xFFD9C98F);
  static const line = Color(0x21FFFFFF);
  static const glass = Color(0x99040506);
  /// Notifications-level backdrop blur sigma.
  static const glassBlur = 13.0;
  static const dim = Color(0xFF858A8C);
  static const soft = Color(0xFFA8AFB1);
}

class ProgressEyebrow extends StatelessWidget {
  const ProgressEyebrow(this.label, {super.key, this.tightTop = false});
  final String label;
  final bool tightTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: tightTop ? 6 : 22, bottom: 13),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: MpColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.2,
        ),
      ),
    );
  }
}

class ProgressGlass extends StatelessWidget {
  const ProgressGlass({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
      padding: padding,
      decoration: BoxDecoration(
        color: MpColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MpColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 45, offset: Offset(0, 18)),
        ],
      ),
      child: child,
    );
  }
}
