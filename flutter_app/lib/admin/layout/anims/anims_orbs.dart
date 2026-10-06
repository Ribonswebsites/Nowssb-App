/// Orbs: Ribon's thinking orbs (flutter_thinking_orbs, MIT) plus orbs
/// drawn here — sphere of dots, galaxy, nebula, voice blob and more.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'anim_core.dart';

const _orbNames = <OrbState, String>{
  OrbState.composing: 'Composing',
  OrbState.listening: 'Listening',
  OrbState.solving: 'Solving',
  OrbState.working: 'Working',
  OrbState.searching: 'Searching',
  OrbState.shaping: 'Shaping',
};

/// The thinking orb a spec stands for (null for drawn ones).
OrbState? thinkingOrbOf(String id) =>
    id.startsWith('orb.') ? OrbState.values.where((s) => 'orb.${s.name}' == id).firstOrNull : null;

final kOrbAnims = <AnimSpec>[
  for (final s in OrbState.values)
    AnimSpec('orb.${s.name}', _orbNames[s] ?? s.name, AnimCategory.orbs,
        build: (context, size, k) => Center(
              child: ThinkingOrb(state: s, size: size, theme: k.onLight ? OrbTheme.light : OrbTheme.dark),
            )),
  const AnimSpec('orb.sphere', 'Dot sphere', AnimCategory.orbs, paint: _sphere),
  const AnimSpec('orb.galaxy', 'Galaxy', AnimCategory.orbs, paint: _galaxy),
  const AnimSpec('orb.nebula', 'Nebula', AnimCategory.orbs, paint: _nebula),
  const AnimSpec('orb.voice', 'Voice blob', AnimCategory.orbs, paint: _voice),
  const AnimSpec('orb.glass', 'Glass', AnimCategory.orbs, paint: _glass),
  const AnimSpec('orb.gyro', 'Gyroscope', AnimCategory.orbs, paint: _gyro),
  const AnimSpec('orb.plasma', 'Plasma', AnimCategory.orbs, paint: _plasma),
  const AnimSpec('orb.atom', 'Atom', AnimCategory.orbs, paint: _atom),
  const AnimSpec('orb.pulse', 'Pulse core', AnimCategory.orbs, paint: _pulseCore),
  const AnimSpec('orb.globe', 'Wire globe', AnimCategory.orbs, paint: _globe),
  const AnimSpec('orb.chroma', 'Chroma', AnimCategory.orbs, paint: _chroma),
  const AnimSpec('orb.liquid', 'Liquid', AnimCategory.orbs, paint: _liquid),
  const AnimSpec('orb.eclipse', 'Eclipse', AnimCategory.orbs, paint: _eclipse),
  const AnimSpec('orb.yarn', 'Spiral ball', AnimCategory.orbs, paint: _yarn),
  const AnimSpec('orb.pixel', 'Pixel orb', AnimCategory.orbs, paint: _pixel),
  const AnimSpec('orb.prism', 'Prism', AnimCategory.orbs, paint: _prism),
];

void _sphere(Canvas c, double t, AnimInk k) {
  final n = k.n(220);
  final ry = t * 0.7, rx = 0.45;
  final golden = math.pi * (3 - math.sqrt(5));
  for (var i = 0; i < n; i++) {
    final y = 1 - (i / (n - 1)) * 2;
    final r = math.sqrt(1 - y * y);
    final th = golden * i;
    var x = math.cos(th) * r, z = math.sin(th) * r;
    final x2 = x * math.cos(ry) - z * math.sin(ry);
    z = x * math.sin(ry) + z * math.cos(ry);
    x = x2;
    final y2 = y * math.cos(rx) - z * math.sin(rx);
    z = y * math.sin(rx) + z * math.cos(rx);
    final depth = (z + 1) / 2;
    final col = Color.lerp(k.violet, k.gold, (y2 + 1) / 2)!;
    c.drawCircle(Offset(50 + x * 38, 50 + y2 * 38), 0.6 + depth * 1.4, fillOf(fade(col, 0.25 + depth * 0.75)));
  }
}

void _galaxy(Canvas c, double t, AnimInk k) {
  c.drawCircle(kMid, 14, glowOf(fade(k.gold, 0.7), 8));
  final n = k.n(300);
  for (var i = 0; i < n; i++) {
    final r = math.pow(rnd(i, 1), 0.7) * 44;
    final arm = (i % 3) * tau / 3;
    final a = arm + r * 0.11 + t * (0.9 - r / 80) + (rnd(i, 2) - 0.5) * 0.6;
    final p = polar(r.toDouble(), a);
    final col = Color.lerp(k.gold, k.sky, r / 44)!;
    c.drawCircle(Offset(p.dx, 50 + (p.dy - 50) * 0.62), 0.5 + rnd(i, 3) * 1.1, fillOf(fade(col, 0.4 + rnd(i, 4) * 0.6)));
  }
  c.drawCircle(kMid, 3.5, fillOf(k.fg));
}

void _nebula(Canvas c, double t, AnimInk k) {
  final cols = [k.violet, k.pink, k.sky, k.mint, k.violet];
  for (var i = 0; i < 5; i++) {
    final o = Offset(50 + osc(t, 7.0 + i, i * 0.2) * 16, 50 + osc(t, 9.0 + i, i * 0.37) * 14);
    c.drawCircle(o, 18 + 6 * osc(t, 5.0 + i), glowOf(fade(cols[i], 0.55), k.lite ? 7 : 11));
  }
  for (var i = 0; i < k.n(30); i++) {
    final tw = 0.5 + 0.5 * osc(t, 1.5 + rnd(i, 1) * 2, rnd(i, 2));
    c.drawCircle(Offset(15 + rnd(i, 3) * 70, 15 + rnd(i, 4) * 70), 0.8, fillOf(fade(k.fg, tw)));
  }
}

void _voice(Canvas c, double t, AnimInk k) {
  Path blob(double base, double amp, double sp) {
    final p = Path();
    for (var i = 0; i <= 72; i++) {
      final a = i / 72 * tau;
      final r = base +
          amp * (math.sin(3 * a + t * 2.1 * sp) * 0.5 + math.sin(5 * a - t * 2.9 * sp) * 0.3 + math.sin(2 * a + t * 1.3) * 0.4);
      final o = polar(r, a);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  c.drawPath(blob(36, 6, 1), fillOf(fade(k.sky, 0.35)));
  c.drawPath(
    blob(30, 5, 1.4),
    Paint()..shader = ui.Gradient.linear(const Offset(20, 20), const Offset(80, 80), [k.pink, k.violet]),
  );
  c.drawPath(blob(14, 3, 2), fillOf(fade(Colors.white, 0.35)));
}

void _glass(Canvas c, double t, AnimInk k) {
  c.drawCircle(
    kMid,
    36,
    Paint()
      ..shader = ui.Gradient.radial(const Offset(42, 40), 44, [k.sky, k.violet, const Color(0xFF14102B)], [0, 0.55, 1]),
  );
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: kMid, radius: 36)));
  for (var i = 0; i < 3; i++) {
    final a = t * (0.8 + i * 0.3) + i * 2;
    c.drawArc(Rect.fromCircle(center: kMid, radius: 14.0 + i * 8), a, 2.2, false, strokeOf(fade(Colors.white, 0.35 - i * 0.08), 3));
  }
  c.restore();
  final hx = 38 + osc(t, 6) * 4;
  c.drawOval(Rect.fromCenter(center: Offset(hx, 33), width: 22, height: 12), glowOf(fade(Colors.white, 0.75), 2.5));
  c.drawCircle(kMid, 36, strokeOf(fade(k.fg, 0.35), 1));
}

void _gyro(Canvas c, double t, AnimInk k) {
  final cols = [k.gold, k.mint, k.pink];
  for (var i = 0; i < 3; i++) {
    c.save();
    c.translate(50, 50);
    c.rotate(i * math.pi / 3 + t * 0.2);
    final sy = math.cos(t * (1.2 + i * 0.4) + i);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 76, height: 76 * sy.abs() + 2), strokeOf(cols[i], 2.4));
    c.restore();
  }
  c.drawCircle(kMid, 6, glowOf(k.gold, 3));
  c.drawCircle(kMid, 4, fillOf(k.fg));
}

void _plasma(Canvas c, double t, AnimInk k) {
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: kMid, radius: 36)));
  for (var y = 14.0; y < 86; y += 3) {
    for (var x = 14.0; x < 86; x += 6) {
      final v = math.sin(x * 0.09 + t * 1.6) + math.sin(y * 0.11 - t * 1.2) + math.sin((x + y) * 0.07 + t);
      c.drawRect(Rect.fromLTWH(x, y, 6.2, 3.2), fillOf(hue(260 + v * 45 + t * 20, 0.65, k.onLight ? 0.75 : 1)));
    }
  }
  c.restore();
  c.drawCircle(kMid, 36, strokeOf(fade(k.fg, 0.4), 1.2));
}

void _atom(Canvas c, double t, AnimInk k) {
  final cols = [k.sky, k.pink, k.mint];
  for (var i = 0; i < 3; i++) {
    c.save();
    c.translate(50, 50);
    c.rotate(i * math.pi / 3);
    final rect = Rect.fromCenter(center: Offset.zero, width: 80, height: 26);
    c.drawOval(rect, strokeOf(fade(k.fg, 0.35), 1.2));
    final a = t * (2 + i * 0.5) + i * 2;
    final e = Offset(math.cos(a) * 40, math.sin(a) * 13);
    c.drawCircle(e, 4, glowOf(cols[i], 2));
    c.drawCircle(e, 2.6, fillOf(cols[i]));
    c.restore();
  }
  c.drawCircle(kMid, 8, Paint()..shader = ui.Gradient.radial(const Offset(48, 48), 9, [k.gold, k.orange]));
}

void _pulseCore(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 3; i++) {
    final s = saw(t, 2.4, i / 3);
    c.drawCircle(kMid, 12 + s * 34, strokeOf(fade(k.gold, 1 - s), 2.5 * (1 - s) + 0.5));
  }
  final b = 1 + 0.08 * osc(t, 1.2);
  c.drawCircle(kMid, 13 * b, glowOf(fade(k.gold, 0.8), 6));
  c.drawCircle(kMid, 10 * b, Paint()..shader = ui.Gradient.radial(const Offset(47, 46), 11, [Colors.white, k.gold]));
}

void _globe(Canvas c, double t, AnimInk k) {
  final p = strokeOf(fade(k.sky, 0.8), 1);
  c.drawCircle(kMid, 36, strokeOf(k.sky, 1.6));
  for (var i = 1; i < 6; i++) {
    final y = -36 + i * 12.0;
    final w = math.sqrt(36 * 36 - y * y) * 2;
    c.drawOval(Rect.fromCenter(center: Offset(50, 50 + y), width: w, height: w * 0.12), p);
  }
  for (var i = 0; i < 6; i++) {
    final a = (t * 0.6 + i * math.pi / 6) % math.pi;
    final w = (72 * math.cos(a)).abs();
    c.drawOval(Rect.fromCenter(center: kMid, width: w, height: 72), p);
  }
  final d = polar(36, -t * 0.6 * 2);
  c.drawCircle(Offset(d.dx, 50 + (d.dy - 50) * 0.3), 2.5, fillOf(k.gold));
}

void _chroma(Canvas c, double t, AnimInk k) {
  final mode = k.onLight ? BlendMode.multiply : BlendMode.screen;
  final cols = k.onLight
      ? [const Color(0xFFFF6BA8), const Color(0xFF5CC8FF), const Color(0xFFFFD43B)]
      : [const Color(0xFFFF3D7F), const Color(0xFF2EA8FF), const Color(0xFF3DFFB0)];
  c.saveLayer(const Rect.fromLTWH(0, 0, 100, 100), Paint());
  for (var i = 0; i < 3; i++) {
    final o = polar(9 + 3 * osc(t, 3, i / 3), t * 1.1 + i * tau / 3);
    c.drawCircle(o, 25, Paint()
      ..color = cols[i]
      ..blendMode = mode);
  }
  c.restore();
}

void _liquid(Canvas c, double t, AnimInk k) {
  final circle = Rect.fromCircle(center: kMid, radius: 34);
  c.save();
  c.clipPath(Path()..addOval(circle));
  for (var layer = 0; layer < 2; layer++) {
    final level = 52 + osc(t, 4) * 4 + layer * 4;
    final p = Path()..moveTo(0, 100);
    for (var x = 0.0; x <= 100; x += 4) {
      p.lineTo(x, level + math.sin(x * 0.11 + t * (2.6 - layer)) * 4 + math.sin(x * 0.27 - t * 2) * 1.5);
    }
    p
      ..lineTo(100, 100)
      ..close();
    c.drawPath(p, fillOf(fade(layer == 0 ? k.sky : k.violet, layer == 0 ? 0.55 : 0.85)));
  }
  for (var i = 0; i < k.n(6); i++) {
    final s = saw(t, 2 + rnd(i) * 2, rnd(i, 1));
    c.drawCircle(Offset(30 + rnd(i, 2) * 40, 82 - s * 26), 1.2 + rnd(i, 3), strokeOf(fade(Colors.white, 1 - s), 0.8));
  }
  c.restore();
  c.drawCircle(kMid, 34, strokeOf(k.fg, 2));
  c.drawArc(circle.deflate(5), -2.6, 0.9, false, strokeOf(fade(Colors.white, 0.6), 2.4));
}

void _eclipse(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  c.rotate(t * 0.25);
  for (var i = 0; i < 16; i++) {
    final len = 40 + 6 * osc(t, 2, i / 16);
    c.save();
    c.rotate(i * tau / 16);
    c.drawPath(
      Path()
        ..moveTo(-2.2, -24)
        ..lineTo(0, -len)
        ..lineTo(2.2, -24)
        ..close(),
      fillOf(fade(k.gold, 0.55)),
    );
    c.restore();
  }
  c.restore();
  c.drawCircle(kMid, 26, glowOf(k.orange, 6));
  c.drawCircle(kMid, 24, fillOf(k.onLight ? const Color(0xFF1B2030) : const Color(0xFF07070C)));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 24), t, 1.2, false, strokeOf(fade(Colors.white, 0.8), 1.2));
}

void _yarn(Canvas c, double t, AnimInk k) {
  final n = k.n(240);
  Offset? prev;
  double prevZ = 0;
  for (var i = 0; i <= n; i++) {
    final s = i / n;
    final th = s * math.pi;
    final ph = s * tau * 9 + t * 0.8;
    final x = math.sin(th) * math.cos(ph), z = math.sin(th) * math.sin(ph), y = math.cos(th);
    final p = Offset(50 + x * 36, 50 + y * 36);
    if (prev != null) {
      final d = ((z + prevZ) / 2 + 1) / 2;
      c.drawLine(prev, p, strokeOf(fade(Color.lerp(k.pink, k.gold, s)!, 0.15 + d * 0.85), 0.6 + d * 1.2));
    }
    prev = p;
    prevZ = z;
  }
}

void _pixel(Canvas c, double t, AnimInk k) {
  const cell = 6.0;
  for (var gy = 0; gy < 13; gy++) {
    for (var gx = 0; gx < 13; gx++) {
      final o = Offset(14 + gx * cell + cell / 2, 14 + gy * cell + cell / 2);
      final d = (o - kMid).distance;
      if (d > 38) continue;
      final i = gy * 13 + gx;
      final on = 0.5 + 0.5 * osc(t, 1.2 + rnd(i) * 2.5, rnd(i, 1));
      final col = Color.lerp(k.mint, k.violet, d / 38)!;
      c.drawRect(Rect.fromCenter(center: o, width: cell - 1.2, height: cell - 1.2), fillOf(fade(col, 0.2 + on * 0.8)));
    }
  }
}

void _prism(Canvas c, double t, AnimInk k) {
  const sides = 6;
  final a0 = t * 0.6;
  const top = Offset(50, 14), bottom = Offset(50, 86);
  for (var i = 0; i < sides; i++) {
    final a = a0 + i * tau / sides, b = a + tau / sides;
    final pa = Offset(50 + math.cos(a) * 32, 50 + math.sin(a) * 8);
    final pb = Offset(50 + math.cos(b) * 32, 50 + math.sin(b) * 8);
    final facing = math.sin((a + b) / 2);
    if (facing < 0) continue;
    final col = hue(200 + i * 30 + t * 30, 0.55, k.onLight ? 0.7 : 1, 0.35 + facing * 0.55);
    c.drawPath(Path()..addPolygon([top, pa, pb], true), fillOf(col));
    c.drawPath(Path()..addPolygon([bottom, pa, pb], true), fillOf(fade(col, 0.7)));
    c.drawLine(top, pa, strokeOf(fade(k.fg, 0.5), 0.6));
    c.drawLine(bottom, pa, strokeOf(fade(k.fg, 0.5), 0.6));
  }
}
