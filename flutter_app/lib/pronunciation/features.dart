/// MFCC front end for audio-to-audio pronunciation comparison.
/// 25 ms Hamming frames, 10 ms hop, 512-point FFT, 26 mel bands, 13 cepstra
/// (c0 dropped), per-utterance mean/variance normalisation so microphone and
/// loudness differences between the client's take and the user's take matter
/// less than the sounds themselves.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'wav.dart';

const int _frame = 400; // 25 ms @ 16 kHz
const int hopSamples = 160; // 10 ms
const int _nfft = 512;
const int _mels = 26;
const int numCeps = 12;

class Features {
  Features(this.mfcc, this.energy);

  /// frames × [numCeps] (+ deltas), normalised.
  final List<Float64List> mfcc;

  /// Log energy per frame (un-normalised), used for silence trim and
  /// syllable boundaries.
  final Float64List energy;

  int get length => mfcc.length;
}

/// Trims leading/trailing silence using frame energy relative to the peak.
Float32List trimSilence(Float32List x, {double dbBelowPeak = 35}) {
  if (x.isEmpty) return x;
  const win = 320;
  final n = x.length ~/ win;
  if (n < 3) return x;
  final e = List<double>.filled(n, 0);
  var peak = 1e-12;
  for (var i = 0; i < n; i++) {
    var s = 0.0;
    for (var j = i * win; j < (i + 1) * win; j++) {
      s += x[j] * x[j];
    }
    e[i] = s / win;
    peak = math.max(peak, e[i]);
  }
  final floor = peak * math.pow(10, -dbBelowPeak / 10);
  var a = 0, b = n - 1;
  while (a < n && e[a] < floor) {
    a++;
  }
  while (b > a && e[b] < floor) {
    b--;
  }
  if (a >= b) return x;
  final start = math.max(0, (a - 2) * win);
  final end = math.min(x.length, (b + 3) * win);
  return Float32List.sublistView(x, start, end);
}

/// Peak RMS of the signal, for "too quiet / nothing heard" detection.
double peakRms(Float32List x) {
  const win = 320;
  var peak = 0.0;
  for (var i = 0; i + win <= x.length; i += win) {
    var s = 0.0;
    for (var j = i; j < i + win; j++) {
      s += x[j] * x[j];
    }
    peak = math.max(peak, math.sqrt(s / win));
  }
  return peak;
}

List<List<double>>? _bank;
List<double>? _hamming;

List<List<double>> _melBank() {
  if (_bank != null) return _bank!;
  double hz2mel(double f) => 2595 * math.log(1 + f / 700) / math.ln10;
  double mel2hz(double m) => 700 * (math.pow(10, m / 2595) - 1);
  final lo = hz2mel(60), hi = hz2mel(7600);
  final pts = [for (var i = 0; i < _mels + 2; i++) mel2hz(lo + (hi - lo) * i / (_mels + 1))];
  final bins = [for (final f in pts) (f * _nfft / kScoreRate).floor()];
  final bank = <List<double>>[];
  for (var m = 1; m <= _mels; m++) {
    final row = List<double>.filled(_nfft ~/ 2 + 1, 0);
    for (var k = bins[m - 1]; k < bins[m]; k++) {
      row[k] = (k - bins[m - 1]) / math.max(1, bins[m] - bins[m - 1]);
    }
    for (var k = bins[m]; k < bins[m + 1]; k++) {
      row[k] = (bins[m + 1] - k) / math.max(1, bins[m + 1] - bins[m]);
    }
    bank.add(row);
  }
  return _bank = bank;
}

void _fft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      var t = re[i];
      re[i] = re[j];
      re[j] = t;
      t = im[i];
      im[i] = im[j];
      im[j] = t;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final a = i + k, b = i + k + len ~/ 2;
        final tr = re[b] * cr - im[b] * ci;
        final ti = re[b] * ci + im[b] * cr;
        re[b] = re[a] - tr;
        im[b] = im[a] - ti;
        re[a] += tr;
        im[a] += ti;
        final ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
}

Features extract(Float32List x) {
  final bank = _melBank();
  final ham = _hamming ??= [
    for (var i = 0; i < _frame; i++) 0.54 - 0.46 * math.cos(2 * math.pi * i / (_frame - 1))
  ];
  final n = x.length < _frame ? 1 : 1 + (x.length - _frame) ~/ hopSamples;
  final ceps = <Float64List>[];
  final energy = Float64List(n);
  final re = Float64List(_nfft), im = Float64List(_nfft);
  final logMel = Float64List(_mels);
  for (var f = 0; f < n; f++) {
    re.fillRange(0, _nfft, 0);
    im.fillRange(0, _nfft, 0);
    var e = 0.0;
    for (var i = 0; i < _frame; i++) {
      final idx = f * hopSamples + i;
      if (idx >= x.length) break;
      final prev = idx > 0 ? x[idx - 1] : 0.0;
      final v = (x[idx] - 0.97 * prev) * ham[i];
      re[i] = v;
      e += x[idx] * x[idx];
    }
    energy[f] = math.log(e + 1e-10);
    _fft(re, im);
    for (var m = 0; m < _mels; m++) {
      var s = 0.0;
      final row = bank[m];
      for (var k = 0; k <= _nfft ~/ 2; k++) {
        final w = row[k];
        if (w != 0) s += w * (re[k] * re[k] + im[k] * im[k]);
      }
      logMel[m] = math.log(s + 1e-10);
    }
    final c = Float64List(numCeps);
    for (var k = 1; k <= numCeps; k++) {
      var s = 0.0;
      for (var m = 0; m < _mels; m++) {
        s += logMel[m] * math.cos(math.pi * k * (m + 0.5) / _mels);
      }
      c[k - 1] = s;
    }
    ceps.add(c);
  }
  // Mean / variance normalisation per coefficient.
  for (var k = 0; k < numCeps; k++) {
    var mean = 0.0;
    for (final c in ceps) {
      mean += c[k];
    }
    mean /= ceps.length;
    var v = 0.0;
    for (final c in ceps) {
      v += (c[k] - mean) * (c[k] - mean);
    }
    final sd = math.sqrt(v / ceps.length) + 1e-6;
    for (final c in ceps) {
      c[k] = (c[k] - mean) / sd;
    }
  }
  // Append deltas (slope over ±2 frames).
  final out = <Float64List>[];
  for (var t = 0; t < ceps.length; t++) {
    final row = Float64List(numCeps * 2);
    for (var k = 0; k < numCeps; k++) {
      row[k] = ceps[t][k];
      var num = 0.0;
      for (var d = 1; d <= 2; d++) {
        final a = ceps[math.min(ceps.length - 1, t + d)][k];
        final b = ceps[math.max(0, t - d)][k];
        num += d * (a - b);
      }
      row[numCeps + k] = num / 10;
    }
    out.add(row);
  }
  return Features(out, energy);
}
