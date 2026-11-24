// What the Player's practice sheet shows for a teacher-recorded stage after a
// take: the score (counted up in a ring), one word, and on request the
// teacher's waveform with the weak spots marked and a plain line for each.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../pronunciation/shabda/shabda_practice.dart';
import '../../pronunciation/shabda/shabda_scorer.dart' show SegmentError;
import 'stage_checklist.dart';
import 'stage_pack.dart';
import 'stage_progress.dart';
import 'stage_scoring.dart';

const _kMuted = Color(0x99FFFFFF);

/// Stage 1 → 2 → 3: passed, the one in play, open, and not recorded yet.
class StageProgressStrip extends StatelessWidget {
  const StageProgressStrip({super.key, required this.pack, required this.current, this.admin = false});
  final StagePack pack;
  final int current;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final progress = StageProgressStore.instance;
    final numbers = <int>{for (final s in pack.stages) s.number, ...pack.comingSoon}.toList()..sort();
    final passed = progress.passedCount(pack.wordKey);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(
          '${pack.stages.length} recorded ${pack.stages.length == 1 ? 'stage' : 'stages'}, all open'
          '${passed > 0 ? ' · $passed passed' : ''}',
          key: const ValueKey('stage-progress-label'),
          style: const TextStyle(color: _kMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final n in numbers) _chip(n, progress),
      ]),
    ]);
  }

  Widget _chip(int n, StageProgressStore progress) {
    final recorded = pack.stages.any((s) => s.number == n);
    final rec = progress.record(pack.wordKey, n);
    // Every recorded stage is open; only one not recorded yet is locked.
    final open = recorded;
    final here = n == current;
    final Color fill = here ? Colors.white : const Color(0x14FFFFFF);
    final Color ink = here ? const Color(0xFF0B0B10) : (rec.passed ? Colors.white : (open ? Colors.white : const Color(0x80FFFFFF)));
    return Container(
      key: ValueKey('stage-chip-$n'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: here ? Colors.white : const Color(0x33FFFFFF)),
      ),
      child: Text.rich(
        TextSpan(children: [
          if (rec.passed && !here)
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 3), child: Icon(Icons.check_rounded, size: 13, color: ink))),
          if (!open)
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 3), child: Icon(Icons.lock_rounded, size: 12, color: ink))),
          TextSpan(text: recorded ? 'Stage $n' : 'Stage $n · $kStageComingSoon'),
        ]),
        style: TextStyle(color: ink, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The score for one take: a count-up from 0 inside a thin white ring, one
/// word, and "See what to improve", which opens the checklist page.
class StageResultPanel extends StatefulWidget {
  const StageResultPanel({super.key, required this.take, required this.stage, this.title = 'What to improve'});
  final StageTake take;
  final int stage;

  /// Heading of the checklist page (the word).
  final String title;

  @override
  State<StageResultPanel> createState() => _StageResultPanelState();
}

class _StageResultPanelState extends State<StageResultPanel> with SingleTickerProviderStateMixin {
  // One smooth ease-out: fast at first, settling softly on the score, with
  // a light tap when it lands (a firmer one for a pass).
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _ease = CurvedAnimation(parent: _c, curve: Curves.easeOutQuart);

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() {
    _c.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted || _c.value < 1 || !widget.take.result.scored) return;
      widget.take.result.passed ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    });
  }

  @override
  void didUpdateWidget(StageResultPanel old) {
    super.didUpdateWidget(old);
    if (!identical(old.take, widget.take)) _run();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final take = widget.take;
    final r = take.result;
    if (!r.scored) {
      return Column(key: const ValueKey('stage-unscored'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(r.headline, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(r.message, style: const TextStyle(color: Color(0xCCF4F4F5), fontSize: 13, height: 1.35)),
      ]);
    }
    final word = r.overall >= 85 ? 'Great' : (r.passed ? 'Close' : 'Try again');
    return Column(key: const ValueKey('stage-result'), crossAxisAlignment: CrossAxisAlignment.center, children: [
      RepaintBoundary(
        child: SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            key: const ValueKey('stage-score-ring'),
            painter: _ScoreRing(_ease, r.overall / 100),
            child: Center(
              child: AnimatedBuilder(
                animation: _ease,
                builder: (_, __) => Text('${(r.overall * _ease.value).round()}',
                    key: const ValueKey('stage-score'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        height: 1,
                        letterSpacing: -2,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      FadeTransition(
        opacity: CurvedAnimation(parent: _c, curve: const Interval(.55, 1)),
        child: Text(word,
            key: const ValueKey('stage-verdict'),
            style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      ),
      if (r.score != null) ...[
        const SizedBox(height: 12),
        GestureDetector(
          key: const ValueKey('stage-improve-btn'),
          behavior: HitTestBehavior.opaque,
          onTap: () => openStageChecklist(context, take, title: widget.title),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('See what to improve',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
            ]),
          ),
        ),
      ],
    ]);
  }
}

class _ScoreRing extends CustomPainter {
  _ScoreRing(this.t, this.target) : super(repaint: t);
  final Animation<double> t;
  final double target;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = t.value * target;
    final rect = Offset.zero & size;
    final r = rect.deflate(4);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x1FFFFFFF));
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * fill.clamp(0.0, 1.0), false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ScoreRing old) => old.target != target || old.t != t;
}

/// Where in the word the take differed: the teacher's recording drawn as a
/// loudness strip (beginning → ending), each place that differed shaded,
/// and a pointer under the worst one with what went wrong there.
class StageWordPointer extends StatelessWidget {
  const StageWordPointer({super.key, required this.take});
  final StageTake take;

  /// The places to mark, worst first (at most three).
  static List<SegmentError> marks(StageTake take) {
    final s = take.result.score;
    if (s == null) return const [];
    final e = List<SegmentError>.of(s.errors)..sort((a, b) => b.severity.compareTo(a.severity));
    return e.take(3).toList();
  }

  static String _part(double t, double a, double b) {
    final p = (t - a) / math.max(1e-3, b - a);
    return p < 0.34 ? 'beginning' : (p > 0.66 ? 'ending' : 'middle');
  }

  @override
  Widget build(BuildContext context) {
    final s = take.result.score!;
    final a = s.refStart, b = s.refEnd;
    final m = marks(take);
    final lines = improveLines(take);
    return Column(key: const ValueKey('stage-pointer'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x26FFFFFF)),
          ),
          child: SizedBox(
            height: 58,
            child: CustomPaint(
              painter: _PointerPainter(take.refTimes, take.refEnergyDb, a, b, m),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      if (lines.isEmpty)
        const Text('Nothing to fix, well done.',
            key: ValueKey('stage-pointer-note'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35))
      else
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(lines[i],
                key: ValueKey(i == 0 ? 'stage-pointer-note' : 'stage-improve-$i'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: i == 0 ? const Color(0xF2FFFFFF) : const Color(0xB3FFFFFF),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35)),
          ),
    ]);
  }

  static String _how(SegmentError w) {
    final d = w.detail.toLowerCase();
    if (w.kind == 'missing') return 'say every sound';
    if (w.kind == 'timing') {
      return d.contains('fast') || d.contains('short') || d.contains('quick')
          ? 'say it a little slower'
          : (d.contains('slow') || d.contains('long') ? 'say it a little quicker' : 'match the teacher’s timing');
    }
    if (w.kind == 'pitch') return 'follow the teacher’s rise and fall';
    return 'copy the teacher’s sound closely';
  }

  /// One to three short lines, one per weak part of the word, worst first:
  /// "Ending: say it a little quicker." Empty when nothing is weak.
  static List<String> improveLines(StageTake take) {
    final s = take.result.score;
    if (s == null) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final w in marks(take)) {
      final where = _part((w.start + w.end) / 2, s.refStart, s.refEnd);
      if (!seen.add(where)) continue;
      out.add('${_cap(where)}: ${_how(w)}.');
    }
    return out;
  }

  /// One short, plain sentence: where to focus and what to do there.
  static String plainTip(StageTake take) {
    final s = take.result.score;
    final m = marks(take);
    if (s == null || m.isEmpty) return 'Lovely — it matches the teacher. Say it once more to make it stick.';
    final w = m.first;
    final where = _part((w.start + w.end) / 2, s.refStart, s.refEnd);
    final d = w.detail.toLowerCase();
    final String how;
    if (w.kind == 'missing') {
      how = 'say every sound there';
    } else if (w.kind == 'timing') {
      how = d.contains('fast') || d.contains('short') || d.contains('quick')
          ? 'say it a little slower'
          : (d.contains('slow') || d.contains('long') ? 'say it a little quicker' : 'match the teacher’s timing');
    } else if (w.kind == 'pitch') {
      how = 'follow the teacher’s rise and fall';
    } else {
      how = 'copy the teacher’s sound closely';
    }
    return 'Focus on the $where, $how.';
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.times, this.db, this.a, this.b, this.marks);
  final List<double> times;
  final List<double> db;
  final double a;
  final double b;
  final List<SegmentError> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - 14; // room for the pointer under the strip
    final span = math.max(1e-3, b - a);
    double x(double t) => ((t - a) / span).clamp(0.0, 1.0) * size.width;
    // Shaded places that differed (worst darkest).
    for (var i = marks.length - 1; i >= 0; i--) {
      final e = marks[i];
      final p = Paint()..color = const Color(0x1FFFFFFF);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(x(e.start), 0, math.max(x(e.end), x(e.start) + 3), h), const Radius.circular(4)), p);
    }
    // The teacher's recording as bars.
    const bars = 56;
    final bw = size.width / bars;
    final bar = Paint()..color = const Color(0x99FFFFFF);
    for (var k = 0; k < bars; k++) {
      final t0 = a + span * k / bars, t1 = a + span * (k + 1) / bars;
      var v = -80.0;
      for (var j = 0; j < times.length && j < db.length; j++) {
        if (times[j] >= t0 && times[j] < t1) v = math.max(v, db[j]);
      }
      final lvl = ((v + 60) / 60).clamp(0.04, 1.0);
      final bh = h * lvl;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(k * bw + bw * .2, (h - bh) / 2, bw * .6, bh), const Radius.circular(2)), bar);
    }
    // The pointer: a triangle under the worst place.
    for (final e in marks) {
      final cx = (x(e.start) + x(e.end)) / 2;
      final tri = Path()
        ..moveTo(cx, h + 2)
        ..lineTo(cx - 7, size.height)
        ..lineTo(cx + 7, size.height)
        ..close();
      canvas.drawPath(tri, Paint()..color = Colors.white);
      canvas.drawLine(Offset(cx, 0), Offset(cx, h), Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.marks != marks || old.db != db;
}
