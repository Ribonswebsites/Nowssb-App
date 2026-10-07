/// More animations (item 8): four or five new drawings in each category.
/// Ids are saved in layouts — never rename or remove one.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'anim_core.dart';

const kMoreAnims = <AnimSpec>[
  // Orbs
  AnimSpec('orb.lotus', 'Lotus', AnimCategory.orbs, paint: _lotus),
  AnimSpec('orb.mandala', 'Mandala', AnimCategory.orbs, paint: _mandala),
  AnimSpec('orb.sun', 'Sun disc', AnimCategory.orbs, paint: _sun),
  AnimSpec('orb.moon', 'Moon phase', AnimCategory.orbs, paint: _moon),
  AnimSpec('orb.breath', 'Breath ring', AnimCategory.orbs, paint: _breath),
  // Loaders
  AnimSpec('ld.pendulum', 'Pendulum', AnimCategory.loaders, paint: _pendulum),
  AnimSpec('ld.stairs', 'Stairs', AnimCategory.loaders, paint: _stairs),
  AnimSpec('ld.squares', 'Square chase', AnimCategory.loaders, paint: _squares),
  AnimSpec('ld.heart', 'Heart fill', AnimCategory.loaders, paint: _heartFill),
  // Backgrounds
  AnimSpec('bg.dunes', 'Dunes', AnimCategory.backgrounds, paint: _dunes, clip: true),
  AnimSpec('bg.tiles', 'Tile pulse', AnimCategory.backgrounds, paint: _tiles, clip: true),
  AnimSpec('bg.beams', 'Light beams', AnimCategory.backgrounds, paint: _beams, clip: true),
  AnimSpec('bg.contour', 'Contours', AnimCategory.backgrounds, paint: _contour, clip: true),
  // Particles
  AnimSpec('pt.petals', 'Petal fall', AnimCategory.particles, paint: _petals),
  AnimSpec('pt.orbiters', 'Orbiters', AnimCategory.particles, paint: _orbiters),
  AnimSpec('pt.dandelion', 'Dandelion', AnimCategory.particles, paint: _dandelion),
  AnimSpec('pt.comets', 'Meteor shower', AnimCategory.particles, paint: _meteors),
  // Celebrations
  AnimSpec('cb.crown', 'Crown', AnimCategory.celebrations, paint: _crown),
  AnimSpec('cb.thumbs', 'Thumbs up', AnimCategory.celebrations, paint: _thumbs),
  AnimSpec('cb.rocket', 'Rocket', AnimCategory.celebrations, paint: _rocket),
  AnimSpec('cb.medal', 'Medal', AnimCategory.celebrations, paint: _medal),
  AnimSpec('cb.sparkler', 'Sparkler', AnimCategory.celebrations, paint: _sparkler),
];

// ── Orbs ──

void _lotus(Canvas c, double t, AnimInk k) {
  final open = 0.75 + 0.25 * osc(t, 3);
  for (var layer = 0; layer < 2; layer++) {
    final n = layer == 0 ? 8 : 6;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i - (n - 1) / 2) * (layer == 0 ? 0.38 : 0.42) * open;
      c.save();
      c.translate(50, 70);
      c.rotate(a + math.pi / 2);
      final len = layer == 0 ? 40.0 : 30.0;
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-10, -len * 0.55, 0, -len)
        ..quadraticBezierTo(10, -len * 0.55, 0, 0);
      c.drawPath(path, fillOf(fade(layer == 0 ? k.pink : k.gold, 0.55 + 0.1 * layer)));
      c.restore();
    }
  }
  c.drawCircle(const Offset(50, 70), 5, fillOf(k.gold));
}

void _mandala(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  for (var ring = 0; ring < 3; ring++) {
    final n = 6 + ring * 4;
    final r = 12.0 + ring * 12;
    final spin = (ring.isEven ? 1 : -1) * t * (0.4 + ring * 0.15);
    for (var i = 0; i < n; i++) {
      final a = spin + i * tau / n;
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      c.drawCircle(p, 3.2 - ring * 0.6, strokeOf(k.palette[ring + 1], 1.6));
    }
    c.drawCircle(Offset.zero, r, strokeOf(fade(k.fg, 0.15), 1));
  }
  c.drawCircle(Offset.zero, 5 + 1.5 * osc(t, 2), fillOf(k.gold));
  c.restore();
}

void _sun(Canvas c, double t, AnimInk k) {
  final glow = 0.5 + 0.5 * osc(t, 2.4);
  c.drawCircle(kMid, 34 + 4 * glow, fillOf(fade(k.orange, 0.18)));
  for (var i = 0; i < 16; i++) {
    final a = i * tau / 16 + t * 0.3;
    final l = i.isEven ? 44.0 : 38.0;
    c.drawLine(polar(28, a), polar(l, a), strokeOf(fade(k.gold, 0.8), 2.4));
  }
  c.drawCircle(kMid, 24, Paint()..shader = ui.Gradient.radial(const Offset(44, 44), 26, [const Color(0xFFFFF3C4), k.orange]));
}

void _moon(Canvas c, double t, AnimInk k) {
  final p = saw(t, 6);
  c.drawCircle(kMid, 30, fillOf(fade(k.fg, 0.92)));
  final dx = (p * 2 - 1) * 64;
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: kMid, radius: 30)));
  c.drawCircle(Offset(50 + dx, 50), 31, fillOf(const Color(0xFF0B1120)));
  c.restore();
  c.drawCircle(kMid, 30, strokeOf(fade(k.sky, 0.5), 1.5));
  for (var i = 0; i < 5; i++) {
    c.drawCircle(Offset(10 + rnd(i) * 80, 8 + rnd(i, 1) * 20), 1 + osc(t, 1.5, rnd(i, 2)).abs(), fillOf(fade(k.fg, 0.7)));
  }
}

void _breath(Canvas c, double t, AnimInk k) {
  final s = 0.5 - 0.5 * math.cos(saw(t, 8) * tau);
  final r = 16 + 22 * s;
  c.drawCircle(kMid, r + 6, fillOf(fade(k.mint, 0.12)));
  c.drawCircle(kMid, r, strokeOf(k.mint, 4));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 44), -math.pi / 2, tau * saw(t, 8), false, strokeOf(fade(k.fg, 0.4), 2));
}

// ── Loaders ──

void _pendulum(Canvas c, double t, AnimInk k) {
  final a = 0.7 * osc(t, 1.6);
  final bob = Offset(50 + math.sin(a) * 40, 14 + math.cos(a) * 40);
  c.drawLine(const Offset(50, 14), bob, strokeOf(fade(k.fg, 0.6), 2));
  c.drawCircle(const Offset(50, 14), 3, fillOf(k.fg));
  c.drawCircle(bob, 10, fillOf(k.violet));
  c.drawCircle(bob.translate(-3, -3), 3, fillOf(fade(k.fg, 0.5)));
}

void _stairs(Canvas c, double t, AnimInk k) {
  final lead = (t * 5).floor() % 6;
  for (var i = 0; i < 5; i++) {
    final on = i <= lead && lead < 5;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 + i * 15.0, 74 - i * 12.0, 12, 8 + i * 12.0), const Radius.circular(3)),
      fillOf(on ? k.palette[i % 6] : fade(k.fg, 0.12)),
    );
  }
}

void _squares(Canvas c, double t, AnimInk k) {
  const spots = [Offset(30, 30), Offset(70, 30), Offset(70, 70), Offset(30, 70)];
  for (var i = 0; i < 3; i++) {
    final p = saw(t, 2.4, i / 3) * 4;
    final a = spots[p.floor() % 4], b = spots[(p.floor() + 1) % 4];
    final f = Curves.easeInOut.transform(p - p.floor());
    final at = Offset.lerp(a, b, f)!;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 22, height: 22), const Radius.circular(5)), fillOf(k.palette[i + 2]));
  }
}

Path _heartPath() => Path()
  ..moveTo(50, 82)
  ..cubicTo(10, 56, 18, 18, 50, 34)
  ..cubicTo(82, 18, 90, 56, 50, 82)
  ..close();

void _heartFill(Canvas c, double t, AnimInk k) {
  final h = _heartPath();
  final p = saw(t, 2.2);
  c.drawPath(h, strokeOf(k.pink, 3));
  c.save();
  c.clipPath(h);
  final y = 84 - 56 * p;
  final wave = Path()..moveTo(0, 100);
  for (var x = 0.0; x <= 100; x += 5) {
    wave.lineTo(x, y + 3 * math.sin(x / 9 + t * 6));
  }
  wave
    ..lineTo(100, 100)
    ..close();
  c.drawPath(wave, fillOf(fade(k.pink, 0.85)));
  c.restore();
}

// ── Backgrounds ──

void _dunes(Canvas c, double t, AnimInk k) {
  c.drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [const Color(0xFF3B1D5A), const Color(0xFFF59E0B)]));
  for (var i = 0; i < 4; i++) {
    final base = 52.0 + i * 13;
    final path = Path()..moveTo(0, 100);
    for (var x = 0.0; x <= 100; x += 4) {
      path.lineTo(x, base + 7 * math.sin(x / (14 + i * 4) + t * (0.3 + i * 0.12) + i));
    }
    path
      ..lineTo(100, 100)
      ..close();
    c.drawPath(path, fillOf(Color.lerp(const Color(0xFFB45309), const Color(0xFF451A03), i / 3)!));
  }
}

void _tiles(Canvas c, double t, AnimInk k) {
  c.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fillOf(const Color(0xFF0B1120)));
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 6; x++) {
      final d = math.sqrt((x - 2.5) * (x - 2.5) + (y - 2.5) * (y - 2.5));
      final v = 0.5 + 0.5 * math.sin(d * 1.3 - t * 3);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(3 + x * 16.3, 3 + y * 16.3, 13, 13), const Radius.circular(3)),
        fillOf(Color.lerp(k.violet, k.sky, v)!.withValues(alpha: 0.25 + 0.6 * v)),
      );
    }
  }
}

void _beams(Canvas c, double t, AnimInk k) {
  c.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fillOf(const Color(0xFF05070D)));
  for (var i = 0; i < 5; i++) {
    final a = -0.6 + i * 0.3 + 0.15 * osc(t, 4.0 + i, i * 0.2);
    final path = Path()
      ..moveTo(50, -6)
      ..lineTo(50 + math.tan(a - 0.06) * 110, 104)
      ..lineTo(50 + math.tan(a + 0.06) * 110, 104)
      ..close();
    c.drawPath(path, Paint()..shader = ui.Gradient.linear(const Offset(50, 0), const Offset(50, 100), [fade(k.palette[i], 0.7), fade(k.palette[i], 0)]));
  }
}

void _contour(Canvas c, double t, AnimInk k) {
  c.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fillOf(const Color(0xFF0E1A16)));
  for (var i = 0; i < 9; i++) {
    final path = Path();
    for (var a = 0.0; a <= tau + 0.01; a += 0.15) {
      final r = 6.0 + i * 7 + 3 * math.sin(a * 3 + t * 0.8 + i * 0.5);
      final p = Offset(44 + math.cos(a) * r, 56 + math.sin(a) * r * 0.8);
      a == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, strokeOf(fade(k.mint, 0.75 - i * 0.07), 1.2));
  }
}

// ── Particles ──

void _petals(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(14); i++) {
    final p = saw(t, 5 + rnd(i) * 3, rnd(i, 1));
    final x = rnd(i, 2) * 100 + 10 * math.sin(p * tau * 2 + i);
    final y = -8 + p * 116;
    c.save();
    c.translate(x, y);
    c.rotate(p * tau * (rnd(i, 3) > 0.5 ? 1 : -1));
    c.drawOval(const Rect.fromLTWH(-5, -2.5, 10, 5), fillOf(fade(i.isEven ? k.pink : const Color(0xFFFFC2D6), 0.85)));
    c.restore();
  }
}

void _orbiters(Canvas c, double t, AnimInk k) {
  for (var ring = 0; ring < 3; ring++) {
    final rx = 18.0 + ring * 13, ry = rx * (0.4 + ring * 0.15);
    c.save();
    c.translate(50, 50);
    c.rotate(ring * 0.9);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), strokeOf(fade(k.fg, 0.12), 1));
    for (var j = 0; j < 2; j++) {
      final a = t * (1.6 - ring * 0.35) + j * math.pi;
      c.drawCircle(Offset(math.cos(a) * rx, math.sin(a) * ry), 3.4, fillOf(k.palette[ring * 2 + j]));
    }
    c.restore();
  }
  c.drawCircle(kMid, 6, fillOf(k.gold));
}

void _dandelion(Canvas c, double t, AnimInk k) {
  c.drawLine(const Offset(50, 96), const Offset(50, 56), strokeOf(fade(k.mint, 0.8), 2));
  for (var i = 0; i < k.n(18); i++) {
    final a = i * tau / 18;
    final away = saw(t, 4, rnd(i));
    final gone = away > 0.55;
    final base = polar(12, a, const Offset(50, 48));
    final p = gone ? base + Offset(30 * (away - 0.55) * 4 + rnd(i, 1) * 10, -20 * (away - 0.55) * 4) : base;
    c.drawLine(const Offset(50, 48), gone ? p : base, strokeOf(fade(k.fg, gone ? 0 : 0.5), 0.8));
    c.drawCircle(p, 1.8, fillOf(fade(k.fg, gone ? 1 - (away - 0.55) / 0.45 : 0.9)));
  }
}

void _meteors(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(7); i++) {
    final p = saw(t, 1.6 + rnd(i) * 1.4, rnd(i, 1));
    final start = Offset(20 + rnd(i, 2) * 110, -10);
    final head = start + Offset(-p * 90, p * 90);
    final tail = head + const Offset(16, -16);
    c.drawLine(tail, head, Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(tail, head, [fade(k.sky, 0), k.fg]));
    c.drawCircle(head, 1.8, fillOf(k.fg));
  }
}

// ── Celebrations ──

void _crown(Canvas c, double t, AnimInk k) {
  final bob = 3 * osc(t, 1.4);
  final path = Path()
    ..moveTo(20, 70 + bob)
    ..lineTo(16, 34 + bob)
    ..lineTo(34, 50 + bob)
    ..lineTo(50, 26 + bob)
    ..lineTo(66, 50 + bob)
    ..lineTo(84, 34 + bob)
    ..lineTo(80, 70 + bob)
    ..close();
  c.drawPath(path, Paint()..shader = ui.Gradient.linear(const Offset(0, 26), const Offset(0, 70), [const Color(0xFFFFE08A), k.orange]));
  for (final x in [16.0, 50.0, 84.0]) {
    c.drawCircle(Offset(x, (x == 50 ? 24 : 32) + bob), 4, fillOf(k.pink));
  }
  for (var i = 0; i < 6; i++) {
    final s = saw(t, 1.2, i / 6);
    c.drawCircle(polar(40 + 10 * s, i * tau / 6 + 0.3, const Offset(50, 50)), 2 * (1 - s), fillOf(fade(k.gold, 1 - s)));
  }
}

void _thumbs(Canvas c, double t, AnimInk k) {
  final s = 1 + 0.12 * math.max(0, osc(t, 1.2));
  c.save();
  c.translate(50, 54);
  c.scale(s, s);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-28, -4, 12, 30), const Radius.circular(3)), fillOf(k.sky));
  final hand = Path()
    ..moveTo(-12, -4)
    ..lineTo(0, -30)
    ..quadraticBezierTo(8, -32, 6, -18)
    ..lineTo(4, -8)
    ..lineTo(22, -8)
    ..quadraticBezierTo(30, -6, 26, 4)
    ..lineTo(20, 24)
    ..quadraticBezierTo(18, 28, 12, 28)
    ..lineTo(-12, 28)
    ..close();
  c.drawPath(hand, fillOf(k.gold));
  c.restore();
}

void _rocket(Canvas c, double t, AnimInk k) {
  final up = (saw(t, 2.4) * 130) - 30;
  final y = 80 - up;
  for (var i = 0; i < 8; i++) {
    final s = saw(t, 0.5, i / 8);
    c.drawCircle(Offset(50 + (rnd(i) - 0.5) * 10 * s, y + 18 + s * 22), 4 * (1 - s), fillOf(fade(i.isEven ? k.orange : k.gold, 1 - s)));
  }
  final body = Path()
    ..moveTo(50, y - 22)
    ..quadraticBezierTo(62, y - 6, 58, y + 14)
    ..lineTo(42, y + 14)
    ..quadraticBezierTo(38, y - 6, 50, y - 22)
    ..close();
  c.drawPath(body, fillOf(k.fg));
  c.drawCircle(Offset(50, y - 4), 4, fillOf(k.sky));
  c.drawPath(Path()..moveTo(42, y + 4)..lineTo(34, y + 16)..lineTo(42, y + 14)..close(), fillOf(k.pink));
  c.drawPath(Path()..moveTo(58, y + 4)..lineTo(66, y + 16)..lineTo(58, y + 14)..close(), fillOf(k.pink));
}

void _medal(Canvas c, double t, AnimInk k) {
  final swing = 0.12 * osc(t, 1.8);
  c.save();
  c.translate(50, 8);
  c.rotate(swing);
  c.drawPath(Path()..moveTo(-14, 0)..lineTo(-4, 40)..lineTo(4, 40)..lineTo(-6, 0)..close(), fillOf(k.sky));
  c.drawPath(Path()..moveTo(14, 0)..lineTo(4, 40)..lineTo(-4, 40)..lineTo(6, 0)..close(), fillOf(k.pink));
  c.drawCircle(const Offset(0, 58), 20, fillOf(k.gold));
  c.drawCircle(const Offset(0, 58), 14, strokeOf(fade(const Color(0xFF7A5A1A), 0.8), 2));
  final shine = saw(t, 2.2);
  c.drawLine(Offset(-14 + shine * 28, 46), Offset(-20 + shine * 28, 70), strokeOf(fade(Colors.white, 0.6 * (1 - shine)), 3));
  c.restore();
}

void _sparkler(Canvas c, double t, AnimInk k) {
  c.drawLine(const Offset(30, 92), const Offset(58, 40), strokeOf(fade(k.fg, 0.5), 2));
  const tip = Offset(58, 40);
  for (var i = 0; i < k.n(24); i++) {
    final s = saw(t, 0.45 + rnd(i) * 0.3, rnd(i, 1));
    final a = rnd(i, 2) * tau;
    final r = 4 + s * 24;
    final p = polar(r, a, tip);
    c.drawLine(polar(r * 0.6, a, tip), p, strokeOf(fade(i % 3 == 0 ? k.gold : k.fg, 1 - s), 1.2));
  }
  c.drawCircle(tip, 4, fillOf(const Color(0xFFFFF3C4)));
}
