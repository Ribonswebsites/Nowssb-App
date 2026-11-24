/// DTW pronunciation scorer — a port of shabda-score/src/scorer.py.
///
/// Compares a user's attempt with ONE client reference recording (the stage
/// being practised): MFCC c1–c12 + energy are aligned with dynamic time
/// warping, then five sub-scores are read off the alignment:
///
///   sounds        cosine distance of z-scored MFCCs (half-VTLN if it helps)
///   rhythm        global duration ratio + local warp slope
///   pitch         60 % absolute register + 40 % contour shape, in cents
///   vowel length  each voiced run of the reference vs. what the user held
///   completeness  holes (near-silence) where the reference has speech
///
/// [scorePair] reproduces the prototype's numbers (see
/// test/shabda_scorer_parity_test.dart). The plain-language feedback in
/// shabda_feedback.dart is built from the same alignment.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'dsp.dart';
import 'shabda_features.dart';

const double wMfcc = 1.00;
const double wEnergy = 0.40;
const double tauSounds = 0.45;
const double tauPitchCents = 90.0;
const double tauPitchShape = 55.0;
const double tauRhythmDev = 0.18;
const double tauVowel = 0.28;

/// Overall tempo change a natural re-take may have without penalty.
const double kTempoTolerance = 1.32;

/// Voices further apart than this (≈ 4 semitones) count as a different
/// register when [scorePair] runs with `adaptRegister`.
const double kRegisterShiftCents = 400;

// The sounds carry the word; rhythm, pitch and vowel length are the
// parts a fresh take by the same speaker varies most in (mic, room, pace),
// so they weigh less.
const Map<String, double> kWeights = {
  'sounds': 0.52,
  'rhythm': 0.14,
  'pitch': 0.10,
  'vowel': 0.12,
  'completeness': 0.12,
};

double _exp(double dist, double tau) => 100.0 * math.exp(-math.max(0.0, dist) / math.max(tau, 1e-9));
double _clamp(double x) => x.isNaN ? 0.0 : x.clamp(0.0, 100.0).toDouble();
double _r1(double x) => (x * 10).roundToDouble() / 10;

/// One time-ranged problem, in reference seconds.
class SegmentError {
  SegmentError(this.start, this.end, this.kind, this.detail, this.severity);
  double start;
  double end;
  final String kind; // sounds | missing | timing | pitch
  final String detail;
  double severity;
}

/// A held vowel of the reference and how long the user held it (ratio).
class VowelCompare {
  const VowelCompare(this.start, this.end, this.ratio);
  final double start;
  final double end;
  final double ratio;
}

class ShabdaScore {
  ShabdaScore({
    required this.overall,
    required this.sounds,
    required this.rhythm,
    required this.pitch,
    required this.vowel,
    required this.completeness,
    this.raw = const {},
    this.errors = const [],
    this.vowelCompares = const [],
    this.path = const [],
    this.refStart = 0,
    this.refEnd = 0,
    this.mfccLocal = const [],
    this.tempo = const [],
    this.pathRefTimes = const [],
    this.missing = const [],
  });

  final double overall;
  final double sounds;
  final double rhythm;
  final double pitch;
  final double vowel;
  final double completeness;
  final Map<String, Object> raw;
  final List<SegmentError> errors;
  final List<VowelCompare> vowelCompares;
  final List<(int, int)> path;

  /// The reference speech span the alignment covers (seconds).
  final double refStart;
  final double refEnd;
  final List<double> mfccLocal;
  final List<double> tempo;
  final List<double> pathRefTimes;
  final List<bool> missing;

  double get durRatio => (raw['dur_ratio'] as double?) ?? 1.0;
  double get absCents => (raw['abs_cents'] as double?) ?? 999.0;
  double get shapeCents => (raw['shape_cents'] as double?) ?? 999.0;
  double get missFrac => (raw['miss_frac'] as double?) ?? 0.0;
  double get medianCents => (raw['median_cents'] as double?) ?? 0.0;
  bool get registerAdapted => (raw['register_adapted'] as bool?) ?? false;

  Map<String, double> get subs => {
        'sounds': sounds,
        'rhythm': rhythm,
        'pitch': pitch,
        'vowel': vowel,
        'completeness': completeness,
      };
}

class _Mat {
  _Mat(this.mfcc, this.f0, this.conf, this.energy, this.speech, this.voiced, this.times);
  final List<Float64List> mfcc;
  final List<double> f0;
  final List<double> conf;
  final List<double> energy;
  final List<bool> speech;
  final List<bool> voiced;
  final List<double> times;
}

_Mat _build(ShabdaFeatures f, int i0, int i1) {
  final speech = f.vad.speech.sublist(i0, i1);
  final f0 = f.f0.sublist(i0, i1);
  final conf = f.f0Conf.sublist(i0, i1);
  return _Mat(
    f.mfcc.sublist(i0, i1),
    f0,
    conf,
    f.logEnergy.sublist(i0, i1),
    speech,
    [for (var i = 0; i < f0.length; i++) conf[i] >= 0.4 && f0[i] > 0 && speech[i]],
    f.times.sublist(i0, i1),
  );
}

/// Column-wise mean / population std over [rows] selected by [sel].
(Float64List, Float64List) _stats(List<Float64List> rows, List<bool> sel, int from, int to) {
  final d = to - from;
  final mu = Float64List(d), sd = Float64List(d);
  var n = 0;
  for (var i = 0; i < rows.length; i++) {
    if (!sel[i]) continue;
    n++;
    for (var c = 0; c < d; c++) {
      mu[c] += rows[i][from + c];
    }
  }
  for (var c = 0; c < d; c++) {
    mu[c] /= math.max(n, 1);
  }
  for (var i = 0; i < rows.length; i++) {
    if (!sel[i]) continue;
    for (var c = 0; c < d; c++) {
      final v = rows[i][from + c] - mu[c];
      sd[c] += v * v;
    }
  }
  for (var c = 0; c < d; c++) {
    sd[c] = math.max(math.sqrt(sd[c] / math.max(n, 1)), 1e-3);
  }
  return (mu, sd);
}

List<Float64List> _z(List<Float64List> rows, Float64List mu, Float64List sd, int from) => [
      for (final r in rows) Float64List.fromList([for (var c = 0; c < mu.length; c++) (r[from + c] - mu[c]) / sd[c]])
    ];

(List<Float64List>, List<Float64List>) _stackNormalized(_Mat r, _Mat u) {
  var rs = [for (final s in r.speech) s];
  if (rs.where((s) => s).length < 5) rs = List<bool>.filled(r.mfcc.length, true);
  final (mu, sd) = _stats(r.mfcc, rs, 1, 13);
  final rz = _z(r.mfcc, mu, sd, 1);
  // Each recording is normalised on its own speech (CMVN): a different
  // phone, mic, distance or room shifts the cepstrum as a whole, and that
  // shift is removed instead of being scored as "wrong sounds".
  var us = [for (final s in u.speech) s];
  if (us.where((s) => s).length < 5) us = List<bool>.filled(u.mfcc.length, true);
  final (umu, usd) = _stats(u.mfcc, us, 1, 13);
  final uz = _z(u.mfcc, umu, usd, 1);
  final re = [
    for (final e in r.energy) Float64List.fromList([e])
  ];
  final ue = [
    for (final e in u.energy) Float64List.fromList([e])
  ];
  final (emu, esd) = _stats(re, rs, 0, 1);
  final (uemu, uesd) = _stats(ue, us, 0, 1);
  Float64List row(Float64List m, double e, double mu0, double sd0) {
    final out = Float64List(13);
    for (var c = 0; c < 12; c++) {
      out[c] = m[c] * wMfcc;
    }
    out[12] = (e - mu0) / sd0 * wEnergy;
    return out;
  }

  return (
    [for (var i = 0; i < rz.length; i++) row(rz[i], r.energy[i], emu[0], esd[0])],
    [for (var i = 0; i < uz.length; i++) row(uz[i], u.energy[i], uemu[0], uesd[0])],
  );
}

double _dist(Float64List a, Float64List b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    s += d * d;
  }
  return math.sqrt(s);
}

double _cosineDist(Float64List a, Float64List b) {
  var na = 0.0, nb = 0.0, dot = 0.0;
  for (var i = 0; i < a.length; i++) {
    na += a[i] * a[i];
    nb += b[i] * b[i];
    dot += a[i] * b[i];
  }
  na = math.sqrt(na);
  nb = math.sqrt(nb);
  if (na < 1e-9 || nb < 1e-9) return 1.0;
  final sim = dot / (na * nb);
  return 1.0 - sim.clamp(-1.0, 1.0);
}

class DtwResult {
  DtwResult(this.path, this.cost, this.normCost);
  final List<(int, int)> path;
  final double cost;
  final double normCost;
}

/// Euclidean DTW with a Sakoe–Chiba band. Path items are (ref, user).
DtwResult dtw(List<Float64List> rx, List<Float64List> ux, {double bandRatio = 0.45}) {
  final n = rx.length, m = ux.length;
  if (n == 0 || m == 0) return DtwResult(const [], double.infinity, double.infinity);
  final mx = math.max(n, m);
  final band = [8, (bandRatio * mx).toInt(), ((n - m).abs() + 0.15 * mx).toInt()].reduce(math.max);
  const inf = 1e30;
  final w = m + 1;
  final dm = Float64List((n + 1) * w)..fillRange(0, (n + 1) * w, inf);
  dm[0] = 0.0;
  final ptr = Int8List(n * m);
  for (var i = 1; i <= n; i++) {
    final j0 = math.max(1, i - band);
    final j1 = math.min(m, i + band);
    final ri = rx[i - 1];
    for (var j = j0; j <= j1; j++) {
      final loc = _dist(ri, ux[j - 1]);
      var best = dm[(i - 1) * w + j - 1];
      var bp = 1;
      final left = dm[i * w + j - 1];
      if (left < best) {
        best = left;
        bp = 2;
      }
      final up = dm[(i - 1) * w + j];
      if (up < best) {
        best = up;
        bp = 3;
      }
      dm[i * w + j] = best + loc;
      ptr[(i - 1) * m + j - 1] = bp;
    }
  }
  if (dm[n * w + m] >= inf / 10) {
    if (bandRatio < 1.5) return dtw(rx, ux, bandRatio: 2.0);
    return DtwResult(const [], dm[n * w + m], dm[n * w + m]);
  }
  final path = <(int, int)>[];
  var i = n, j = m;
  while (i > 0 && j > 0) {
    path.add((i - 1, j - 1));
    var p = ptr[(i - 1) * m + j - 1];
    if (p == 0) {
      final c = [dm[(i - 1) * w + j - 1], dm[i * w + j - 1], dm[(i - 1) * w + j]];
      p = 1;
      if (c[1] < c[0]) p = 2;
      if (c[2] < c[p - 1]) p = 3;
    }
    if (p == 1) {
      i--;
      j--;
    } else if (p == 2) {
      j--;
    } else {
      i--;
    }
  }
  final rev = path.reversed.toList();
  final cost = dm[n * w + m];
  return DtwResult(rev, cost, cost / math.max(1, rev.length));
}

List<double> _localTempo(List<(int, int)> path) {
  if (path.isEmpty) return const [];
  final byRef = <int, List<int>>{};
  for (final (a, b) in path) {
    (byRef[a] ??= []).add(b);
  }
  final keys = byRef.keys.toList()..sort();
  if (keys.length < 3) return List<double>.filled(keys.length, 1.0);
  final u = [for (final k in keys) byRef[k]!.reduce((x, y) => x + y) / byRef[k]!.length];
  final r = [for (final k in keys) k.toDouble()];
  final n = u.length;
  var slope = List<double>.filled(n, 0);
  // numpy.gradient with coordinates (second-order interior, first-order edges)
  slope[0] = (u[1] - u[0]) / (r[1] - r[0]);
  slope[n - 1] = (u[n - 1] - u[n - 2]) / (r[n - 1] - r[n - 2]);
  for (var i = 1; i < n - 1; i++) {
    final hs = r[i] - r[i - 1], hd = r[i + 1] - r[i];
    slope[i] = (hs * hs * u[i + 1] + (hd * hd - hs * hs) * u[i] - hd * hd * u[i - 1]) / (hs * hd * (hd + hs));
  }
  if (n >= 5) {
    final sm = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      var s = 0.0;
      var c = 0;
      for (var k = i - 5; k <= i + 5; k++) {
        if (k >= 0 && k < n) {
          s += slope[k];
          c++;
        }
      }
      sm[i] = s / c;
    }
    slope = sm;
  }
  return [for (final s in slope) math.max(s, 1e-3)];
}

/// Scores [usr] against [ref] (port of `score_pair`).
///
/// [adaptRegister] (app only, off for parity): when the two voices sit more
/// than [kRegisterShiftCents] apart — e.g. a man practising a woman's
/// recording — pitch is judged on the contour around each voice's own
/// centre instead of on the absolute note, which no other voice could hit.
ShabdaScore scorePair(ShabdaFeatures ref, ShabdaFeatures usr, {bool adaptRegister = false}) {
  final (r0, r1) = speechSlice(ref);
  final (u0, u1) = speechSlice(usr);
  final rm = _build(ref, r0, r1);
  final um = _build(usr, u0, u1);

  final rMed = ref.f0Median, uMed = usr.f0Median;
  var alpha = 1.0;
  if (rMed >= 70 && uMed >= 70) {
    final rawA = (uMed / rMed).clamp(0.67, 1.50).toDouble();
    alpha = 1.0 + 0.5 * (rawA - 1.0);
  }
  List<Float64List>? uWarp;
  if ((alpha - 1.0).abs() >= 0.03) {
    final w = mfccOnly(usr.x, freqWarp: alpha);
    if (w.length >= 2) uWarp = w.sublist(u0, math.min(u1, w.length));
  }

  final (rx, ux) = _stackNormalized(rm, um);
  final aln = dtw(rx, ux);
  final path = aln.path;
  if (path.isEmpty) {
    return ShabdaScore(
        overall: 0, sounds: 0, rhythm: 0, pitch: 0, vowel: 0, completeness: 0, raw: {'error': 'empty path'});
  }
  final np = path.length;

  // ---- sounds ----
  final rsp = rm.speech;
  final sel = rsp.where((s) => s).length >= 5 ? rsp : List<bool>.filled(rm.mfcc.length, true);
  final (mu, sd) = _stats(rm.mfcc, sel, 1, 13);
  final rz = _z(rm.mfcc, mu, sd, 1);
  final usel = um.speech.where((s) => s).length >= 5 ? um.speech : List<bool>.filled(um.mfcc.length, true);
  final (umu, usd) = _stats(um.mfcc, usel, 1, 13);
  final uz = _z(um.mfcc, umu, usd, 1);
  var mfccLocal = [for (final (a, b) in path) _cosineDist(rz[a], uz[b])];

  // ---- activity ----
  final uDb = usr.energyDb.sublist(u0, u1);
  final uDbAl = [for (final (_, b) in path) uDb[math.min(b, uDb.length - 1)]];
  final rSp = [for (final (a, _) in path) rm.speech[a]];
  final spVals = [
    for (var k = 0; k < np; k++)
      if (rSp[k]) uDbAl[k]
  ];
  final peakSp = spVals.isNotEmpty ? percentile(spVals, 90) : uDbAl.reduce(math.max);
  // "Missing" = no louder than the take's own background where the
  // recording has voice. On a quiet mic that is 24 dB under the voice; in a
  // noisy room the background sits closer, so the line follows it.
  final bg = [for (final d in usr.energyDb) if (d > -90) d];
  final floorDb = bg.length >= 10 ? percentile(bg, 10) : peakSp - 40;
  final missLine = math.max(peakSp - 24.0, math.min(floorDb + 4.0, peakSp - 14.0));
  // Only where the recording is clearly voiced (well above its own floor),
  // so soft onsets and tails never count as left out.
  final rDb = ref.energyDb.sublist(r0, r1);
  final rDbAl = [for (final (a, _) in path) rDb[math.min(a, rDb.length - 1)]];
  final rBg = [for (final d in ref.energyDb) if (d > -90) d];
  final rFloor = rBg.length >= 10 ? percentile(rBg, 10) : -90.0;
  final rVoiced = [for (var k = 0; k < np; k++) rSp[k] && rDbAl[k] > rFloor + 12];
  var missing = [
    for (var k = 0; k < np; k++)
      rSp[k] && (uDbAl[k] < peakSp - 24.0 || (rVoiced[k] && uDbAl[k] < missLine))
  ];
  final active = [for (final m in missing) !m];
  final activeCount = active.where((a) => a).length;
  final refE = [for (final (a, _) in path) rm.energy[a]];
  final medE = median(refE);
  double avg(List<double> loc) {
    if (activeCount >= 4) {
      var ws = 0.0, acc = 0.0;
      for (var k = 0; k < np; k++) {
        final w = active[k] ? math.exp(refE[k] - medE) : 0.0;
        ws += w;
        acc += w * loc[k];
      }
      if (ws <= 0) {
        ws = 0;
        acc = 0;
        for (var k = 0; k < np; k++) {
          if (active[k]) {
            ws += 1;
            acc += loc[k];
          }
        }
      }
      return acc / ws;
    }
    return loc.isEmpty ? 1.0 : mean(loc);
  }

  var soundsDist = avg(mfccLocal);
  if (uWarp != null && uWarp.length == um.mfcc.length) {
    final (wmu, wsd) = _stats(uWarp, usel, 1, 13);
    final uz2 = _z(uWarp, wmu, wsd, 1);
    final locW = [for (final (a, b) in path) _cosineDist(rz[a], uz2[b])];
    final dw = avg(locW);
    if (dw < soundsDist) {
      soundsDist = dw;
      mfccLocal = locW;
    }
  }
  final sounds = _clamp(_exp(soundsDist, tauSounds));

  // ---- rhythm ----
  final rDur = math.max(1e-3, rm.times.last - rm.times.first + kHopS);
  final uDur = math.max(1e-3, um.times.last - um.times.first + kHopS);
  final durRatio = uDur / rDur;
  // A natural re-take can be up to about 30 % quicker or slower: only the
  // part of the overall tempo change beyond that counts, and the local
  // timing is read relative to the take's own overall pace.
  final logDur = math.max(0.0, math.log(durRatio).abs() - math.log(kTempoTolerance));
  final tempo = _localTempo(path);
  double rhythmDev, rhythmVar;
  if (tempo.isNotEmpty) {
    final g = math.log(durRatio);
    // Small local wobbles (about ±8 %) are how anyone re-says a word.
    final ll = [for (final t in tempo) math.max(0.0, (math.log(math.max(t, 1e-3)) - g).abs() - 0.08)];
    rhythmDev = mean(ll);
    rhythmVar = stdDev(ll);
  } else {
    rhythmDev = logDur;
    rhythmVar = 0;
  }
  final rhythmRaw = 0.40 * rhythmDev + 0.50 * logDur + 0.10 * rhythmVar;
  final rhythm = rhythmRaw < 0.04 ? 100.0 : _clamp(_exp(math.max(0.0, rhythmRaw - 0.02), tauRhythmDev));

  // ---- pitch ----
  final rF0 = [for (final (a, _) in path) rm.f0[a]];
  final uF0 = [for (final (_, b) in path) um.f0[b]];
  final rV = [for (final (a, _) in path) rm.voiced[a]];
  final uV = [for (final (_, b) in path) um.voiced[b]];
  final both = [for (var k = 0; k < np; k++) rV[k] && uV[k] && rF0[k] >= 60 && uF0[k] >= 60];
  var agree = 0;
  for (var k = 0; k < np; k++) {
    if (rV[k] == uV[k]) agree++;
  }
  final voicingAgree = agree / np;
  double absCents, shapeCents, pitch;
  var medianCents = 0.0;
  var registerAdapted = false;
  final nBoth = both.where((b) => b).length;
  if (nBoth >= 8) {
    final raw = [
      for (var k = 0; k < np; k++)
        if (both[k]) 1200.0 * log2(uF0[k] / rF0[k])
    ];
    // Pitch trackers jump an octave in a reverberant room or on a thin mic:
    // fold those jumps back next to the take's median offset.
    final m0 = median(raw);
    final cents = [for (final c in raw) c - 1200.0 * ((c - m0) / 1200.0).roundToDouble()];
    absCents = mean([for (final c in cents) c.abs()]);
    final med = median(cents);
    medianCents = med;
    shapeCents = mean([for (final c in cents) (c - med).abs()]);
    if (adaptRegister && rMed >= 70 && uMed >= 70 && (1200.0 * log2(uMed / rMed)).abs() >= kRegisterShiftCents) {
      absCents = shapeCents;
      registerAdapted = true;
    }
    // Rise and fall only: the contour relative to the take's own median,
    // so a higher or lower voice (or a pitch-shifted mic) is not penalised.
    pitch = _clamp(_exp(shapeCents, tauPitchShape));
    pitch *= 0.7 + 0.3 * voicingAgree;
    pitch = _clamp(pitch);
  } else {
    absCents = 999.0;
    shapeCents = 999.0;
    pitch = _clamp(40.0 * voicingAgree);
  }

  // ---- vowel length ----
  final ratios = <double>[];
  final compares = <VowelCompare>[];
  final rT = [for (final (a, _) in path) rm.times[a]];
  for (final v in ref.vowels) {
    var cnt = 0;
    final idxs = <int>{};
    var anyActive = false;
    for (var k = 0; k < np; k++) {
      if (rT[k] >= v.start && rT[k] <= v.end) {
        cnt++;
        if (active[k]) {
          idxs.add(path[k].$2);
          anyActive = true;
        }
      }
    }
    if (cnt < 2) continue;
    final uLen = anyActive ? idxs.length * kHopS : kHopS * 0.25;
    final rLen = math.max(v.dur, 1e-3);
    // Relative to the take's overall pace: a quicker re-take shortens every
    // vowel a little, which is not a vowel-length mistake.
    ratios.add(uLen / rLen / durRatio);
    compares.add(VowelCompare(v.start, v.end, uLen / rLen / durRatio));
  }
  double vowelRaw;
  if (ratios.isNotEmpty) {
    vowelRaw = mean([for (final r in ratios) math.log(r.clamp(0.12, 6.0)).abs()]);
  } else {
    final rVd = math.max(rm.voiced.where((v) => v).length, 1) * kHopS;
    var uv = 0;
    for (var k = 0; k < np; k++) {
      if (active[k] && um.voiced[path[k].$2]) uv++;
    }
    final uVd = math.max(uv, 1) * kHopS;
    vowelRaw = math.log(uVd / rVd).abs();
    ratios.add(uVd / rVd);
  }
  final vowel = _clamp(_exp(vowelRaw, tauVowel));

  // ---- completeness ----
  final spIdx = [
    for (var k = 0; k < np; k++)
      if (rSp[k]) k
  ];
  var missFrac = spIdx.isEmpty ? 0.0 : spIdx.where((k) => missing[k]).length / spIdx.length;
  if (missFrac < 0.03) {
    missFrac = 0.0;
    missing = List<bool>.filled(np, false);
  }
  final visited = {for (final (a, _) in path) a};
  final skipFrac = 1.0 - visited.length / math.max(1, rm.times.length);
  final uActiveS = activeCount * kHopS;
  final shortfall = math.max(0.0, 1.0 - (uActiveS / math.max(rDur * math.min(durRatio, 1.0), 1e-3)));
  final completeness = _clamp(100.0 * math.pow(1.0 - missFrac, 1.15) * math.exp(-0.5 * skipFrac - 0.3 * shortfall));

  final overall = _clamp(kWeights['sounds']! * sounds +
      kWeights['rhythm']! * rhythm +
      kWeights['pitch']! * pitch +
      kWeights['vowel']! * vowel +
      kWeights['completeness']! * completeness);

  final errors = segmentErrors(path, rT, mfccLocal, rF0, uF0, rV, uV, tempo, missing);
  return ShabdaScore(
    overall: _r1(overall),
    sounds: _r1(sounds),
    rhythm: _r1(rhythm),
    pitch: _r1(pitch),
    vowel: _r1(vowel),
    completeness: _r1(completeness),
    raw: {
      'sounds_dist': soundsDist,
      'dtw_norm_cost': aln.normCost,
      'dur_ratio': durRatio,
      'rhythm_dev': rhythmDev,
      'rhythm_var': rhythmVar,
      'abs_cents': absCents,
      'shape_cents': shapeCents,
      'median_cents': medianCents,
      'register_adapted': registerAdapted,
      'voicing_agree': voicingAgree,
      'vowel_raw': vowelRaw,
      'miss_frac': missFrac,
      'skip_frac': skipFrac,
      'shortfall': shortfall,
      'n_path': np,
      'ref_speech_s': rDur,
      'usr_speech_s': uDur,
      'ref_f0_median': rMed,
      'usr_f0_median': uMed,
    },
    errors: errors,
    vowelCompares: compares,
    path: path,
    refStart: rm.times.first,
    refEnd: rm.times.last,
    mfccLocal: mfccLocal,
    tempo: tempo,
    pathRefTimes: rT,
    missing: missing,
  );
}

/// Port of `_segment_errors`: 0.28 s windows of the reference.
List<SegmentError> segmentErrors(List<(int, int)> path, List<double> rT, List<double> mfccLocal, List<double> rF0,
    List<double> uF0, List<bool> rV, List<bool> uV, List<double> tempo, List<bool> missing) {
  if (path.isEmpty) return [];
  const win = 0.28;
  final t0 = rT.first, t1 = rT.last;
  final errors = <SegmentError>[];
  var t = t0;
  while (t < t1) {
    final te = math.min(t1, t + win);
    final sel = [
      for (var k = 0; k < rT.length; k++)
        if (rT[k] >= t && rT[k] < te) k
    ];
    if (sel.length < 4) {
      t = te;
      continue;
    }
    String? kind;
    var detail = '';
    var sev = 0.0;
    final loc = mean([for (final k in sel) mfccLocal[k]]);
    if (loc > 1.6) {
      kind = 'sounds';
      detail = 'this part does not match the reference sounds';
      sev = math.min(1.0, (loc - 1.0) / 2.0);
    }
    final mfr = sel.where((k) => missing[k]).length / sel.length;
    if (mfr > 0.45) {
      kind = 'missing';
      detail = 'this part is quiet or missing in the attempt';
      sev = math.max(sev, mfr);
    }
    if (tempo.isNotEmpty) {
      final lt = [for (final k in sel) tempo[path[k].$1.clamp(0, tempo.length - 1)]];
      final med = median(lt);
      if (med >= 1.45) {
        kind ??= 'timing';
        detail = 'this part was drawn out / slower than the reference';
        sev = math.max(sev, math.min(1.0, med - 1.0));
      } else if (med <= 0.68) {
        kind ??= 'timing';
        detail = 'this part was rushed';
        sev = math.max(sev, math.min(1.0, 1.0 - med));
      }
    }
    final b = [
      for (final k in sel)
        if (rV[k] && uV[k] && rF0[k] >= 60 && uF0[k] >= 60) k
    ];
    if (b.length >= 4) {
      final cents = [for (final k in b) 1200.0 * log2(uF0[k] / rF0[k])];
      if (b.length >= 6) {
        final rMove = 1200 * log2(rF0[b.last] / math.max(rF0[b.first], 60));
        final uMove = 1200 * log2(uF0[b.last] / math.max(uF0[b.first], 60));
        if (rMove.abs() > 80 && uMove.abs() < rMove.abs() * 0.35) {
          kind ??= 'pitch';
          detail = rMove > 0
              ? 'pitch is flat here where the reference rises'
              : 'pitch is flat here where the reference falls';
          sev = math.max(sev, 0.55);
        }
      }
      final mc = median(cents);
      if (mc.abs() > 250) {
        kind ??= 'pitch';
        detail = mc > 0 ? 'pitch is well above the reference here' : 'pitch is well below the reference here';
        sev = math.max(sev, math.min(1.0, mc.abs() / 400));
      }
    }
    if (kind != null && sev >= 0.35) {
      if (errors.isNotEmpty && errors.last.kind == kind && (errors.last.end - t).abs() < 0.02) {
        errors.last.end = te;
        errors.last.severity = math.max(errors.last.severity, sev);
      } else {
        errors.add(SegmentError(t, te, kind, detail, (sev * 100).round() / 100));
      }
    }
    t = te;
  }
  errors.sort((a, b) => b.severity.compareTo(a.severity));
  final top = errors.take(8).toList()..sort((a, b) => a.start.compareTo(b.start));
  return top;
}
