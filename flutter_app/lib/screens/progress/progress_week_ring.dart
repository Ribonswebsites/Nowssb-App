/// REBUILD-C hero for My Progress: the current week as a breathing ring of
/// seven arcs (one per day, lit when practised) around the real streak.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'progress_tokens.dart';

class ProgressWeekRing extends StatefulWidget {
  const ProgressWeekRing({super.key, required this.days, required this.streak, this.size = 300, this.compact = false});
  final bool compact;
  final List<({String date, bool done, bool isToday, bool isFuture})> days;
  final int streak;
  final double size;
  @override
  State<ProgressWeekRing> createState() => _ProgressWeekRingState();
}

class _ProgressWeekRingState extends State<ProgressWeekRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: _RingPainter(widget.days, widget.compact, reduce ? 1 : Curves.easeOutCubic.transform(_c.value))),
            ),
          ),
        ),
        if (!widget.compact)
        for (var i = 0; i < 7; i++)
          Align(
            alignment: Alignment(
              math.cos(-math.pi / 2 + (i + .5) * 2 * math.pi / 7) * .98,
              math.sin(-math.pi / 2 + (i + .5) * 2 * math.pi / 7) * .98,
            ),
            child: Text(letters[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.days[i].isToday ? MpColors.gold : MpColors.dim)),
          ),
        if (!widget.compact) Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${widget.streak}', style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 84, height: 1, fontWeight: FontWeight.w200, color: MpColors.white)),
          const SizedBox(height: 8),
          Text(widget.streak == 1 ? 'DAY IN A ROW' : 'DAYS IN A ROW', style: const TextStyle(fontSize: 10.5, letterSpacing: 3, color: MpColors.muted)),
        ]),
      ]),
    );
  }
}

const _play = [MpColors.gold, MpColors.gold, MpColors.gold, MpColors.gold];

class _RingPainter extends CustomPainter {
  _RingPainter(this.days, this.compact, this.t);
  final bool compact;
  final List<({String date, bool done, bool isToday, bool isFuture})> days;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * .78;
    final breathe = t;
    if (!compact) canvas.drawCircle(c, r * (1.05 + .05 * breathe), Paint()
      ..shader = RadialGradient(colors: [MpColors.gold.withOpacity(.10 + .06 * breathe), MpColors.gold.withOpacity(0)]).createShader(Rect.fromCircle(center: c, radius: r * 1.2)));
    const seg = 2 * math.pi / 7;
    const gap = .12;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < 7; i++) {
      final d = days[i];
      final start = -math.pi / 2 + i * seg + gap / 2;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = compact ? (d.done ? 9 : 5) : (d.done ? 10 : 3);
      if (d.done && compact) {
        p.color = _play[i % 4];
      } else if (d.done) {
        p.color = compact ? _play[i % 4] : MpColors.gold;
        canvas.drawArc(rect, start, seg - gap, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 22
          ..color = MpColors.gold.withOpacity(.12 + .1 * breathe)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      } else {
        p.color = compact ? const Color(0x2EFFFFFF) : (d.isFuture ? Colors.white.withOpacity(.07) : Colors.white.withOpacity(.18));
      }
      canvas.drawArc(rect, start, (seg - gap) * t, false, p);
      if (d.isToday) {
        // A slow comet travelling along today's arc.
        final a = start + (seg - gap) * t;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, compact ? 3 : 4, Paint()..color = compact ? MpColors.white : const Color(0xFFFFF1D6));
      }
    }
    // Inner hairline.
    canvas.drawCircle(c, r * .82, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = Colors.white.withOpacity(.08));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => true;
}
