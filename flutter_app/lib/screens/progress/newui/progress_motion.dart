/// Code-drawn 3D-style visuals and motion for the new Progress page.
/// No bundled assets. All motion stops when reduced motion is on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'progress_glass.dart';

bool pgReduceMotion(BuildContext c) => MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// A looping 0..1 clock that freezes under reduced motion.
mixin PgLoop<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  Duration get period;
  late final AnimationController loop = AnimationController(vsync: this, duration: period);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (pgReduceMotion(context)) {
      loop.stop();
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Breathing glass orb with Blender-style shading (key light, rim light,
/// specular highlight, contact shadow). Its glow brightens with the real
/// weekly consistency, it does not invent progress.
class PgOrb extends StatefulWidget {
  const PgOrb({super.key, required this.intensity, this.size = 150});
  final double intensity;
  final double size;
  @override
  State<PgOrb> createState() => _PgOrbState();
}

class _PgOrbState extends State<PgOrb> with SingleTickerProviderStateMixin, PgLoop {
  @override
  Duration get period => const Duration(seconds: 8); // ~7.5 breaths a minute
  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: loop,
          builder: (_, __) => CustomPaint(
            size: Size.square(widget.size),
            painter: _OrbPainter(loop.value, widget.intensity.clamp(0.0, 1.0)),
          ),
        ),
      );
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t, this.k);
  final double t, k;
  @override
  void paint(Canvas canvas, Size s) {
    final breath = 0.5 - 0.5 * math.cos(2 * math.pi * t);
    final r = s.width * (0.34 + 0.03 * breath);
    final c = Offset(s.width / 2, s.height * 0.46);
    // contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, s.height * 0.92), width: r * 1.5, height: r * 0.22),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // aura glow scales with real consistency
    canvas.drawCircle(
      c,
      r * 1.45,
      Paint()
        ..shader = RadialGradient(colors: [PgColors.violet.withAlpha((40 + 110 * k * (0.7 + 0.3 * breath)).round()), const Color(0x009B8CFF)])
            .createShader(Rect.fromCircle(center: c, radius: r * 1.45)),
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    // body: off-centre radial = key light top-left
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [Color(0xFFEDE8FF), Color(0xFFA796FF), Color(0xFF4B3A9E), Color(0xFF241A52)],
          stops: [0, 0.35, 0.8, 1],
        ).createShader(rect),
    );
    // rim light bottom-right
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(center: Alignment(0.6, 0.7), radius: 0.7, colors: [Color(0x66FFC8F0), Color(0x00FFC8F0)])
            .createShader(rect),
    );
    // specular
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.35, -r * 0.45), width: r * 0.55, height: r * 0.3),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.t != t || o.k != k;
}

/// Floating shaded shapes (sphere, torus, pill) drifting slowly, like the
/// glass-meditation reference.
class PgFloaters extends StatefulWidget {
  const PgFloaters({super.key});
  @override
  State<PgFloaters> createState() => _PgFloatersState();
}

class _PgFloatersState extends State<PgFloaters> with SingleTickerProviderStateMixin, PgLoop {
  @override
  Duration get period => const Duration(seconds: 30);
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: loop,
            builder: (_, __) => CustomPaint(painter: _FloatPainter(loop.value), size: Size.infinite),
          ),
        ),
      );
}

class _FloatPainter extends CustomPainter {
  _FloatPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size s) {
    final a = 2 * math.pi * t;
    // sphere
    final c1 = Offset(s.width * 0.86, s.height * (0.12 + 0.015 * math.sin(a)));
    final r1 = s.width * 0.07;
    canvas.drawCircle(
      c1,
      r1,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xCCFFFFFF), Color(0x88B7A8FF), Color(0x334B3A9E)])
            .createShader(Rect.fromCircle(center: c1, radius: r1)),
    );
    // torus (thick ring with lit top edge)
    final c2 = Offset(s.width * 0.1, s.height * (0.55 + 0.02 * math.cos(a)));
    final ring = Rect.fromCircle(center: c2, radius: s.width * 0.08);
    canvas.save();
    canvas.translate(c2.dx, c2.dy);
    canvas.rotate(0.3 * math.sin(a));
    canvas.translate(-c2.dx, -c2.dy);
    canvas.drawOval(
      Rect.fromCenter(center: c2, width: ring.width, height: ring.height * 0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.035
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAAF3D9FF), Color(0x337F6BFF)])
            .createShader(ring),
    );
    canvas.restore();
    // pill
    final c3 = Offset(s.width * (0.78 + 0.02 * math.cos(a)), s.height * 0.82);
    final pill = RRect.fromRectAndRadius(Rect.fromCenter(center: c3, width: s.width * 0.2, height: s.width * 0.07), const Radius.circular(40));
    canvas.save();
    canvas.translate(c3.dx, c3.dy);
    canvas.rotate(-0.5 + 0.1 * math.sin(a));
    canvas.translate(-c3.dx, -c3.dy);
    canvas.drawRRect(
      pill,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99FFFFFF), Color(0x229B8CFF)])
            .createShader(pill.outerRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloatPainter o) => o.t != t;
}

/// Fade + rise entrance; instant under reduced motion.
class PgEnter extends StatelessWidget {
  const PgEnter({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (pgReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + 90 * index),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Number that counts up to its real value once.
class PgCount extends StatelessWidget {
  const PgCount({super.key, required this.value, required this.style, this.suffix = ''});
  final int value;
  final TextStyle style;
  final String suffix;
  @override
  Widget build(BuildContext context) {
    if (pgReduceMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}
