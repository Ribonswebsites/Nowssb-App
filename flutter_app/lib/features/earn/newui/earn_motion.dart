import 'dart:math' as math;

import 'package:flutter/material.dart';

/// True when the user asked the OS for reduced motion.
bool earnStill(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Fades and lifts [child] in after [index] × 70 ms. Instant when motion is reduced.
class EarnEntrance extends StatelessWidget {
  const EarnEntrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (earnStill(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + index * 70),
      curve: Interval(math.min(0.6, index * 0.08), 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Counts a real server number up from 0 (display only; never inflates it).
class EarnCountUp extends StatelessWidget {
  const EarnCountUp({super.key, required this.value, this.suffix = '', required this.style});
  final int value;
  final String suffix;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (earnStill(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Clay / Blender-style 3D medal, drawn procedurally. Slow float and light
/// sweep; a still frame under reduced motion.
class EarnMedal extends StatefulWidget {
  const EarnMedal({super.key, required this.color, this.size = 76});
  final Color color;
  final double size;

  @override
  State<EarnMedal> createState() => _EarnMedalState();
}

class _EarnMedalState extends State<EarnMedal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (earnStill(context)) {
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
    return Semantics(
      image: true,
      label: 'Rank medal',
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _MedalPainter(widget.color, _c.value)),
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.color, this.t);
  final Color color;
  final double t;

  Color _shade(double f) => Color.lerp(color, Colors.black, f)!;
  Color _tint(double f) => Color.lerp(color, Colors.white, f)!;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final bob = math.sin(t * 2 * math.pi) * s * 0.03;
    final c = Offset(size.width / 2, size.height / 2 + bob);
    final r = s * 0.40;

    // Soft contact shadow on the "floor" (shrinks as the medal rises).
    final sh = 1 - bob / (s * 0.06);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.95), width: r * 1.5 * sh, height: r * 0.28),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Extruded edge (thickness) for the 3D look.
    canvas.drawCircle(c.translate(0, s * 0.04), r, Paint()..color = _shade(0.45));
    // Rim.
    final rim = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(t * 2 * math.pi),
          colors: [_tint(0.55), _shade(0.25), _tint(0.2), _shade(0.35), _tint(0.55)],
        ).createShader(rim),
    );
    // Face, lit from the top-left like a clay render.
    final face = r * 0.78;
    canvas.drawCircle(
      c,
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [_tint(0.45), color, _shade(0.3)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: face)),
    );
    // Embossed star.
    final star = _star(c, face * 0.55, face * 0.24);
    canvas.drawPath(star.shift(Offset(0, s * 0.012)), Paint()..color = _shade(0.4));
    canvas.drawPath(
      star,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_tint(0.6), _shade(0.1)])
            .createShader(Rect.fromCircle(center: c, radius: face)),
    );
    // Specular highlight + moving light sweep.
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-r * 0.32, -r * 0.42), width: r * 0.62, height: r * 0.26),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(rim));
    final x = c.dx - r * 1.6 + r * 3.2 * ((t * 1.0) % 1.0);
    canvas.drawRect(
      Rect.fromLTWH(x - r * 0.15, c.dy - r, r * 0.3, r * 2),
      Paint()
        ..shader = LinearGradient(
                colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromLTWH(x - r * 0.15, c.dy - r, r * 0.3, r * 2)),
    );
    canvas.restore();
  }

  Path _star(Offset c, double outer, double inner) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? outer : inner;
      final o = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.t != t || old.color != color;
}

/// Progress bar with a slow "breathing" glow (4 s in / out, meditation pace).
class EarnBreathingBar extends StatefulWidget {
  const EarnBreathingBar({super.key, required this.value, required this.color});
  final double value;
  final Color color;

  @override
  State<EarnBreathingBar> createState() => _EarnBreathingBarState();
}

class _EarnBreathingBarState extends State<EarnBreathingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (earnStill(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = earnStill(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? widget.value : 0, end: widget.value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.15 + 0.25 * _c.value), blurRadius: 6 + 8 * _c.value)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const Key('earn-target-progress'),
              value: v,
              minHeight: 8,
              backgroundColor: const Color(0x26FFFFFF),
              valueColor: AlwaysStoppedAnimation(widget.color),
            ),
          ),
        ),
      ),
    );
  }
}
