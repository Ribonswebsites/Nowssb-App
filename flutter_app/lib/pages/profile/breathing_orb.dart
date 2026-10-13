/// Blender-style 3D glass orb drawn in code: a lit sphere with a rim glow,
/// specular highlight and an orbiting ring, breathing on a slow 8 s cycle
/// (4 in, 4 out). Static when reduce-motion is on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class BreathingOrb extends StatefulWidget {
  const BreathingOrb({super.key, this.size = 150, this.animate = true, this.child});
  final double size;
  final bool animate;
  final Widget? child;
  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = !widget.animate || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (still) {
      _c.stop();
      _c.value = 0.5;
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
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => CustomPaint(painter: OrbPainter(_c.value), child: child),
            child: Center(child: widget.child),
          ),
        ),
      );
}

class OrbPainter extends CustomPainter {
  OrbPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final breath = 0.5 - 0.5 * math.cos(t * 2 * math.pi); // 0..1..0
    final r = size.shortestSide * (0.36 + 0.04 * breath);

    // Soft glow halo.
    canvas.drawCircle(c, r * 1.45, Paint()..shader = RadialGradient(colors: [const Color(0xFFB79CFF).withValues(alpha: 0.30 + 0.15 * breath), const Color(0x00B79CFF)]).createShader(Rect.fromCircle(center: c, radius: r * 1.45)));

    // Back half of the orbiting ring (behind sphere).
    _ring(canvas, c, r, back: true);

    // Lit sphere: key light top-left, violet body, deep shadow bottom-right.
    final sphere = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..shader = const RadialGradient(center: Alignment(-0.35, -0.45), radius: 1.0, colors: [Color(0xFFF1E9FF), Color(0xFFB79CFF), Color(0xFF5B45B8), Color(0xFF231A4A)], stops: [0, 0.3, 0.75, 1]).createShader(sphere));
    // Rim light.
    canvas.drawCircle(c, r - 1, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const SweepGradient(colors: [Color(0x00FFFFFF), Color(0x88E2D5FF), Color(0x00FFFFFF), Color(0x00FFFFFF)]).createShader(sphere));
    // Specular highlight.
    final hl = c + Offset(-r * 0.38, -r * 0.42);
    canvas.drawOval(Rect.fromCenter(center: hl, width: r * 0.5, height: r * 0.32), Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: hl, radius: r * 0.3)));

    _ring(canvas, c, r, back: false);
  }

  void _ring(Canvas canvas, Offset c, double r, {required bool back}) {
    final rect = Rect.fromCenter(center: c, width: r * 2.7, height: r * 0.7);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFE2D5FF).withValues(alpha: back ? 0.25 : 0.7);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.35);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(rect, back ? math.pi : 0, math.pi, false, p);
    // A small moon travelling the ring.
    final a = t * 2 * math.pi;
    final onFront = math.sin(a) > 0;
    if (onFront != back) {
      final m = Offset(c.dx + math.cos(a) * rect.width / 2, c.dy + math.sin(a) * rect.height / 2);
      canvas.drawCircle(m, 4.5, Paint()..color = const Color(0xFFF4F1FF).withValues(alpha: back ? 0.4 : 0.95));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OrbPainter old) => old.t != t;
}
