/// Small numeric helpers for the Shabda scorer: FFT, windows, DCT and the
/// numpy / scipy functions the Python prototype (shabda-score) relies on,
/// with the same edge behaviour so the Dart port reproduces its numbers.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Periodic Hann window (scipy `get_window('hann', n, fftbins=True)`).
Float64List hannPeriodic(int n) {
  final w = Float64List(n);
  for (var i = 0; i < n; i++) {
    w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / n);
  }
  return w;
}

/// In-place iterative radix-2 complex FFT. [re]/[im] length must be a power
/// of two. [inverse] computes the unscaled inverse transform.
class Fft {
  Fft(this.n)
      : _cos = Float64List(n ~/ 2),
        _sin = Float64List(n ~/ 2),
        _rev = Int32List(n) {
    if (n & (n - 1) != 0) throw ArgumentError('FFT size must be a power of two');
    for (var i = 0; i < n ~/ 2; i++) {
      _cos[i] = math.cos(2 * math.pi * i / n);
      _sin[i] = math.sin(2 * math.pi * i / n);
    }
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var r = 0;
      var x = i;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (x & 1);
        x >>= 1;
      }
      _rev[i] = r;
    }
  }

  final int n;
  final Float64List _cos;
  final Float64List _sin;
  final Int32List _rev;

  void transform(Float64List re, Float64List im, {bool inverse = false}) {
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    final sign = inverse ? 1.0 : -1.0;
    for (var size = 2; size <= n; size <<= 1) {
      final half = size >> 1;
      final step = n ~/ size;
      for (var start = 0; start < n; start += size) {
        var k = 0;
        for (var j = start; j < start + half; j++) {
          final wr = _cos[k];
          final wi = sign * _sin[k];
          final l = j + half;
          final xr = re[l] * wr - im[l] * wi;
          final xi = re[l] * wi + im[l] * wr;
          re[l] = re[j] - xr;
          im[l] = im[j] - xi;
          re[j] += xr;
          im[j] += xi;
          k += step;
        }
      }
    }
  }
}

/// numpy.percentile with the default linear interpolation.
double percentile(List<double> values, double p) {
  if (values.isEmpty) return double.nan;
  final s = List<double>.from(values)..sort();
  final pos = p / 100.0 * (s.length - 1);
  final lo = pos.floor();
  final hi = math.min(lo + 1, s.length - 1);
  final f = pos - lo;
  return s[lo] + (s[hi] - s[lo]) * f;
}

double median(List<double> values) => percentile(values, 50);

double mean(List<double> v) {
  if (v.isEmpty) return double.nan;
  var s = 0.0;
  for (final x in v) {
    s += x;
  }
  return s / v.length;
}

/// Population standard deviation (numpy default ddof=0).
double stdDev(List<double> v) {
  if (v.isEmpty) return double.nan;
  final m = mean(v);
  var s = 0.0;
  for (final x in v) {
    s += (x - m) * (x - m);
  }
  return math.sqrt(s / v.length);
}

/// numpy.interp for increasing [xp]: clamps outside the range.
double interp(double x, List<double> xp, List<double> fp) {
  final n = xp.length;
  if (n == 0) return 0;
  if (x <= xp[0]) return fp[0];
  if (x >= xp[n - 1]) return fp[n - 1];
  var lo = 0, hi = n - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) >> 1;
    if (xp[mid] <= x) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final dx = xp[hi] - xp[lo];
  if (dx == 0) return fp[hi];
  return fp[lo] + (fp[hi] - fp[lo]) * (x - xp[lo]) / dx;
}

/// scipy.signal.medfilt with zero padding at the edges.
Float64List medfilt(List<double> x, int k) {
  final n = x.length;
  final h = k ~/ 2;
  final out = Float64List(n);
  final buf = List<double>.filled(k, 0);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < k; j++) {
      final idx = i - h + j;
      buf[j] = (idx < 0 || idx >= n) ? 0.0 : x[idx];
    }
    final s = List<double>.from(buf)..sort();
    out[i] = s[h];
  }
  return out;
}

/// numpy.searchsorted(a, v, side='left').
int searchLeft(List<double> a, double v) {
  var lo = 0, hi = a.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (a[mid] < v) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// numpy.searchsorted(a, v, side='right').
int searchRight(List<double> a, double v) {
  var lo = 0, hi = a.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (a[mid] <= v) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

double log2(double x) => math.log(x) / math.ln2;
double log10(double x) => math.log(x) / math.ln10;
