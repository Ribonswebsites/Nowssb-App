// The Dart Shabda scorer started as a port of the Python prototype
// (shabda-score; golden numbers in test/fixtures/shabda/python_golden.json).
// Feature extraction still matches it exactly. Scoring deliberately departs
// from it since Nov 24 (Ribon: the teacher scored 33 on her own word): the
// take is normalised per utterance, pitch is compared by shape only, and
// pace may differ by about 30 %. So these tests now pin behaviour, not the
// prototype's numbers: same recording 99+, another stage of the word never
// passes, a slower/faster or higher/lower take of the same word passes, and
// a take with a missing middle or end never passes.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pronunciation/shabda/audio_io.dart';
import 'package:nowssb/pronunciation/shabda/shabda_features.dart';
import 'package:nowssb/pronunciation/shabda/shabda_practice.dart' show kPracticeConfig, calibratedScore, kMinAlignedRhythm;
import 'package:nowssb/pronunciation/shabda/shabda_scorer.dart';

const _fx = 'test/fixtures/shabda';

Float64List _load(String path) => wavTo16k(File(path).readAsBytesSync());

/// Python writes the edited take back through int16 before extracting.
Float64List _q16(Float64List x) =>
    Float64List.fromList([for (final v in x) (v.clamp(-1.0, 1.0) * 32767).truncate() / 32768.0]);

Float64List _midcut(Float64List x) {
  final y = Float64List.fromList(x);
  final n = y.length;
  for (var i = (0.45 * n).toInt(); i < (0.70 * n).toInt(); i++) {
    y[i] = 0;
  }
  return y;
}

Float64List _trunc(Float64List x) {
  final y = Float64List.fromList(x);
  for (var i = (0.60 * y.length).toInt(); i < y.length; i++) {
    y[i] = 0;
  }
  return y;
}

void main() {
  final golden = jsonDecode(File('$_fx/python_golden.json').readAsStringSync()) as Map<String, dynamic>;
  final raw = {for (var n = 1; n <= 3; n++) n: extractFeatures(_load('$_fx/raw_stage$n.wav'))};
  final clean = {for (var n = 1; n <= 3; n++) n: extractFeatures(_load('$_fx/clean_stage$n.wav'))};

  const c = kPracticeConfig;
  bool passes(ShabdaScore s) =>
      calibratedScore(s.overall) >= c.passMark && s.completeness >= c.minCompleteness && s.rhythm >= kMinAlignedRhythm;

  group('feature parity', () {
    test('frames, speech span and pitch median match the prototype', () {
      for (var n = 1; n <= 3; n++) {
        final g = golden['features']['$n'] as Map<String, dynamic>;
        final f = raw[n]!;
        expect(f.frames, g['frames']);
        final iv = (g['intervals'] as List).cast<List>();
        expect(f.vad.intervals.length, iv.length);
        expect((f.vad.intervals.first[0] - (iv.first[0] as num)).abs(), lessThan(0.021));
        expect((f.vad.intervals.last[1] - (iv.last[1] as num)).abs(), lessThan(0.021));
        expect((f.f0Median - (g['f0_median'] as num)).abs(), lessThan(3.0));
      }
    });
  });

  group('scores (raw recordings)', () {
    for (var r = 1; r <= 3; r++) {
      for (var u = 1; u <= 3; u++) {
        test('stage $r reference vs stage $u take', () {
          final s = scorePair(raw[r]!, raw[u]!);
          if (r == u) {
            expect(s.overall, greaterThanOrEqualTo(99));
          } else {
            expect(passes(s), isFalse, reason: '${s.overall} ${s.subs}');
          }
        });
      }
    }
  });

  group('scores (clean references)', () {
    for (var r = 1; r <= 3; r++) {
      for (var u = 1; u <= 3; u++) {
        test('ref $r vs $u', () {
          final s = scorePair(clean[r]!, clean[u]!);
          if (r == u) {
            expect(s.overall, greaterThanOrEqualTo(99));
          } else {
            expect(passes(s), isFalse, reason: '${s.overall} ${s.subs}');
          }
        });
      }
    }
  });

  group('scores (same word re-said, or cut off)', () {
    for (var n = 1; n <= 3; n++) {
      for (final v in ['tempo0.8', 'tempo1.25', 'pitchn3', 'pitchp3', 'midcut', 'trunc']) {
        test('stage $n $v', () {
          final Float64List take;
          if (v == 'midcut') {
            take = _q16(_midcut(_load('$_fx/clean_stage$n.wav')));
          } else if (v == 'trunc') {
            take = _q16(_trunc(_load('$_fx/clean_stage$n.wav')));
          } else {
            take = _load('$_fx/stage${n}_$v.wav');
          }
          final s = scorePair(clean[n]!, extractFeatures(take));
          if (v == 'midcut' || v == 'trunc') {
            expect(passes(s), isFalse, reason: 'a cut-off attempt must not pass: ${s.overall} ${s.subs}');
          } else if (v.startsWith('pitch')) {
            // Three semitones moves the voice's formants too (another
            // speaker, in effect): clearly above a different word, but not
            // a guaranteed pass. Two semitones passes (scorer_robustness).
            expect(calibratedScore(s.overall), greaterThan(55), reason: '${s.overall} ${s.subs}');
          } else {
            expect(passes(s), isTrue, reason: 'same word, other pace or pitch: ${s.overall} ${s.subs}');
          }
        });
      }
    }
  });
}
