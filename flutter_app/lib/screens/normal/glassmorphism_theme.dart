import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class NormalGlassMode extends InheritedWidget {
  const NormalGlassMode(
      {super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NormalGlassMode>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(NormalGlassMode oldWidget) =>
      oldWidget.enabled != enabled;
}

/// White glassmorphism surfaces used only by Flutter's Normal Home.
/// Fashion Plus and every other screen remain unchanged.
class NormalGlassBackground extends StatelessWidget {
  const NormalGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xEEF7FBFF), Color(0xFFFFFFFF)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: CustomPaint(painter: _GlassOrbsPainter())),
          child,
        ],
      ),
    );
  }
}

/// A translucent, blurred, bordered surface around an existing Normal section.
class NormalGlassSection extends StatelessWidget {
  const NormalGlassSection(
      {super.key, required this.child, this.header = false});

  final Widget child;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(header ? 28 : 24);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: header ? 12 : 8,
        vertical: header ? 4 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
              color: Color(0x220B2447), blurRadius: 30, offset: Offset(0, 14)),
          BoxShadow(
              color: Color(0xE6FFFFFF), blurRadius: 20, offset: Offset(-6, -6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x66FFFFFF),
              borderRadius: radius,
              border: Border.all(color: const Color(0xF2FFFFFF), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class NormalGlassToggle extends StatelessWidget {
  const NormalGlassToggle(
      {super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          enabled ? 'Use Neomorphism theme' : 'Use white Glassmorphism theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 48,
            height: 38,
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0xD9FFFFFF) : const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFFFFF), width: 1.2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x220B2447),
                    blurRadius: 10,
                    offset: Offset(2, 4)),
                BoxShadow(
                    color: Color(0xCCFFFFFF),
                    blurRadius: 8,
                    offset: Offset(-2, -2)),
              ],
            ),
            child: Icon(
              enabled ? Icons.blur_off_rounded : Icons.blur_on_rounded,
              size: 21,
              color: const Color(0xFF31577F),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassOrbsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (
        Offset(size.width * .10, size.height * .12),
        170.0,
        const Color(0x2447A7FF)
      ),
      (
        Offset(size.width * .92, size.height * .34),
        220.0,
        const Color(0x1F9F7BFF)
      ),
      (
        Offset(size.width * .30, size.height * .88),
        260.0,
        const Color(0x1F61D6C8)
      ),
    ];
    for (final (center, radius, color) in blobs) {
      canvas.drawCircle(center, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
