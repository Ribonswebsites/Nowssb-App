/// Colours and shared chrome for My Progress (Glass Orb).
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class MpColors {
  MpColors._();
  static const bg = Color(0xFF020304);
  static const white = Color(0xFFF5F5F3);
  static const muted = Color(0xFF9B9D9E);
  static const gold = Color(0xFFD9C98F);
  static const line = Color(0x14FFFFFF);
  static const glass = Color(0x8C0A0B0C);
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
      padding: EdgeInsets.only(top: tightTop ? 12 : 40, bottom: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: MpColors.soft,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          height: 1.3,
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
    this.radius = 28,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: MpColors.glassBlur, sigmaY: MpColors.glassBlur),
        child: Container(
      constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
      padding: padding,
      decoration: BoxDecoration(
        color: MpColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MpColors.line),
      ),
      child: child,
        ),
      ),
    );
  }
}
