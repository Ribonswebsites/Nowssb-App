// Pronunciation v1: audio-to-audio scoring against the client's reference.
// Fixtures are synthetic voices (ffmpeg flite) used only to exercise the
// maths — four different voices so "same word, different speaker" is tested.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pronunciation/scorer.dart';
import 'package:nowssb/pronunciation/wav.dart';

Uint8List fx(String name) => File('test/fixtures/pron/$name').readAsBytesSync();

int score(String ref, String take, [List<String> syl = const []]) => scoreTake(
      references: [fx(ref)],
      take: fx(take),
      syllables: syl,
    ).score;

void main() {
  const words = ['aarogya', 'shakti', 'chandra', 'prana'];
  const voices = ['kal', 'slt', 'awb', 'rms'];

  test('WAV reader: 44.1 kHz stereo becomes 16 kHz mono of the same length', () {
    final a = decodeWav(fx('chandra_kal.wav'));
    final b = decodeWav(fx('chandra_kal_44k_stereo.wav'));
    expect((a.length - b.length).abs() < 400, isTrue);
  });

  test('identical take scores ~100', () {
    expect(score('shakti_slt.wav', 'shakti_slt.wav'), greaterThanOrEqualTo(95));
  });

  test('same voice, slower and noisy, still scores high', () {
    expect(score('aarogya_slt.wav', 'aarogya_slt_slow_noisy.wav'), greaterThanOrEqualTo(75));
  });

  test('a different word scores lower than the right word', () {
    final right = score('aarogya_slt.wav', 'aarogya_slt_slow_noisy.wav');
    for (final w in ['shakti', 'chandra', 'prana']) {
      expect(score('${w}_slt.wav', 'aarogya_slt_slow_noisy.wav'), lessThan(right - 20), reason: w);
    }
  });

  test('across different voices the right word usually ranks first', () {
    var good = 0, total = 0;
    var sameSum = 0.0, diffSum = 0.0, sameN = 0, diffN = 0;
    for (final w in words) {
      for (final v in voices) {
        final take = fx('${w}_$v.wav');
        final best = <String, int>{};
        for (final rw in words) {
          for (final rv in voices) {
            if (rv == v) continue;
            final s = scoreTake(references: [fx('${rw}_$rv.wav')], take: take, syllables: const []).score;
            best[rw] = (best[rw] ?? -1) < s ? s : best[rw]!;
            if (rw == w) {
              sameSum += s;
              sameN++;
            } else {
              diffSum += s;
              diffN++;
            }
          }
        }
        total++;
        final top = best.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        if (top == w) good++;
      }
    }
    expect(good, greaterThanOrEqualTo(12), reason: '$good/$total');
    expect(sameSum / sameN, greaterThan(diffSum / diffN + 10));
  });

  test('multiple reference takes: the best-matching take is used', () {
    final r = scoreTake(
      references: [fx('prana_kal.wav'), fx('aarogya_slt.wav'), fx('shakti_awb.wav')],
      take: fx('aarogya_slt_slow_noisy.wav'),
      syllables: const ['aa', 'ro', 'gya'],
    );
    expect(r.outcome, PronunciationOutcome.scored);
    expect(r.bestTake, 1);
    expect(r.syllables.map((s) => s.text), ['aa', 'ro', 'gya']);
    for (final s in r.syllables) {
      expect(s.score, inInclusiveRange(0, 100));
    }
  });

  test('no reference / non-WAV reference / silence are honest states', () {
    expect(scoreTake(references: const [], take: fx('prana_slt.wav'), syllables: const []).outcome,
        PronunciationOutcome.noReference);
    expect(scoreTake(references: [fx('prana_slt.m4a')], take: fx('prana_slt.wav'), syllables: const []).outcome,
        PronunciationOutcome.unsupportedReference);
    final silent = scoreSamples(refs: [decodeWav(fx('prana_slt.wav'))], take: Float32List(16000), syllables: const []);
    expect(silent.outcome, PronunciationOutcome.tooQuiet);
    expect(const PronunciationResult(outcome: PronunciationOutcome.noReference).verdict,
        contains('not added yet'));
  });
}
