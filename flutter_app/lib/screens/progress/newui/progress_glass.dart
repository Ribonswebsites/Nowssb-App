/// Page-local glass pieces for the new Progress page, styled to
/// /workspace/specs/card-reference-exact.png (card only, never its background).
///
/// Outer card uses the kit's rebuilt NGlass (origin/main).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/glass_core.dart' show NGlass;
import '../../../nowssb_ui/tokens.dart' show NTokens;

class PgColors {
  static const ink = Color(0xFFFFFFFF);
  static const sub = Color(0xB3FFFFFF); // muted white body text
  static const glass = Color(0x40CFC6F2); // translucent light-lavender frost
  static const panel = Color(0x26FFFFFF); // inner frosted panel
  static const edge = Color(0x59FFFFFF); // soft white 1px border
  static const pillInk = Color(0xFF1E1A33);
}

/// Outer frosted card: the kit's rebuilt neutral NGlass (white frost, 1px
/// soft white border) at radius 30, per Ribon's approved card (5:53 PM IST).
class PgGlass extends StatelessWidget {
  const PgGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 30});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      NGlass(radius: radius, blur: NTokens.blurLarge, padding: padding, child: child);
}

/// Inner frosted panel (lower half of the reference card), radius 20.
class PgPanel extends StatelessWidget {
  const PgPanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(18, 18, 14, 14)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: PgColors.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: child,
      );
}

/// Small white rounded pill ("Next" in the reference).
class PgPill extends StatelessWidget {
  const PgPill({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label, style: const TextStyle(color: PgColors.pillInk, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

/// Page dots: filled = done, wide = today.
class PgDots extends StatelessWidget {
  const PgDots({super.key, required this.done, this.current = -1});
  final List<bool> done;
  final int current;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < done.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == current ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: done[i] || i == current ? Colors.white : const Color(0x59FFFFFF),
            ),
          ),
      ]);
}

/// Ring showing a 0..1 fraction (weekly consistency).
class PgRing extends StatelessWidget {
  const PgRing({super.key, required this.value, required this.label, this.size = 132});
  final double value;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0.0, 1.0)),
          child: Center(
            child: Text(label, style: const TextStyle(color: PgColors.ink, fontSize: 28, fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(8), 0, 2 * math.pi, false, p..color = const Color(0x22FFFFFF));
    canvas.drawArc(rect.deflate(8), -math.pi / 2, 2 * math.pi * v, false,
        p..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}
