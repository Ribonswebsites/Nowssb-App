/// NowssB Rewards — "Glass coffer": a line-drawn chest with a glass front;
/// gold coins stack inside up to the real fraction of the next chest;
/// the streak is a row of 8px beads.
///
/// Data (all live, from EconomyMirror as the home's V5RewardsInvite reads it):
/// [coins] = summary coins, [streak] = summary streak, [signedIn] = uid != null.
/// No coins-per-chest rule exists in the economy (the weekly chest is paid on
/// active days), so the glass fills with this week's streak beads (streak/7).
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NRewards extends StatefulWidget {
  const NRewards({super.key, required this.coins, required this.streak, required this.signedIn,
      required this.onOpenRewards, required this.onSignIn});
  final int coins, streak;
  final bool signedIn;
  final VoidCallback onOpenRewards, onSignIn;
  @override
  State<NRewards> createState() => _NRewardsState();
}

class _NRewardsState extends State<NRewards> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 6);
  @override
  Widget build(BuildContext context) {
    final fill = widget.signedIn ? (widget.streak.clamp(0, 7)) / 7 : 0.0;
    final day = widget.streak.clamp(0, 7);
    final glass = SizedBox(width: 132, height: 120, child: AnimatedBuilder(animation: loop, builder: (_, __) =>
        CustomPaint(painter: _Chest(fill: fill, t: loop.value))));
    // the fill is the real streak; say so under the chest
    final chest = widget.signedIn
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            glass,
            const SizedBox(height: 4),
            Text('Day $day of 7', key: const ValueKey('rewards-day'), textAlign: TextAlign.center,
                style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700)),
          ])
        : glass;
    final beads = Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 7; i++)
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.signedIn && i < widget.streak ? const Color(0xFFE8792F) : const Color(0xFFC9CED9))),
    ]);
    final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('NowssB Rewards', style: nHello),
      Text(widget.signedIn ? '${widget.coins} coins' : 'Sign in for rewards', style: nTitle),
      const SizedBox(height: 6),
      Text(widget.signedIn ? 'Open your rewards' : 'Coins and streak stay on your account', style: nSub),
      if (widget.signedIn) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [beads, Text('${widget.streak}-day streak', maxLines: 1, softWrap: false, style: nSub)]),
      ],
    ]);
    return Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 10), child: NPress(
      label: widget.signedIn ? 'Open rewards' : 'Sign in',
      onTap: widget.signedIn ? widget.onOpenRewards : widget.onSignIn,
      child: Container(decoration: neu(r: 30), padding: const EdgeInsets.all(18),
        child: LayoutBuilder(builder: (c, k) {
          final narrow = k.maxWidth / MediaQuery.textScalerOf(c).scale(1) < 300;
          return narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: chest), const SizedBox(height: 10), copy])
              : Row(children: [chest, const SizedBox(width: 14), Expanded(child: copy)]);
        }))));
  }
}

/// "Glass coffer": a line-drawn chest in the app's ink and violet with a
/// glass front. Gold coins stack inside the glass up to [fill] (the real
/// coins-into-this-chest fraction), with a level tick on the side; the
/// gold surface shimmers. At 0 the glass is empty.
class _Chest extends CustomPainter {
  _Chest({required this.fill, required this.t});
  final double fill, t;
  static const ink = Color(0xFF1C1B33), violet = Color(0xFF6C63D9), gold = Color(0xFFE2A93A), goldHi = Color(0xFFFFDB7A);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = Rect.fromLTWH(w * .1, h * .34, w * .8, h * .56);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..color = ink..strokeJoin = StrokeJoin.round;
    c.drawOval(Rect.fromLTWH(w * .12, h * .87, w * .76, h * .09), Paint()..color = const Color(0x338E97B5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // lid: a low arch with a violet band
    final lid = Path()..moveTo(body.left, body.top)..lineTo(body.left, body.top - h * .1)
      ..quadraticBezierTo(w / 2, body.top - h * .34, body.right, body.top - h * .1)..lineTo(body.right, body.top)..close();
    c.drawPath(lid, Paint()..color = Colors.white);
    c.drawPath(lid, Paint()..style = PaintingStyle.stroke..strokeWidth = 7..color = violet.withValues(alpha: .18));
    c.drawLine(Offset(w / 2, body.top - h * .22), Offset(w / 2, body.top), Paint()..strokeWidth = 7..color = violet);
    c.drawPath(lid, line);
    // body
    final rb = RRect.fromRectAndCorners(body, bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10));
    c.drawRRect(rb, Paint()..color = Colors.white);
    // glass window
    final glass = Rect.fromLTRB(body.left + 12, body.top + 10, body.right - 12, body.bottom - 10);
    final gr = RRect.fromRectAndRadius(glass, const Radius.circular(6));
    c.drawRRect(gr, Paint()..color = const Color(0xFFEDEBFB));
    c.save();
    c.clipRRect(gr);
    final top = glass.bottom - glass.height * fill;
    if (fill > 0) {
      // stacked coins, row by row, up to the level
      const rowH = 6.0;
      var row = 0;
      for (var y = glass.bottom - rowH / 2; y > top - 1; y -= rowH, row++) {
        for (var x = glass.left + (row.isOdd ? 9.0 : 4.0); x < glass.right; x += 11) {
          c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 12, height: 6), Paint()..color = gold);
          c.drawOval(Rect.fromCenter(center: Offset(x, y - 1), width: 9, height: 3), Paint()..color = goldHi);
        }
      }
      // shimmering gold surface
      final surf = Path()..moveTo(glass.left, top);
      for (var x = 0.0; x <= glass.width; x += 4) {
        surf.lineTo(glass.left + x, top + math.sin(x / glass.width * math.pi * 3 + t * math.pi * 2) * 1.6);
      }
      c.drawPath(surf, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = goldHi);
    }
    // glass glare
    c.drawLine(Offset(glass.left + 8, glass.top + 4), Offset(glass.left + 2, glass.top + 16),
        Paint()..strokeWidth = 3..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .8));
    c.restore();
    c.drawRRect(gr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = ink.withValues(alpha: .5));
    c.drawRRect(rb, line);
    // clasp
    final clasp = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, body.top), width: 16, height: 14), const Radius.circular(4));
    c.drawRRect(clasp, Paint()..color = violet);
    c.drawRRect(clasp, line..strokeWidth = 2);
    c.drawCircle(Offset(w / 2, body.top + 1), 2, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(_Chest o) => o.t != t || o.fill != fill;
}
