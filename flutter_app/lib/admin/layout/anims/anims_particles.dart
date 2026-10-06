/// Particles: fields of small things moving together.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'anim_core.dart';

const kParticleAnims = <AnimSpec>[
  AnimSpec('pt.fireflies', 'Fireflies', AnimCategory.particles, paint: _fireflies),
  AnimSpec('pt.sparkles', 'Sparkles', AnimCategory.particles, paint: _sparkles),
  AnimSpec('pt.swarm', 'Swarm', AnimCategory.particles, paint: _swarm),
  AnimSpec('pt.vortex', 'Vortex', AnimCategory.particles, paint: _vortex),
  AnimSpec('pt.fountain', 'Fountain', AnimCategory.particles, paint: _fountain),
  AnimSpec('pt.smoke', 'Smoke', AnimCategory.particles, paint: _smoke),
  AnimSpec('pt.fire', 'Flame', AnimCategory.particles, paint: _fire),
  AnimSpec('pt.bubbles', 'Bubbles', AnimCategory.particles, paint: _bubbles),
  AnimSpec('pt.constellation', 'Network', AnimCategory.particles, paint: _network),
  AnimSpec('pt.rings', 'Ring dust', AnimCategory.particles, paint: _ringDust),
  AnimSpec('pt.magnet', 'Magnet', AnimCategory.particles, paint: _magnet),
  AnimSpec('pt.dissolve', 'Dissolve', AnimCategory.particles, paint: _dissolve),
  AnimSpec('pt.burst', 'Burst', AnimCategory.particles, paint: _burst),
  AnimSpec('pt.flow', 'Flow field', AnimCategory.particles, paint: _flow),
  AnimSpec('pt.leaves', 'Leaves', AnimCategory.particles, paint: _leaves),
  AnimSpec('pt.hearts', 'Hearts', AnimCategory.particles, paint: _hearts),
  AnimSpec('pt.lightning', 'Lightning', AnimCategory.particles, paint: _lightning),
];

void _fireflies(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(22); i++) {
    final x = 50 + math.sin(t * (0.3 + rnd(i, 1) * 0.4) + i) * 40 * rnd(i, 2) + (rnd(i, 3) - 0.5) * 30;
    final y = 50 + math.cos(t * (0.25 + rnd(i, 4) * 0.4) + i * 2) * 38 * rnd(i, 5);
    final glow = 0.5 + 0.5 * osc(t, 1.5 + rnd(i, 6) * 2, rnd(i, 7));
    c.drawCircle(Offset(x, y), 3.5, glowOf(fade(k.gold, glow * 0.6), 3));
    c.drawCircle(Offset(x, y), 1.2, fillOf(fade(k.onLight ? k.orange : const Color(0xFFFFF6C2), 0.4 + glow * 0.6)));
  }
}

void _sparkles(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(16); i++) {
    final cyc = saw(t, 1.6 + rnd(i, 1) * 1.4, rnd(i, 2));
    final gen = ((t / (1.6 + rnd(i, 1) * 1.4)) + rnd(i, 2)).floor();
    final o = Offset(10 + rnd(i * 31 + gen, 3) * 80, 10 + rnd(i * 31 + gen, 4) * 80);
    final s = math.sin(cyc * math.pi);
    final r = 2 + rnd(i, 5) * 5;
    c.drawPath(starPath(o, r * s + 0.1, r * s * 0.25 + 0.05, points: 4, rot: cyc), fillOf(i.isEven ? k.gold : k.fg));
  }
}

void _swarm(Canvas c, double t, AnimInk k) {
  Offset path(double u) => Offset(50 + math.sin(u * 0.9) * 32, 50 + math.sin(u * 1.4) * 28);
  for (var i = 0; i < k.n(70); i++) {
    final lag = rnd(i, 1) * 1.4;
    final j = Offset(math.sin(t * 3 + i) * 9 * rnd(i, 2), math.cos(t * 2.6 + i) * 9 * rnd(i, 3));
    c.drawCircle(path(t - lag) + j, 1.8 - lag * 0.6, fillOf(fade(Color.lerp(k.sky, k.violet, lag / 1.4)!, 1 - lag * 0.5)));
  }
  c.drawCircle(path(t), 3, fillOf(k.fg));
}

void _vortex(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(110); i++) {
    final s = saw(t, 3 + rnd(i, 1) * 2, rnd(i, 2));
    final r = 44 * (1 - s);
    final a = rnd(i, 3) * tau + s * 6;
    c.drawCircle(polar(r, a), 0.6 + (1 - s) * 1.4, fillOf(fade(Color.lerp(k.violet, k.mint, s)!, math.min(1, s * 3))));
  }
  c.drawCircle(kMid, 5, glowOf(k.mint, 4));
}

void _fountain(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(70); i++) {
    final life = 1.6 + rnd(i, 1) * 0.6;
    final s = saw(t, life, rnd(i, 2)) * life;
    final vx = (rnd(i, 3) - 0.5) * 30, vy = -55 - rnd(i, 4) * 20;
    final p = Offset(50 + vx * s, 88 + vy * s + 0.5 * 60 * s * s);
    if (p.dy > 92) continue;
    c.drawCircle(p, 1.4, fillOf(fade(Color.lerp(k.sky, k.mint, rnd(i, 5))!, 1 - s / life * 0.6)));
  }
  c.drawOval(Rect.fromCenter(center: const Offset(50, 90), width: 30, height: 5), fillOf(fade(k.sky, 0.3)));
}

void _smoke(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(18); i++) {
    final s = saw(t, 4, i / k.n(18));
    final x = 50 + math.sin(s * 5 + i) * 10 * s + (rnd(i) - 0.5) * 8;
    final y = 86 - s * 74;
    c.drawCircle(Offset(x, y), 5 + s * 16, glowOf(fade(k.onLight ? const Color(0xFF6B7280) : const Color(0xFFCBD5E1), (1 - s) * 0.35), 5));
  }
}

void _fire(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(40); i++) {
    final s = saw(t, 1 + rnd(i, 1) * 0.6, rnd(i, 2));
    final x = 50 + (rnd(i, 3) - 0.5) * 26 * (1 - s) + math.sin(t * 6 + i) * 3 * s;
    final y = 86 - s * 60 * (0.7 + rnd(i, 4) * 0.5);
    final col = Color.lerp(const Color(0xFFFFE066), const Color(0xFFE8590C), s)!;
    c.drawCircle(Offset(x, y), 9 * (1 - s) + 1, glowOf(fade(col, 0.75 * (1 - s)), 3));
  }
  c.drawOval(Rect.fromCenter(center: const Offset(50, 82), width: 22, height: 10), glowOf(const Color(0xFFFFF3BF), 3));
}

void _bubbles(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(18); i++) {
    final s = saw(t, 3 + rnd(i, 1) * 3, rnd(i, 2));
    final r = 2 + rnd(i, 3) * 7;
    final o = Offset(10 + rnd(i, 4) * 80 + math.sin(t * 2 + i) * 3, 105 - s * 115);
    c.drawCircle(o, r, fillOf(fade(k.sky, 0.12)));
    c.drawCircle(o, r, strokeOf(fade(k.sky, 0.8), 0.7));
    c.drawCircle(o - Offset(r * 0.35, r * 0.35), r * 0.25, fillOf(fade(Colors.white, 0.8)));
  }
}

void _network(Canvas c, double t, AnimInk k) {
  final n = k.n(22);
  final pts = [
    for (var i = 0; i < n; i++)
      Offset(50 + math.sin(t * (0.2 + rnd(i, 1) * 0.3) + i) * 42, 50 + math.cos(t * (0.2 + rnd(i, 2) * 0.3) + i * 1.7) * 42),
  ];
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final d = (pts[i] - pts[j]).distance;
      if (d < 28) c.drawLine(pts[i], pts[j], strokeOf(fade(k.sky, (1 - d / 28) * 0.8), 0.6));
    }
  }
  for (final p in pts) {
    c.drawCircle(p, 1.6, fillOf(k.fg));
  }
}

void _ringDust(Canvas c, double t, AnimInk k) {
  c.drawCircle(kMid, 15, Paint()..shader = ui.Gradient.radial(const Offset(45, 45), 18, [k.gold, k.orange]));
  for (var i = 0; i < k.n(160); i++) {
    final r = 22 + rnd(i, 1) * 20;
    final a = rnd(i, 2) * tau + t * (24 / r);
    final p = Offset(50 + math.cos(a) * r, 50 + math.sin(a) * r * 0.32);
    if (math.sin(a) < 0 && (p - kMid).distance < 15) continue;
    c.drawCircle(p, 0.5 + rnd(i, 3) * 0.6, fillOf(fade(k.fg, 0.4 + rnd(i, 4) * 0.6)));
  }
}

void _magnet(Canvas c, double t, AnimInk k) {
  final cyc = saw(t, 3);
  final pull = cyc < 0.5 ? Curves.easeInOutCubic.transform(cyc * 2) : 1 - Curves.easeInOutCubic.transform((cyc - 0.5) * 2);
  for (var i = 0; i < k.n(60); i++) {
    final home = Offset(6 + rnd(i, 1) * 88, 6 + rnd(i, 2) * 88);
    final target = polar(10 + rnd(i, 3) * 4, rnd(i, 4) * tau + t);
    c.drawCircle(Offset.lerp(home, target, pull)!, 1.4, fillOf(Color.lerp(k.pink, k.violet, rnd(i, 5))!));
  }
}

void _dissolve(Canvas c, double t, AnimInk k) {
  final cyc = saw(t, 3.5);
  for (var y = 0; y < 10; y++) {
    for (var x = 0; x < 10; x++) {
      final i = y * 10 + x;
      final start = (x / 10) * 0.5 + rnd(i) * 0.15;
      final u = ((cyc - start) / 0.35).clamp(0.0, 1.0);
      final back = cyc > 0.85 ? (cyc - 0.85) / 0.15 : 0.0;
      final m = u * (1 - back);
      final o = Offset(28 + x * 4.6 + m * 40 * rnd(i, 1), 28 + y * 4.6 - m * 30 * rnd(i, 2));
      c.drawRect(Rect.fromLTWH(o.dx, o.dy, 4, 4), fillOf(fade(Color.lerp(k.gold, k.pink, y / 9)!, 1 - m)));
    }
  }
}

void _burst(Canvas c, double t, AnimInk k) {
  final s = saw(t, 1.8);
  final e = Curves.easeOutCubic.transform(s);
  for (var i = 0; i < k.n(40); i++) {
    final a = rnd(i, 1) * tau;
    final r = e * (20 + rnd(i, 2) * 26);
    final p = polar(r, a);
    c.drawLine(polar(r * 0.75, a), p, strokeOf(fade(k.palette[i % 6], 1 - s), 1.6));
  }
  c.drawCircle(kMid, 6 * (1 - s), fillOf(k.fg));
}

void _flow(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(60); i++) {
    var p = Offset(rnd(i, 1) * 100, rnd(i, 2) * 100);
    final path = Path()..moveTo(p.dx, p.dy);
    const steps = 8;
    final phase = saw(t, 4, rnd(i, 3)) * 30;
    for (var j = 0; j < steps; j++) {
      final a = math.sin(p.dx * 0.05 + t * 0.4) + math.cos(p.dy * 0.05) * 1.5;
      p = p + Offset(math.cos(a), math.sin(a)) * (2 + phase * 0.05);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, strokeOf(fade(Color.lerp(k.sky, k.violet, rnd(i, 4))!, 0.65), 0.8));
    c.drawCircle(p, 1, fillOf(k.fg));
  }
}

void _leaves(Canvas c, double t, AnimInk k) {
  final cols = [k.orange, k.gold, const Color(0xFFC2410C), k.mint];
  for (var i = 0; i < k.n(14); i++) {
    final sp = 0.7 + rnd(i, 1) * 0.6;
    final y = (rnd(i, 2) * 120 + t * 12 * sp) % 120 - 10;
    final x = rnd(i, 3) * 100 + math.sin(t * 1.4 * sp + i) * 10;
    c.save();
    c.translate(x, y);
    c.rotate(math.sin(t * 2 * sp + i) * 1.2);
    final leaf = Path()
      ..moveTo(0, -5)
      ..quadraticBezierTo(4, 0, 0, 5)
      ..quadraticBezierTo(-4, 0, 0, -5)
      ..close();
    c.drawPath(leaf, fillOf(cols[i % 4]));
    c.drawLine(const Offset(0, -5), const Offset(0, 5), strokeOf(fade(Colors.black, 0.2), 0.4));
    c.restore();
  }
}

void _hearts(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < k.n(12); i++) {
    final s = saw(t, 3 + rnd(i, 1) * 2, rnd(i, 2));
    final x = 20 + rnd(i, 3) * 60 + math.sin(s * 8 + i) * 6;
    final y = 95 - s * 90;
    final size = 6 + rnd(i, 4) * 7;
    c.drawPath(heartPath(Offset(x, y), size * (0.6 + 0.4 * math.sin(s * math.pi))), fillOf(fade(i.isEven ? k.pink : const Color(0xFFFF8FAB), math.sin(s * math.pi))));
  }
}

void _lightning(Canvas c, double t, AnimInk k) {
  final cyc = saw(t, 1.6);
  final gen = (t / 1.6).floor();
  // A storm cloud glow, lit up by each strike.
  c.drawOval(const Rect.fromLTWH(20, 0, 60, 16), glowOf(fade(k.violet, cyc < 0.15 ? 0.7 : 0.3), 6));
  if (cyc > 0.7) return;
  final a = cyc < 0.1 ? 1.0 : (0.7 - cyc) / 0.6;
  for (var b = 0; b < 2; b++) {
    final p = Path()..moveTo(50 + (rnd(gen, 1 + b) - 0.5) * 20, 6);
    var x = p.getBounds().left;
    for (var y = 6.0; y < 94; y += 8) {
      x += (rnd(gen * 13 + y.toInt() + b * 97, 3) - 0.5) * 16;
      p.lineTo(x, y + 8);
    }
    c.drawPath(p, strokeOf(fade(k.violet, a * 0.5), 5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawPath(p, strokeOf(fade(k.onLight ? k.violet : Colors.white, a), 1.4 - b * 0.5));
  }
}
