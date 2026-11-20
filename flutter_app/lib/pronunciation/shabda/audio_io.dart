/// Getting a phone recording ready for the Shabda scorer: WAV decode (any
/// PCM / float format, any channel count), a windowed-sinc resampler to
/// 16 kHz, DC removal, a spectral noise gate and the checks that turn a bad
/// take into a clear message instead of a made-up score.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'dsp.dart';
import 'shabda_features.dart' show kSr;

class AudioFormatError implements Exception {
  AudioFormatError(this.reason);
  final String reason;
  @override
  String toString() => 'AudioFormatError: $reason';
}

class DecodedAudio {
  DecodedAudio(this.samples, this.sampleRate);
  final Float64List samples;
  final int sampleRate;
}

/// Decodes a RIFF/WAVE file to mono floats in -1..1 at its own rate.
DecodedAudio decodeWavBytes(Uint8List bytes) {
  bool tag(int at, String s) {
    if (at + 4 > bytes.length) return false;
    for (var i = 0; i < 4; i++) {
      if (bytes[at + i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  if (!tag(0, 'RIFF') || !tag(8, 'WAVE')) throw AudioFormatError('not a WAV file');
  final d = ByteData.sublistView(bytes);
  var p = 12;
  int? format, channels, rate, bits;
  int? dataStart, dataLen;
  while (p + 8 <= bytes.length) {
    var size = d.getUint32(p + 4, Endian.little);
    final body = p + 8;
    if (tag(p, 'fmt ')) {
      format = d.getUint16(body, Endian.little);
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
      bits = d.getUint16(body + 14, Endian.little);
      if (format == 0xFFFE && size >= 26) format = d.getUint16(body + 24, Endian.little);
    } else if (tag(p, 'data')) {
      dataStart = body;
      // A recorder that was stopped abruptly may leave 0 / 0xFFFFFFFF here.
      if (size == 0 || body + size > bytes.length) size = bytes.length - body;
      dataLen = size;
      break;
    }
    p = body + size + (size.isOdd ? 1 : 0);
  }
  if (format == null || channels == null || rate == null || bits == null || dataStart == null) {
    throw AudioFormatError('missing fmt or data chunk');
  }
  if (!(format == 1 || (format == 3 && (bits == 32 || bits == 64)))) {
    throw AudioFormatError('compressed WAV (format $format)');
  }
  final bytesPer = bits ~/ 8;
  if (bytesPer < 1 || bytesPer > 8 || channels < 1 || rate < 4000) throw AudioFormatError('bad WAV header');
  final frames = dataLen! ~/ (bytesPer * channels);
  final out = Float64List(frames);
  for (var i = 0; i < frames; i++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      final o = dataStart + (i * channels + c) * bytesPer;
      double v;
      if (format == 3) {
        v = bytesPer == 8 ? d.getFloat64(o, Endian.little) : d.getFloat32(o, Endian.little);
      } else if (bytesPer == 1) {
        v = (d.getUint8(o) - 128) / 128.0;
      } else if (bytesPer == 2) {
        v = d.getInt16(o, Endian.little) / 32768.0;
      } else if (bytesPer == 3) {
        var x = d.getUint8(o) | (d.getUint8(o + 1) << 8) | (d.getUint8(o + 2) << 16);
        if (x & 0x800000 != 0) x -= 0x1000000;
        v = x / 8388608.0;
      } else {
        v = d.getInt32(o, Endian.little) / 2147483648.0;
      }
      sum += v;
    }
    out[i] = sum / channels;
  }
  return DecodedAudio(out, rate);
}

/// Band-limited resampling (Hann-windowed sinc, 16 zero crossings).
Float64List resampleTo(Float64List x, int from, {int to = kSr}) {
  if (from == to || x.isEmpty) return x;
  final ratio = to / from;
  final n = (x.length * ratio).floor();
  final out = Float64List(n);
  final cutoff = math.min(1.0, ratio) * 0.95; // relative to the input Nyquist
  const zc = 16;
  final halfWidth = zc / cutoff;
  for (var i = 0; i < n; i++) {
    final t = i / ratio;
    final c = t.floor();
    final lo = (t - halfWidth).ceil();
    final hi = (t + halfWidth).floor();
    var acc = 0.0, wsum = 0.0;
    for (var j = math.max(0, lo); j <= math.min(x.length - 1, hi); j++) {
      final dx = t - j;
      final arg = dx * cutoff;
      final sinc = arg.abs() < 1e-9 ? 1.0 : math.sin(math.pi * arg) / (math.pi * arg);
      final win = 0.5 + 0.5 * math.cos(math.pi * dx / halfWidth);
      final w = sinc * win;
      acc += x[j] * w;
      wsum += w;
    }
    out[i] = wsum.abs() > 1e-9 ? acc / wsum : x[math.min(c, x.length - 1)];
  }
  return out;
}

/// Bytes of a WAV recording → 16 kHz mono.
Float64List wavTo16k(Uint8List bytes) {
  final a = decodeWavBytes(bytes);
  return resampleTo(a.samples, a.sampleRate);
}

/// Removes DC and very low rumble (one-pole high-pass at ~60 Hz).
Float64List highPass(Float64List x, {double hz = 60}) {
  if (x.isEmpty) return x;
  final rc = 1.0 / (2 * math.pi * hz);
  const dt = 1.0 / kSr;
  final a = rc / (rc + dt);
  final y = Float64List(x.length);
  var prevX = x[0], prevY = 0.0;
  for (var i = 1; i < x.length; i++) {
    prevY = a * (prevY + x[i] - prevX);
    prevX = x[i];
    y[i] = prevY;
  }
  return y;
}

/// Spectral noise gate for the user's microphone take.
///
/// The noise spectrum is the average of the quietest 15 % of 32 ms frames.
/// Every bin is attenuated by a Wiener-style gain (over-subtraction 1.6,
/// floor −20 dB), smoothed over time so speech onsets are not chewed off.
/// Returns the signal unchanged when it is already clean (> 35 dB SNR).
Float64List spectralGate(Float64List x, {double floorDb = -20}) {
  const n = 512, hop = 128;
  if (x.length < n * 4) return x;
  final fft = Fft(n);
  final win = hannPeriodic(n);
  final frames = 1 + (x.length - n) ~/ hop;
  const bins = n ~/ 2 + 1;
  final mags = List.generate(frames, (_) => Float64List(bins));
  final phRe = List.generate(frames, (_) => Float64List(bins));
  final phIm = List.generate(frames, (_) => Float64List(bins));
  final energy = Float64List(frames);
  final re = Float64List(n), im = Float64List(n);
  for (var f = 0; f < frames; f++) {
    for (var i = 0; i < n; i++) {
      re[i] = x[f * hop + i] * win[i];
      im[i] = 0;
    }
    fft.transform(re, im);
    var e = 0.0;
    for (var k = 0; k < bins; k++) {
      final p = re[k] * re[k] + im[k] * im[k];
      mags[f][k] = p;
      phRe[f][k] = re[k];
      phIm[f][k] = im[k];
      e += p;
    }
    energy[f] = e;
  }
  final order = List<int>.generate(frames, (i) => i)..sort((a, b) => energy[a].compareTo(energy[b]));
  final quiet = order.take(math.max(4, (frames * 0.15).round())).toList();
  final noise = Float64List(bins);
  for (final f in quiet) {
    for (var k = 0; k < bins; k++) {
      noise[k] += mags[f][k] / quiet.length;
    }
  }
  final loud = order.skip((frames * 0.9).floor()).toList();
  var loudE = 0.0;
  for (final f in loud) {
    loudE += energy[f] / math.max(1, loud.length);
  }
  var noiseE = 0.0;
  for (final v in noise) {
    noiseE += v;
  }
  if (noiseE <= 0 || 10 * log10(loudE / noiseE) > 35) return x;

  final gFloor = math.pow(10, floorDb / 20).toDouble();
  final out = Float64List(x.length);
  final norm = Float64List(x.length);
  final prevGain = Float64List(bins)..fillRange(0, bins, 1.0);
  for (var f = 0; f < frames; f++) {
    for (var k = 0; k < bins; k++) {
      final p = mags[f][k];
      var g = p <= 0 ? gFloor : math.sqrt(math.max(0.0, 1.0 - 1.6 * noise[k] / p));
      if (g < gFloor) g = gFloor;
      // fast attack, slower release
      g = g > prevGain[k] ? g : 0.6 * g + 0.4 * prevGain[k];
      prevGain[k] = g;
      re[k] = phRe[f][k] * g;
      im[k] = phIm[f][k] * g;
      if (k > 0 && k < n ~/ 2) {
        re[n - k] = re[k];
        im[n - k] = -im[k];
      }
    }
    fft.transform(re, im, inverse: true);
    for (var i = 0; i < n; i++) {
      out[f * hop + i] += re[i] / n * win[i];
      norm[f * hop + i] += win[i] * win[i];
    }
  }
  for (var i = 0; i < x.length; i++) {
    out[i] = norm[i] > 1e-6 ? out[i] / norm[i] : 0.0;
  }
  return out;
}

/// Peak-normalises to [targetPeak] (no-op for digital silence).
Float64List normalizePeak(Float64List x, {double targetPeak = 0.89}) {
  var peak = 0.0;
  for (final v in x) {
    if (v.abs() > peak) peak = v.abs();
  }
  if (peak < 1e-6) return x;
  final g = targetPeak / peak;
  return Float64List.fromList([for (final v in x) v * g]);
}

/// Simple level statistics on 20 ms frames, before any processing.
class InputLevels {
  InputLevels({required this.peakDb, required this.loudDb, required this.floorDb, required this.voicedSeconds});
  final double peakDb;

  /// Mean of the loudest 10 % of frames.
  final double loudDb;

  /// Median of the quietest 20 % of frames.
  final double floorDb;

  /// Seconds of frames at least 12 dB above the floor.
  final double voicedSeconds;

  double get snrDb => loudDb - floorDb;
}

InputLevels measureLevels(Float64List x) {
  const w = 320;
  final n = x.length ~/ w;
  if (n < 3) return InputLevels(peakDb: -120, loudDb: -120, floorDb: -120, voicedSeconds: 0);
  final db = <double>[];
  var peak = 0.0;
  for (var f = 0; f < n; f++) {
    var s = 0.0;
    for (var i = 0; i < w; i++) {
      final v = x[f * w + i];
      s += v * v;
      if (v.abs() > peak) peak = v.abs();
    }
    db.add(10 * log10(s / w + 1e-12));
  }
  final sorted = List<double>.from(db)..sort();
  final floor = median(sorted.sublist(0, math.max(1, (n * 0.2).floor())));
  final top = sorted.sublist((n * 0.9).floor());
  final loud = mean(top);
  final voiced = db.where((v) => v >= floor + 12).length * w / kSr;
  return InputLevels(peakDb: 20 * log10(peak + 1e-12), loudDb: loud, floorDb: floor, voicedSeconds: voiced);
}

/// Adds deterministic white hiss at [db] dBFS RMS (fixed seed, so the same
/// take always scores the same).
Float64List addComfortNoise(Float64List x, {double db = -42}) {
  final amp = math.pow(10, db / 20).toDouble() * math.sqrt(3);
  var state = 0x2545F491;
  final y = Float64List(x.length);
  for (var i = 0; i < x.length; i++) {
    state ^= (state << 13) & 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    y[i] = x[i] + amp * (state / 0xFFFFFFFF * 2 - 1);
  }
  return y;
}
