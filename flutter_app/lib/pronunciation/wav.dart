/// Minimal WAV (RIFF) reader for pronunciation scoring: PCM 8/16/24/32-bit
/// and 32-bit float, any channel count, resampled to 16 kHz mono.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const int kScoreRate = 16000;

/// Thrown when bytes are not a WAV this reader understands (e.g. m4a/mp3).
class UnsupportedAudio implements Exception {
  UnsupportedAudio(this.reason);
  final String reason;
  @override
  String toString() => 'UnsupportedAudio: $reason';
}

bool looksLikeWav(Uint8List b) =>
    b.length > 12 &&
    b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && // RIFF
    b[8] == 0x57 && b[9] == 0x41 && b[10] == 0x56 && b[11] == 0x45; // WAVE

/// Decodes [bytes] to mono samples in -1..1 at [kScoreRate].
Float32List decodeWav(Uint8List bytes) {
  if (!looksLikeWav(bytes)) throw UnsupportedAudio('not a WAV file');
  final d = ByteData.sublistView(bytes);
  var p = 12;
  int? format, channels, rate, bits;
  int? dataStart, dataLen;
  while (p + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(p, p + 4));
    var size = d.getUint32(p + 4, Endian.little);
    final body = p + 8;
    if (id == 'fmt ') {
      format = d.getUint16(body, Endian.little);
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
      bits = d.getUint16(body + 14, Endian.little);
      if (format == 0xFFFE && size >= 26) {
        format = d.getUint16(body + 24, Endian.little); // extensible subformat
      }
    } else if (id == 'data') {
      dataStart = body;
      // Streaming recorders may leave 0 / 0xFFFFFFFF until finalised.
      if (size == 0 || body + size > bytes.length) size = bytes.length - body;
      dataLen = size;
      break;
    }
    p = body + size + (size.isOdd ? 1 : 0);
  }
  if (format == null || dataStart == null || channels == null || rate == null || bits == null) {
    throw UnsupportedAudio('missing fmt or data chunk');
  }
  if (!(format == 1 || (format == 3 && bits == 32))) {
    throw UnsupportedAudio('compressed WAV format $format');
  }
  final bytesPer = bits ~/ 8;
  if (bytesPer < 1 || bytesPer > 4 || channels < 1) throw UnsupportedAudio('bad sample size');
  final frames = dataLen! ~/ (bytesPer * channels);
  final mono = Float32List(frames);
  for (var i = 0; i < frames; i++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      final o = dataStart + (i * channels + c) * bytesPer;
      double v;
      if (format == 3) {
        v = d.getFloat32(o, Endian.little);
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
    mono[i] = sum / channels;
  }
  return resample(mono, rate, kScoreRate);
}

/// Linear-interpolation resampler with a crude box low-pass when shrinking.
Float32List resample(Float32List x, int from, int to) {
  if (from == to || x.isEmpty) return x;
  var src = x;
  if (from > to) {
    final k = (from / to).floor();
    if (k > 1) {
      src = Float32List(x.length);
      var acc = 0.0;
      for (var i = 0; i < x.length; i++) {
        acc += x[i];
        if (i >= k) acc -= x[i - k];
        src[i] = acc / math.min(i + 1, k);
      }
    }
  }
  final n = (x.length * to / from).floor();
  final out = Float32List(n);
  final step = from / to;
  for (var i = 0; i < n; i++) {
    final t = i * step;
    final j = t.floor();
    final f = t - j;
    final a = src[math.min(j, src.length - 1)];
    final b = src[math.min(j + 1, src.length - 1)];
    out[i] = a + (b - a) * f;
  }
  return out;
}
