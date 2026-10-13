/// Page-local glass pieces for the new Progress page.
///
/// SWAP POINT: NowssB Bug Hunter's shared kit (GlassWrapper, spec 14.2) is not
/// on main yet. When it lands, replace [PgGlass] with GlassWrapper and delete
/// this file's [PgGlass]; every call site uses the same (child, padding) shape.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class PgColors {
  static const bg = Color(0xFF1A1433);
  static const violet = Color(0xFF9B8CFF);
  static const lilac = Color(0xFFD9D0FF);
  static const ink = Color(0xFFF7F5FF);
  static const sub = Color(0xFFB9B2D9);
  static const glass = Color(0x22FFFFFF);
  static const edge = Color(0x40FFFFFF);
}

class PgGlass extends StatelessWidget {
  const PgGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: PgColors.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: PgColors.edge),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Procedural "aura": slow floating soft orbs (no bundled assets, spec 15/16).
/// Respects reduced motion: static when animations are disabled.
class PgAura extends StatefulWidget {
  const PgAura({super.key});
  @override
  State<PgAura> createState() => _PgAuraState();
}

class _PgAuraState extends State<PgAura> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _AuraPainter(_c.value), size: Size.infinite),
        ),
      );
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2156), PgColors.bg, Color(0xFF120E24)],
        ).createShader(Offset.zero & size),
    );
    const orbs = [
      (0.2, 0.18, 0.32, Color(0x669B8CFF)),
      (0.85, 0.35, 0.26, Color(0x55E7B8FF)),
      (0.4, 0.75, 0.38, Color(0x447F9CFF)),
    ];
    for (var i = 0; i < orbs.length; i++) {
      final o = orbs[i];
      final a = 2 * math.pi * (t + i / 3);
      final c = Offset(size.width * (o.$1 + 0.04 * math.sin(a)), size.height * (o.$2 + 0.03 * math.cos(a)));
      final r = size.shortestSide * o.$3;
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [o.$4, o.$4.withAlpha(0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.t != t;
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
        p..shader = const SweepGradient(colors: [PgColors.violet, PgColors.lilac, PgColors.violet]).createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}
