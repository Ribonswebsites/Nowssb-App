/// R27 — CustomPainter animations that replace the home's videos/Lottie:
///  • [R27SoundOrb]   → Sound Library card video (assets/video/orb-loop.mp4)
///  • [R27BreathFlame]→ legacy streak disc (kept, unused on Normal home)
///  • [R27StreakCandle]→ Normal-home streak mark: growing candle flame
///  • [R27Coin]       → NowssB Earn coin Lottie (nm-anim-coins.json)
///  • [R27PosterDrift]→ "Offers and earning" video (hero-meaning-store.mp4)
///  • [R27Meditator]  → replaces the Cleopatra / red-haired model cut-outs
/// Plus [R27Ribbon] (gift cards) and [R27Foil] (sealed scratch cards).
/// All freeze under reduced motion and in shot tests.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kit.dart';

const _tau = math.pi * 2;

// ── Sound orb ─────────────────────────────────────────────────────────────
class R27SoundOrb extends StatelessWidget {
  const R27SoundOrb({super.key, this.size = 120, this.light = false});
  final double size;
  /// Normal home: light neumorphic well instead of the black disc.
  final bool light;
  @override
  Widget build(BuildContext context) => R27Anim(
        period: const Duration(seconds: 6),
        builder: (_, t) => CustomPaint(size: Size.square(size), painter: _OrbP(t, light)),
      );
}

class _OrbP extends CustomPainter {
  _OrbP(this.t, [this.light = false]);
  final double t;
  final bool light;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final R = s.shortestSide / 2;
    c.drawCircle(o, R, Paint()..shader = ui.Gradient.radial(o, R, light ? const [Color(0xFFFFFFFF), Color(0xFFE4E7EF)] : const [Color(0xFF1A1712), r27Black], [0, 1]));
    // breathing rings
    for (var k = 0; k < 3; k++) {
      final p = (t + k / 3) % 1;
      c.drawCircle(o, R * (.38 + .6 * p), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = r27Gold.withValues(alpha: (1 - p) * .55));
    }
    // radial sound bars
    const n = 56;
    final bar = Paint()..strokeCap = StrokeCap.round..strokeWidth = math.max(1.4, R * .035);
    for (var i = 0; i < n; i++) {
      final a = i / n * _tau;
      final amp = .5 + .5 * math.sin(a * 3 + t * _tau) * math.cos(a * 2 - t * _tau * 2);
      final r0 = R * .34, r1 = r0 + R * (.08 + .22 * amp.abs());
      bar.color = Color.lerp(r27Gold, light ? const Color(0xFF7A4E0C) : Colors.white, amp.abs())!.withValues(alpha: .9);
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * r0, o + Offset(math.cos(a), math.sin(a)) * r1, bar);
    }
    // core
    final core = R * (.26 + .03 * math.sin(t * _tau * 2));
    c.drawCircle(o, core, Paint()..shader = ui.Gradient.radial(o - Offset(core * .3, core * .3), core * 1.3,
        const [Color(0xFFFFF3D6), r27Gold, Color(0xFF6B4A14)], [0, .55, 1]));
  }
  @override
  bool shouldRepaint(_OrbP o) => o.t != t || o.light != light;
}

// ── Streak breath flame ───────────────────────────────────────────────────
class R27BreathFlame extends StatelessWidget {
  const R27BreathFlame({super.key, required this.streak, this.size = 92, this.light = false});
  /// Normal home: light neumorphic well instead of the black disc.
  final bool light;
  /// Real streak days; lights that many of the seven week beads.
  final int streak;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: R27Anim(
          period: const Duration(milliseconds: 4200),
          builder: (_, t) => CustomPaint(size: Size.square(size), painter: _FlameP(t, streak, light)),
        ),
      );
}

class _FlameP extends CustomPainter {
  _FlameP(this.t, this.streak, [this.light = false]);
  final bool light;
  final double t;
  final int streak;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final R = s.shortestSide / 2;
    c.drawCircle(o, R, Paint()..color = light ? const Color(0xFFF0F2F7) : r27Black);
    final lit = streak <= 0 ? 0 : ((streak - 1) % 7) + 1;
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + i / 7 * _tau + t * _tau * .08;
      final on = i < lit;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * R * .78, R * (on ? .085 : .06),
          Paint()..color = on ? r27Gold : (light ? const Color(0x2E000000) : const Color(0x40FFFFFF)));
    }
    final breath = .88 + .12 * math.sin(t * _tau);
    final h = R * .9 * breath, w = R * .42;
    final base = o + Offset(0, R * .36);
    final sway = math.sin(t * _tau * 3) * w * .12;
    Path flame(double k) => Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - w * k, base.dy - h * .15 * k, base.dx - w * .55 * k + sway, base.dy - h * .65 * k, base.dx + sway * 1.6, base.dy - h * k)
      ..cubicTo(base.dx + w * .55 * k + sway, base.dy - h * .65 * k, base.dx + w * k, base.dy - h * .15 * k, base.dx, base.dy)
      ..close();
    c.drawCircle(base - Offset(0, h * .45), R * .6, Paint()
      ..shader = ui.Gradient.radial(base - Offset(0, h * .45), R * .6, [r27Gold.withValues(alpha: .35), Colors.transparent]));
    c.drawPath(flame(1), Paint()..shader = ui.Gradient.linear(base, base - Offset(0, h), const [Color(0xFFB4561E), r27Gold, Color(0xFFFFE6A8)], [0, .5, 1]));
    c.drawPath(flame(.5), Paint()..color = const Color(0xFFFFF6E0));
  }
  @override
  bool shouldRepaint(_FlameP o) => o.t != t || o.streak != streak || o.light != light;
}

// ── Streak candle (Normal home) ───────────────────────────────────────────
/// Growing candle flame for the Normal-home "YOUR STREAK" card.
/// Height follows the live streak. Day 0 is an unlit wick with a dim ember.
/// Painted as a tall flame and a short candle — no disc, ring, orb or particles.
class R27StreakCandle extends StatelessWidget {
  const R27StreakCandle({
    super.key,
    required this.streak,
    this.size = const Size(72, 84),
  });

  /// Real streak days; the flame grows with this value.
  final int streak;
  final Size size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$streak day streak',
    child: R27Anim(
      period: const Duration(milliseconds: 2600),
      builder: (_, t) => CustomPaint(size: size, painter: _CandleP(t, streak)),
    ),
  );
}

class _CandleP extends CustomPainter {
  _CandleP(this.t, this.streak);
  final double t;
  final int streak;
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final h = s.height;
    final w = s.width;

    // Slim column in the lower third so the unlit state still reads as a candle.
    final candleW = w * .28;
    final candleH = h * .34;
    final baseY = h - h * .05;
    final candleTop = baseY - candleH;

    final body = RRect.fromLTRBR(
      cx - candleW / 2,
      candleTop,
      cx + candleW / 2,
      baseY,
      const Radius.circular(3.5),
    );
    c.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - candleW / 2, candleTop),
          Offset(cx + candleW / 2, baseY),
          const [Color(0xFFFFF8EA), Color(0xFFF0D9A8), Color(0xFFE2C48A)],
          const [0, .55, 1],
        ),
    );
    // Soft left highlight, no circular shine.
    c.drawRRect(
      RRect.fromLTRBR(
        cx - candleW / 2 + 1.2,
        candleTop + 2,
        cx - candleW * .12,
        baseY - 2,
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x66FFFFFF),
    );
    // Thin wax lip and a small drip — a cap, not a lid or disc.
    final lip = RRect.fromLTRBR(
      cx - candleW / 2 - .8,
      candleTop - 1.4,
      cx + candleW / 2 + .8,
      candleTop + 1.8,
      const Radius.circular(1.2),
    );
    c.drawRRect(
      lip,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, candleTop - 1.4),
          Offset(cx, candleTop + 1.8),
          const [Color(0xFFFFE6A8), Color(0xFFD9A441), Color(0xFFB88A2E)],
          const [0, .55, 1],
        ),
    );
    final drip = Path()
      ..moveTo(cx + candleW / 2 - .4, candleTop + 1)
      ..cubicTo(cx + candleW / 2 + 3.2, candleTop + 4, cx + candleW / 2 + 2.4, candleTop + candleH * .42, cx + candleW / 2 + .2, candleTop + candleH * .46)
      ..lineTo(cx + candleW / 2 - .2, candleTop + 1.6)
      ..close();
    c.drawPath(drip, Paint()..color = const Color(0xFFE8C57A));

    final wickTop = candleTop - 8.5;
    final wick = RRect.fromLTRBR(
      cx - .7,
      wickTop,
      cx + .7,
      candleTop + .4,
      const Radius.circular(.8),
    );
    c.drawRRect(wick, Paint()..color = const Color(0xFF3A2A1C));

    final lit = streak > 0;
    // 1 day is already a clear flame; 7+ days reach full height.
    final strength = lit ? (.42 + .58 * ((streak.clamp(1, 7) - 1) / 6)) : 0.0;
    final flicker =
        1 + .10 * math.sin(t * _tau) + .05 * math.sin(t * _tau * 2.65 + .4);
    final sway =
        math.sin(t * _tau * 1.12) * .22 + math.sin(t * _tau * 2.35 + .7) * .08;
    final maxH = candleTop - h * .07;
    final flameH =
        maxH *
        (lit ? strength : .22) *
        (lit ? flicker : (1 + .12 * math.sin(t * _tau)));
    final flameW = w * (lit ? (.34 + .08 * strength) : .22);

    Path tongue(double k, double swayMul) {
      final base = Offset(cx, wickTop + 1.2);
      final tip = Offset(cx + sway * flameW * swayMul, base.dy - flameH * k);
      final midY = base.dy - flameH * k * .38;
      return Path()
        ..moveTo(base.dx - flameW * .12 * k, base.dy)
        ..cubicTo(
          base.dx - flameW * k,
          midY + flameH * k * .08,
          tip.dx - flameW * .28 * k,
          tip.dy + flameH * k * .28,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx + flameW * .28 * k,
          tip.dy + flameH * k * .28,
          base.dx + flameW * k,
          midY + flameH * k * .08,
          base.dx + flameW * .12 * k,
          base.dy,
        )
        ..close();
    }

    if (!lit) {
      // Dim ember: a short, dull tongue that breathes. Shape stays a flame, not a circle.
      final ember = tongue(.85, .35);
      c.drawPath(
        ember,
        Paint()
          ..color = const Color(0xCCC45C22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      c.drawPath(
        ember,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, wickTop),
            Offset(cx, wickTop - flameH),
            const [Color(0xFF8A3B16), Color(0xFFE07030), Color(0xFFFFC078)],
            const [0, .5, 1],
          ),
      );
      c.drawPath(tongue(.45, .2), Paint()..color = const Color(0xFFFFE0A0));
      return;
    }

    // Soft flame-shaped glow (follows the tongue, not a circular orb).
    c.drawPath(
      tongue(1.18, 1.05),
      Paint()
        ..color = const Color(0x55D9A441)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    c.drawPath(
      tongue(1, 1),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, wickTop),
          Offset(cx + sway * flameW, wickTop - flameH),
          const [Color(0xFFB4561E), Color(0xFFD9A441), Color(0xFFFFE6A8)],
          const [0, .48, 1],
        ),
    );
    c.drawPath(
      tongue(.68, .7),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, wickTop),
          Offset(cx + sway * flameW * .7, wickTop - flameH * .68),
          const [Color(0xFFE8A83A), Color(0xFFFFE6A8), Color(0xFFFFF6E0)],
          const [0, .5, 1],
        ),
    );
    c.drawPath(tongue(.38, .45), Paint()..color = const Color(0xFFFFF6E0));
  }

  @override
  bool shouldRepaint(_CandleP o) => o.t != t || o.streak != streak;
}

// ── Spinning coin ─────────────────────────────────────────────────────────
class R27Coin extends StatelessWidget {
  const R27Coin({super.key, this.size = 52});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: R27Anim(
          period: const Duration(milliseconds: 3200),
          builder: (_, t) => CustomPaint(size: Size.square(size), painter: _CoinP(t)),
        ),
      );
}

class _CoinP extends CustomPainter {
  _CoinP(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final R = s.shortestSide * .4;
    final sx = math.cos(t * _tau).abs().clamp(.08, 1.0);
    // sparkles orbit
    for (var i = 0; i < 4; i++) {
      final a = t * _tau + i * _tau / 4;
      final p = o + Offset(math.cos(a) * R * 1.18, math.sin(a) * R * .5 - R * .1);
      final k = .5 + .5 * math.sin(a * 2);
      c.drawCircle(p, 1 + 1.6 * k, Paint()..color = const Color(0xFFFFE6A8).withValues(alpha: .4 + .5 * k));
    }
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(sx, 1);
    final rim = Rect.fromCircle(center: Offset.zero, radius: R);
    c.drawOval(rim.shift(const Offset(2.5, 0)), Paint()..color = const Color(0xFF7A5313));
    c.drawOval(rim, Paint()..shader = ui.Gradient.linear(rim.topLeft, rim.bottomRight, const [Color(0xFFFFE6A8), r27Gold, Color(0xFF8C6118)], [0, .5, 1]));
    c.drawCircle(Offset.zero, R * .78, Paint()..style = PaintingStyle.stroke..strokeWidth = R * .06..color = const Color(0xFF8C6118));
    // lotus emboss (no letters)
    final petal = Paint()..color = const Color(0xFF8C6118);
    for (var i = -2; i <= 2; i++) {
      c.save();
      c.rotate(i * .42);
      c.drawPath(Path()
        ..moveTo(0, R * .38)
        ..quadraticBezierTo(R * .2, 0, 0, -R * .46)
        ..quadraticBezierTo(-R * .2, 0, 0, R * .38), petal);
      c.restore();
    }
    c.restore();
  }
  @override
  bool shouldRepaint(_CoinP o) => o.t != t;
}

// ── Poster drift (Ken Burns crossfade) ────────────────────────────────────
/// Slow pan-and-fade through hour posters with each poster's word in
/// Anton. Words come from assets/content/library.json.
class R27PosterDrift extends StatelessWidget {
  const R27PosterDrift({super.key, required this.hours, this.showWord = true});
  final List<String> hours;
  final bool showWord;
  @override
  Widget build(BuildContext context) => R27Anim(
        period: Duration(seconds: 7 * hours.length),
        builder: (_, t) {
          final f = t * hours.length;
          final i = f.floor() % hours.length;
          final local = f - f.floor();
          final fade = ((local - .8) / .2).clamp(0.0, 1.0);
          Widget layer(int k, double lt, double op) => Opacity(
                opacity: op,
                child: Transform.scale(
                  scale: 1.06 + .08 * lt,
                  alignment: Alignment(-.4 + .8 * lt, .2),
                  child: R27Img(hours[k]),
                ),
              );
          final next = (i + 1) % hours.length;
          return ClipRect(
            child: Stack(fit: StackFit.expand, children: [
              layer(i, local, 1),
              if (fade > 0) layer(next, 0, fade),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [Color(0xE6000000), Color(0x00000000)], stops: [0, .7]))),
              if (showWord)
                Positioned(left: 16, top: 14, bottom: 14, width: 150,
                  child: Opacity(
                    opacity: 1 - fade,
                    child: R27Word(hours[i].toUpperCase(), color: Colors.white),
                  )),
            ]),
          );
        },
      );
}

// ── Seated meditator ──────────────────────────────────────────────────────
/// Breathing seated silhouette with sound rings — the meditation figure
/// that replaces the fashion model cut-outs in the ritual hero.
class R27Meditator extends StatelessWidget {
  const R27Meditator({super.key, this.color = r27Gold, this.size = const Size(220, 220), this.figure = true});
  final Color color;
  /// false = sound rings only (when the poster behind already shows a sitter).
  final bool figure;
  final Size size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: R27Anim(
          period: const Duration(seconds: 8),
          builder: (_, t) => CustomPaint(size: size, painter: _SitP(t, color, figure)),
        ),
      );
}

class _SitP extends CustomPainter {
  _SitP(this.t, this.color, this.figure);
  final double t;
  final Color color;
  final bool figure;
  @override
  void paint(Canvas c, Size s) {
    final u = math.min(s.width, s.height);
    final cx = s.width / 2, base = s.height * .92;
    final b = math.sin(t * _tau) * .5 + .5; // breath
    final head = Offset(cx, base - u * (.66 + .012 * b));
    for (var k = 0; k < 3; k++) {
      final p = (t * 1.5 + k / 3) % 1;
      c.drawCircle(head, u * (.12 + .42 * p), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = color.withValues(alpha: (1 - p) * .5));
    }
    c.drawCircle(head, u * .22, Paint()..shader = ui.Gradient.radial(head, u * .22, [color.withValues(alpha: .35), Colors.transparent]));
    if (!figure) return;
    final fill = Paint()..shader = ui.Gradient.linear(Offset(cx, head.dy), Offset(cx, base), [const Color(0xFF1C1A17), r27Black]);
    final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeJoin = StrokeJoin.round..color = color.withValues(alpha: .85);
    final r = u * .07, sw = u * (.15 + .006 * b), sh = head.dy + r + u * .07;
    // seated lotus pose: shoulders, elbows out, hands on knees, crossed legs
    final body = Path()
      ..moveTo(cx - u * .035, head.dy + r * .9)
      ..lineTo(cx - u * .035, sh - u * .04)
      ..quadraticBezierTo(cx - sw, sh - u * .03, cx - sw * 1.05, sh + u * .06)
      ..quadraticBezierTo(cx - sw * 1.45, base - u * .26, cx - sw * 1.7, base - u * .14)
      ..quadraticBezierTo(cx - u * .44, base - u * .1, cx - u * .45, base - u * .045)
      ..quadraticBezierTo(cx - u * .43, base + u * .005, cx, base)
      ..quadraticBezierTo(cx + u * .43, base + u * .005, cx + u * .45, base - u * .045)
      ..quadraticBezierTo(cx + u * .44, base - u * .1, cx + sw * 1.7, base - u * .14)
      ..quadraticBezierTo(cx + sw * 1.45, base - u * .26, cx + sw * 1.05, sh + u * .06)
      ..quadraticBezierTo(cx + sw, sh - u * .03, cx + u * .035, sh - u * .04)
      ..lineTo(cx + u * .035, head.dy + r * .9)
      ..close();
    c.drawPath(body, fill);
    c.drawPath(body, edge);
    // inner arm line and the crossed shin
    for (final d in [-1.0, 1.0]) {
      c.drawPath(Path()
        ..moveTo(cx + d * sw * .62, sh + u * .1)
        ..quadraticBezierTo(cx + d * sw * .8, base - u * .2, cx + d * sw * 1.35, base - u * .15), edge);
    }
    c.drawPath(Path()
      ..moveTo(cx - u * .36, base - u * .06)
      ..quadraticBezierTo(cx, base - u * .14, cx + u * .36, base - u * .06), edge);
    // hands in mudra on the knees
    for (final d in [-1.0, 1.0]) {
      c.drawCircle(Offset(cx + d * sw * 1.72, base - u * .135), u * .018, Paint()..color = color);
    }
    c.drawCircle(head, r, fill);
    c.drawCircle(head, r, edge);
  }
  @override
  bool shouldRepaint(_SitP o) => o.t != t;
}

// ── Gift ribbon ───────────────────────────────────────────────────────────
class R27Ribbon extends CustomPainter {
  R27Ribbon(this.t, {this.color = r27Gold});
  final double t;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final x = s.width * .5, y = s.height * .42;
    final band = Paint()..color = color;
    c.drawRect(Rect.fromLTWH(x - 7, 0, 14, s.height), band);
    c.drawRect(Rect.fromLTWH(0, y - 7, s.width, 14), band);
    // moving sheen
    final sx = -s.width * .4 + (s.width * 1.8) * t;
    c.drawRect(Offset.zero & s, Paint()
      ..blendMode = BlendMode.srcATop
      ..shader = ui.Gradient.linear(Offset(sx, 0), Offset(sx + s.width * .3, s.height),
          [Colors.transparent, Colors.white.withValues(alpha: .28), Colors.transparent], [0, .5, 1]));
    // bow
    final lift = math.sin(t * _tau) * 2;
    for (final d in [-1.0, 1.0]) {
      c.drawPath(Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + d * 30, y - 30 - lift, x + d * 34, y - 6)
        ..quadraticBezierTo(x + d * 22, y + 6, x, y)
        ..close(), band);
      c.drawPath(Path()
        ..moveTo(x, y)
        ..lineTo(x + d * 18, y + 30 + lift)
        ..lineTo(x + d * 8, y + 26)
        ..close(), band);
    }
    c.drawCircle(Offset(x, y), 8, Paint()..color = Color.lerp(color, Colors.black, .25)!);
  }
  @override
  bool shouldRepaint(R27Ribbon o) => o.t != t;
}

// ── Foil (sealed scratch card) ────────────────────────────────────────────
class R27Foil extends CustomPainter {
  R27Foil(this.t, this.tint);
  final double t;
  final Color tint;
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16));
    c.drawRRect(r, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(s.width, s.height),
        [Color.lerp(tint, Colors.black, .55)!, Color.lerp(tint, Colors.black, .8)!, Color.lerp(tint, Colors.black, .5)!], [0, .5, 1]));
    c.save();
    c.clipRRect(r);
    final rnd = math.Random(7);
    final dot = Paint()..color = Colors.white.withValues(alpha: .08);
    for (var i = 0; i < 140; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height), .6 + rnd.nextDouble(), dot);
    }
    for (var k = 0; k < 2; k++) {
      final x = -s.width + (s.width * 3) * ((t + k * .5) % 1);
      c.drawPath(Path()
        ..moveTo(x, 0)
        ..lineTo(x + 40, 0)
        ..lineTo(x + 40 - s.height * .6, s.height)
        ..lineTo(x - s.height * .6, s.height)
        ..close(), Paint()..color = tint.withValues(alpha: .18));
    }
    c.restore();
    c.drawRRect(r.deflate(.7), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = tint.withValues(alpha: .7));
  }
  @override
  bool shouldRepaint(R27Foil o) => o.t != t || o.tint != tint;
}
