// The practice pipeline as a user meets it: a microphone take is checked,
// cleaned and scored against one stage's client recording, and the feedback
// must say what was wrong and where. Synthetic attempts are built from the
// client's own cleaned recordings (no generated voices).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pronunciation/shabda/audio_io.dart';
import 'package:nowssb/pronunciation/shabda/shabda_features.dart';
import 'package:nowssb/pronunciation/shabda/shabda_practice.dart';

const _fx = 'test/fixtures/shabda';
const _assets = 'assets/words/america';

Float64List _load(String p) => wavTo16k(File(p).readAsBytesSync());

/// Surrounds a take with the room tone of the same recording (its first
/// 0.25 s, before the word), so the floor stays constant like a real mic.
Float64List _pad(Float64List x, {double before = 0.6, double after = 0.8, double noiseDb = -60, int seed = 1}) {
  final tone = x.sublist(0, (0.25 * kSr).round());
  final r = math.Random(seed);
  final amp = math.pow(10, noiseDb / 20).toDouble();
  final b = (before * kSr).round(), a = (after * kSr).round();
  double t(int i) =>
      tone[i % tone.length] * (i ~/ tone.length).isEven.toInt() +
      tone[tone.length - 1 - i % tone.length] * (i ~/ tone.length).isOdd.toInt();
  return Float64List.fromList([
    for (var i = 0; i < b; i++) t(i) + amp * (r.nextDouble() * 2 - 1),
    for (final v in x) v + amp * (r.nextDouble() * 2 - 1),
    for (var i = 0; i < a; i++) t(i + 7) + amp * (r.nextDouble() * 2 - 1),
  ]);
}

extension on bool {
  int toInt() => this ? 1 : 0;
}

Float64List _addNoise(Float64List x, double snrDb, {int seed = 7}) {
  final r = math.Random(seed);
  var p = 0.0;
  var n = 0;
  for (final v in x) {
    if (v.abs() > 0.02) {
      p += v * v;
      n++;
    }
  }
  final sigRms = math.sqrt(p / math.max(n, 1));
  final noiseRms = sigRms / math.pow(10, snrDb / 20);
  // uniform noise with the wanted RMS (uniform[-a,a] has rms a/sqrt3)
  final a = noiseRms * math.sqrt(3);
  return Float64List.fromList([for (final v in x) v + a * (r.nextDouble() * 2 - 1)]);
}

Uint8List _wav(Float64List x, int rate, {int channels = 1}) {
  final n = x.length;
  final data = ByteData(44 + n * 2 * channels);
  void str(int o, String s) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2 * channels, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2 * channels, Endian.little);
  data.setUint16(32, 2 * channels, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2 * channels, Endian.little);
  for (var i = 0; i < n; i++) {
    for (var c = 0; c < channels; c++) {
      data.setInt16(44 + (i * channels + c) * 2, (x[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
  }
  return data.buffer.asUint8List();
}

void main() {
  final refAudio = {for (var n = 1; n <= 3; n++) n: _load('$_assets/america_stage${n}_ref.wav')};
  final ref = {
    for (var n = 1; n <= 3; n++) n: referenceFeatures(File('$_assets/america_stage${n}_ref.wav').readAsBytesSync())
  };

  String all(AttemptResult r) => r.fixes.join(' ').toLowerCase();

  for (var n = 1; n <= 3; n++) {
    group('stage $n', () {
      test('the client recording itself (with mic hiss) passes', () {
        final r = assessTake(ref[n]!, _pad(refAudio[n]!), stage: n);
        expect(r.status, AttemptStatus.scored, reason: r.message);
        expect(r.passed, isTrue, reason: '${r.overall} ${r.subs.map((s) => '${s.label}=${s.value}')}');
        expect(r.overall, greaterThanOrEqualTo(85));
        expect(r.good, isNotEmpty);
      });

      test('a clean take in a slightly noisy room (25 dB SNR) still passes', () {
        final r = assessTake(ref[n]!, _addNoise(_pad(refAudio[n]!), 25), stage: n);
        expect(r.status, AttemptStatus.scored);
        expect(r.passed, isTrue, reason: '${r.overall} ${r.subs.map((s) => '${s.label}=${s.value}')} ${r.fixes}');
      });

      test('a 48 kHz stereo phone WAV is resampled and scores like 16 kHz', () {
        final x = _pad(refAudio[n]!);
        final up = resampleTo(x, kSr, to: 48000);
        final r48 = assessTakeBytes(ref[n]!, _wav(up, 48000, channels: 2), stage: n);
        final r16 = assessTake(ref[n]!, x, stage: n);
        expect(r48.status, AttemptStatus.scored);
        expect((r48.overall - r16.overall).abs(), lessThanOrEqualTo(4));
        expect(r48.passed, isTrue);
      });

      test('20% slower: fails, says slower', () {
        final r = assessTake(ref[n]!, _pad(_load('$_fx/stage${n}_tempo0.8.wav')), stage: n);
        expect(r.passed, isFalse, reason: '${r.overall}');
        expect(all(r), anyOf(contains('slower'), contains('drawn out'), contains('too long')), reason: '${r.fixes}');
      });

      test('25% faster: fails, says faster / rushed', () {
        final r = assessTake(ref[n]!, _pad(_load('$_fx/stage${n}_tempo1.25.wav')), stage: n);
        expect(r.passed, isFalse, reason: '${r.overall}');
        expect(all(r), anyOf(contains('faster'), contains('rushed'), contains('too short')), reason: '${r.fixes}');
      });

      for (final p in ['pitchn3', 'pitchp3']) {
        test('3 semitones ${p == 'pitchp3' ? 'up' : 'down'}: fails, names pitch', () {
          final r = assessTake(ref[n]!, _pad(_load('$_fx/stage${n}_$p.wav')), stage: n);
          expect(r.passed, isFalse, reason: '${r.overall}');
          expect(r.subs.firstWhere((s) => s.key == 'pitch').value, lessThan(50));
          expect(all(r), anyOf(contains('pitch'), contains('semitone'), contains('melody'), contains('sounds')),
              reason: '${r.fixes}');
        });
      }

      test('middle of the word silenced: fails, says which part is missing', () {
        final x = Float64List.fromList(refAudio[n]!);
        final s = (0.45 * x.length).toInt(), e = (0.70 * x.length).toInt();
        // replaced by the room tone, as when someone simply skips a part
        final tone = x.sublist(0, 4000);
        for (var i = s; i < e; i++) {
          x[i] = tone[i % tone.length];
        }
        final r = assessTake(ref[n]!, _pad(x), stage: n);
        expect(r.status, AttemptStatus.scored);
        expect(r.passed, isFalse, reason: '${r.overall} ${r.subs.map((s) => '${s.label}=${s.value}')}');
        expect(all(r), anyOf(contains('missing'), contains('lost'), contains('skipped')), reason: '${r.fixes}');
        expect(r.fixes.first.toLowerCase(), anyOf(contains('middle'), contains('ending')), reason: '${r.fixes}');
      });

      test('ending cut off: fails, says the ending', () {
        final x = Float64List.fromList(refAudio[n]!);
        final tone = x.sublist(0, 4000);
        for (var i = (0.60 * x.length).toInt(); i < x.length; i++) {
          x[i] = tone[i % tone.length];
        }
        final r = assessTake(ref[n]!, _pad(x), stage: n);
        expect(r.passed, isFalse, reason: '${r.overall}');
        expect(all(r), contains('ending'), reason: '${r.fixes}');
      });

      test('another stage\'s recording: low score, sounds called out', () {
        final other = n == 1 ? 2 : 1;
        final r = assessTake(ref[n]!, _pad(refAudio[other]!), stage: n);
        expect(r.status, AttemptStatus.scored);
        expect(r.passed, isFalse);
        expect(r.overall, lessThan(50));
        expect(r.fixes, isNotEmpty);
      });
    });
  }

  group('takes that cannot be judged get a message, not a score', () {
    test('silence', () {
      final r = assessTake(ref[1]!, Float64List(3 * kSr));
      expect(r.status, AttemptStatus.silent);
      expect(r.scored, isFalse);
      expect(r.overall, 0);
      expect(r.message, isNotEmpty);
    });

    test('very faint', () {
      final faint = Float64List.fromList([for (final v in _pad(refAudio[1]!, noiseDb: -90)) v * 0.006]);
      final r = assessTake(ref[1]!, faint);
      expect(r.status, AttemptStatus.tooQuiet);
    });

    test('only noise', () {
      final r = math.Random(3);
      final noise = Float64List.fromList([for (var i = 0; i < 3 * kSr; i++) 0.2 * (r.nextDouble() * 2 - 1)]);
      expect(assessTake(ref[1]!, noise).status, AttemptStatus.tooNoisy);
    });

    test('voice buried in noise (3 dB SNR)', () {
      final r = assessTake(ref[1]!, _addNoise(_pad(refAudio[1]!), 3));
      expect(r.status, AttemptStatus.tooNoisy);
    });

    test('a short tap', () {
      final x = Float64List(3 * kSr);
      for (var i = 0; i < (0.12 * kSr).round(); i++) {
        x[kSr + i] = 0.5 * math.sin(2 * math.pi * 220 * i / kSr);
      }
      expect(assessTake(ref[1]!, x).status, AttemptStatus.tooShort);
    });

    test('the word said four times in a row', () {
      final w = refAudio[1]!;
      final x = Float64List.fromList([...w, ...w, ...w, ...w]);
      expect(assessTake(ref[1]!, _pad(x)).status, AttemptStatus.tooLong);
    });
  });

  test('heavy background noise (10 dB SNR) asks for a quieter place', () {
    for (var n = 1; n <= 3; n++) {
      final r = assessTake(ref[n]!, _addNoise(_pad(refAudio[n]!), 10), stage: n);
      expect(r.status, AttemptStatus.tooNoisy);
      expect(r.message, contains('quieter'));
      expect(r.scored, isFalse);
    }
  });

  test('a noisier room (18 dB SNR) is still scored, and the right stage wins clearly', () {
    final r = assessTake(ref[2]!, _addNoise(_pad(refAudio[2]!), 18), stage: 2);
    expect(r.status, AttemptStatus.scored, reason: r.message);
    expect(r.passed, isTrue, reason: '${r.overall}');
    final other = assessTake(ref[2]!, _addNoise(_pad(refAudio[3]!), 18), stage: 2);
    expect(other.passed, isFalse);
    expect(r.overall, greaterThan(other.overall + 25));
  });

  test('scoring time', () {
    final take = _pad(refAudio[3]!);
    assessTake(ref[3]!, take); // warm-up
    final sw = Stopwatch()..start();
    const runs = 5;
    for (var i = 0; i < runs; i++) {
      assessTake(ref[3]!, take);
    }
    final ms = sw.elapsedMilliseconds / runs;
    // ignore: avoid_print
    print('Shabda scoring: ${ms.toStringAsFixed(0)} ms per attempt (JIT, test VM)');
    expect(ms, lessThan(1500));
  });
}
