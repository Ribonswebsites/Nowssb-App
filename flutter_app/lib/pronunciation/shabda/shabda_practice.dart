/// One practice attempt, end to end: the user's microphone take is checked
/// (silence, too quiet, too noisy, too short, too long), cleaned (high-pass,
/// spectral noise gate, peak level), trimmed to the spoken part and scored
/// against ONE stage's client recording. The result carries the 0–100 score,
/// the five sub-scores, and plain feedback that says WHERE in the word the
/// attempt differed and how to fix it.
///
/// A take that cannot be judged gets a message and no score — never a
/// made-up number.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_io.dart';
import 'dsp.dart';
import 'shabda_features.dart';
import 'shabda_scorer.dart';

/// Pass rule. Provisional until Ribon sends real learner attempts to
/// calibrate on — change the numbers here (one place).
class PracticeConfig {
  const PracticeConfig({
    this.passMark = 70,
    this.minCompleteness = 75,
    this.minRhythm = 50,
    this.minVowel = 45,
    this.minPitch = 35,
    this.minSpeechSeconds = 0.25,
    this.maxLengthRatio = 3.0,
    this.minSnrDb = 10,
    this.silentPeakDb = -50,
    this.quietPeakDb = -36,
  });

  /// Overall score needed to pass a stage.
  final double passMark;

  /// A pass also needs the whole word said, in roughly the right time, on
  /// roughly the right contour — a high average cannot hide a missing part.
  final double minCompleteness;
  final double minRhythm;
  final double minPitch;
  final double minVowel;

  final double minSpeechSeconds;
  final double maxLengthRatio;
  final double minSnrDb;
  final double silentPeakDb;
  final double quietPeakDb;
}

const kPracticeConfig = PracticeConfig();

enum AttemptStatus { scored, silent, tooQuiet, tooNoisy, tooShort, tooLong }

class SubScore {
  const SubScore(this.key, this.label, this.value);
  final String key;
  final String label;
  final int value;
}

class AttemptResult {
  AttemptResult({
    required this.status,
    required this.headline,
    this.message = '',
    this.overall = 0,
    this.subs = const [],
    this.passed = false,
    this.good = const [],
    this.fixes = const [],
    this.score,
    this.elapsedMs = 0,
  });

  final AttemptStatus status;
  final String headline;

  /// For a take that could not be scored: what happened and what to do.
  final String message;
  final int overall;
  final List<SubScore> subs;
  final bool passed;

  /// What the attempt got right.
  final List<String> good;

  /// What to fix, most important first, each tied to a part of the word.
  final List<String> fixes;
  final ShabdaScore? score;
  final int elapsedMs;

  bool get scored => status == AttemptStatus.scored;
}

/// Prepares a client reference recording (WAV bytes) once, through the
/// same conditioning as a microphone take so both are compared like for like.
ShabdaFeatures referenceFeatures(Uint8List wavBytes) => extractFeatures(conditionTake(highPass(wavTo16k(wavBytes))));

/// The shared clean-up for references and takes: noise gate, peak level,
/// trim to the spoken part, and a fixed low hiss (−42 dBFS) so a very quiet
/// room and a noisier one leave the same floor — otherwise a soft consonant
/// in a silent room reads as a "missing" part.
Float64List conditionTake(Float64List x) => addComfortNoise(_trimToSpeech(normalizePeak(spectralGate(x))));

/// Scores a microphone take (WAV bytes) against [ref].
AttemptResult assessTakeBytes(ShabdaFeatures ref, Uint8List takeWav,
        {PracticeConfig config = kPracticeConfig, int stage = 1}) =>
    assessTake(ref, wavTo16k(takeWav), config: config, stage: stage);

/// Scores a 16 kHz mono take against [ref].
AttemptResult assessTake(ShabdaFeatures ref, Float64List take,
    {PracticeConfig config = kPracticeConfig, int stage = 1}) {
  final sw = Stopwatch()..start();
  AttemptResult fail(AttemptStatus st, String head, String msg) =>
      AttemptResult(status: st, headline: head, message: msg, elapsedMs: sw.elapsedMilliseconds);

  var x = highPass(take);
  final lv = measureLevels(x);
  if (lv.voicedSeconds < 0.04 && lv.peakDb >= config.silentPeakDb && lv.floorDb > -55) {
    return fail(AttemptStatus.tooNoisy, 'Too much background noise',
        'All we could hear was noise. Move somewhere quieter (away from fans, traffic or music) and say the word again.');
  }
  if (lv.peakDb < config.silentPeakDb || lv.voicedSeconds < 0.04) {
    return fail(AttemptStatus.silent, 'We didn’t hear you',
        'Nothing came through the microphone. Hold the phone about a hand’s length away, tap the mic and say the word right after the recording.');
  }
  if (lv.peakDb < config.quietPeakDb) {
    return fail(AttemptStatus.tooQuiet, 'Too quiet',
        'Your voice was very faint. Speak up a little or bring the phone closer, then try again.');
  }
  if (lv.snrDb < config.minSnrDb) {
    return fail(AttemptStatus.tooNoisy, 'Too much background noise',
        'We couldn’t separate your voice from the noise around you. Move somewhere quieter (away from fans, traffic or music) and try again.');
  }

  final usr = extractFeatures(conditionTake(x));
  final refSpeech = math.max(ref.vad.speechDur, 0.1);
  if (usr.vad.intervals.isEmpty || usr.vad.speechDur < config.minSpeechSeconds) {
    return fail(AttemptStatus.tooShort, 'Too short',
        'We only caught a very short sound. Say the whole word, the way the recording does.');
  }
  if (usr.vad.speechDur > refSpeech * config.maxLengthRatio + 0.5) {
    return fail(AttemptStatus.tooLong, 'Say it once',
        'That was much longer than the recording (${usr.vad.speechDur.toStringAsFixed(1)} s against ${refSpeech.toStringAsFixed(1)} s). Say the word once, then stop.');
  }

  final s = scorePair(ref, usr, adaptRegister: true);
  final matched = calibratedScore(s.overall).round();
  // A pass needs the score and the whole word said. Rhythm, pitch and vowel
  // length vary too much between a fresh take and the recording (mic, room,
  // pace) to veto a pass on their own; they still show what to improve.
  // The one exception: a take whose timing cannot be lined up with the
  // recording at all (rhythm near 0, e.g. a word cut off mid-way and
  // stretched) is not the same word said again.
  final inOrder = s.rhythm >= kMinAlignedRhythm && wholeWordSaid(s);
  // A part left out keeps the score under the pass mark too, so the number
  // and the verdict never disagree.
  final overall = inOrder ? matched : math.min(matched, 60);
  final passed = overall >= config.passMark && s.completeness >= config.minCompleteness && inOrder;
  final fb = buildFeedback(s, passed: passed, stage: stage, config: config);
  // Why a take did or did not pass, in one line.
  final short = <String>[
    if (s.completeness < config.minCompleteness || !inOrder) 'the whole word, start to end',
  ];
  final message = passed
      ? 'Close to the recording — well done.'
      : overall >= config.passMark
          ? 'Nearly there. Say ${short.join(', ')}.'
          : 'You need ${config.passMark.round()} to pass${short.isEmpty ? '' : '. Say ${short.join(', ')}'}.';
  return AttemptResult(
    status: AttemptStatus.scored,
    headline: passed
        ? 'Passed · Stage $stage'
        : overall >= config.passMark
            ? 'Almost — one part needs work'
            : overall >= 55
                ? 'Close — fix the parts below'
                : overall >= 40
                    ? 'Getting there'
                    : 'Not a match yet',
    message: message,
    overall: overall,
    subs: [
      SubScore('sounds', 'Sounds', s.sounds.round()),
      SubScore('rhythm', 'Rhythm', s.rhythm.round()),
      SubScore('pitch', 'Pitch', s.pitch.round()),
      SubScore('vowel', 'Vowel length', s.vowel.round()),
      SubScore('completeness', 'Completeness', s.completeness.round()),
    ],
    passed: passed,
    good: fb.good,
    fixes: fb.fixes,
    score: s,
    elapsedMs: sw.elapsedMilliseconds,
  );
}

/// Maps the raw match (0–100) to the score shown. Calibrated on the
/// teacher recordings under phone-like conditions (noise 10–20 dB SNR,
/// reverb, a thin mic, gain ±12 dB, pace 0.75–1.3×, pitch ±2 semitones,
/// added silence): the same word lands at raw 60–100, a different word at
/// raw 25–45. Below 45 the score is unchanged; 45–65 opens up so a fresh
/// re-take reads as a pass; above 65 it rises gently to 100.
/// Rhythm below this means the take could not be lined up with the
/// recording (see the pass rule in [assessTake]).
const double kMinAlignedRhythm = 5;

double calibratedScore(double raw) {
  final r = raw.clamp(0.0, 100.0).toDouble();
  if (r <= 50) return r;
  if (r <= 65) return 50 + (r - 50) * (78 - 50) / 15;
  return 78 + (r - 65) * (100 - 78) / 35;
}

/// Keeps the spoken part plus 0.35 s before and 0.5 s after — the same
/// framing the shipped client references have.
Float64List _trimToSpeech(Float64List x) {
  const w = 320;
  final n = x.length ~/ w;
  if (n < 5) return x;
  final db = <double>[];
  for (var f = 0; f < n; f++) {
    var s = 0.0;
    for (var i = 0; i < w; i++) {
      final v = x[f * w + i];
      s += v * v;
    }
    db.add(10 * log10(s / w + 1e-12));
  }
  // The room's floor, ignoring digital silence (a phone that gates its
  // mic, or padding) so the threshold is not pulled down to -120 dB.
  final live = [for (final v in db) if (v > -90) v]..sort();
  final sorted = List<double>.from(db)..sort();
  final floor = live.length >= 5 ? median(live.sublist(0, math.max(1, (live.length * 0.2).floor()))) : median(sorted.sublist(0, math.max(1, (n * 0.2).floor())));
  final peak = sorted.last;
  final th = math.max(floor + 10, peak - 35);
  var a = db.indexWhere((v) => v >= th);
  var b = db.lastIndexWhere((v) => v >= th);
  if (a < 0 || b < a) return x;
  final s0 = math.max(0, a * w - (0.35 * kSr).round());
  final s1 = math.min(x.length, (b + 1) * w + (0.5 * kSr).round());
  return Float64List.sublistView(x, s0, s1);
}

class Feedback {
  Feedback(this.good, this.fixes);
  final List<String> good;
  final List<String> fixes;
}

String _region(double t, double start, double end) {
  final span = math.max(1e-3, end - start);
  final p = (t - start) / span;
  if (p < 0.34) return 'beginning';
  if (p > 0.66) return 'ending';
  return 'middle';
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Per third of the word: alignment cost, local tempo and missing share,
/// plus the parts that were left out.
({List<double> cost, List<double> tempoMed, List<double> miss, List<int> missQ, bool cutEnd}) _thirdStats(
    ShabdaScore s) {
  final st = s.refStart, en = s.refEnd;
  final third = (en - st) / 3;

  final cost = List<double>.filled(3, 0), tempoMed = List<double>.filled(3, 1), miss = List<double>.filled(3, 0);
  for (var q = 0; q < 3; q++) {
    final lo = st + q * third, hi = q == 2 ? en + 1e-6 : st + (q + 1) * third;
    final idx = [
      for (var k = 0; k < s.pathRefTimes.length; k++)
        if (s.pathRefTimes[k] >= lo && s.pathRefTimes[k] < hi) k
    ];
    if (idx.isEmpty) continue;
    cost[q] = mean([for (final k in idx) s.mfccLocal[k]]);
    if (s.tempo.isNotEmpty) {
      tempoMed[q] = median([for (final k in idx) s.tempo[s.path[k].$1.clamp(0, s.tempo.length - 1)]]);
    }
    miss[q] = idx.where((k) => s.missing.length > k && s.missing[k]).length / idx.length;
  }

  // ---- completeness ----
  final missQ = [
    for (var q = 0; q < 3; q++)
      if (miss[q] > 0.3) q
  ];
  final cutEnd = tempoMed[2] < 0.4 && s.durRatio < 0.8;
  return (cost: cost, tempoMed: tempoMed, miss: miss, missQ: missQ, cutEnd: cutEnd);
}

/// False when part of the word was left out: the ending cut off, or a third
/// of the word mostly silent where the recording has voice.
bool wholeWordSaid(ShabdaScore s) {
  final t = _thirdStats(s);
  // Stricter than the feedback line: a thin phone mic can drop a soft final
  // consonant, which is worth a tip but is not a cut-off word.
  final cut = t.tempoMed[2] < 0.25 && s.durRatio < 0.8;
  return !cut && t.missQ.isEmpty;
}

/// Turns the alignment into located, practical feedback.
Feedback buildFeedback(ShabdaScore s, {required bool passed, int stage = 1, PracticeConfig config = kPracticeConfig}) {
  final fixes = <(double, String)>[]; // (priority: lower = more important, text)
  final good = <String>[];
  final st = s.refStart, en = s.refEnd;
  final third = (en - st) / 3;
  final thirds = ['beginning', 'middle', 'ending'];
  final (:cost, :tempoMed, :miss, :missQ, :cutEnd) = _thirdStats(s);
  bool shortVowelIn(int q) => s.vowelCompares.any((v) {
        final mid = (v.start + v.end) / 2;
        return v.ratio < 0.6 && mid >= st + q * third && mid < st + (q + 1) * third;
      });
  final skipped = [
    for (var q = 0; q < 2; q++)
      if (tempoMed[q] < 0.55 || (tempoMed[q] < 0.75 && shortVowelIn(q))) q
  ];
  if (cutEnd) {
    fixes.add((
      0,
      'The ending of the word is cut off — keep your voice going until the word is finished, like the recording.'
    ));
  } else if (skipped.isNotEmpty && s.sounds >= 50) {
    final q = skipped.reduce((a, b) => tempoMed[a] <= tempoMed[b] ? a : b);
    fixes.add((
      0,
      'Part of the ${thirds[q]} of the word is missing — you skipped through it. Say every sound there, like the recording.'
    ));
  } else if (missQ.isNotEmpty) {
    final q = missQ.reduce((a, b) => miss[a] >= miss[b] ? a : b);
    fixes.add((
      0,
      'The ${thirds[q]} of the word is missing or too quiet — say that part fully, at the same strength as the rest.'
    ));
  } else if (s.completeness < 80) {
    var q = 0;
    for (var k = 1; k < 3; k++) {
      if (miss[k] > miss[q]) q = k;
    }
    fixes.add((
      1,
      miss[q] > 0.08
          ? 'Part of the ${thirds[q]} of the word got lost — say every sound from start to finish.'
          : 'Part of the word got lost — say every sound from start to finish.'
    ));
  }

  // ---- rhythm ----
  if (s.rhythm < 78) {
    final pct = ((s.durRatio - 1).abs() * 100).round();
    if (s.durRatio < 0.85) {
      fixes.add((2, 'You said it about $pct% faster than the recording — slow down and give each part its time.'));
    } else if (s.durRatio > 1.18) {
      fixes.add((
        2,
        'You said it about $pct% slower than the recording — keep the same pace, without stretching every sound.'
      ));
    }
    var worst = -1;
    var worstDev = 0.0;
    for (var q = 0; q < 3; q++) {
      final dev = math.log(math.max(tempoMed[q], 1e-3)).abs();
      if (dev > worstDev) {
        worstDev = dev;
        worst = q;
      }
    }
    final before = fixes.length;
    if (worst >= 0 && worstDev > math.log(1.35) && !(cutEnd && worst == 2) && !skipped.contains(worst)) {
      fixes.add((
        2.5,
        tempoMed[worst] < 1
            ? 'You rushed the ${thirds[worst]} of the word — hold that part a little longer.'
            : 'The ${thirds[worst]} of the word was drawn out — tighten it to match the recording.'
      ));
    }
    if (fixes.length == before && !(s.durRatio < 0.85 || s.durRatio > 1.18) && worst >= 0 && !skipped.contains(worst)) {
      fixes.add((
        2.6,
        tempoMed[worst] < 1
            ? 'Your timing is uneven — the ${thirds[worst]} of the word came a little too quickly.'
            : 'Your timing is uneven — the ${thirds[worst]} of the word lasted a little too long.'
      ));
    }
  }

  // ---- sounds ----
  if (s.sounds < 78) {
    var q = 0;
    for (var k = 1; k < 3; k++) {
      if (cost[k] > cost[q]) q = k;
    }
    if (s.sounds < 50) {
      fixes.add((
        -1,
        'The sounds are quite different from Stage $stage’s recording, especially in the ${thirds[q]}. Listen again and copy it sound for sound.'
      ));
    } else {
      fixes.add((
        3,
        'The sounds in the ${thirds[q]} of the word don’t match yet — replay the recording and copy the mouth shape there.'
      ));
    }
  }

  // ---- pitch ----
  if (s.pitch < 78) {
    final pe = s.errors.where((e) => e.kind == 'pitch').toList();
    if (!s.registerAdapted && s.absCents >= 200 && s.medianCents.abs() >= 150) {
      final semis = (s.medianCents.abs() / 100).round();
      fixes.add((
        3.5,
        s.medianCents > 0
            ? 'Your voice sits about $semis semitone${semis == 1 ? '' : 's'} higher than the recording — bring the note down.'
            : 'Your voice sits about $semis semitone${semis == 1 ? '' : 's'} lower than the recording — lift the note up.'
      ));
    }
    if (pe.isNotEmpty) {
      final e = pe.first;
      final where = _region((e.start + e.end) / 2, st, en);
      final what = e.detail.contains('rises')
          ? 'your pitch stays flat where the recording rises'
          : e.detail.contains('falls')
              ? 'your pitch stays flat where the recording falls'
              : e.detail.contains('above')
                  ? 'your pitch is well above the recording'
                  : 'your pitch is well below the recording';
      fixes.add((3.6, '${_cap('in the $where of the word')}, $what — follow the rise and fall of the voice.'));
    } else if (s.shapeCents >= 70) {
      fixes.add((3.7, 'The melody of the word is flatter than the recording — follow how the voice rises and falls.'));
    }
  }

  // ---- vowel length ----
  if (s.vowel < 78 && s.vowelCompares.isNotEmpty) {
    final v = s.vowelCompares.reduce((a, b) => math.log(a.ratio).abs() >= math.log(b.ratio).abs() ? a : b);
    final where = _region((v.start + v.end) / 2, st, en);
    if (v.ratio < 0.85) {
      final times = (1 / math.max(v.ratio, 0.05));
      fixes.add((
        4,
        'The held sound in the $where was too short — hold it ${times >= 2.6 ? 'about three times as long' : times >= 1.6 ? 'about twice as long' : 'a little longer'}.'
      ));
    } else if (v.ratio > 1.18) {
      fixes.add((4, 'The held sound in the $where was too long — cut it closer to the recording’s length.'));
    } else {
      fixes.add((
        4.5,
        'The held sounds are uneven — match how long each one lasts in the recording, especially in the $where.'
      ));
    }
  }

  // ---- what was right ----
  if (s.sounds >= 85) good.add('Your sounds match the recording.');
  if (s.rhythm >= 85) good.add('Your timing matches the recording.');
  if (s.pitch >= 85) {
    good.add(s.registerAdapted
        ? 'Your pitch follows the recording’s rise and fall in your own voice.'
        : 'Your pitch follows the recording.');
  }
  if (s.vowel >= 85) good.add('You held the long sounds for the right time.');
  if (s.completeness >= 90 && !cutEnd) good.add('You said the whole word.');
  if (good.isEmpty) {
    final best = s.subs.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value >= 60) {
      const names = {
        'sounds': 'sounds',
        'rhythm': 'timing',
        'pitch': 'pitch',
        'vowel': 'vowel length',
        'completeness': 'completeness'
      };
      good.add('Your strongest part was ${names[best.key]} (${best.value.round()}).');
    }
  }

  fixes.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <String>[];
  for (final f in fixes) {
    if (!out.contains(f.$2)) out.add(f.$2);
  }
  if (out.isEmpty && !passed) {
    out.add('Listen once more and match the recording as closely as you can — you are near the pass mark.');
  }
  return Feedback(good, out.take(4).toList());
}
