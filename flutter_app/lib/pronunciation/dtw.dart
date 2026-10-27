/// Dynamic time warping between two MFCC sequences, so a slower or faster
/// take still lines up with the reference sound by sound.
library;

import 'dart:math' as math;
import 'dart:typed_data';

class DtwResult {
  DtwResult(this.cost, this.path);

  /// Mean frame distance along the best path.
  final double cost;

  /// (refFrame, takeFrame) pairs from start to end.
  final List<(int, int)> path;
}

double frameDistance(Float64List a, Float64List b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    s += d * d;
  }
  return math.sqrt(s / a.length);
}

/// Classic DTW with a Sakoe–Chiba band ([band] as a fraction of the longer
/// sequence) and symmetric steps.
DtwResult dtw(List<Float64List> ref, List<Float64List> take, {double band = 0.4}) {
  final n = ref.length, m = take.length;
  if (n == 0 || m == 0) return DtwResult(double.infinity, const []);
  final w = math.max((math.max(n, m) * band).ceil(), (n - m).abs() + 2);
  const inf = double.infinity;
  final acc = List.generate(n, (_) => Float64List(m)..fillRange(0, m, inf));
  final steps = List.generate(n, (_) => Uint8List(m)); // 0 diag,1 up,2 left
  for (var i = 0; i < n; i++) {
    final c = (i * m / n).round();
    final lo = math.max(0, c - w), hi = math.min(m - 1, c + w);
    for (var j = lo; j <= hi; j++) {
      final d = frameDistance(ref[i], take[j]);
      if (i == 0 && j == 0) {
        acc[i][j] = d;
        continue;
      }
      var best = inf;
      var s = 0;
      if (i > 0 && j > 0 && acc[i - 1][j - 1] < best) {
        best = acc[i - 1][j - 1];
        s = 0;
      }
      if (i > 0 && acc[i - 1][j] < best) {
        best = acc[i - 1][j];
        s = 1;
      }
      if (j > 0 && acc[i][j - 1] < best) {
        best = acc[i][j - 1];
        s = 2;
      }
      acc[i][j] = best + d;
      steps[i][j] = s;
    }
  }
  if (acc[n - 1][m - 1] == inf) return DtwResult(inf, const []);
  final path = <(int, int)>[];
  var i = n - 1, j = m - 1;
  while (true) {
    path.add((i, j));
    if (i == 0 && j == 0) break;
    final s = steps[i][j];
    if (i == 0) {
      j--;
    } else if (j == 0) {
      i--;
    } else if (s == 0) {
      i--;
      j--;
    } else if (s == 1) {
      i--;
    } else {
      j--;
    }
  }
  final rev = path.reversed.toList();
  var total = 0.0;
  for (final (a, b) in rev) {
    total += frameDistance(ref[a], take[b]);
  }
  return DtwResult(total / rev.length, rev);
}
