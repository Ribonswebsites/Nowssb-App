/// Audio-to-audio pronunciation score: the user's take against the client's
/// own reference recording(s). No speech-to-text and no spelling: the words
/// are invented and spelled differently from how they sound, so only the
/// recorded sound counts.
///
/// Pipeline: WAV → 16 kHz mono → silence trim → MFCC+Δ (normalised) → DTW
/// against every reference take → best take wins → 0–100 score, and the
/// DTW path split over the word's syllables for per-syllable feedback.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'dtw.dart';
import 'features.dart';
import 'wav.dart';

/// The raw DTW distance depends a lot on voice and microphone, so it is
/// normalised by the distance to the same reference played backwards (same
/// voice, same spectrum, wrong order of sounds). A ratio at or below
/// [goodCost] scores 100, at or above [badCost] scores 0. Calibrated on
/// cross-voice same-word vs different-word pairs (test/pronunciation_test.dart).
const double goodCost = 0.45;
const double badCost = 1.0;

int costToScore(double cost) {
  if (!cost.isFinite) return 0;
  final s = 100 * (badCost - cost) / (badCost - goodCost);
  return s.clamp(0, 100).round();
}

enum PronunciationOutcome { scored, noReference, unsupportedReference, tooQuiet, tooShort }

class SyllableScore {
  const SyllableScore(this.text, this.score);
  final String text;
  final int score;
}

class PronunciationResult {
  const PronunciationResult({
    required this.outcome,
    this.score = 0,
    this.syllables = const [],
    this.bestTake = -1,
  });

  final PronunciationOutcome outcome;
  final int score;
  final List<SyllableScore> syllables;
  final int bestTake;

  String get verdict {
    switch (outcome) {
      case PronunciationOutcome.noReference:
        return 'Reference recording not added yet';
      case PronunciationOutcome.unsupportedReference:
        return 'This reference can\'t be compared yet';
      case PronunciationOutcome.tooQuiet:
        return 'We could not hear you — try closer to the mic';
      case PronunciationOutcome.tooShort:
        return 'That was too short — say the whole word';
      case PronunciationOutcome.scored:
        if (score >= 75) return 'Excellent — that matches the recording';
        if (score >= 50) return 'Close — nearly there';
        if (score >= 30) return 'Getting there — listen again and repeat';
        return 'Not yet — replay the recording and copy its sound';
    }
  }

  /// The weakest syllable worth a tip, if any is clearly behind the rest.
  SyllableScore? get weakest {
    if (syllables.length < 2) return null;
    final w = syllables.reduce((a, b) => a.score <= b.score ? a : b);
    return w.score < 50 && w.score < syllables.map((s) => s.score).reduce(math.max) - 10 ? w : null;
  }
}

/// Relative weight of a syllable when the reference can't be segmented by
/// energy: its vowel count (at least 1).
double _weight(String s) {
  final v = RegExp(r'[aeiouyāīūēōAEIOUY]').allMatches(s).length;
  return math.max(1, v).toDouble();
}

/// Splits [f] into [count] contiguous segments: boundary guesses at
/// vowel-weighted positions, each nudged to the lowest-energy frame nearby
/// (syllable edges are usually energy dips).
List<int> syllableBoundaries(Features f, List<String> syllables) {
  final n = f.length;
  final count = syllables.length;
  if (count <= 1 || n < count * 4) {
    return [0, n];
  }
  final weights = syllables.map(_weight).toList();
  final total = weights.fold<double>(0, (a, b) => a + b);
  final cuts = <int>[0];
  var run = 0.0;
  final slack = math.max(2, (n / count / 3).round());
  for (var i = 0; i < count - 1; i++) {
    run += weights[i];
    final guess = (n * run / total).round();
    var best = guess;
    var bestE = double.infinity;
    for (var j = math.max(cuts.last + 2, guess - slack); j <= math.min(n - 2, guess + slack); j++) {
      if (f.energy[j] < bestE) {
        bestE = f.energy[j];
        best = j;
      }
    }
    cuts.add(best.clamp(cuts.last + 1, n - 1));
  }
  cuts.add(n);
  return cuts;
}

/// Scores [take] (WAV bytes) against [references] (WAV bytes, one per take
/// the client recorded). [syllables] are the word's syllable boxes.
PronunciationResult scoreTake({
  required List<Uint8List> references,
  required Uint8List take,
  required List<String> syllables,
}) {
  if (references.isEmpty) {
    return const PronunciationResult(outcome: PronunciationOutcome.noReference);
  }
  final refs = <Float32List>[];
  for (final r in references) {
    try {
      refs.add(trimSilence(decodeWav(r)));
    } on UnsupportedAudio {
      // skip; reported below if none decode
    }
  }
  if (refs.isEmpty) {
    return const PronunciationResult(outcome: PronunciationOutcome.unsupportedReference);
  }
  Float32List raw;
  try {
    raw = decodeWav(take);
  } on UnsupportedAudio {
    return const PronunciationResult(outcome: PronunciationOutcome.tooQuiet);
  }
  return scoreSamples(refs: refs, take: raw, syllables: syllables);
}

PronunciationResult scoreSamples({
  required List<Float32List> refs,
  required Float32List take,
  required List<String> syllables,
}) {
  if (refs.isEmpty) {
    return const PronunciationResult(outcome: PronunciationOutcome.noReference);
  }
  if (peakRms(take) < 0.004) {
    return const PronunciationResult(outcome: PronunciationOutcome.tooQuiet);
  }
  final t = trimSilence(take);
  if (t.length < kScoreRate * 0.12) {
    return const PronunciationResult(outcome: PronunciationOutcome.tooShort);
  }
  final tf = extract(t);
  DtwResult? best;
  Features? bestRef;
  var bestNorm = 1.0;
  var bestIdx = -1;
  for (var i = 0; i < refs.length; i++) {
    final rf = extract(trimSilence(refs[i]));
    final d = dtw(rf.mfcc, tf.mfcc);
    final anti = dtw(rf.mfcc.reversed.toList(), tf.mfcc).cost;
    // A take far longer/shorter than the reference is a different utterance.
    final ratio = tf.length / math.max(1, rf.length);
    final lengthPenalty = ratio > 2.6 || ratio < 0.38 ? 0.2 : 0.0;
    final norm = anti > 1e-9 ? anti : 1.0;
    final cost = d.cost / norm + lengthPenalty;
    if (best == null || cost < best.cost) {
      best = DtwResult(cost, d.path);
      bestNorm = norm;
      bestRef = rf;
      bestIdx = i;
    }
  }
  final overall = costToScore(best!.cost);
  final sylls = syllables.where((s) => s.trim().isNotEmpty).toList();
  final per = <SyllableScore>[];
  if (sylls.isNotEmpty) {
    final cuts = syllableBoundaries(bestRef!, sylls);
    for (var s = 0; s < sylls.length; s++) {
      if (cuts.length <= s + 1) break;
      final lo = cuts[s], hi = cuts[s + 1];
      var sum = 0.0;
      var k = 0;
      for (final (r, q) in best.path) {
        if (r >= lo && r < hi) {
          sum += frameDistance(bestRef.mfcc[r], tf.mfcc[q]);
          k++;
        }
      }
      per.add(SyllableScore(sylls[s], k == 0 ? 0 : costToScore(sum / k / bestNorm)));
    }
  }
  return PronunciationResult(
    outcome: PronunciationOutcome.scored,
    score: overall,
    syllables: per,
    bestTake: bestIdx,
  );
}
