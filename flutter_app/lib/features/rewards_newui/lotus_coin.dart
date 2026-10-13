/// Signature golden lotus coin (spec 15 #1 / 16 #6): a coin slowly turning
/// above still water, ripples spreading, sparkles orbiting. Pure
/// CustomPainter, original code, no third-party assets. Holds still when
/// reduced motion is on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LotusCoin extends StatefulWidget {
  const LotusCoin({super.key, this.size = 96});
  final double size;
  @override
  State<LotusCoin> createState() => _LotusCoinState();
}

class _LotusCoinState extends State<LotusCoin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
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
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: LotusCoinPainter(_c.value))),
          ),
        ),
      );
}

class LotusCoinPainter extends CustomPainter {
  LotusCoinPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w * .42);
    final r = w * .26;
    final a = 2 * math.pi * t;

    // Water ripples.
    final water = Offset(w / 2, w * .86);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      final rect = Rect.fromCenter(center: water, width: w * (.3 + .6 * p), height: w * (.08 + .14 * p));
      canvas.drawOval(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFFFE4A8).withValues(alpha: .5 * (1 - p)));
    }
    // Soft glow + reflection.
    final bob = math.sin(a) * w * .025;
    final cc = c.translate(0, bob);
    canvas.drawCircle(
        cc,
        r * 1.8,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x66FFD27A), Color(0x00FFD27A)]).createShader(Rect.fromCircle(center: cc, radius: r * 1.8)));
    canvas.drawOval(Rect.fromCenter(center: water, width: r * 1.4, height: r * .25), Paint()..color = const Color(0x33FFD27A));

    // Coin turning: horizontal scale by cos, with an edge band for depth.
    final turn = math.cos(a * .5);
    final sx = turn.abs().clamp(.12, 1.0);
    canvas.save();
    canvas.translate(cc.dx, cc.dy);
    canvas.scale(sx, 1);
    final edge = Paint()..color = const Color(0xFFB07A1E);
    canvas.drawCircle(Offset(turn >= 0 ? -3 / sx : 3 / sx, 0), r, edge);
    final face = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader =
              const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF1C2), Color(0xFFFFC94D), Color(0xFFD9962A)])
                  .createShader(face));
    canvas.drawCircle(
        Offset.zero,
        r * .84,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .06
          ..color = const Color(0x99FFF6D8));
    // Lotus: five petals.
    final petal = Paint()..color = const Color(0xFFC9861F);
    for (var i = 0; i < 5; i++) {
      final ang = -math.pi / 2 + (i - 2) * .42;
      canvas.save();
      canvas.rotate(ang + math.pi / 2);
      final path = Path()
        ..moveTo(0, r * .25)
        ..quadraticBezierTo(r * .2, -r * .1, 0, -r * .5)
        ..quadraticBezierTo(-r * .2, -r * .1, 0, r * .25);
      canvas.drawPath(path, petal);
      canvas.restore();
    }
    canvas.restore();

    // Orbiting sparkles.
    for (var i = 0; i < 4; i++) {
      final ang = a + i * math.pi / 2;
      final o = cc + Offset(math.cos(ang) * r * 1.5, math.sin(ang) * r * .5);
      final tw = (math.sin(a * 3 + i) + 1) / 2;
      _spark(canvas, o, w * .02 + tw * w * .015, Colors.white.withValues(alpha: .4 + .6 * tw));
    }
  }

  void _spark(Canvas canvas, Offset o, double s, Color col) {
    final p = Path()
      ..moveTo(o.dx, o.dy - s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s);
    canvas.drawPath(p, Paint()..color = col);
  }

  @override
  bool shouldRepaint(LotusCoinPainter old) => old.t != t;
}

/// Counts up to [value] once (honest: lands on the server's number).
class CountUpText extends StatelessWidget {
  const CountUpText(this.value, {super.key, this.style});
  final int value;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? value.toDouble() : 0, end: value.toDouble()),
      duration: still ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

/// Calm staggered fade-and-rise for hub sections.
class CalmReveal extends StatelessWidget {
  const CalmReveal({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + 80 * index),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }
}
