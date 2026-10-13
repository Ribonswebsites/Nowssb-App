/// Procedural "Aura" backdrop: soft violet orbs drifting slowly (spec 16).
/// No bundled art, so nothing to credit. Respects reduce-motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProfileAura extends StatefulWidget {
  const ProfileAura({super.key});
  @override
  State<ProfileAura> createState() => _ProfileAuraState();
}

class _ProfileAuraState extends State<ProfileAura> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

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
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: AuraPainter(_c.value), size: Size.infinite),
        ),
      );
}

class AuraPainter extends CustomPainter {
  AuraPainter(this.t);
  final double t;

  static const bgTop = Color(0xFF1B1530);
  static const bgBottom = Color(0xFF0C0A16);
  static const orbs = [Color(0xFF9B7BFF), Color(0xFFC3A6FF), Color(0xFF6E8BFF), Color(0xFFE2A7F0)];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom]).createShader(rect));
    final a = t * 2 * math.pi;
    for (var i = 0; i < orbs.length; i++) {
      final ph = a + i * 1.7;
      final c = Offset(
        size.width * (0.25 + 0.5 * ((i * 0.37) % 1)) + math.cos(ph) * size.width * 0.08,
        size.height * (0.15 + 0.22 * i) + math.sin(ph * 0.8) * 24,
      );
      final r = size.shortestSide * (0.28 + 0.06 * math.sin(ph));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [orbs[i].withValues(alpha: 0.35), orbs[i].withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(AuraPainter old) => old.t != t;
}
