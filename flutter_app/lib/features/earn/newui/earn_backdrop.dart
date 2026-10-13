import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Procedural soft-violet backdrop with slow floating orbs (no bundled art).
/// Respects reduced motion: draws a still frame when animations are disabled.
class EarnBackdrop extends StatefulWidget {
  const EarnBackdrop({super.key, required this.child});
  final Widget child;

  @override
  State<EarnBackdrop> createState() => _EarnBackdropState();
}

class _EarnBackdropState extends State<EarnBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
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
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _OrbPainter(_c.value)),
          ),
        ),
      ),
      widget.child,
    ]);
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t);
  final double t;

  static const _orbs = [
    (0.15, 0.12, 0.34, Color(0xFFB9A4FF)),
    (0.85, 0.30, 0.26, Color(0xFF8FD3FF)),
    (0.30, 0.70, 0.30, Color(0xFFE3B8FF)),
    (0.80, 0.88, 0.22, Color(0xFFA7F0E0)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1433), Color(0xFF2A1F4D), Color(0xFF161229)],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < _orbs.length; i++) {
      final (x, y, r, c) = _orbs[i];
      final a = 2 * math.pi * (t + i / _orbs.length);
      final center = Offset(size.width * (x + 0.03 * math.sin(a)), size.height * (y + 0.02 * math.cos(a)));
      final radius = size.shortestSide * r;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
