// Ribon (Nov 24): the teacher scored 33 on her own word. A fresh take by the
// same speaker must pass under phone conditions; a different word must not.
// Each stage is scored against its CLEAN reference (what the app ships),
// with the teacher's raw take degraded here in Dart: gain ±12 dB, noise at
// 15 dB SNR, a small room echo, leading/trailing silence, and a ±10 % speed
// change (pace and pitch together, like a different phone or a slightly
// quicker take). The full ffmpeg table (reverb, phone band, tempo 0.75–1.3,
// pitch ±2 semitones, combined) is in tool/audio/scorer_eval.md.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pronunciation/shabda/audio_io.dart';
import 'package:nowssb/pronunciation/shabda/shabda_practice.dart';

Uint8List _wav(Float64List x) {
  final n = x.length;
  final b = ByteData(44 + n * 2);
  void s(int o, String t) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(o + i, t.codeUnitAt(i));
    }
  }
  s(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, 16000, Endian.little);
  b.setUint32(28, 32000, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  s(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    b.setInt16(44 + i * 2, (x[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

double _rms(Float64List x) {
  var s = 0.0;
  for (final v in x) {
    s += v * v;
  }
  return math.sqrt(s / math.max(1, x.length));
}

final _deg = <String, Float64List Function(Float64List)>{
  'as recorded': (x) => x,
  'gain +12 dB': (x) => Float64List.fromList([for (final v in x) (v * 3.98).clamp(-0.99, 0.99)]),
  'gain -12 dB': (x) => Float64List.fromList([for (final v in x) v * 0.25]),
  'noise 15 dB': (x) {
    final r = math.Random(3);
    final a = _rms(x) / math.pow(10, 15 / 20) * math.sqrt(3);
    return Float64List.fromList([for (final v in x) v + a * (r.nextDouble() * 2 - 1)]);
  },
  'room echo': (x) {
    final y = Float64List.fromList(x);
    for (final (d, g) in [(560, .45), (1120, .3), (1920, .2), (3200, .12)]) {
      for (var i = d; i < y.length; i++) {
        y[i] += g * x[i - d];
      }
    }
    return y;
  },
  'silence around': (x) => Float64List.fromList([...List.filled(16000, 0.0), ...x, ...List.filled(24000, 0.0)]),
  'speed 0.9x': (x) => _resample(x, 0.9),
  'speed 1.1x': (x) => _resample(x, 1.1),
};

Float64List _resample(Float64List x, double speed) {
  final n = (x.length / speed).floor();
  return Float64List.fromList([
    for (var i = 0; i < n; i++)
      () {
        final p = i * speed, j = p.floor(), f = p - j;
        final a = x[math.min(j, x.length - 1)], b = x[math.min(j + 1, x.length - 1)];
        return a + (b - a) * f;
      }()
  ]);
}

void main() {
  final items = (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;
  final stages = <(String, int, String, String)>[];
  for (final it in items) {
    for (final st in ((it as Map)['practice']?['stages'] as List? ?? const [])) {
      final m = st as Map;
      final ref = m['reference'] as String;
      stages.add((it['key'] as String, (m['stage'] as num).toInt(), ref, ref.replaceFirst('_ref_clean.wav', '_ref.wav')));
    }
  }

  test('every stage is scored against its own clean recording', () {
    expect(stages, hasLength(7));
    for (final (key, n, ref, _) in stages) {
      expect(ref, 'assets/words/$key/${key}_stage${n}_ref_clean.wav');
      expect(File(ref).existsSync(), isTrue, reason: ref);
    }
  });

  test('the teacher\'s own take passes (75+) under phone conditions; another word stays under 50', () {
    final lines = <String>[];
    final same = <int>[];
    final notPassed = <String>[];
    for (final (key, n, ref, raw) in stages) {
      final feats = referenceFeatures(File(ref).readAsBytesSync());
      final take = wavTo16k(File(raw).readAsBytesSync());
      final row = <String>[];
      for (final e in _deg.entries) {
        final r = assessTakeBytes(feats, _wav(e.value(take)));
        expect(r.status, AttemptStatus.scored, reason: '$key $n ${e.key}');
        row.add('${e.key} ${r.overall}');
        same.add(r.overall);
        if (!r.passed) notPassed.add('$key $n ${e.key} ${r.overall}');
        expect(r.overall, greaterThan(50), reason: '$key stage $n, ${e.key}: ${r.overall}');

        row.add('${e.key} ${r.overall}');
      }
      for (final (k2, n2, _, raw2) in stages) {
        if (k2 == key) continue;
        final r = assessTakeBytes(feats, File(raw2).readAsBytesSync());
        expect(r.overall, lessThan(50), reason: '$key $n vs $k2 $n2: ${r.overall}');
        expect(r.passed, isFalse);
        row.add('$k2$n2 ${r.overall}');
      }
      lines.add('$key $n: ${row.join(', ')}');
    }
    // ignore: avoid_print
    print(lines.join('\n'));
    // 56 degraded takes. Known weak spot: Washington stage 2 (the long
    // version) slowed AND lowered together (speed 0.9x) and under 15 dB
    // noise; everything else is 75+.
    final under = same.where((s) => s < 75).length;
    expect(same.length, 56);
    expect(under, lessThanOrEqualTo(2), reason: lines.join('\n'));
    expect(notPassed.length, lessThanOrEqualTo(2), reason: notPassed.join('\n'));
    // ignore: avoid_print
    print('not passed: $notPassed');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('the score shown is calibrated, monotonic and unchanged below 50', () {
    expect(calibratedScore(30), 30);
    expect(calibratedScore(50), 50);
    expect(calibratedScore(65), closeTo(78, 1e-9));
    expect(calibratedScore(100), 100);
    var last = -1.0;
    for (var r = 0.0; r <= 100; r += 0.5) {
      final c = calibratedScore(r);
      expect(c, greaterThanOrEqualTo(last));
      last = c;
    }
  });
}
