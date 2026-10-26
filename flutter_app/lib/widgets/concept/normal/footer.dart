/// Footer — "One root": the meditating mark sits on a root whose trunk runs
/// down through the link grid, sending a branch into every pill on every
/// row. Pills are plain one-line labels (no icons) in an even grid: two
/// across with the trunk between the columns, or one column with the trunk
/// on the left on narrow screens.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NFooter extends StatefulWidget {
  const NFooter({super.key, required this.onLink});
  final void Function(String key) onLink;
  static const links = [
    ('About', 'about'), ('Word Science', 'word-science'), ('Sound Library', 'sound-library'),
    ('Meaning Store', 'meaning-store'), ('Practice', 'practice'), ('Profile', 'profile'),
  ];
  @override
  State<NFooter> createState() => _NFooterState();
}

class _NFooterState extends State<NFooter> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(milliseconds: 5500);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(children: [
        const NLottie('assets/home/nm-v4-meditate.json', size: 96),
        const Text('NowssB', style: nTitle),
        const Text('Different words.', textAlign: TextAlign.center, style: nHello),
        const Text('One root.', textAlign: TextAlign.center, style: nHello),
        LayoutBuilder(builder: (c, k) {
          final sc = MediaQuery.textScalerOf(c).scale(1);
          final w = k.maxWidth;
          final two = w >= 220; // two columns down to 320 @1.3x
          const top = 26.0, vgap = 12.0;
          final tight = w / sc < 300; // labels may wrap to two lines
          final ph = math.max(48.0, (tight ? 2 : 1) * 16 * sc + 18);
          final trunkGap = two ? 30.0 : 0.0;
          final indent = two ? 0.0 : 26.0;
          final cols = two ? 2 : 1;
          final cw = two ? (w - trunkGap) / 2 : w - indent;
          final trunkX = two ? w / 2 : 10.0;
          final n = NFooter.links.length;
          final rows = (n / cols).ceil();
          final h = top + rows * ph + (rows - 1) * vgap;
          final pills = <Rect>[
            for (var i = 0; i < n; i++)
              Rect.fromLTWH(two ? (i % 2 == 0 ? 0 : cw + trunkGap) : indent,
                  top + (i ~/ cols) * (ph + vgap), cw, ph),
          ];
          return SizedBox(height: h + 4, width: w, child: Stack(children: [
            Positioned.fill(child: AnimatedBuilder(animation: loop, builder: (_, __) =>
                CustomPaint(painter: _Root(t: loop.value, trunkX: trunkX, startX: w / 2, pills: pills)))),
            for (var i = 0; i < n; i++)
              Positioned.fromRect(rect: pills[i], child: _pill(NFooter.links[i])),
          ]));
        }),
      ]));

  Widget _pill((String, String) l) => NPress(label: l.$1, onTap: () => widget.onLink(l.$2), child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: neu(r: 22),
      child: Text(l.$1, maxLines: 2, textAlign: TextAlign.center,
          style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700, fontSize: 13))));
}

/// Root from the mark down into a trunk, with one branch into each pill's
/// inner edge; a pulse of light travels down the trunk.
class _Root extends CustomPainter {
  _Root({required this.t, required this.trunkX, required this.startX, required this.pills});
  final double t, trunkX, startX;
  final List<Rect> pills;
  @override
  void paint(Canvas c, Size s) {
    final g = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = nGold.withValues(alpha: .8);
    final lastY = pills.map((r) => r.center.dy).reduce(math.max);
    final trunk = Path()..moveTo(startX, 0);
    if (trunkX != startX) {
      trunk.cubicTo(startX, 14, trunkX, 6, trunkX, 22);
    } else {
      trunk.lineTo(trunkX, 22);
    }
    trunk.lineTo(trunkX, lastY);
    c.drawPath(trunk, g);
    for (final r in pills) {
      final toLeft = r.center.dx < trunkX;
      final ex = toLeft ? r.right - 2 : r.left + 2;
      final y = r.center.dy;
      final b = Path()..moveTo(trunkX, y - 12)..quadraticBezierTo(trunkX, y, ex, y);
      c.drawPath(b, g);
      c.drawCircle(Offset(ex, y), 2.6, Paint()..color = nGold);
    }
    final py = lastY * t;
    c.drawCircle(Offset(trunkX, py), 3.5, Paint()..color = const Color(0xFFFFD970)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }
  @override
  bool shouldRepaint(_Root o) => o.t != t;
}
