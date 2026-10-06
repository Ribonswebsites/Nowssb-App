/// Backgrounds: animated fills — gradients, aurora, waves, stars, grids.
/// Each fills its whole box (clipped), so a big one becomes a backdrop.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'anim_core.dart';

const kBackgroundAnims = <AnimSpec>[
  AnimSpec('bg.gradient', 'Gradient', AnimCategory.backgrounds, paint: _gradient, clip: true),
  AnimSpec('bg.aurora', 'Aurora', AnimCategory.backgrounds, paint: _aurora, clip: true),
  AnimSpec('bg.waves', 'Waves', AnimCategory.backgrounds, paint: _waves, clip: true),
  AnimSpec('bg.mesh', 'Mesh', AnimCategory.backgrounds, paint: _mesh, clip: true),
  AnimSpec('bg.stars', 'Starfield', AnimCategory.backgrounds, paint: _stars, clip: true),
  AnimSpec('bg.warp', 'Warp', AnimCategory.backgrounds, paint: _warp, clip: true),
  AnimSpec('bg.bokeh', 'Bokeh', AnimCategory.backgrounds, paint: _bokeh, clip: true),
  AnimSpec('bg.synth', 'Retro grid', AnimCategory.backgrounds, paint: _synth, clip: true),
  AnimSpec('bg.ripples', 'Ripples', AnimCategory.backgrounds, paint: _ripples, clip: true),
  AnimSpec('bg.stripes', 'Stripes', AnimCategory.backgrounds, paint: _stripes, clip: true),
  AnimSpec('bg.lava', 'Lava', AnimCategory.backgrounds, paint: _lava, clip: true),
  AnimSpec('bg.rain', 'Rain', AnimCategory.backgrounds, paint: _rain, clip: true),
  AnimSpec('bg.snow', 'Snow', AnimCategory.backgrounds, paint: _snow, clip: true),
  AnimSpec('bg.sunburst', 'Sunburst', AnimCategory.backgrounds, paint: _sunburst, clip: true),
  AnimSpec('bg.halftone', 'Halftone', AnimCategory.backgrounds, paint: _halftone, clip: true),
  AnimSpec('bg.clouds', 'Sky', AnimCategory.backgrounds, paint: _clouds, clip: true),
  AnimSpec('bg.conic', 'Conic', AnimCategory.backgrounds, paint: _conic, clip: true),
  AnimSpec('bg.matrix', 'Code rain', AnimCategory.backgrounds, paint: _matrix, clip: true),
];

const _box = Rect.fromLTWH(0, 0, 100, 100);

Color _night(AnimInk k) => k.onLight ? const Color(0xFFF3F0FF) : const Color(0xFF0B0B1A);

void _gradient(Canvas c, double t, AnimInk k) {
  final a = t * 0.4;
  final from = Offset(50 + math.cos(a) * 70, 50 + math.sin(a) * 70);
  final to = Offset(50 - math.cos(a) * 70, 50 - math.sin(a) * 70);
  final h = t * 12;
  final v = k.onLight ? 0.95 : 0.8, s = k.onLight ? 0.35 : 0.7;
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(from, to, [hue(h + 280, s, v), hue(h + 330, s, v), hue(h + 20, s, v)], [0, 0.5, 1]));
}

void _aurora(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [k.onLight ? const Color(0xFFE6F4FF) : const Color(0xFF041022), _night(k)]));
  final cols = [k.mint, k.sky, k.violet];
  for (var b = 0; b < 3; b++) {
    final p = Path();
    final base = 32 + b * 12.0;
    for (var x = -5.0; x <= 105; x += 5) {
      final y = base + math.sin(x * 0.05 + t * (0.7 + b * 0.2) + b) * 9 + math.sin(x * 0.13 - t * 0.5) * 4;
      x == -5 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    c.drawPath(p, strokeOf(fade(cols[b], 0.55), 14)..maskFilter = MaskFilter.blur(BlurStyle.normal, k.lite ? 4 : 6));
    c.drawPath(p, strokeOf(fade(cols[b], 0.6), 1.5));
  }
}

void _waves(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.onLight ? const Color(0xFFEAF6FF) : const Color(0xFF071A33)));
  for (var w = 0; w < 4; w++) {
    final p = Path()..moveTo(0, 100);
    final base = 40 + w * 14.0;
    for (var x = 0.0; x <= 100; x += 4) {
      p.lineTo(x, base + math.sin(x * 0.07 + t * (1.2 - w * 0.15) + w * 1.3) * (5 - w * 0.6));
    }
    p
      ..lineTo(100, 100)
      ..close();
    c.drawPath(p, fillOf(fade(Color.lerp(k.sky, k.violet, w / 3)!, 0.35 + w * 0.15)));
  }
}

void _mesh(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(_night(k)));
  final cols = [k.pink, k.sky, k.gold, k.violet];
  for (var i = 0; i < 4; i++) {
    final o = Offset(50 + osc(t, 9.0 + i * 2, i * 0.25) * 34, 50 + osc(t, 11.0 + i, i * 0.31 + 0.2) * 34);
    c.drawCircle(o, 55, Paint()..shader = ui.Gradient.radial(o, 55, [fade(cols[i], 0.85), fade(cols[i], 0)]));
  }
}

void _stars(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.onLight ? const Color(0xFF1B2440) : const Color(0xFF05050F)));
  for (var i = 0; i < k.n(90); i++) {
    final layer = 1 + i % 3;
    final x = (rnd(i, 1) * 100 - t * 3 * layer) % 100;
    final tw = 0.55 + 0.45 * osc(t, 1 + rnd(i, 3) * 3, rnd(i, 4));
    c.drawCircle(Offset(x, rnd(i, 2) * 100), 0.35 * layer, fillOf(fade(Colors.white, tw * (0.4 + layer * 0.2))));
  }
}

void _warp(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(const Color(0xFF03030A)));
  for (var i = 0; i < k.n(70); i++) {
    final a = rnd(i, 1) * tau;
    final s = saw(t, 1.6 + rnd(i, 2), rnd(i, 3));
    final r0 = math.pow(s, 2.2) * 75, r1 = r0 + 2 + s * 14;
    c.drawLine(polar(r0.toDouble(), a), polar(r1.toDouble(), a), strokeOf(fade(Color.lerp(Colors.white, const Color(0xFF9FD8FF), rnd(i, 4))!, s), 0.4 + s * 1.2));
  }
}

void _bokeh(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(100, 100), [k.onLight ? const Color(0xFFFFF4E6) : const Color(0xFF1A0F2E), _night(k)]));
  for (var i = 0; i < k.n(20); i++) {
    final x = rnd(i, 1) * 100 + osc(t, 8 + rnd(i, 2) * 6, rnd(i, 3)) * 6;
    final y = (rnd(i, 4) * 120 - t * (2 + rnd(i, 5) * 3)) % 120 - 10;
    final r = 4 + rnd(i, 6) * 10;
    final col = k.palette[i % 6];
    c.drawCircle(Offset(x, y), r, fillOf(fade(col, 0.22)));
    c.drawCircle(Offset(x, y), r, strokeOf(fade(col, 0.35), 0.6));
  }
}

void _synth(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 55), [const Color(0xFF12002B), const Color(0xFF5B0E6B)]));
  c.drawCircle(const Offset(50, 46), 18, Paint()..shader = ui.Gradient.linear(const Offset(0, 28), const Offset(0, 56), [const Color(0xFFFFD43B), const Color(0xFFFF4D9A)]));
  for (var i = 0; i < 4; i++) {
    c.drawRect(Rect.fromLTWH(30, 44 + i * 3.4, 40, 1.1 + i * 0.3), fillOf(const Color(0xFF5B0E6B)));
  }
  c.drawRect(const Rect.fromLTWH(0, 55, 100, 45), fillOf(const Color(0xFF10001F)));
  final line = strokeOf(const Color(0xFFFF4DD8), 0.7);
  for (var i = -10; i <= 10; i++) {
    c.drawLine(Offset(50 + i * 4.0, 55), Offset(50 + i * 22.0, 100), line);
  }
  final s = saw(t, 1.2);
  for (var j = 0; j < 8; j++) {
    final u = (j + s) / 8;
    c.drawLine(Offset(0, 55 + u * u * 45), Offset(100, 55 + u * u * 45), line);
  }
}

void _ripples(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.onLight ? const Color(0xFFE7FAF5) : const Color(0xFF052520)));
  const centers = [Offset(30, 35), Offset(72, 66), Offset(60, 20)];
  for (var j = 0; j < 3; j++) {
    for (var i = 0; i < 4; i++) {
      final s = saw(t, 3.2, i / 4 + j * 0.33);
      c.drawCircle(centers[j], s * 50, strokeOf(fade(k.mint, (1 - s) * 0.8), 1.2));
    }
  }
}

void _stripes(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.gold));
  c.save();
  c.translate(50, 50);
  c.rotate(-math.pi / 4);
  final off = saw(t, 1.5) * 20;
  for (var x = -100.0; x < 100; x += 20) {
    c.drawRect(Rect.fromLTWH(x + off, -100, 10, 200), fillOf(fade(k.onLight ? Colors.white : const Color(0xFF1B2030), 0.35)));
  }
  c.restore();
}

void _lava(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [const Color(0xFF3B0A2A), const Color(0xFF6B1430)]));
  for (var i = 0; i < 6; i++) {
    final y = 50 + osc(t, 9 + i * 1.7, rnd(i)) * 42;
    final x = 20 + rnd(i, 1) * 60 + osc(t, 7.0 + i, rnd(i, 2)) * 8;
    final r = 9 + rnd(i, 3) * 9;
    c.drawCircle(Offset(x, y), r * 1.3, glowOf(fade(const Color(0xFFFF6B3D), 0.5), 6));
    c.drawCircle(Offset(x, y), r, Paint()..shader = ui.Gradient.radial(Offset(x - r * .3, y - r * .3), r, [const Color(0xFFFFC145), const Color(0xFFFF4D3D)]));
  }
}

void _rain(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [k.onLight ? const Color(0xFFD8E2EE) : const Color(0xFF101828), k.onLight ? const Color(0xFFB8C6D8) : const Color(0xFF1E2A3E)]));
  final drop = strokeOf(fade(k.onLight ? const Color(0xFF4A6280) : const Color(0xFFAFC8E8), 0.7), 0.7);
  for (var i = 0; i < k.n(60); i++) {
    final sp = 1 + rnd(i, 2);
    final y = (rnd(i, 1) * 110 + t * 70 * sp) % 110 - 10;
    final x = rnd(i, 3) * 110 - y * 0.15;
    c.drawLine(Offset(x, y), Offset(x - 1.2, y + 6 * sp), drop);
  }
  for (var i = 0; i < k.n(6); i++) {
    final s = saw(t, 0.8, rnd(i, 7));
    c.drawOval(Rect.fromCenter(center: Offset(rnd(i, 8) * 100, 92 + rnd(i, 9) * 6), width: s * 10, height: s * 2.5), strokeOf(fade(drop.color, 1 - s), 0.5));
  }
}

void _snow(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [const Color(0xFF1C2E4A), const Color(0xFF4A6A8F)]));
  for (var i = 0; i < k.n(70); i++) {
    final sp = 0.5 + rnd(i, 2);
    final y = (rnd(i, 1) * 110 + t * 9 * sp) % 110 - 5;
    final x = rnd(i, 3) * 100 + math.sin(t * sp + i) * 4;
    c.drawCircle(Offset(x, y), 0.5 + sp * 0.9, fillOf(fade(Colors.white, 0.5 + sp * 0.3)));
  }
}

void _sunburst(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.onLight ? const Color(0xFFFFE8A3) : const Color(0xFFB45309)));
  c.save();
  c.translate(50, 50);
  c.rotate(t * 0.15);
  final ray = fillOf(k.onLight ? const Color(0xFFFFF6D6) : const Color(0xFFD97706));
  for (var i = 0; i < 16; i++) {
    c.drawPath(Path()..moveTo(0, 0)..lineTo(math.cos(i * tau / 16) * 90, math.sin(i * tau / 16) * 90)..lineTo(math.cos((i + 0.5) * tau / 16) * 90, math.sin((i + 0.5) * tau / 16) * 90)..close(), ray);
  }
  c.restore();
  c.drawCircle(kMid, 16, Paint()..shader = ui.Gradient.radial(kMid, 16, [Colors.white, fade(Colors.white, 0)]));
}

void _halftone(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(k.onLight ? Colors.white : const Color(0xFF14121F)));
  for (var y = 0; y < 13; y++) {
    for (var x = 0; x < 13; x++) {
      final o = Offset(4 + x * 7.7 + (y.isOdd ? 3.85 : 0), 4 + y * 7.7);
      final d = (o - Offset(50 + osc(t, 6) * 30, 50 + osc(t, 8, 0.25) * 30)).distance;
      final r = (3.6 * (1 - d / 70)).clamp(0.3, 3.6);
      c.drawCircle(o, r, fillOf(k.pink));
    }
  }
}

void _clouds(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 100), [const Color(0xFF4DABF7), const Color(0xFFBDE4FF)]));
  for (var i = 0; i < 5; i++) {
    final sc = 0.6 + rnd(i, 1) * 0.7;
    final x = (rnd(i, 2) * 140 + t * (2 + i) * sc) % 140 - 20;
    final y = 15 + rnd(i, 3) * 60;
    final cloud = fillOf(fade(Colors.white, 0.75 + 0.2 * sc));
    for (final b in const [Offset(0, 0), Offset(7, -4), Offset(14, 0), Offset(7, 2)]) {
      c.drawCircle(Offset(x + b.dx * sc, y + b.dy * sc), 6 * sc, cloud);
    }
  }
}

void _conic(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  c.rotate(t * 0.5);
  final v = k.onLight ? 0.95 : 0.85, s = k.onLight ? 0.45 : 0.75;
  c.drawRect(const Rect.fromLTWH(-80, -80, 160, 160),
      Paint()..shader = ui.Gradient.sweep(Offset.zero, [for (var h = 0; h <= 360; h += 60) hue(h.toDouble(), s, v)], [for (var h = 0; h <= 360; h += 60) h / 360]));
  c.restore();
  c.drawRect(_box, Paint()..shader = ui.Gradient.radial(kMid, 70, [fade(Colors.white, k.onLight ? 0.6 : 0.25), fade(Colors.white, 0)]));
}

void _matrix(Canvas c, double t, AnimInk k) {
  c.drawRect(_box, fillOf(const Color(0xFF020A04)));
  const cols = 14;
  for (var col = 0; col < cols; col++) {
    final speed = 18 + rnd(col, 1) * 26;
    final head = (rnd(col, 2) * 140 + t * speed) % 140 - 20;
    final x = col * 100 / cols + 2;
    for (var j = 0; j < 12; j++) {
      final y = head - j * 5.2;
      if (y < -5 || y > 105) continue;
      final a = j == 0 ? 1.0 : (1 - j / 12) * 0.8;
      final glyph = ((t * 6).floor() + col * 7 + j * 3) % 4;
      final p = fillOf(j == 0 ? const Color(0xFFD3FFE0) : fade(const Color(0xFF22E36B), a));
      switch (glyph) {
        case 0:
          c.drawRect(Rect.fromLTWH(x, y, 3.4, 4), p);
        case 1:
          c.drawRect(Rect.fromLTWH(x + 1.2, y, 1.1, 4), p);
        case 2:
          c.drawRect(Rect.fromLTWH(x, y + 1.4, 3.4, 1.1), p);
        default:
          c.drawCircle(Offset(x + 1.7, y + 2), 1.4, p);
      }
    }
  }
}
