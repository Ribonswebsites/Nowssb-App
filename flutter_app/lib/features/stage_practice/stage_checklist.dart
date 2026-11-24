// "See what to improve": a page of its own, laid out as a checklist. Five
// rows (Sounds, Timing and pace, Long sounds, Rise and fall, Whole word),
// each a tick or a cross with one plain line; a crossed row also shows the
// teacher's word as a waveform with a white marker where it differed.
// No numbers. Worked out in the scoring isolate, before the score animates.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../pronunciation/shabda/shabda_practice.dart';
import '../../pronunciation/shabda/shabda_scorer.dart' show SegmentError, ShabdaScore, kTempoTolerance;
import 'stage_scoring.dart';

/// One checklist row.
class StageCheck {
  const StageCheck(this.id, this.label, this.ok, this.line, {this.start, this.end});
  final String id; // sounds | pace | long | pitch | whole
  final String label;
  final bool ok;
  final String line;

  /// Where in the teacher's word it differed (reference seconds), if known.
  final double? start;
  final double? end;
}

const kCheckLabels = {
  'sounds': 'Sounds',
  'pace': 'Timing and pace',
  'long': 'Long sounds',
  'pitch': 'Rise and fall',
  'whole': 'Whole word',
};

String _part(double t, ShabdaScore s) {
  final p = (t - s.refStart) / math.max(1e-3, s.refEnd - s.refStart);
  return p < 0.34 ? 'beginning' : (p > 0.66 ? 'ending' : 'middle');
}

SegmentError? _worst(ShabdaScore s, bool Function(SegmentError e) test) {
  SegmentError? w;
  for (final e in s.errors) {
    if (test(e) && (w == null || e.severity > w.severity)) w = e;
  }
  return w;
}

/// The five rows for a scored take (empty when it could not be scored).
List<StageCheck> buildChecklist(AttemptResult r) {
  final s = r.score;
  if (!r.scored || s == null) return const [];
  final out = <StageCheck>[];

  // Sounds
  final ws = _worst(s, (e) => e.kind == 'sounds');
  final soundsOk = s.sounds >= 60;
  out.add(StageCheck('sounds', kCheckLabels['sounds']!, soundsOk,
      soundsOk
          ? 'Your sounds match the teacher.'
          : 'Copy the teacher’s sounds in the ${ws == null ? 'word' : '${_part((ws.start + ws.end) / 2, s)} of the word'}.',
      start: soundsOk ? null : ws?.start,
      end: soundsOk ? null : ws?.end));

  // Timing and pace
  final wt = _worst(s, (e) => e.kind == 'timing');
  final tooFast = s.durRatio < 1 / kTempoTolerance, tooSlow = s.durRatio > kTempoTolerance;
  final paceOk = !tooFast && !tooSlow && s.rhythm >= 30;
  out.add(StageCheck('pace', kCheckLabels['pace']!, paceOk,
      paceOk
          ? 'Your pace matches the teacher.'
          : tooFast
              ? 'Slow down a little and give each part its time.'
              : tooSlow
                  ? 'Say it a little quicker, in one flow.'
                  : 'Match the teacher’s timing in the ${wt == null ? 'middle' : _part((wt.start + wt.end) / 2, s)}.',
      start: paceOk ? null : wt?.start,
      end: paceOk ? null : wt?.end));

  // Long sounds (held vowels)
  final vc = [...s.vowelCompares]..sort((a, b) => math.log(b.ratio).abs().compareTo(math.log(a.ratio).abs()));
  final longOk = s.vowel >= 50 || vc.isEmpty;
  final v = vc.isEmpty ? null : vc.first;
  out.add(StageCheck('long', kCheckLabels['long']!, longOk,
      longOk
          ? 'You held the long sounds like the teacher.'
          : 'Hold the long sound in the ${_part((v!.start + v.end) / 2, s)} a little ${v.ratio < 1 ? 'longer' : 'shorter'}.',
      start: longOk ? null : v?.start,
      end: longOk ? null : v?.end));

  // Rise and fall
  final wp = _worst(s, (e) => e.kind == 'pitch');
  final pitchOk = s.pitch >= 45;
  out.add(StageCheck('pitch', kCheckLabels['pitch']!, pitchOk,
      pitchOk
          ? 'Your voice rises and falls like the teacher’s.'
          : 'Follow the teacher’s rise and fall in the ${wp == null ? 'word' : '${_part((wp.start + wp.end) / 2, s)} of the word'}.',
      start: pitchOk ? null : wp?.start,
      end: pitchOk ? null : wp?.end));

  // Whole word
  final wm = _worst(s, (e) => e.kind == 'missing');
  final wholeOk = s.completeness >= kPracticeConfig.minCompleteness && s.rhythm >= kMinAlignedRhythm && wholeWordSaid(s);
  out.add(StageCheck('whole', kCheckLabels['whole']!, wholeOk,
      wholeOk
          ? 'You said every part of the word.'
          : wm == null
              ? 'Say the whole word, right to the end.'
              : 'Say every sound in the ${_part((wm.start + wm.end) / 2, s)} of the word.',
      start: wholeOk ? null : (wm?.start ?? s.refStart + (s.refEnd - s.refStart) * .7),
      end: wholeOk ? null : (wm?.end ?? s.refEnd)));
  // Every crossed row points somewhere on the waveform: its own spot, else
  // the worst spot of the take, else the whole word.
  final any = _worst(s, (_) => true);
  return [
    for (final c in out)
      c.ok || c.start != null
          ? c
          : StageCheck(c.id, c.label, c.ok, c.line, start: any?.start ?? s.refStart, end: any?.end ?? s.refEnd)
  ];
}

/// Opens the checklist as its own page over the practice pop-up. The
/// system back gesture (or the back arrow) returns to the score.
Future<void> openStageChecklist(BuildContext context, StageTake take, {required String title}) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    settings: const RouteSettings(name: 'stage-checklist'),
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => StageChecklistPage(take: take, title: title),
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(c), child: child));
    },
  ));
}

class StageChecklistPage extends StatelessWidget {
  const StageChecklistPage({super.key, required this.take, required this.title});
  final StageTake take;
  final String title;

  @override
  Widget build(BuildContext context) {
    final checks = take.checks.isNotEmpty ? take.checks : buildChecklist(take.result);
    final s = take.result.score;
    final allOk = checks.every((c) => c.ok);
    return Scaffold(
      key: const ValueKey('stage-checklist'),
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
            child: Row(children: [
              IconButton(
                key: const ValueKey('checklist-back'),
                tooltip: 'Back to your score',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
            child: Text(allOk ? 'Nothing to fix, well done.' : 'What to improve',
                key: const ValueKey('checklist-headline'),
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final c in checks) _CheckRow(check: c, take: take, score: s),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check, required this.take, required this.score});
  final StageCheck check;
  final StageTake take;
  final ShabdaScore? score;

  @override
  Widget build(BuildContext context) {
    final c = check;
    final s = score;
    return Container(
      key: ValueKey('check-row-${c.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.ok ? const Color(0x1FFFFFFF) : const Color(0x40FFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            key: ValueKey(c.ok ? 'check-ok-${c.id}' : 'check-fix-${c.id}'),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.ok ? Colors.white : Colors.transparent,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(c.ok ? Icons.check_rounded : Icons.close_rounded,
                size: 17, color: c.ok ? const Color(0xFF000000) : Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(c.line,
                  key: ValueKey('check-line-${c.id}'),
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.35)),
            ]),
          ),
        ]),
        if (!c.ok && s != null && c.start != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            key: ValueKey('check-wave-${c.id}'),
            height: 40,
            child: CustomPaint(painter: _MarkerWave(take.refTimes, take.refEnergyDb, s.refStart, s.refEnd, c.start!, c.end!)),
          ),
        ],
      ]),
    );
  }
}

/// The teacher's word as bars, with a white marker over the part to fix.
class _MarkerWave extends CustomPainter {
  _MarkerWave(this.times, this.db, this.a, this.b, this.s0, this.s1);
  final List<double> times, db;
  final double a, b, s0, s1;

  @override
  void paint(Canvas canvas, Size size) {
    final span = math.max(1e-3, b - a);
    final h = size.height - 8;
    double x(double t) => ((t - a) / span).clamp(0.0, 1.0) * size.width;
    final m0 = x(s0), m1 = math.max(x(s1), x(s0) + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(m0 - 2, 0, m1 + 2, h), const Radius.circular(5)),
        Paint()..color = const Color(0x26FFFFFF));
    const bars = 48;
    final bw = size.width / bars;
    for (var k = 0; k < bars; k++) {
      final t0 = a + span * k / bars, t1 = a + span * (k + 1) / bars;
      var v = -80.0;
      for (var j = 0; j < times.length && j < db.length; j++) {
        if (times[j] >= t0 && times[j] < t1) v = math.max(v, db[j]);
      }
      final lvl = ((v + 60) / 60).clamp(0.05, 1.0);
      final bh = h * lvl;
      final cx = k * bw + bw / 2;
      final inside = cx >= m0 - 1 && cx <= m1 + 1;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(k * bw + bw * .22, (h - bh) / 2, bw * .56, bh), const Radius.circular(2)),
          Paint()..color = inside ? Colors.white : const Color(0x66FFFFFF));
    }
    final cx = (m0 + m1) / 2;
    canvas.drawPath(
        Path()
          ..moveTo(cx, h + 1)
          ..lineTo(cx - 6, size.height)
          ..lineTo(cx + 6, size.height)
          ..close(),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MarkerWave o) => o.s0 != s0 || o.s1 != s1 || o.db != db;
}
