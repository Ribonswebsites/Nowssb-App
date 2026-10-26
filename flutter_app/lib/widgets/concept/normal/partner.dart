/// Partner points — "Constellation": Spark, Glow and Radiant are the stars
/// of a zig-zag asterism. Reached stars are lit gold with a glow; the link
/// between two reached stars is solid gold and the link to the next star
/// fills with real progress. Before Spark, a halo around Spark sweeps with
/// progress and your pulsing point rides its rim (never left of Spark).
///
/// Data: [points] = partner `confirmed` points (partner program summary);
/// [levels] = server `config.partner.levels` (functions/_lib/economy/
/// config.js). Both are runtime values with no fallback: when [levels] is
/// null or empty the constellation and the "points to" line are hidden.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NPartner extends StatefulWidget {
  const NPartner({super.key, required this.points, required this.levels, required this.onPartner});
  final int points;
  final List<(String, int)>? levels;
  final VoidCallback onPartner;
  @override
  State<NPartner> createState() => _NPartnerState();
}

class _NPartnerState extends State<NPartner> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 3);
  @override
  Widget build(BuildContext context) {
    final lv = widget.levels ?? const <(String, int)>[];
    final has = lv.isNotEmpty;
    final next = has ? lv.where((l) => l.$2 > widget.points).firstOrNull : null;
    final reached = has ? lv.lastWhere((l) => l.$2 <= widget.points, orElse: () => ('', 0)) : ('', 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Open partner program', onTap: widget.onPartner, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reached.$1.isEmpty ? 'Partner points' : 'Partner · ${reached.$1}', style: nHello),
          Text('${widget.points}', style: nTitle),
          if (has) ...[
            const SizedBox(height: 2),
            Text(next == null ? '${lv.last.$1} reached' : '${next.$2 - widget.points} points to ${next.$1}',
                style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (c, k) {
              final sc = MediaQuery.textScalerOf(c).scale(1);
              final w = k.maxWidth;
              const skyH = 96.0;
              final pts = [for (var i = 0; i < lv.length; i++) _starPos(i, lv.length, w, skyH)];
              final lowest = pts.map((p) => p.dy).reduce(math.max);
              return SizedBox(height: lowest + 16 + 36 * sc, child: Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned(left: 0, right: 0, top: 0, height: skyH, child: AnimatedBuilder(animation: loop, builder: (_, __) =>
                    CustomPaint(painter: _Sky(t: loop.value, points: widget.points, stars: pts,
                        th: [for (final l in lv) l.$2])))),
                for (var i = 0; i < lv.length; i++)
                  Positioned(
                    top: pts[i].dy + 15,
                    left: (pts[i].dx - 45).clamp(0.0, w - 90),
                    width: 90,
                    child: Column(children: [
                      Text(lv[i].$1, maxLines: 1, style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700)),
                      Text('${lv[i].$2}', maxLines: 1, style: nSub),
                    ])),
              ]));
            }),
          ],
          const SizedBox(height: 8),
          const Text('Points come only from real purchases through your links.', style: nSub),
        ]),
      )));
  }
}

/// Star i of n in a constellation (not on a line): spread across the
/// width, zig-zagging up and down like a real asterism.
Offset _starPos(int i, int n, double w, double h) {
  const pad = 30.0;
  final fx = n == 1 ? .5 : i / (n - 1);
  const ys = [.68, .22, .5, .3, .62];
  return Offset(pad + (w - 2 * pad) * fx, h * ys[i % ys.length]);
}

/// Constellation: tier stars at their thresholds, joined star-to-star.
/// Reached stars are lit gold with a glow; a line between two reached stars
/// is solid gold; the line toward the next star fills with real progress
/// (points between the two thresholds). Before the first star, a halo
/// around that star sweeps with progress and "you" sits on its rim, so the
/// marker is never left of the first star.
class _Sky extends CustomPainter {
  _Sky({required this.t, required this.points, required this.stars, required this.th});
  final double t;
  final int points;
  final List<Offset> stars;
  final List<int> th;
  static const gold = Color(0xFFE2A93A), goldHi = Color(0xFFFFD970);
  @override
  void paint(Canvas c, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 22; i++) {
      final o = Offset(6 + rnd.nextDouble() * (s.width - 12), 4 + rnd.nextDouble() * (s.height - 8));
      final tw = .35 + .35 * math.sin((t + i / 22) * math.pi * 2);
      c.drawCircle(o, rnd.nextDouble() < .3 ? 1.5 : 1, Paint()..color = const Color(0xFF6C63D9).withValues(alpha: tw * .5));
    }
    final reached = [for (final v in th) points >= v];
    Offset you = stars.first;
    // links between stars
    for (var i = 0; i + 1 < stars.length; i++) {
      final a = stars[i], b = stars[i + 1];
      final dash = Paint()..strokeWidth = 1.4..color = const Color(0xFFA9AEC0);
      final d = b - a;
      for (var f = 0.0; f < 1; f += .06) {
        c.drawLine(a + d * f, a + d * math.min(f + .03, 1), dash);
      }
      double fill = 0;
      if (reached[i + 1]) {
        fill = 1;
      } else if (reached[i]) {
        fill = ((points - th[i]) / (th[i + 1] - th[i])).clamp(0.0, 1.0);
        you = a + d * fill;
      }
      if (fill > 0) {
        final e = a + d * fill;
        c.drawLine(a, e, Paint()..strokeWidth = 6..strokeCap = StrokeCap.round..color = goldHi.withValues(alpha: .35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        c.drawLine(a, e, Paint()..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = const Color(0xFFA87314)); // 3.66:1 on the card
      }
    }
    // stars
    for (var i = 0; i < stars.length; i++) {
      final o = stars[i];
      final r = 8.0 + i * 1.5;
      if (reached[i]) {
        final g = .7 + .3 * math.sin((t + i / 3) * math.pi * 2);
        c.drawCircle(o, r + 9, Paint()..color = goldHi.withValues(alpha: .5 * g)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2 + math.pi / 4;
          c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * (r + 7 * g), Paint()..strokeWidth = 1..color = gold.withValues(alpha: .6));
        }
      }
      final star = _star(o, r, r * .45);
      c.drawPath(star, Paint()..color = reached[i] ? gold : Colors.white);
      c.drawPath(star, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeJoin = StrokeJoin.round
          ..color = reached[i] ? const Color(0xFF9A6A12) : const Color(0xFF7D8396));
    }
    // before the first star: a halo around it sweeps with real progress
    if (!reached.first) {
      final o = stars.first;
      const hr = 17.0;
      final f = (points / th.first).clamp(0.0, 1.0);
      c.drawCircle(o, hr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFFC9CDDA));
      if (f > 0) {
        c.drawArc(Rect.fromCircle(center: o, radius: hr), -math.pi / 2, math.pi * 2 * f, false,
            Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = gold);
      }
      final a = -math.pi / 2 + math.pi * 2 * f;
      you = o + Offset(math.cos(a), math.sin(a)) * hr;
    } else if (reached.last) {
      you = stars.last;
    }
    final pulse = math.sin(t * math.pi * 2) * .5 + .5;
    // on a star exactly: ring it instead of covering the lit star
    final onStar = stars.indexWhere((o) => (o - you).distance < 1);
    if (onStar >= 0 && reached[onStar]) {
      final r = 8.0 + onStar * 1.5 + 6 + 2 * pulse;
      c.drawCircle(you, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = nLink);
      return;
    }
    c.drawCircle(you, 8 + 4 * pulse, Paint()..color = nLink.withValues(alpha: .18 * (1 - pulse) + .08));
    c.drawCircle(you, 5, Paint()..color = nLink);
    c.drawCircle(you, 2, Paint()..color = Colors.white);
  }
  Path _star(Offset o, double r, double ri) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final a = -math.pi / 2 + k * math.pi / 5;
      final rr = k.isEven ? r : ri;
      final q = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }
  @override
  bool shouldRepaint(_Sky o) => o.t != t || o.points != points || o.stars != stars;
}
