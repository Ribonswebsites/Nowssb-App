/// Feature extraction for the Shabda scorer — a line-for-line port of
/// shabda-score/src/audio_features.py (the Python prototype): MFCC on a
/// 26-band mel bank, frame energy, YIN pitch, an energy VAD with an adaptive
/// noise floor, and voiced "vowel-ish" runs.
///
/// 16 kHz mono, 25 ms frames, 10 ms hop. The client's recordings are the only
/// pronunciation reference; nothing here knows any words.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'dsp.dart';

const int kSr = 16000;
const int kWin = 400;
const int kHop = 160;
const int kNfft = 512;
const int kMels = 26;
const int kMfcc = 13;
const int kF0Win = 1024;
const double kFmin = 60.0;
const double kFmax = 500.0;
const double kYinThreshold = 0.12;
const double kPreEmph = 0.97;
const double kHopS = kHop / kSr;

class VowelRun {
  const VowelRun(this.start, this.end);
  final double start;
  final double end;
  double get dur => end - start;
}

class Vad {
  Vad({
    required this.speech,
    required this.intervals,
    required this.speechDur,
    required this.totalDur,
    required this.noiseFloorDb,
    required this.snrDb,
  });
  final List<bool> speech;
  final List<List<double>> intervals;
  final double speechDur;
  final double totalDur;
  final double noiseFloorDb;
  final double snrDb;
}

/// Everything the scorer needs about one recording.
class ShabdaFeatures {
  ShabdaFeatures({
    required this.x,
    required this.duration,
    required this.times,
    required this.mfcc,
    required this.logEnergy,
    required this.energyDb,
    required this.f0,
    required this.f0Conf,
    required this.vad,
    required this.vowels,
    required this.f0Median,
    required this.peak,
  });

  final Float64List x;
  final double duration;
  final List<double> times;

  /// [T][13], c0 included.
  final List<Float64List> mfcc;
  final List<double> logEnergy;
  final List<double> energyDb;
  final List<double> f0;
  final List<double> f0Conf;
  final Vad vad;
  final List<VowelRun> vowels;
  final double f0Median;
  final double peak;

  int get frames => times.length;
}

// ── framing ────────────────────────────────────────────────────────────

int _frameCount(int len, int win, int hop) {
  if (len < win) len = win;
  return 1 + (len - win) ~/ hop;
}

double _sample(Float64List x, int i) => i < x.length ? x[i] : 0.0;

List<double> frameTimes(int len) {
  final n = _frameCount(len, kWin, kHop);
  return [for (var i = 0; i < n; i++) (i * kHop + kWin / 2) / kSr];
}

Float64List _preemph(Float64List x) {
  final y = Float64List(x.length);
  if (x.isEmpty) return y;
  y[0] = x[0];
  for (var i = 1; i < x.length; i++) {
    y[i] = x[i] - kPreEmph * x[i - 1];
  }
  return y;
}

/// Mel filterbank range (see [melFilterbank]).
const double kMelLowHz = 200.0;
const double kMelHighHz = 4000.0;

double hzToMel(double hz) => 2595.0 * log10(1.0 + hz / 700.0);
double melToHz(double mel) => 700.0 * (math.pow(10.0, mel / 2595.0) - 1.0);

List<Float64List> melFilterbank({double alpha = 1.0}) {
  const nBins = kNfft ~/ 2 + 1;
  final warped = alpha != 1.0;
  final a = alpha.clamp(0.67, 1.50).toDouble();
  // The speech band a phone mic reliably carries (200 Hz – 4 kHz), so a
  // different handset, a cheap mic or a speakerphone reads the same.
  final low = hzToMel(kMelLowHz), high = hzToMel(kMelHighHz);
  final bins = <int>[];
  for (var i = 0; i < kMels + 2; i++) {
    final mel = low + (high - low) * i / (kMels + 1);
    var hz = melToHz(mel);
    if (warped) hz = (hz * a).clamp(0.0, kSr / 2.0 - 1.0).toDouble();
    var b = ((kNfft + 1) * hz / kSr).floor();
    b = b.clamp(0, nBins - 1);
    bins.add(b);
  }
  final fb = [for (var m = 0; m < kMels; m++) Float64List(nBins)];
  for (var m = 1; m <= kMels; m++) {
    final l = bins[m - 1];
    var c = bins[m];
    var r = bins[m + 1];
    if (c == l) c = math.min(l + 1, nBins - 1);
    if (r == c) r = math.min(c + 1, nBins - 1);
    if (!warped || c > l) {
      for (var k = l; k < c; k++) {
        fb[m - 1][k] = (k - l) / (c - l);
      }
    }
    if (!warped || r > c) {
      for (var k = c; k < r; k++) {
        fb[m - 1][k] = (r - k) / (r - c);
      }
    }
  }
  for (final row in fb) {
    for (var k = 0; k < nBins; k++) {
      if (row[k] < 0) row[k] = 0;
    }
  }
  return fb;
}

List<Float64List>? _melFb;
final Fft _fft512 = Fft(kNfft);
final Fft _fft2048 = Fft(2 * kF0Win);
final Float64List _hann400 = hannPeriodic(kWin);
final Float64List _hann1024 = hannPeriodic(kF0Win);

/// Static MFCC [T][13] (c0 included), optionally on a warped mel bank.
List<Float64List> mfccOnly(Float64List x, {double freqWarp = 1.0}) {
  final fb = (freqWarp - 1.0).abs() < 0.02 ? (_melFb ??= melFilterbank()) : melFilterbank(alpha: freqWarp);
  final xp = _preemph(x);
  final n = _frameCount(x.length, kWin, kHop);
  final re = Float64List(kNfft), im = Float64List(kNfft);
  const nBins = kNfft ~/ 2 + 1;
  final spec = Float64List(nBins);
  final logMel = Float64List(kMels);
  final out = <Float64List>[];
  for (var f = 0; f < n; f++) {
    final s = f * kHop;
    for (var i = 0; i < kNfft; i++) {
      re[i] = i < kWin ? _sample(xp, s + i) * _hann400[i] : 0.0;
      im[i] = 0.0;
    }
    _fft512.transform(re, im);
    var mx = 0.0;
    for (var k = 0; k < nBins; k++) {
      final p = re[k] * re[k] + im[k] * im[k];
      spec[k] = p;
      if (p > mx) mx = p;
    }
    final floor = 0.01 * mx;
    for (var k = 0; k < nBins; k++) {
      if (spec[k] < floor) spec[k] = floor;
    }
    for (var m = 0; m < kMels; m++) {
      final row = fb[m];
      var acc = 0.0;
      for (var k = 0; k < nBins; k++) {
        acc += spec[k] * row[k];
      }
      logMel[m] = math.log(acc + 1e-10);
    }
    out.add(_dctOrtho(logMel));
  }
  return out;
}

final List<Float64List> _dctBasis = [
  for (var k = 0; k < kMfcc; k++)
    Float64List.fromList([
      for (var i = 0; i < kMels; i++)
        math.cos(math.pi * k * (2 * i + 1) / (2 * kMels)) * (k == 0 ? math.sqrt(1.0 / kMels) : math.sqrt(2.0 / kMels))
    ])
];

Float64List _dctOrtho(Float64List v) {
  final out = Float64List(kMfcc);
  for (var k = 0; k < kMfcc; k++) {
    final b = _dctBasis[k];
    var s = 0.0;
    for (var i = 0; i < kMels; i++) {
      s += v[i] * b[i];
    }
    out[k] = s;
  }
  return out;
}

/// Per-frame RMS of the raw (not pre-emphasised) signal.
List<double> _frameRms(Float64List x) {
  final n = _frameCount(x.length, kWin, kHop);
  return [
    for (var f = 0; f < n; f++)
      () {
        var s = 0.0;
        final st = f * kHop;
        for (var i = 0; i < kWin; i++) {
          final v = _sample(x, st + i);
          s += v * v;
        }
        return math.sqrt(s / kWin + 1e-16);
      }()
  ];
}

// ── pitch (YIN) ────────────────────────────────────────────────────────

class _Yin {
  _Yin(this.f0, this.conf, this.times);
  final List<double> f0;
  final List<double> conf;
  final List<double> times;
}

_Yin _yinF0(Float64List x0) {
  const win = kF0Win, hop = kHop;
  final x = x0.length < win ? (Float64List(win)..setAll(0, x0)) : x0;
  final nFrames = 1 + (x.length - win) ~/ hop;
  final tauMin = math.max(1, kSr ~/ kFmax.toInt());
  final tauMax = math.min(win - 2, kSr ~/ kFmin.toInt());
  final f0 = List<double>.filled(nFrames, 0);
  final conf = List<double>.filled(nFrames, 0);
  final times = [for (var i = 0; i < nFrames; i++) (i * hop + win / 2) / kSr];
  const fpad = 2 * win;
  final re = Float64List(fpad), im = Float64List(fpad);
  final frame = Float64List(win);
  final csum = Float64List(win + 1);
  // Only taus up to tauMax+1 are ever read, but the cumulative mean needs
  // every d[tau] from 1 up to there.
  final need = math.min(win, tauMax + 2);
  final d = Float64List(need);
  final cmnd = Float64List(need);

  for (var i = 0; i < nFrames; i++) {
    final start = i * hop;
    for (var j = 0; j < win; j++) {
      frame[j] = x[start + j] * _hann1024[j];
    }
    for (var j = 0; j < fpad; j++) {
      re[j] = j < win ? frame[j] : 0.0;
      im[j] = 0.0;
    }
    _fft2048.transform(re, im);
    for (var j = 0; j < fpad; j++) {
      re[j] = re[j] * re[j] + im[j] * im[j];
      im[j] = 0.0;
    }
    _fft2048.transform(re, im, inverse: true);
    csum[0] = 0;
    for (var j = 0; j < win; j++) {
      csum[j + 1] = csum[j] + frame[j] * frame[j];
    }
    for (var tau = 0; tau < need; tau++) {
      final acf = re[tau] / fpad;
      final sum1 = csum[win - tau] - csum[0];
      final sum2 = csum[win] - csum[tau];
      var v = sum1 + sum2 - 2.0 * acf;
      if (tau == 0) v = 0.0;
      d[tau] = v < 0 ? 0.0 : v;
    }
    cmnd[0] = 1.0;
    var cs = d[0];
    for (var tau = 1; tau < need; tau++) {
      cs += d[tau];
      cmnd[tau] = d[tau] * tau / (cs + 1e-12);
    }
    int? chosen;
    for (var t = tauMin; t <= tauMax; t++) {
      if (cmnd[t] < kYinThreshold && t + 1 <= tauMax && cmnd[t] <= cmnd[t - 1] && cmnd[t] <= cmnd[t + 1]) {
        chosen = t;
        break;
      }
    }
    if (chosen == null) {
      var best = tauMin;
      for (var t = tauMin + 1; t <= tauMax; t++) {
        if (cmnd[t] < cmnd[best]) best = t;
      }
      if (cmnd[best] < 0.45) chosen = best;
    }
    if (chosen == null) continue;
    var t0 = chosen.toDouble();
    if (chosen >= 1 && chosen < win - 1) {
      final a = cmnd[chosen - 1], b = cmnd[chosen], c = cmnd[chosen + 1];
      final den = 2 * b - a - c;
      if (den.abs() > 1e-12) t0 = chosen + (a - c) / (2 * den);
    }
    f0[i] = kSr / t0;
    conf[i] = (1.0 - cmnd[chosen]).clamp(0.0, 1.0).toDouble();
  }

  // Median filter to kill isolated jumps; fill holes of <= 5 frames.
  final voiced = [for (final c in conf) c >= 0.4];
  if (voiced.any((v) => v)) {
    final f0m = [for (var i = 0; i < nFrames; i++) voiced[i] ? f0[i] : double.nan];
    final valid = [for (final v in f0m) !v.isNaN];
    if (valid.where((v) => v).length >= 3) {
      final f0i = List<double>.from(f0m);
      final holes = <List<int>>[];
      var inHole = false;
      var s = 0;
      for (var i = 0; i < valid.length; i++) {
        if (!valid[i] && !inHole) {
          inHole = true;
          s = i;
        } else if (valid[i] && inHole) {
          inHole = false;
          holes.add([s, i]);
        }
      }
      if (inHole) holes.add([s, valid.length]);
      for (final h in holes) {
        final a = h[0], b = h[1];
        if (b - a <= 5 && a > 0 && b < valid.length) {
          for (var k = a; k < b; k++) {
            f0i[k] = f0m[a - 1] + (f0m[b] - f0m[a - 1]) * (k - (a - 1)) / (b - (a - 1));
            conf[k] = math.max(conf[k], 0.35);
          }
        }
      }
      final nan = [for (final v in f0i) v.isNaN];
      final tmp = [for (var i = 0; i < nFrames; i++) nan[i] ? 0.0 : f0i[i]];
      final med = medfilt(tmp, 5);
      for (var i = 0; i < nFrames; i++) {
        if (nan[i]) {
          med[i] = 0;
          conf[i] = math.min(conf[i], 0.2);
        }
        f0[i] = med[i];
      }
    }
  }
  return _Yin(f0, conf, times);
}

// ── VAD ────────────────────────────────────────────────────────────────

List<bool> fillGaps(List<bool> mask, int maxGap) {
  final out = List<bool>.from(mask);
  final n = out.length;
  var i = 0;
  while (i < n) {
    if (!out[i]) {
      var j = i;
      while (j < n && !out[j]) {
        j++;
      }
      if (i > 0 && j < n && (j - i) <= maxGap) {
        for (var k = i; k < j; k++) {
          out[k] = true;
        }
      }
      i = j;
    } else {
      i++;
    }
  }
  return out;
}

List<bool> dropShort(List<bool> mask, int minLen) {
  final out = List<bool>.from(mask);
  final n = out.length;
  var i = 0;
  while (i < n) {
    if (out[i]) {
      var j = i;
      while (j < n && out[j]) {
        j++;
      }
      if (j - i < minLen) {
        for (var k = i; k < j; k++) {
          out[k] = false;
        }
      }
      i = j;
    } else {
      i++;
    }
  }
  return out;
}

List<bool> _erode(List<bool> mask, int pad) {
  if (pad <= 0) return List<bool>.from(mask);
  final n = mask.length;
  final out = List<bool>.filled(n, false);
  for (var i = 0; i < n; i++) {
    final a = math.max(0, i - pad), b = math.min(n, i + pad + 1);
    var all = true;
    for (var k = a; k < b; k++) {
      if (!mask[k]) {
        all = false;
        break;
      }
    }
    out[i] = all;
  }
  return out;
}

List<List<double>> runsToIntervals(List<bool> mask, List<double> times) {
  final out = <List<double>>[];
  final n = mask.length;
  var i = 0;
  while (i < n) {
    if (mask[i]) {
      var j = i;
      while (j < n && mask[j]) {
        j++;
      }
      out.add([math.max(0.0, times[i] - kHopS / 2), times[j - 1] + kHopS / 2]);
      i = j;
    } else {
      i++;
    }
  }
  return out;
}

Vad vadSegments(List<double> energyDb, List<double> times, int nSamples) {
  final sorted = List<double>.from(energyDb)..sort();
  var floor = median(sorted.sublist(0, math.max(1, (0.2 * sorted.length).toInt())));
  final p20 = percentile(energyDb, 20);
  floor = math.min(floor, p20);
  final peak = percentile(energyDb, 97);
  var thresh = floor + 11.0;
  if (thresh > peak - 8.0) thresh = math.max(floor + 3.0, peak - 10.0);
  thresh = math.min(thresh, peak - 7.0);
  final onTh = thresh, offTh = thresh - 3.0;
  var speech = List<bool>.filled(energyDb.length, false);
  var active = false;
  for (var i = 0; i < energyDb.length; i++) {
    final e = energyDb[i];
    if (!active && e >= onTh) {
      active = true;
    } else if (active && e < offTh) {
      active = false;
    }
    speech[i] = active;
  }
  speech = fillGaps(speech, 22);
  speech = dropShort(speech, 8);
  var intervals = runsToIntervals(speech, times);
  if (intervals.isNotEmpty) {
    final peaks = <double>[];
    for (final iv in intervals) {
      var mx = -120.0;
      var any = false;
      for (var i = 0; i < times.length; i++) {
        if (times[i] >= iv[0] && times[i] <= iv[1]) {
          if (!any || energyDb[i] > mx) mx = energyDb[i];
          any = true;
        }
      }
      peaks.add(any ? mx : -120.0);
    }
    final loudest = peaks.reduce(math.max);
    final keep = [for (final p in peaks) p >= loudest - 15.0];
    if (keep.any((k) => k) && !keep.every((k) => k)) {
      speech = List<bool>.filled(speech.length, false);
      final kept = <List<double>>[];
      for (var k = 0; k < intervals.length; k++) {
        if (!keep[k]) continue;
        kept.add(intervals[k]);
        for (var i = 0; i < times.length; i++) {
          if (times[i] >= intervals[k][0] && times[i] <= intervals[k][1]) speech[i] = true;
        }
      }
      intervals = kept;
    }
  }
  var speechDur = 0.0;
  for (final iv in intervals) {
    speechDur += iv[1] - iv[0];
  }
  final total = nSamples / kSr;
  var eroded = _erode(speech, 4);
  var silenceCore = _erode([for (final s in speech) !s], 4);
  if (!eroded.any((v) => v)) eroded = speech;
  if (!silenceCore.any((v) => v)) silenceCore = [for (final s in speech) !s];
  double meanRms(List<bool> mask) {
    var s = 0.0;
    var c = 0;
    for (var i = 0; i < mask.length; i++) {
      if (!mask[i]) continue;
      final r = math.pow(10.0, energyDb[i] / 20.0).toDouble();
      s += r * r;
      c++;
    }
    return c == 0 ? 1e-12 : math.sqrt(s / c);
  }

  final snr = 20.0 * log10((meanRms(eroded) + 1e-12) / (meanRms(silenceCore) + 1e-12));
  return Vad(
    speech: speech,
    intervals: intervals,
    speechDur: speechDur,
    totalDur: total,
    noiseFloorDb: floor,
    snrDb: snr,
  );
}

List<VowelRun> vowelRuns(
    List<double> f0, List<double> conf, List<double> energyDb, List<double> times, List<bool> speechMask) {
  final n = [f0.length, energyDb.length, speechMask.length, times.length].reduce(math.min);
  final sp = <double>[
    for (var i = 0; i < n; i++)
      if (speechMask[i]) energyDb[i]
  ];
  final medS = sp.isNotEmpty ? median(sp) : median(energyDb.sublist(0, n));
  var voiced = [
    for (var i = 0; i < n; i++)
      conf[i] >= 0.4 && f0[i] >= kFmin && f0[i] <= kFmax && speechMask[i] && energyDb[i] >= medS - 8.0
  ];
  voiced = fillGaps(voiced, 3);
  voiced = dropShort(voiced, 4);
  final runs = <VowelRun>[];
  for (final iv in runsToIntervals(voiced, times.sublist(0, n))) {
    var any = false;
    for (var i = 0; i < n; i++) {
      if (times[i] >= iv[0] && times[i] <= iv[1] && voiced[i]) {
        any = true;
        break;
      }
    }
    if (any) runs.add(VowelRun(iv[0], iv[1]));
  }
  return runs;
}

/// Full feature extraction (port of `extract`).
ShabdaFeatures extractFeatures(Float64List x) {
  final duration = x.length / kSr;
  final times = frameTimes(x.length);
  final t = times.length;
  final mfcc = mfccOnly(x);
  final rms = _frameRms(x);
  final logE = [for (final r in rms) math.log(r + 1e-10)];
  final energyDb = [for (final r in rms) 20.0 * log10(r + 1e-12)];
  final yin = _yinF0(x);
  List<double> fit(List<double> arr) {
    if (arr.length == t) return arr;
    return [for (final tt in times) interp(tt, yin.times.sublist(0, arr.length), arr)];
  }

  final f0a = fit(yin.f0);
  final confA = fit(yin.conf);
  final vad = vadSegments(energyDb, times, x.length);
  final speech = vad.speech;
  final vowels = vowelRuns(f0a, confA, energyDb, times, speech);
  final vf = <double>[
    for (var i = 0; i < t; i++)
      if (confA[i] >= 0.4 && f0a[i] >= kFmin && f0a[i] <= kFmax && speech[i]) f0a[i]
  ];
  var peak = 0.0;
  for (final v in x) {
    if (v.abs() > peak) peak = v.abs();
  }
  return ShabdaFeatures(
    x: x,
    duration: duration,
    times: times,
    mfcc: mfcc,
    logEnergy: logE,
    energyDb: energyDb,
    f0: f0a,
    f0Conf: confA,
    vad: vad,
    vowels: vowels,
    f0Median: vf.length >= 5 ? median(vf) : 0.0,
    peak: peak,
  );
}

/// Frame range covering speech, with a 50 ms pad (port of `speech_slice`).
(int, int) speechSlice(ShabdaFeatures f, {double pad = 0.05}) {
  final iv = f.vad.intervals;
  if (iv.isEmpty) return (0, f.frames);
  final start = math.max(0.0, iv.first[0] - pad);
  final end = math.min(f.duration, iv.last[1] + pad);
  var i0 = searchLeft(f.times, start);
  var i1 = searchRight(f.times, end);
  i0 = math.max(0, i0);
  i1 = math.min(f.frames, math.max(i0 + 1, i1));
  return (i0, i1);
}
