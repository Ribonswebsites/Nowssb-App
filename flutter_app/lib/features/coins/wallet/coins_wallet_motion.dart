import 'dart:math' as math;
import 'package:flutter/material.dart';

bool _reduce(BuildContext c) => MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// Mixin: a looping controller that freezes when reduce-motion is on.
mixin _CalmLoop<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController loop = AnimationController(vsync: this, duration: loopDuration);
  Duration get loopDuration;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce(context)) {
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

/// Slow-drifting, softly shaded 3D orbs behind the glass (Blender-style
/// "clay spheres", drawn procedurally).
class AuraBackground extends StatefulWidget {
  const AuraBackground({super.key, required this.child});
  final Widget child;
  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground> with SingleTickerProviderStateMixin, _CalmLoop {
  @override
  Duration get loopDuration => const Duration(seconds: 40);
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1F4F), Color(0xFF4B3A8C), Color(0xFF1B1533)]))),
        RepaintBoundary(child: AnimatedBuilder(animation: loop,
            builder: (_, __) => CustomPaint(painter: _OrbsPainter(loop.value)))),
        widget.child,
      ]);
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter(this.t);
  final double t;
  static const _orbs = [
    (0.15, 0.18, 0.22, Color(0xFFB39DFF), 0.0),
    (0.85, 0.32, 0.16, Color(0xFFFFD27A), 1.7),
    (0.25, 0.78, 0.18, Color(0xFF8FD3FF), 3.1),
    (0.80, 0.86, 0.12, Color(0xFFE7A6FF), 4.4),
  ];
  @override
  void paint(Canvas canvas, Size s) {
    for (final o in _orbs) {
      final a = t * 2 * math.pi + o.$5;
      final c = Offset(s.width * o.$1 + math.sin(a) * 14, s.height * o.$2 + math.cos(a * .8) * 18);
      final r = s.width * o.$3;
      // body: lit from top-left like a soft studio render
      canvas.drawCircle(c, r, Paint()
        ..shader = RadialGradient(center: const Alignment(-.4, -.5), radius: 1.0, colors: [
          Color.lerp(Colors.white, o.$4, .35)!.withValues(alpha: .55),
          o.$4.withValues(alpha: .35),
          o.$4.withValues(alpha: .05),
        ], stops: const [0, .55, 1]).createShader(Rect.fromCircle(center: c, radius: r)));
      // specular
      canvas.drawCircle(c + Offset(-r * .35, -r * .4), r * .14,
          Paint()..color = Colors.white.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter o) => o.t != t;
}

/// Breathing glow (§16): scale 1.00→1.025 + glow on a 5s inhale/exhale.
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({super.key, required this.child, this.color = const Color(0xFFE0A526), this.radius = 30});
  final Widget child;
  final Color color;
  final double radius;
  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow> with SingleTickerProviderStateMixin, _CalmLoop {
  @override
  Duration get loopDuration => const Duration(seconds: 10);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: loop, child: widget.child, builder: (_, child) {
        final b = .5 - .5 * math.cos(loop.value * 2 * math.pi); // 0→1→0 over 10s = 5s in, 5s out
        return Transform.scale(scale: 1 + .025 * b, child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: .10 + .18 * b), blurRadius: 24 + 20 * b),
            ]),
            child: child));
      });
}

/// Golden lotus coin with rim, embossed petals, sweeping specular and water
/// ripples below. Fully procedural.
class LotusCoin3D extends StatefulWidget {
  const LotusCoin3D({super.key, this.size = 84});
  final double size;
  @override
  State<LotusCoin3D> createState() => _LotusCoin3DState();
}

class _LotusCoin3DState extends State<LotusCoin3D> with SingleTickerProviderStateMixin, _CalmLoop {
  @override
  Duration get loopDuration => const Duration(seconds: 8);
  @override
  Widget build(BuildContext context) => SizedBox(width: widget.size * 1.6, height: widget.size * 1.35,
      child: AnimatedBuilder(animation: loop,
          builder: (_, __) => CustomPaint(painter: _CoinPainter(loop.value, widget.size))));
}

class _CoinPainter extends CustomPainter {
  _CoinPainter(this.t, this.d);
  final double t, d;
  @override
  void paint(Canvas canvas, Size s) {
    final a = t * 2 * math.pi;
    final bob = math.sin(a) * d * .04;
    final c = Offset(s.width / 2, d / 2 + bob + 4);
    final r = d / 2;
    // ripples on still water
    final water = Offset(s.width / 2, s.height - d * .12);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      canvas.drawOval(Rect.fromCenter(center: water, width: d * (.5 + p), height: d * (.12 + p * .18)),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2
            ..color = const Color(0xFFFFE9A8).withValues(alpha: .35 * (1 - p)));
    }
    // reflection glow
    canvas.drawOval(Rect.fromCenter(center: water, width: d * .7, height: d * .14),
        Paint()..color = const Color(0x55E0A526)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // gentle 3D turn: squash x
    final sx = .78 + .22 * math.cos(a);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(sx, 1);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    // edge thickness
    canvas.drawCircle(Offset(r * .06 * math.sin(a), 0), r, Paint()..color = const Color(0xFF8A5A08));
    // rim
    canvas.drawCircle(Offset.zero, r, Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFFFF1C2), Color(0xFFD99A1E), Color(0xFF9C6510)]).createShader(rect));
    // face
    canvas.drawCircle(Offset.zero, r * .84, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4),
        colors: [Color(0xFFFFE9A8), Color(0xFFE0A526), Color(0xFFB27812)]).createShader(rect));
    // embossed lotus petals
    final hi = Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: .9);
    final lo = Paint()..color = const Color(0xFF9C6510).withValues(alpha: .45);
    for (var i = -2; i <= 2; i++) {
      for (final (p, off) in [(lo, const Offset(1.2, 1.2)), (hi, Offset.zero)]) {
        canvas.save();
        canvas.translate(off.dx, r * .28 + off.dy);
        canvas.rotate(i * .45);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * .3), width: r * .26, height: r * .62), p);
        canvas.restore();
      }
    }
    // sweeping specular band
    final sweep = (t * 2 % 1) * 2.4 - 1.2;
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(rect, Paint()..shader = LinearGradient(
        begin: Alignment(sweep - .3, -1), end: Alignment(sweep + .3, 1),
        colors: [Colors.transparent, Colors.white.withValues(alpha: .45), Colors.transparent]).createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinPainter o) => o.t != t;
}

/// One-shot soft sparkle ring, played once when the balance finishes counting.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({super.key, required this.play});
  final bool play;
  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didUpdateWidget(SparkleBurst old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play && !_reduce(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(animation: _c,
      builder: (_, __) => _c.value == 0 || _c.value == 1 ? const SizedBox.shrink()
          : CustomPaint(size: const Size(220, 120), painter: _SparklePainter(Curves.easeOut.transform(_c.value)))));
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.p);
  final double p;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final paint = Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 1 - p);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * 2 * math.pi;
      final o = c + Offset(math.cos(a) * 90 * p, math.sin(a) * 45 * p);
      final k = 3.5 * (1 - p) + 1;
      canvas.drawPath(Path()..moveTo(o.dx, o.dy - k * 2)..lineTo(o.dx + k * .6, o.dy)..lineTo(o.dx, o.dy + k * 2)
        ..lineTo(o.dx - k * .6, o.dy)..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.p != p;
}

/// Staggered calm entrance (fade + 12px rise). Instant under reduce-motion.
class CalmEntrance extends StatelessWidget {
  const CalmEntrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) {
    if (_reduce(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + 90 * index),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c)),
    );
  }
}
