/// Calm "Aura" motion for the Coupons page (spec 15/16), all procedural.
/// Slow breathing violet glow + floating glass orbs and a tilted ring
/// (Spline-style 3D look from gradients and highlights, no bundled assets).
/// Static when [animate] is false or the OS asks for reduced motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class CouponsAura extends StatefulWidget {
  const CouponsAura({super.key, this.animate = true});
  final bool animate;
  @override
  State<CouponsAura> createState() => _CouponsAuraState();
}

class _CouponsAuraState extends State<CouponsAura> with SingleTickerProviderStateMixin {
  // One 24s loop drives everything: slow, meditative, cheap.
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !still) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: IgnorePointer(
          child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: AuraPainter(_c.value), size: Size.infinite)),
        ),
      );
}

class AuraPainter extends CustomPainter {
  const AuraPainter(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final w = 2 * math.pi * t;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E2358), Color(0xFF1A1433), Color(0xFF100C1F)])
            .createShader(Offset.zero & s),
    );
    // Breathing glow (inhale/exhale ~ 6s twice per loop... 4 breaths per loop).
    final breath = 0.5 + 0.5 * math.sin(w * 4);
    final g = Offset(s.width * 0.5, s.height * 0.22);
    c.drawCircle(
      g,
      s.width * (0.55 + 0.08 * breath),
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFF9B7BFF).withValues(alpha: 0.28 + 0.12 * breath), Colors.transparent])
            .createShader(Rect.fromCircle(center: g, radius: s.width * 0.7)),
    );
    _orb(c, Offset(s.width * 0.12 + 10 * math.sin(w), s.height * 0.36 + 16 * math.cos(w)), 34, const Color(0xFFB9A4FF));
    _orb(c, Offset(s.width * 0.9 + 8 * math.cos(w * 2), s.height * 0.55 + 20 * math.sin(w)), 22, const Color(0xFF8FE3F5));
    _orb(c, Offset(s.width * 0.78 + 12 * math.sin(w), s.height * 0.12 + 10 * math.sin(w * 2)), 16, const Color(0xFFF3C6FF));
    _ring(c, Offset(s.width * 0.18 + 6 * math.cos(w), s.height * 0.8 + 12 * math.sin(w)), 40, w);
  }

  void _orb(Canvas c, Offset o, double r, Color col) {
    final rect = Rect.fromCircle(center: o, radius: r);
    c.drawCircle(o.translate(4, 8), r, Paint()..color = Colors.black.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.4, -0.5), colors: [Colors.white.withValues(alpha: 0.85), col.withValues(alpha: 0.65), col.withValues(alpha: 0.15)], stops: const [0, 0.45, 1])
            .createShader(rect),
    );
    c.drawCircle(o, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withValues(alpha: 0.3));
  }

  void _ring(Canvas c, Offset o, double r, double w) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(0.6 + 0.2 * math.sin(w));
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * (0.7 + 0.15 * math.cos(w)));
    c.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..shader = const SweepGradient(colors: [Color(0xFFE9DFFF), Color(0xFF8D6CF0), Color(0xFF5B3FC4), Color(0xFFE9DFFF)]).createShader(rect),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(AuraPainter old) => old.t != t;
}

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
