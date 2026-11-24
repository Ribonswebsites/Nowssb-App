// What the Player's practice sheet shows for a teacher-recorded stage: the
// stage progress (Stage 1 → 2 → 3), and after a take the score, the five
// sub-scores, a pointer on the teacher's recording showing WHERE the take
// differed, and the tips.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../pronunciation/shabda/shabda_practice.dart';
import '../../pronunciation/shabda/shabda_scorer.dart' show SegmentError;
import 'stage_pack.dart';
import 'stage_progress.dart';
import 'stage_scoring.dart';

const _kGood = Color(0xFF7BE0A8);
const _kWarn = Color(0xFFFFC86B);
const _kBad = Color(0xFFFF8A80);
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

/// Score, sub-scores, the pointer and the tips for one scored take.
class StageResultPanel extends StatelessWidget {
  const StageResultPanel({super.key, required this.take, required this.stage});
  final StageTake take;
  final int stage;

  @override
  Widget build(BuildContext context) {
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
      Text('${r.overall}',
          key: const ValueKey('stage-score'),
          style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w300, height: 1, letterSpacing: -2)),
      const SizedBox(height: 4),
      Text(word,
          key: const ValueKey('stage-verdict'),
          style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      if (r.score != null) ...[
        const SizedBox(height: 16),
        StageWordPointer(take: take),
      ],
    ]);
  }

  // Kept for the sheet's older layout; the score screen no longer shows them.
  // ignore: unused_element
  Widget _subBar(SubScore s) {
    final c = s.value >= 70 ? _kGood : (s.value >= 45 ? _kWarn : _kBad);
    return Padding(
      key: ValueKey('stage-sub-${s.key}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 96, child: Text(s.label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: s.value / 100,
              minHeight: 6,
              backgroundColor: const Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ),
        SizedBox(width: 34, child: Text('${s.value}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _tip(String mark, String text, Color c, Key? key) => Padding(
        key: key,
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.18)),
            child: mark.isEmpty
                ? Icon(Icons.check_rounded, size: 13, color: c)
                : Text(mark, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5, height: 1.35))),
        ]),
      );
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
    final worst = m.isEmpty ? null : m.first;
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
              painter: _PointerPainter(take.refTimes, take.refEnergyDb, a, b, worst == null ? const [] : [worst]),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        plainTip(take),
        key: const ValueKey('stage-pointer-note'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35),
      ),
    ]);
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
    if (marks.isNotEmpty) {
      final cx = (x(marks.first.start) + x(marks.first.end)) / 2;
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
