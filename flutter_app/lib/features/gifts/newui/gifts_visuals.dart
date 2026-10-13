import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../gift_unwrap.dart' show kGiftSparkleLottie;
import 'gifts_kit.dart';

/// Procedural "Blender-style" translucent glass gift box: three shaded faces,
/// a ribbon and bow, a soft floor shadow, and a slow float + sway (about one
/// breath every 6 s). Petals drift up around it. No bundled art; the only
/// asset is the existing licensed sparkle Lottie (see CREDITS.md), shown
/// faintly behind the box.
class GiftsHeroScene extends StatefulWidget {
  const GiftsHeroScene({super.key, this.size = 120, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<GiftsHeroScene> createState() => _GiftsHeroSceneState();
}

class _GiftsHeroSceneState extends State<GiftsHeroScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !widget.animate || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    final s = widget.size;
    return Semantics(
      image: true,
      label: 'A glass gift box',
      child: SizedBox(
        width: s * 1.3,
        height: s * 1.3,
        child: Stack(alignment: Alignment.center, children: [
          if (!still)
            IgnorePointer(
              child: Opacity(
                opacity: .35,
                child: Lottie.asset(kGiftSparkleLottie, width: s * 1.3, height: s * 1.3, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = still ? 0.0 : _c.value;
              return CustomPaint(size: Size(s * 1.3, s * 1.3), painter: _GiftScenePainter(t));
            },
          ),
        ]),
      ),
    );
  }
}

class _GiftScenePainter extends CustomPainter {
  _GiftScenePainter(this.t);
  final double t; // 0..1 over 12 s

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final breath = math.sin(t * 2 * math.pi * 2); // two breaths per loop
    final lift = breath * w * .025;
    final sway = math.sin(t * 2 * math.pi) * .05;
    final c = Offset(w / 2, w * .56 - lift);

    // Halo.
    canvas.drawCircle(
      c,
      w * .48,
      Paint()
        ..shader = RadialGradient(colors: [GiftsPalette.pink.withValues(alpha: .28 + .1 * breath.abs()), GiftsPalette.violet.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: w * .48)),
    );

    // Floor shadow shrinks as the box rises.
    final sh = Offset(w / 2, w * .9);
    canvas.drawOval(
      Rect.fromCenter(center: sh, width: w * (.48 - .04 * breath), height: w * .07),
      Paint()
        ..color = Colors.black.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Petals drifting up.
    final rnd = math.Random(7);
    for (var i = 0; i < 9; i++) {
      final phase = (t * 1.5 + i / 9) % 1.0;
      final x = w * (.15 + .7 * rnd.nextDouble()) + math.sin((phase + i) * 2 * math.pi) * w * .04;
      final y = w * (.95 - .9 * phase);
      final a = math.sin(phase * math.pi) * .7;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * (i.isEven ? 1 : -1));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * .045, height: w * .024),
          Paint()..color = (i % 3 == 0 ? GiftsPalette.amber : GiftsPalette.pink).withValues(alpha: a));
      canvas.restore();
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sway);
    final b = w * .26; // half box width
    final d = w * .1; // isometric depth
    final h = w * .3; // body height

    Path quad(List<Offset> p) => Path()..addPolygon(p, true);
    Paint face(Color a, Color z) => Paint()
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, z]).createShader(Rect.fromLTWH(-b, -h, 2 * b + d, 2 * h));

    // Body: front, side, top (glass = translucent gradient + bright edge).
    final front = quad([Offset(-b, -h * .2), Offset(b - d, -h * .2), Offset(b - d, h * .8), Offset(-b, h * .8)]);
    final side = quad([Offset(b - d, -h * .2), Offset(b, -h * .2 - d), Offset(b, h * .8 - d), Offset(b - d, h * .8)]);
    canvas.drawPath(front, face(const Color(0x99FFC2E2), const Color(0x669B8CFF)));
    canvas.drawPath(side, face(const Color(0x88B9A9FF), const Color(0x556A4FC9)));
    // Lid (slightly wider, lifts a touch on each breath).
    final ly = -h * .2 - w * .012 * (breath + 1);
    final lid = quad([Offset(-b - 6, ly - h * .18), Offset(b - d + 6, ly - h * .18), Offset(b - d + 6, ly), Offset(-b - 6, ly)]);
    final lidSide = quad([Offset(b - d + 6, ly - h * .18), Offset(b + 6, ly - h * .18 - d), Offset(b + 6, ly - d), Offset(b - d + 6, ly)]);
    final lidTop = quad([Offset(-b - 6, ly - h * .18), Offset(-b - 6 + d, ly - h * .18 - d), Offset(b + 6, ly - h * .18 - d), Offset(b - d + 6, ly - h * .18)]);
    canvas.drawPath(lidTop, face(const Color(0xCCFFFFFF), const Color(0x99FFC2E2)));
    canvas.drawPath(lid, face(const Color(0xAAFFD1EA), const Color(0x889B8CFF)));
    canvas.drawPath(lidSide, face(const Color(0x99C9BCFF), const Color(0x666A4FC9)));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .55);
    for (final p in [front, side, lid, lidSide, lidTop]) {
      canvas.drawPath(p, edge);
    }

    // Ribbon (vertical band on front and lid) + bow.
    final rib = Paint()..color = GiftsPalette.amber.withValues(alpha: .85);
    final rx = (-b + b - d) / 2;
    canvas.drawRect(Rect.fromLTRB(rx - w * .03, -h * .2, rx + w * .03, h * .8), rib);
    canvas.drawRect(Rect.fromLTRB(rx - w * .03, ly - h * .18, rx + w * .03, ly), rib);
    final bowY = ly - h * .18 - d / 2;
    for (final s in [-1.0, 1.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(rx + d / 2 + s * w * .06, bowY - w * .02), width: w * .12, height: w * .07), rib);
    }
    canvas.drawCircle(Offset(rx + d / 2, bowY - w * .015), w * .025, Paint()..color = const Color(0xFFFFE0A3));

    // Specular streak on the glass.
    canvas.drawLine(
        Offset(-b + w * .04, -h * .1),
        Offset(-b + w * .04, h * .55),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .35));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GiftScenePainter o) => o.t != t;
}

/// Fades and lifts a section in, staggered by [index]. Calm, 500 ms.
class GiftsReveal extends StatelessWidget {
  const GiftsReveal({super.key, required this.index, required this.child, this.animate = true});
  final int index;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate || (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + 90 * index),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c)),
      child: child,
    );
  }
}
