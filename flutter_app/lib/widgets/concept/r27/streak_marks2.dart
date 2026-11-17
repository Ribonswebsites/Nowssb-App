/// Streak marks, round 4 — three candidates for the right side of the
/// Normal-home "YOUR STREAK" card (72 × 84 inside the inset well). All
/// hand-painted, 60 fps CustomPainters; no circles, orbs, rings, particles,
/// candles or flames.
///  • [StreakSilkRibbons] (A) — four silk ribbons that turn and flow, and
///    climb higher and richer as the streak grows; gold joins at a full week.
///  • [StreakGlassTower]  (B) — a tower of frosted glass levels, one level
///    per day this week; light rises through the lit glass.
///  • [StreakLotusLine]   (C) — a line-art lotus drawn stroke by stroke over
///    still water; it opens a little more each day and blooms at seven.
/// Each plays a one-time intro, then a calm loop. Fully static in Still
/// mode / reduced motion ([StreakMarkAnim]). No haptics anywhere.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kit.dart';
import 'streak_marks.dart' show StreakMarkAnim, streakLitInWeek;

const _tau = math.pi * 2;
const _accent = Color(0xFF6C63D9);
const _indigo = Color(0xFF453BB3);
const _lilac = Color(0xFF9C95F0);
const _gold = r27Gold;
const _paleGold = Color(0xFFFFE3A0);
const _surface = Color(0xFFEDEFF4);
const _etch = Color(0xFFC9CCD8);

double _ease(double x) => Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));
double _seg(double x, double a, double b) => ((x - a) / (b - a)).clamp(0.0, 1.0);

/// 0 → 1 over the first week (0 days = 0, 7 days = 1).
double _week(int s) => s >= 7 ? 1.0 : streakLitInWeek(s) / 7;

/// Extra richness for long streaks (weeks beyond the first), 0 → 1 by day 28.
double _depth(int s) => ((s - 7) / 21).clamp(0.0, 1.0);

/// The well's own rounded shape, so motion never spills past it.
void _clipWell(Canvas c, Size s) =>
    c.clipRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20)));

// ───────────────────────── A · silk ribbons ─────────────────────────

class StreakSilkRibbons extends StatelessWidget {
  const StreakSilkRibbons({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  static const intro = Duration(milliseconds: 1500);
  static const period = Duration(milliseconds: 4800);
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: intro,
          period: period,
          builder: (_, i, t) => CustomPaint(size: size, painter: _SilkP(streak, i, t)),
        ),
      );
}

class _SilkP extends CustomPainter {
  _SilkP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;

  static const _ribbons = [
    // (base colour, width factor, lane offset, phase offset)
    (_lilac, 1.00, .00, 0.0),
    (_accent, .92, .07, 1.7),
    (_indigo, .80, .14, 3.1),
    (_gold, .55, .20, 4.4),
  ];

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _clipWell(c, s);
    final g = _week(streak) * _ease(intro);
    final deep = _depth(streak);
    final w = s.width, h = s.height;
    const n = 36;
    for (var r = 0; r < _ribbons.length; r++) {
      final (base, wf, lane, ph) = _ribbons[r];
      final isGold = r == 3;
      // Gold joins only once the week is under way; it fully arrives at 7.
      final presence = isGold ? _seg(_week(streak), .3, 1) : 1.0;
      if (presence <= 0) continue;
      final unfurl = _ease(_seg(intro, r * .12, .55 + r * .12));
      if (unfurl <= 0) continue;
      // Pale, low and calm at 0 days → tall, saturated, climbing at 7.
      final tint = Color.lerp(Color.lerp(base, _surface, .55)!, base, .35 + .65 * g)!;
      final col = isGold ? Color.lerp(_gold, const Color(0xFFC28A22), deep)! : Color.lerp(tint, _indigo, deep * .25)!;
      final baseY = h * (.84 - lane * .75);
      final rise = h * (.05 + .40 * g + lane * .30 * g);
      final amp = h * (.025 + .05 * g);
      final hw0 = h * (.05 + .035 * g) * wf;
      final top = <Offset>[], bot = <Offset>[], shade = <double>[];
      final xEnd = -w * .1 + (w * 1.2) * unfurl;
      for (var k = 0; k <= n; k++) {
        final u = k / n;
        final x = -w * .1 + w * 1.2 * u;
        if (x > xEnd + 0.01) break;
        final yc = baseY - rise * _ease(u) - amp * math.sin(_tau * (u * .85 - t) + ph);
        // Silk turning over: wide where it faces us, thin at the twist.
        final turn = math.cos(math.pi * (u * 1.25 - t) + ph * .5).abs();
        final hw = hw0 * (.22 + .78 * turn);
        // Normal of the centre line, so the band keeps its width on slopes.
        final dy = -rise * (_ease(u + .01) - _ease(u)) / .01 / (w * 1.2) -
            amp * _tau * .85 * math.cos(_tau * (u * .85 - t) + ph) / (w * 1.2);
        final len = math.sqrt(1 + dy * dy);
        final nx = -dy / len, ny = 1 / len;
        top.add(Offset(x - nx * hw, yc - ny * hw));
        bot.add(Offset(x + nx * hw, yc + ny * hw));
        shade.add(turn);
      }
      if (top.length < 2) continue;
      final alpha = (isGold ? .95 : .88) * presence;
      final path = Path()..addPolygon([...top, ...bot.reversed], true);
      // Soft drop shadow into the well for the neumorphic depth.
      c.drawPath(
        path.shift(const Offset(0, 2.2)),
        Paint()
          ..color = const Color(0xFF1E2140).withValues(alpha: .10 * presence)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      final pos = <Offset>[], cols = <Color>[];
      final hi = Color.lerp(col, Colors.white, isGold ? .55 : .5)!;
      final lo = Color.lerp(col, const Color(0xFF14123A), .22)!;
      for (var k = 0; k < top.length; k++) {
        final sh = shade[k];
        pos..add(top[k])..add(bot[k]);
        // Lit upper fold, darker underside: reads as turning silk.
        cols
          ..add(Color.lerp(col, hi, sh * .9)!.withValues(alpha: alpha))
          ..add(Color.lerp(lo, col, .35 + .5 * sh)!.withValues(alpha: alpha));
      }
      c.drawVertices(
        ui.Vertices(ui.VertexMode.triangleStrip, pos, colors: cols),
        BlendMode.dst,
        Paint(),
      );
      // Anti-aliased edges, and a fine sheen line along the upper edge.
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = col.withValues(alpha: alpha * .6),
      );
      final edge = Path()..addPolygon(top, false);
      c.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = Colors.white.withValues(alpha: (.35 + .35 * g) * presence),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SilkP o) => o.t != t || o.intro != intro || o.streak != streak;
}

// ───────────────────────── B · glass tower ─────────────────────────

class StreakGlassTower extends StatelessWidget {
  const StreakGlassTower({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  static const intro = Duration(milliseconds: 1600);
  static const period = Duration(milliseconds: 3600);
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: intro,
          period: period,
          builder: (_, i, t) => CustomPaint(size: size, painter: _TowerP(streak, i, t)),
        ),
      );
}

class _TowerP extends CustomPainter {
  _TowerP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _clipWell(c, s);
    const n = 7;
    final lit = streakLitInWeek(streak);
    final deep = _depth(streak);
    final cx = s.width / 2;
    final sh = s.height * .082, gap = s.height * .026;
    final bottom = s.height * .80;
    final total = n * sh + (n - 1) * gap;
    final wBot = s.width * .66, wTop = s.width * .46;

    Rect slab(int j, [double dy = 0]) {
      final wj = wBot + (wTop - wBot) * j / (n - 1);
      final y1 = bottom - j * (sh + gap) + dy;
      return Rect.fromLTRB(cx - wj / 2, y1 - sh, cx + wj / 2, y1);
    }

    // The light that rises through the lit levels once per loop.
    final beamY = bottom + 10 - (total + 30) * t;

    // Reflection of the lowest lit levels on the polished floor.
    final reflect = math.min(lit, 2);
    for (var j = 0; j < reflect; j++) {
      final p = _ease(_seg(intro, j * .09, .35 + j * .09));
      final r = slab(j);
      final mirror = Rect.fromLTRB(r.left, 2 * bottom - r.bottom + 3, r.right, 2 * bottom - r.top + 3);
      c.drawRRect(
        RRect.fromRectAndRadius(mirror, const Radius.circular(2.6)),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, mirror.top),
            Offset(0, mirror.bottom),
            [_accent.withValues(alpha: .16 * p * (1 - j * .45)), _accent.withValues(alpha: 0)],
          ),
      );
    }
    // Floor line.
    c.drawLine(
      Offset(cx - wBot * .62, bottom + 1.6),
      Offset(cx + wBot * .62, bottom + 1.6),
      Paint()
        ..strokeWidth = .8
        ..shader = ui.Gradient.linear(
          Offset(cx - wBot * .62, 0),
          Offset(cx + wBot * .62, 0),
          [const Color(0x00FFFFFF), Colors.white, const Color(0x00FFFFFF)],
          const [0, .5, 1],
        ),
    );

    for (var j = 0; j < n; j++) {
      final on = j < lit;
      if (!on) {
        // Etched glass outline: the level waiting to be built.
        final r = RRect.fromRectAndRadius(slab(j), const Radius.circular(2.6));
        c.drawRRect(r.shift(const Offset(.6, .6)),
            Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = Colors.white);
        c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = _etch);
        if (j == lit) {
          // The next level breathes softly — "build me today".
          final b = .5 + .5 * math.sin(_tau * t);
          c.drawRRect(r, Paint()..color = _accent.withValues(alpha: (.06 + .08 * b) * _ease(intro)));
        }
        continue;
      }
      final p = _ease(_seg(intro, j * .09, .38 + j * .09));
      if (p <= 0) continue;
      final rect = slab(j, -(1 - p) * 16);
      final r = RRect.fromRectAndRadius(rect, const Radius.circular(2.6));
      final today = j == lit - 1;
      final k = lit <= 1 ? 0.0 : j / (lit - 1);
      final glass = today
          ? Color.lerp(_gold, const Color(0xFFC28A22), deep)!
          : Color.lerp(Color.lerp(_indigo, _accent, k)!, _lilac, k * .5)!;
      final beam = math.exp(-math.pow((rect.center.dy - beamY) / 9, 2).toDouble());
      // Soft glow under the glass (a rectangle, not a halo).
      c.drawRRect(
        r.shift(const Offset(0, 1.8)),
        Paint()
          ..color = glass.withValues(alpha: (.22 + .18 * beam) * p)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, today ? 3.2 : 2.2),
      );
      // Frosted glass body: clear at the top edge, colour pooling below.
      c.drawRRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [
              Color.lerp(glass, Colors.white, .62)!.withValues(alpha: .92 * p),
              glass.withValues(alpha: (.78 + .12 * deep) * p),
              Color.lerp(glass, const Color(0xFF1A1640), .18)!.withValues(alpha: .9 * p),
            ],
            const [0, .55, 1],
          ),
      );
      // Top face of the glass brick, seen from just above.
      final dpt = sh * .38;
      final face = Path()
        ..moveTo(rect.left + 1.4, rect.top + .6)
        ..lineTo(rect.left + 3.4, rect.top - dpt)
        ..lineTo(rect.right - 3.4, rect.top - dpt)
        ..lineTo(rect.right - 1.4, rect.top + .6)
        ..close();
      c.drawPath(
        face,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, rect.top - dpt),
            Offset(0, rect.top),
            [Colors.white.withValues(alpha: .95 * p), Color.lerp(glass, Colors.white, .7)!.withValues(alpha: .9 * p)],
          ),
      );
      // Light rising through: a white wash that passes level by level.
      if (beam > .02) {
        c.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: .38 * beam * p));
      }
      // Glass edges: bright top lip and left edge, crisp outline.
      c.drawLine(Offset(rect.left + 2.2, rect.top + .9), Offset(rect.right - 2.2, rect.top + .9),
          Paint()..strokeWidth = .9..color = Colors.white.withValues(alpha: .85 * p));
      c.drawLine(Offset(rect.left + .9, rect.top + 2), Offset(rect.left + .9, rect.bottom - 2),
          Paint()..strokeWidth = .7..color = Colors.white.withValues(alpha: .5 * p));
      c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = Color.lerp(glass, const Color(0xFF14123A), .25)!.withValues(alpha: .55 * p));
    }

    // Diagonal glass sheen across the built part of the tower.
    if (lit > 0 && intro >= 1) {
      final topY = slab(lit - 1).top;
      final x = -40 + (s.width + 80) * _ease(_seg(t, .55, .95));
      final band = Path();
      for (var j = 0; j < lit; j++) {
        band.addRRect(RRect.fromRectAndRadius(slab(j), const Radius.circular(2.6)));
      }
      c.save();
      c.clipPath(band);
      c.drawRect(
        Rect.fromLTRB(0, topY, s.width, bottom),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x - 14, bottom),
            Offset(x + 14, topY),
            [const Color(0x00FFFFFF), Colors.white.withValues(alpha: .55), const Color(0x00FFFFFF)],
            const [0, .5, 1],
          ),
      );
      c.restore();
      // Full week: a fine gold crown line above the top level.
      if (lit == 7) {
        final crown = slab(6);
        final y = crown.top - gap * 1.4;
        c.drawLine(
          Offset(crown.left + 3, y),
          Offset(crown.right - 3, y),
          Paint()
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..color = _paleGold.withValues(alpha: .7 + .3 * math.sin(_tau * t).abs()),
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_TowerP o) => o.t != t || o.intro != intro || o.streak != streak;
}

// ───────────────────────── C · line-art lotus ─────────────────────────

class StreakLotusLine extends StatelessWidget {
  const StreakLotusLine({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  static const intro = Duration(milliseconds: 2200);
  static const period = Duration(milliseconds: 4400);
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: intro,
          period: period,
          builder: (_, i, t) => CustomPaint(size: size, painter: _LotusP(streak, i, t)),
        ),
      );
}

class _LotusP extends CustomPainter {
  _LotusP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;

  Path _petal(Offset b, double a, double len, double wid) {
    final d = Offset(math.sin(a), -math.cos(a));
    final nrm = Offset(math.cos(a), math.sin(a));
    final tip = b + d * len;
    return Path()
      ..moveTo(b.dx, b.dy)
      ..cubicTo(
        (b + d * (len * .28) + nrm * (wid * len)).dx,
        (b + d * (len * .28) + nrm * (wid * len)).dy,
        (tip - d * (len * .30) + nrm * (wid * len * .42)).dx,
        (tip - d * (len * .30) + nrm * (wid * len * .42)).dy,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        (tip - d * (len * .30) - nrm * (wid * len * .42)).dx,
        (tip - d * (len * .30) - nrm * (wid * len * .42)).dy,
        (b + d * (len * .28) - nrm * (wid * len)).dx,
        (b + d * (len * .28) - nrm * (wid * len)).dy,
        b.dx,
        b.dy,
      );
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _clipWell(c, s);
    final g = _week(streak);
    final deep = _depth(streak);
    final breathe = .025 * math.sin(_tau * t) * _ease(intro);
    final o = (.10 + .90 * g + breathe).clamp(0.0, 1.05);
    final b = Offset(s.width / 2, s.height * .69);
    final L = s.height * .44;

    // Still water: three drifting line ripples below the flower.
    final water = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1;
    final wp = _ease(_seg(intro, 0, .3));
    for (var k = 0; k < 3; k++) {
      final y = b.dy + 5.5 + k * 5.2;
      final half = s.width * (.36 - k * .08);
      final line = Path();
      for (var x = -half; x <= half + .01; x += 2) {
        final yy = y + 1.0 * math.sin(_tau * (x / 22 + t + k * .3));
        if (x == -half) {
          line.moveTo(b.dx + x, yy);
        } else {
          line.lineTo(b.dx + x, yy);
        }
      }
      water.shader = ui.Gradient.linear(
        Offset(b.dx - half, 0),
        Offset(b.dx + half, 0),
        [
          _accent.withValues(alpha: 0),
          _accent.withValues(alpha: (.40 - k * .1) * (.6 + .4 * g)),
          _accent.withValues(alpha: 0),
        ],
        const [0, .5, 1],
      );
      for (final m in line.computeMetrics()) {
        final mid = m.length / 2;
        c.drawPath(m.extractPath(mid - mid * wp, mid + mid * wp), water);
      }
    }

    // Petals back to front: (angle, length, width, intro start).
    final spec = <(double, double, double, double)>[
      for (final sg in [-1.0, 1.0]) (sg * (.30 + 1.02 * o), .66, .30, .55),
      for (final sg in [-1.0, 1.0]) (sg * (.16 + .62 * o), .84, .33, .40),
      for (final sg in [-1.0, 1.0]) (sg * (.05 + .30 * o), .95, .31, .25),
      (0, 1.0, .34 * (.72 + .28 * o), .12),
    ];
    final gild = Color.lerp(_gold, const Color(0xFFC28A22), deep)!;
    final petalPaths = <Path>[];
    for (final (a, lf, wf, start) in spec) {
      final p = _ease(_seg(intro, start, start + .38));
      if (p <= 0) continue;
      final path = _petal(b, a, L * lf, wf);
      petalPaths.add(path);
      final rect = path.getBounds();
      final fillA = _ease(_seg(intro, .55, 1));
      // Fill hides the petals behind, so the line art stays clean.
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(b.dx, b.dy),
            Offset(b.dx, rect.top),
            [
              Color.lerp(_surface, _lilac, .18 + .30 * g)!.withValues(alpha: .97 * fillA),
              Color.lerp(_surface, const Color(0xFFF6E6F0), .4 + .6 * g)!.withValues(alpha: .97 * fillA),
              Color.lerp(_surface, _paleGold, .15 + .65 * g)!.withValues(alpha: .97 * fillA),
            ],
            const [0, .55, 1],
          ),
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(b.dx, b.dy),
          Offset(b.dx, rect.top),
          [
            Color.lerp(const Color(0xFFA9A4D8), _indigo, .35 + .65 * g)!,
            Color.lerp(const Color(0xFFB7B1E6), _accent, .35 + .65 * g)!,
            Color.lerp(const Color(0xFFD9C58E), gild, .3 + .7 * g)!,
          ],
          const [0, .5, 1],
        );
      for (final m in path.computeMetrics()) {
        c.drawPath(m.extractPath(0, m.length * p), stroke);
      }
      // Centre vein: a fine gold line that appears as the streak grows.
      if (g > 0 && fillA > 0) {
        final d = Offset(math.sin(a), -math.cos(a));
        c.drawLine(
          b + d * (L * lf * .22),
          b + d * (L * lf * .78),
          Paint()
            ..strokeWidth = .8
            ..strokeCap = StrokeCap.round
            ..color = gild.withValues(alpha: .55 * g * fillA),
        );
      }
    }
    // A soft travelling glint along the centre petal's outline (a line, not a dot).
    if (intro >= 1 && petalPaths.isNotEmpty) {
      final m = petalPaths.last.computeMetrics().first;
      final pos = m.length * t;
      final glint = m.extractPath(math.max(0, pos - m.length * .12), math.min(m.length, pos + m.length * .02));
      c.drawPath(
        glint,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .55 + .35 * g)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .9),
      );
    }
    // Base cup: a shallow gold stroke that sits the flower on the water.
    final cupP = _ease(_seg(intro, .5, .85));
    if (cupP > 0) {
      final cw = s.width * (.14 + .12 * o);
      final cup = Path()
        ..moveTo(b.dx - cw, b.dy - 2)
        ..quadraticBezierTo(b.dx, b.dy + 6, b.dx + cw, b.dy - 2);
      for (final m in cup.computeMetrics()) {
        final mid = m.length / 2;
        c.drawPath(
          m.extractPath(mid - mid * cupP, mid + mid * cupP),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(const Color(0xFFD9C58E), gild, g)!,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_LotusP o) => o.t != t || o.intro != intro || o.streak != streak;
}
