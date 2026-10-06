/// Loaders: spinners, dots, bars and other "one moment" animations.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'anim_core.dart';

const kLoaderAnims = <AnimSpec>[
  AnimSpec('ld.arc', 'Arc', AnimCategory.loaders, paint: _arc),
  AnimSpec('ld.bounce', 'Bounce dots', AnimCategory.loaders, paint: _bounce),
  AnimSpec('ld.ios', 'Petals', AnimCategory.loaders, paint: _ios),
  AnimSpec('ld.bars', 'Equalizer', AnimCategory.loaders, paint: _bars),
  AnimSpec('ld.dual', 'Dual ring', AnimCategory.loaders, paint: _dual),
  AnimSpec('ld.ping', 'Ping', AnimCategory.loaders, paint: _ping),
  AnimSpec('ld.flip', 'Flip square', AnimCategory.loaders, paint: _flip),
  AnimSpec('ld.grid', 'Grid', AnimCategory.loaders, paint: _grid),
  AnimSpec('ld.orbit', 'Orbit', AnimCategory.loaders, paint: _orbit),
  AnimSpec('ld.infinity', 'Infinity', AnimCategory.loaders, paint: _infinity),
  AnimSpec('ld.hourglass', 'Hourglass', AnimCategory.loaders, paint: _hourglass),
  AnimSpec('ld.bar', 'Progress', AnimCategory.loaders, paint: _bar),
  AnimSpec('ld.comet', 'Comet', AnimCategory.loaders, paint: _comet),
  AnimSpec('ld.fold', 'Folding', AnimCategory.loaders, paint: _fold),
  AnimSpec('ld.wave', 'Dot wave', AnimCategory.loaders, paint: _dotWave),
  AnimSpec('ld.ecg', 'Heartbeat', AnimCategory.loaders, paint: _ecg),
  AnimSpec('ld.clock', 'Clock', AnimCategory.loaders, paint: _clock),
  AnimSpec('ld.typing', 'Typing', AnimCategory.loaders, paint: _typing),
  AnimSpec('ld.segments', 'Segments', AnimCategory.loaders, paint: _segments),
  AnimSpec('ld.cradle', 'Cradle', AnimCategory.loaders, paint: _cradle),
  AnimSpec('ld.spiral', 'Spiral', AnimCategory.loaders, paint: _spiral),
  AnimSpec('ld.triangle', 'Triangle', AnimCategory.loaders, paint: _triangle),
];

void _arc(Canvas c, double t, AnimInk k) {
  final p = saw(t, 1.6);
  final sweep = 0.3 + 4.2 * (p < 0.5 ? Curves.easeInOut.transform(p * 2) : 1 - Curves.easeInOut.transform(p * 2 - 1));
  final start = t * 4.5 + (p >= 0.5 ? 4.2 * Curves.easeInOut.transform(p * 2 - 1) : 0);
  c.drawCircle(kMid, 30, strokeOf(fade(k.fg, 0.1), 7));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 30), start, sweep, false, strokeOf(k.gold, 7));
}

void _bounce(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 3; i++) {
    final s = saw(t, 1.1, -i * 0.15);
    final h = math.sin(s * math.pi).abs();
    final y = 62 - h * 26;
    final squash = s < 0.08 || s > 0.92 ? 1.25 : 1.0;
    c.drawOval(Rect.fromCenter(center: Offset(28 + i * 22.0, y), width: 12 * squash, height: 12 / squash), fillOf(k.palette[i]));
    c.drawOval(Rect.fromCenter(center: Offset(28 + i * 22.0, 72), width: 12 - h * 6, height: 2.5), fillOf(fade(k.fg, 0.15)));
  }
}

void _ios(Canvas c, double t, AnimInk k) {
  final lead = (t * 12).floor() % 12;
  for (var i = 0; i < 12; i++) {
    final age = (lead - i) % 12;
    final a = i * tau / 12 - math.pi / 2;
    c.drawLine(polar(16, a), polar(32, a), strokeOf(fade(k.fg, 1 - age / 12 * 0.85), 5.5));
  }
}

void _bars(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 5; i++) {
    final h = 14 + 44 * (0.5 + 0.5 * osc(t, 0.9 + i * 0.13, i * 0.21)).abs();
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(22 + i * 14.0, 50), width: 9, height: h), const Radius.circular(4.5));
    c.drawRRect(r, Paint()..shader = ui.Gradient.linear(Offset(0, 50 - h / 2), Offset(0, 50 + h / 2), [k.pink, k.violet]));
  }
}

void _dual(Canvas c, double t, AnimInk k) {
  c.drawArc(Rect.fromCircle(center: kMid, radius: 34), t * 4, 2.2, false, strokeOf(k.sky, 5));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 34), t * 4 + math.pi, 2.2, false, strokeOf(k.sky, 5));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 22), -t * 6, 1.6, false, strokeOf(k.gold, 5));
  c.drawArc(Rect.fromCircle(center: kMid, radius: 22), -t * 6 + math.pi, 1.6, false, strokeOf(k.gold, 5));
}

void _ping(Canvas c, double t, AnimInk k) {
  final s = saw(t, 1.4);
  c.drawCircle(kMid, 10 + s * 32, fillOf(fade(k.mint, (1 - s) * 0.5)));
  c.drawCircle(kMid, 10 + s * 32, strokeOf(fade(k.mint, 1 - s), 2));
  c.drawCircle(kMid, 10, fillOf(k.mint));
}

void _flip(Canvas c, double t, AnimInk k) {
  final p = saw(t, 1.6);
  final ax = p < 0.5 ? math.cos(p * 2 * math.pi) : 1.0;
  final ay = p >= 0.5 ? math.cos((p - 0.5) * 2 * math.pi) : 1.0;
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: kMid, width: 44 * ax.abs() + 1, height: 44 * ay.abs() + 1), const Radius.circular(6)),
    fillOf(ax < 0 || ay < 0 ? k.violet : k.gold),
  );
}

void _grid(Canvas c, double t, AnimInk k) {
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final s = 0.5 + 0.5 * osc(t, 1.3, -(x + y) * 0.12);
      final size = 16 * (0.35 + 0.65 * s);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(30 + x * 20.0, 30 + y * 20.0), width: size, height: size), const Radius.circular(3)),
        fillOf(Color.lerp(k.sky, k.mint, (x + y) / 4)!),
      );
    }
  }
}

void _orbit(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 5; i++) {
    final a = t * 3.2 - i * 0.32 + math.sin(t * 3.2) * 0.4 * i / 5;
    c.drawCircle(polar(28, a), 5.5 - i * 0.8, fillOf(fade(k.gold, 1 - i * 0.17)));
  }
  c.drawCircle(kMid, 28, strokeOf(fade(k.fg, 0.08), 1));
}

void _infinity(Canvas c, double t, AnimInk k) {
  Offset at(double u) {
    final s = math.sin(u), co = math.cos(u);
    final d = 1 + s * s;
    return Offset(50 + 34 * co / d, 50 + 34 * s * co / d);
  }

  final path = Path();
  for (var i = 0; i <= 80; i++) {
    final o = at(i / 80 * tau);
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  c.drawPath(path, strokeOf(fade(k.fg, 0.12), 5));
  for (var j = 0; j < 14; j++) {
    final u = t * 3 - j * 0.09;
    c.drawCircle(at(u), 3.2 * (1 - j / 16), fillOf(fade(k.pink, 1 - j / 14)));
  }
}

void _hourglass(Canvas c, double t, AnimInk k) {
  final cyc = saw(t, 3);
  final flipping = cyc > 0.85;
  final fill = flipping ? 1.0 : cyc / 0.85;
  c.save();
  c.translate(50, 50);
  if (flipping) c.rotate((cyc - 0.85) / 0.15 * math.pi);
  final glass = Path()
    ..moveTo(-18, -30)
    ..lineTo(18, -30)
    ..lineTo(2, 0)
    ..lineTo(18, 30)
    ..lineTo(-18, 30)
    ..lineTo(-2, 0)
    ..close();
  c.save();
  c.clipPath(glass);
  final top = flipping ? 0.0 : 1 - fill;
  c.drawRect(Rect.fromLTRB(-20, -30 * top, 20, 0), fillOf(k.gold));
  final bottomH = 30 * (flipping ? 1.0 : fill);
  c.drawRect(Rect.fromLTRB(-20, 30 - bottomH, 20, 30), fillOf(k.gold));
  if (!flipping) c.drawLine(const Offset(0, 0), const Offset(0, 30), strokeOf(k.gold, 1.2));
  c.restore();
  c.drawPath(glass, strokeOf(k.fg, 2.2));
  c.drawLine(const Offset(-22, -31), const Offset(22, -31), strokeOf(k.fg, 3));
  c.drawLine(const Offset(-22, 31), const Offset(22, 31), strokeOf(k.fg, 3));
  c.restore();
}

void _bar(Canvas c, double t, AnimInk k) {
  final track = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 46, 76, 8), const Radius.circular(4));
  c.drawRRect(track, fillOf(fade(k.fg, 0.12)));
  c.save();
  c.clipRRect(track);
  final s = saw(t, 1.5);
  final x = -30 + s * 136;
  c.drawRect(Rect.fromLTWH(x, 46, 30 + 20 * math.sin(s * math.pi), 8),
      Paint()..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + 50, 0), [k.sky, k.violet]));
  c.restore();
}

void _comet(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  c.rotate(t * 5);
  c.drawCircle(
    Offset.zero,
    30,
    strokeOf(const Color(0xFFFFFFFF), 7)
      ..shader = ui.Gradient.sweep(Offset.zero, [fade(k.orange, 0), k.orange], [0.0, 0.9]),
  );
  c.drawCircle(const Offset(30, 0), 4.5, fillOf(k.orange));
  c.restore();
}

void _fold(Canvas c, double t, AnimInk k) {
  c.save();
  c.translate(50, 50);
  c.rotate(math.pi / 4);
  for (var i = 0; i < 4; i++) {
    final s = saw(t, 2.4, -i * 0.15);
    final vis = s < 0.4 ? (s / 0.4) : (s < 0.7 ? 1.0 : 1 - (s - 0.7) / 0.3);
    c.save();
    c.rotate(i * math.pi / 2);
    c.drawRect(Rect.fromLTWH(1, 1, 22 * vis.clamp(0.0, 1.0), 22), fillOf(fade(k.palette[i], vis.clamp(0.0, 1.0))));
    c.restore();
  }
  c.restore();
}

void _dotWave(Canvas c, double t, AnimInk k) {
  for (var i = 0; i < 7; i++) {
    final y = 50 + osc(t, 1.4, -i * 0.1) * 16;
    c.drawCircle(Offset(17 + i * 11.0, y), 4, fillOf(hue(170 + i * 18, 0.65, k.onLight ? 0.75 : 1)));
  }
}

void _ecg(Canvas c, double t, AnimInk k) {
  double beat(double x) {
    final u = (x / 100 + t * 0.5) % 1;
    if (u < 0.30 || u > 0.55) return 0;
    if (u < 0.36) return -6 * (u - 0.30) / 0.06;
    if (u < 0.42) return -6 + 34 * (u - 0.36) / 0.06;
    if (u < 0.47) return 28 - 46 * (u - 0.42) / 0.05;
    return -18 + 18 * (u - 0.47) / 0.08;
  }

  final p = Path();
  for (var x = 0.0; x <= 100; x += 1) {
    final y = 54 - beat(x);
    x == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  c.drawPath(p, strokeOf(fade(k.pink, 0.35), 5));
  c.drawPath(p, strokeOf(k.pink, 2));
}

void _clock(Canvas c, double t, AnimInk k) {
  c.drawCircle(kMid, 32, strokeOf(k.fg, 3.5));
  for (var i = 0; i < 12; i++) {
    final a = i * tau / 12;
    c.drawLine(polar(26, a), polar(29, a), strokeOf(fade(k.fg, 0.6), 1.5));
  }
  c.drawLine(kMid, polar(22, t * 0.5 - math.pi / 2), strokeOf(k.fg, 3.5));
  c.drawLine(kMid, polar(27, t * 6 - math.pi / 2), strokeOf(k.gold, 2.4));
  c.drawCircle(kMid, 3, fillOf(k.gold));
}

void _typing(Canvas c, double t, AnimInk k) {
  final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 30, 72, 36), const Radius.circular(18));
  c.drawRRect(bubble, fillOf(fade(k.fg, 0.12)));
  c.drawPath(
    Path()
      ..moveTo(22, 62)
      ..lineTo(14, 74)
      ..lineTo(32, 64)
      ..close(),
    fillOf(fade(k.fg, 0.12)),
  );
  for (var i = 0; i < 3; i++) {
    final s = saw(t, 1.2, -i * 0.18);
    final up = s < 0.4 ? math.sin(s / 0.4 * math.pi) : 0.0;
    c.drawCircle(Offset(36 + i * 14.0, 48 - up * 6), 4.5, fillOf(fade(k.fg, 0.45 + up * 0.55)));
  }
}

void _segments(Canvas c, double t, AnimInk k) {
  const n = 10;
  final lead = (t * 8) % n;
  for (var i = 0; i < n; i++) {
    final age = (lead - i) % n;
    final a = i * tau / n - math.pi / 2;
    c.drawArc(Rect.fromCircle(center: kMid, radius: 30), a + 0.08, tau / n - 0.16, false,
        strokeOf(Color.lerp(k.gold, fade(k.fg, 0.12), age / n)!, 9, cap: StrokeCap.butt));
  }
}

void _cradle(Canvas c, double t, AnimInk k) {
  final sw = osc(t, 1.4);
  c.drawLine(const Offset(18, 24), const Offset(82, 24), strokeOf(k.fg, 2.5));
  for (var i = 0; i < 5; i++) {
    var a = 0.0;
    if (i == 0 && sw < 0) a = sw * 0.6;
    if (i == 4 && sw > 0) a = sw * 0.6;
    final pivot = Offset(30 + i * 10.0, 24);
    final ball = pivot + Offset(math.sin(a) * 38, math.cos(a) * 38);
    c.drawLine(pivot, ball, strokeOf(fade(k.fg, 0.5), 0.8));
    c.drawCircle(ball, 5, Paint()..shader = ui.Gradient.radial(ball - const Offset(1.5, 1.5), 6, [Colors.white, k.gold]));
  }
}

void _spiral(Canvas c, double t, AnimInk k) {
  final n = k.n(28);
  for (var i = 0; i < n; i++) {
    final u = i / n;
    final a = u * tau * 2.2 - t * 3;
    final r = 4 + u * 34;
    final pulse = 0.5 + 0.5 * osc(t, 1.2, -u);
    c.drawCircle(polar(r, a), 1 + u * 3 * pulse, fillOf(fade(Color.lerp(k.violet, k.mint, u)!, 0.4 + pulse * 0.6)));
  }
}

void _triangle(Canvas c, double t, AnimInk k) {
  final pts = [polar(30, -math.pi / 2), polar(30, math.pi / 6), polar(30, 5 * math.pi / 6)];
  c.drawPath(Path()..addPolygon(pts, true), strokeOf(fade(k.fg, 0.12), 3));
  for (var j = 0; j < 3; j++) {
    final u = (saw(t, 2.1) * 3 + j) % 3;
    final i = u.floor();
    final f = Curves.easeInOut.transform(u - i);
    final p = Offset.lerp(pts[i], pts[(i + 1) % 3], f)!;
    c.drawCircle(p, 6, fillOf(k.palette[j + 1]));
  }
}
