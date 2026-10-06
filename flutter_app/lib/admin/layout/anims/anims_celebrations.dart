/// Celebrate: confetti, fireworks and other "you did it" moments.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'anim_core.dart';

const kCelebrationAnims = <AnimSpec>[
  AnimSpec('cb.confetti', 'Confetti', AnimCategory.celebrations, paint: _confetti),
  AnimSpec('cb.rain', 'Confetti rain', AnimCategory.celebrations, paint: _confettiRain),
  AnimSpec('cb.fireworks', 'Fireworks', AnimCategory.celebrations, paint: _fireworks),
  AnimSpec('cb.balloons', 'Balloons', AnimCategory.celebrations, paint: _balloons),
  AnimSpec('cb.streamers', 'Streamers', AnimCategory.celebrations, paint: _streamers),
  AnimSpec('cb.popper', 'Popper', AnimCategory.celebrations, paint: _popper),
  AnimSpec('cb.stars', 'Star burst', AnimCategory.celebrations, paint: _starBurst),
  AnimSpec('cb.trophy', 'Trophy', AnimCategory.celebrations, paint: _trophy),
  AnimSpec('cb.hearts', 'Love burst', AnimCategory.celebrations, paint: _heartBurst),
  AnimSpec('cb.check', 'Success', AnimCategory.celebrations, paint: _check),
  AnimSpec('cb.glitter', 'Glitter', AnimCategory.celebrations, paint: _glitter),
  AnimSpec('cb.badge', 'Badge', AnimCategory.celebrations, paint: _badge),
  AnimSpec('cb.coins', 'Coins', AnimCategory.celebrations, paint: _coins),
  AnimSpec('cb.gift', 'Gift', AnimCategory.celebrations, paint: _gift),
];

const _party = [Color(0xFFFF5C9A), Color(0xFF4CC3FF), Color(0xFFFFD43B), Color(0xFF34D399), Color(0xFF9F7BFF), Color(0xFFFFA94D)];

void _piece(Canvas c, Offset o, double rot, double flip, Color col, int shape) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(rot);
  final p = fillOf(col);
  switch (shape % 3) {
    case 0:
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: 5, height: 2.6 * flip.abs() + 0.3), p);
    case 1:
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 3.2 * flip.abs() + 0.3, height: 3.2), p);
    default:
      c.drawPath(Path()..addPolygon([const Offset(0, -2.2), Offset(2.2 * flip, 1.6), Offset(-2.2 * flip, 1.6)], true), p);
  }
  c.restore();
}

void _confetti(Canvas c, double t, AnimInk k) {
  const period = 2.6;
  final s = saw(t, period) * period;
  for (var i = 0; i < k.n(60); i++) {
    final a = -math.pi / 2 + (rnd(i, 1) - 0.5) * 2.4;
    final v = 50 + rnd(i, 2) * 45;
    final drag = 1 - math.exp(-s * 2.2);
    final p = Offset(50 + math.cos(a) * v * drag / 2.2 * 1.6, 70 + math.sin(a) * v * drag / 2.2 * 1.6 + 14 * s * s);
    final alpha = (1 - s / period * 1.1).clamp(0.0, 1.0);
    _piece(c, p, t * 5 * (rnd(i, 3) - 0.5) + i, math.cos(t * 7 + i), fade(_party[i % 6], alpha), i);
  }
}

void _confettiRain(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(50); i++) {
    final sp = 0.7 + rnd(i, 1) * 0.6;
    final y = (rnd(i, 2) * 120 + t * 22 * sp) % 120 - 10;
    final x = rnd(i, 3) * 100 + math.sin(t * 2 * sp + i) * 5;
    _piece(c, Offset(x, y), t * 2 * sp + i, math.cos(t * 6 * sp + i), _party[i % 6], i);
  }
}

void _fireworks(Canvas c, double t, AnimInk k) {
  for (var f = 0; f < 3; f++) {
    final period = 2.2 + f * 0.3;
    final cyc = saw(t, period, f * 0.33);
    final gen = ((t / period) + f * 0.33).floor();
    final centre = Offset(22 + rnd(gen * 3 + f, 1) * 56, 22 + rnd(gen * 3 + f, 2) * 34);
    final col = _party[(gen + f) % 6];
    if (cyc < 0.25) {
      final u = cyc / 0.25;
      final from = Offset(centre.dx, 100);
      c.drawLine(Offset.lerp(from, centre, u * 0.85)!, Offset.lerp(from, centre, u)!, strokeOf(fade(col, 0.9), 1.2));
      continue;
    }
    final u = (cyc - 0.25) / 0.75;
    final e = Curves.easeOutCubic.transform(u);
    final n = k.n(26);
    for (var i = 0; i < n; i++) {
      final a = i * tau / n;
      final r = e * 22;
      final p = polar(r, a, centre) + Offset(0, u * u * 8);
      c.drawLine(polar(r * 0.8, a, centre) + Offset(0, u * u * 8), p, strokeOf(fade(col, 1 - u), 1.1));
      c.drawCircle(p, 0.9, fillOf(fade(Colors.white, (1 - u) * 0.9)));
    }
  }
}

void _balloons(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 6; i++) {
    final sp = 0.8 + rnd(i, 1) * 0.5;
    final y = (rnd(i, 2) * 140 - t * 10 * sp) % 140 + 10;
    final x = 12 + i * 15.0 + math.sin(t * sp + i) * 4;
    final col = _party[i];
    final string = Path()
      ..moveTo(x, y + 9)
      ..quadraticBezierTo(x + math.sin(t * 2 + i) * 3, y + 16, x, y + 24);
    c.drawPath(string, strokeOf(fade(k.fg, 0.5), 0.5));
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 13, height: 16),
        Paint()..shader = ui.Gradient.radial(Offset(x - 2.5, y - 3.5), 10, [Color.lerp(col, Colors.white, 0.5)!, col]));
    c.drawPath(Path()..addPolygon([Offset(x, y + 7.5), Offset(x - 1.5, y + 10), Offset(x + 1.5, y + 10)], true), fillOf(col));
  }
}

void _streamers(Canvas c, double t, AnimInk k) {
  for (var s = 0; s < 6; s++) {
    final p = Path();
    final x0 = 8 + s * 17.0;
    final fall = saw(t, 3.2, s / 6);
    for (var j = 0; j <= 20; j++) {
      final y = -20 + j * 5.0 + fall * 30;
      final x = x0 + math.sin(j * 0.6 + t * 3 + s) * 5;
      j == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    c.drawPath(p, strokeOf(_party[s], 2.4));
  }
}

void _popper(Canvas c, double t, AnimInk k) {
  const period = 2.2;
  final s = saw(t, period);
  for (var i = 0; i < k.n(40); i++) {
    final a = -math.pi / 4 + (rnd(i, 1) - 0.5) * 1.1;
    final v = 60 + rnd(i, 2) * 50;
    final tt = s * period;
    final p = Offset(22 + math.cos(a) * v * tt * 0.6, 80 + math.sin(a) * v * tt * 0.6 + 22 * tt * tt);
    _piece(c, p, t * 6 + i, math.cos(t * 8 + i), fade(_party[i % 6], (1 - s).clamp(0.0, 1.0)), i);
  }
  c.save();
  c.translate(18, 84);
  c.rotate(-math.pi / 4);
  final kick = s < 0.1 ? 1 + (0.1 - s) * 2 : 1.0;
  c.scale(kick, kick);
  c.drawPath(Path()..addPolygon([const Offset(-6, 0), const Offset(6, 0), const Offset(0, 16)], true), Paint()..shader = ui.Gradient.linear(const Offset(-6, 0), const Offset(6, 0), [k.violet, k.pink]));
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 3), fillOf(k.gold));
  c.restore();
}

void _starBurst(Canvas c, double t, AnimInk k) {
  final s = saw(t, 2);
  final e = Curves.easeOutBack.transform(s.clamp(0.0, 1.0));
  for (var i = 0; i < 8; i++) {
    final a = i * tau / 8 + s;
    final o = polar(10 + e * 30, a);
    c.drawPath(starPath(o, 5 * (1 - s * 0.6), 2.2 * (1 - s * 0.6), rot: t * 2), fillOf(fade(i.isEven ? k.gold : k.orange, 1 - s * 0.8)));
  }
  final pop = 1 + 0.15 * math.sin(math.min(1, s * 4) * math.pi);
  c.drawPath(starPath(kMid, 16 * pop, 7 * pop), Paint()..shader = ui.Gradient.radial(const Offset(48, 46), 18, [const Color(0xFFFFF3BF), k.gold]));
}

void _trophy(Canvas c, double t, AnimInk k) {
  final gold = Paint()..shader = ui.Gradient.linear(const Offset(30, 0), const Offset(70, 0), [const Color(0xFFB8860B), const Color(0xFFFFE066), const Color(0xFFB8860B)], [0, 0.5, 1]);
  final cup = Path()
    ..moveTo(32, 24)
    ..lineTo(68, 24)
    ..quadraticBezierTo(68, 56, 50, 60)
    ..quadraticBezierTo(32, 56, 32, 24)
    ..close();
  c.drawArc(const Rect.fromLTWH(22, 28, 16, 16), math.pi / 2, math.pi, false, strokeOf(const Color(0xFFD4A017), 3));
  c.drawArc(const Rect.fromLTWH(62, 28, 16, 16), -math.pi / 2, math.pi, false, strokeOf(const Color(0xFFD4A017), 3));
  c.drawPath(cup, gold);
  c.drawRect(const Rect.fromLTWH(46, 60, 8, 12), gold);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 72, 28, 7), const Radius.circular(2)), gold);
  c.save();
  c.clipPath(cup);
  final sx = -20 + saw(t, 2.4) * 140;
  c.drawPath(Path()..addPolygon([Offset(sx, 20), Offset(sx + 8, 20), Offset(sx - 12, 62), Offset(sx - 20, 62)], true), fillOf(fade(Colors.white, 0.7)));
  c.restore();
  for (var i = 0; i < 4; i++) {
    final tw = math.max(0.0, osc(t, 1.4, i * 0.25));
    c.drawPath(starPath(Offset(20 + rnd(i, 1) * 60, 10 + rnd(i, 2) * 20), 3.5 * tw + 0.1, 0.9 * tw + 0.05, points: 4), fillOf(k.gold));
  }
}

void _heartBurst(Canvas c, double t, AnimInk k) {
  final s = saw(t, 2.2);
  final beat = 1 + 0.18 * math.max(0.0, math.sin(s * tau * 2));
  c.drawPath(heartPath(const Offset(50, 52), 34 * beat), Paint()..shader = ui.Gradient.linear(const Offset(30, 30), const Offset(70, 70), [const Color(0xFFFF8FAB), k.pink]));
  for (var i = 0; i < 8; i++) {
    final a = i * tau / 8 - math.pi / 2;
    final e = Curves.easeOut.transform(s);
    c.drawPath(heartPath(polar(24 + e * 22, a, const Offset(50, 50)), 7 * (1 - s)), fillOf(fade(k.pink, 1 - s)));
  }
}

void _check(Canvas c, double t, AnimInk k) {
  final s = saw(t, 2.4);
  final ring = (s / 0.35).clamp(0.0, 1.0);
  final tick = ((s - 0.3) / 0.25).clamp(0.0, 1.0);
  final fill = Curves.easeOutBack.transform(((s - 0.25) / 0.2).clamp(0.0, 1.0));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 32), -math.pi / 2, tau * ring, false, strokeOf(k.mint, 4));
  c.drawCircle(kMid, 28 * fill, fillOf(fade(k.mint, 0.9)));
  final path = Path()
    ..moveTo(36, 51)
    ..lineTo(46, 61)
    ..lineTo(66, 40);
  final m = path.computeMetrics().first;
  c.drawPath(m.extractPath(0, m.length * tick), strokeOf(Colors.white, 6));
  if (s > 0.55) {
    final u = (s - 0.55) / 0.45;
    for (var i = 0; i < 10; i++) {
      final a = i * tau / 10;
      c.drawCircle(polar(36 + u * 12, a), 2 * (1 - u), fillOf(k.palette[i % 6]));
    }
  }
}

void _glitter(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(80); i++) {
    final y = (rnd(i, 1) * 110 + t * (6 + rnd(i, 2) * 8)) % 110 - 5;
    final x = rnd(i, 3) * 100 + math.sin(t + i) * 2;
    final flash = math.pow(0.5 + 0.5 * osc(t, 0.6 + rnd(i, 4), rnd(i, 5)), 4).toDouble();
    final col = Color.lerp(k.gold, Colors.white, flash)!;
    c.drawRect(Rect.fromCenter(center: Offset(x, y), width: 2.2, height: 2.2), fillOf(fade(col, 0.55 + flash * 0.45)));
    if (flash > 0.6) c.drawPath(starPath(Offset(x, y), 4.5 * flash, 0.8, points: 4), fillOf(fade(k.onLight ? k.orange : Colors.white, flash)));
  }
}

void _badge(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  c.rotate(t * 0.4);
  for (var i = 0; i < 12; i++) {
    c.save();
    c.rotate(i * tau / 12);
    c.drawPath(Path()..addPolygon([const Offset(-4, -26), const Offset(4, -26), const Offset(0, -46)], true), fillOf(fade(k.gold, 0.45)));
    c.restore();
  }
  c.restore();
  final wobble = 1 + 0.05 * osc(t, 1.6);
  c.drawPath(starPath(kMid, 30 * wobble, 25 * wobble, points: 14), fillOf(k.violet));
  c.drawCircle(kMid, 20 * wobble, fillOf(k.onLight ? Colors.white : const Color(0xFF1B1238)));
  c.drawPath(starPath(kMid, 11, 4.6), fillOf(k.gold));
}

void _coins(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(12); i++) {
    final s = saw(t, 1.6 + rnd(i, 1), rnd(i, 2));
    final y = -10 + s * 120;
    final x = 10 + rnd(i, 3) * 80;
    final w = (math.cos(t * 5 + i)).abs() * 12 + 1.5;
    final r = Rect.fromCenter(center: Offset(x, y), width: w, height: 12);
    c.drawOval(r, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [const Color(0xFFFFE066), const Color(0xFFD4A017)]));
    c.drawOval(r.deflate(2), strokeOf(fade(const Color(0xFFB8860B), 0.8), 0.8));
  }
}

void _gift(Canvas c, double t, AnimInk k) {
  final s = saw(t, 3);
  final shake = s < 0.4 ? math.sin(s * 60) * 0.06 * (s / 0.4) : 0.0;
  final open = Curves.easeOutBack.transform(((s - 0.45) / 0.2).clamp(0.0, 1.0));
  c.save();
  c.translate(50, 78);
  c.rotate(shake);
  c.drawRect(const Rect.fromLTWH(-20, -26, 40, 26), fillOf(k.pink));
  c.drawRect(const Rect.fromLTWH(-3, -26, 6, 26), fillOf(k.gold));
  c.save();
  c.translate(0, -26 - open * 18);
  c.rotate(-open * 0.35);
  c.drawRect(const Rect.fromLTWH(-23, -8, 46, 8), fillOf(Color.lerp(k.pink, Colors.white, 0.15)!));
  c.drawRect(const Rect.fromLTWH(-3, -8, 6, 8), fillOf(k.gold));
  c.drawOval(const Rect.fromLTWH(-10, -14, 10, 7), strokeOf(k.gold, 2.4));
  c.drawOval(const Rect.fromLTWH(0, -14, 10, 7), strokeOf(k.gold, 2.4));
  c.restore();
  c.restore();
  if (open > 0) {
    final u = ((s - 0.45) / 0.55).clamp(0.0, 1.0);
    for (var i = 0; i < k.n(18); i++) {
      final a = -math.pi / 2 + (rnd(i, 1) - 0.5) * 1.8;
      final r = u * (20 + rnd(i, 2) * 30);
      c.drawPath(starPath(polar(r, a, const Offset(50, 50)), 3, 1.2, points: 4), fillOf(fade(_party[i % 6], 1 - u)));
    }
  }
}
