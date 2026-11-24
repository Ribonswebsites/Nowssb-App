// Parity: the Dart Shabda scorer must reproduce the Python prototype
// (shabda-score) on the client's three America recordings and on synthetic
// wrong attempts made from them. Golden numbers: test/fixtures/shabda/
// python_golden.json (written by the prototype, see AUDIT.md).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pronunciation/shabda/audio_io.dart';
import 'package:nowssb/pronunciation/shabda/shabda_features.dart';
import 'package:nowssb/pronunciation/shabda/shabda_practice.dart' show kPracticeConfig;
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

  void expectClose(ShabdaScore s, Map<String, dynamic> g, String label) {
    final got = {'overall': s.overall, ...s.subs};
    final msg = '$label dart=$got python=$g';
    expect((s.overall - (g['overall'] as num)).abs(), lessThanOrEqualTo(0.5), reason: msg);
    for (final k in s.subs.keys) {
      expect((got[k]! - (g[k] as num)).abs(), lessThanOrEqualTo(1.0), reason: '$k: $msg');
    }
  }

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

  group('score parity (raw recordings)', () {
    for (var r = 1; r <= 3; r++) {
      for (var u = 1; u <= 3; u++) {
        test('stage $r reference vs stage $u take', () {
          final s = scorePair(raw[r]!, raw[u]!);
          expectClose(s, golden['raw']['$r-$u'] as Map<String, dynamic>, 'raw $r-$u');
          if (r == u) {
            expect(s.overall, greaterThanOrEqualTo(99));
          } else {
            expect(s.overall, inInclusiveRange(20, 46));
          }
        });
      }
    }
  });

  group('score parity (scoring references shipped in the app)', () {
    for (var r = 1; r <= 3; r++) {
      for (var u = 1; u <= 3; u++) {
        test('ref $r vs $u', () {
          final s = scorePair(clean[r]!, clean[u]!);
          expectClose(s, golden['ref']['$r-$u'] as Map<String, dynamic>, 'ref $r-$u');
          if (r == u) {
            expect(s.overall, greaterThanOrEqualTo(99));
          } else {
            expect(s.overall, inInclusiveRange(20, 46));
          }
        });
      }
    }
  });

  group('score parity (synthetic wrong attempts)', () {
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
          expectClose(s, golden['degraded']['$n-$v'] as Map<String, dynamic>, 'degraded $n-$v');
          const c = kPracticeConfig;
          final passes = s.overall >= c.passMark &&
              s.completeness >= c.minCompleteness &&
              s.rhythm >= c.minRhythm &&
              s.pitch >= c.minPitch;
          expect(passes, isFalse, reason: 'a wrong attempt must not pass: overall ${s.overall} ${s.subs}');
          expect(s.overall, lessThan(72));
        });
      }
    }
  });
}
