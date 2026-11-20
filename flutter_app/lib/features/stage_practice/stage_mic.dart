/// The microphone for stage practice: a WAV take at 16 kHz mono with the
/// phone's own processing off (no auto-gain, echo cancel or noise
/// suppression — they reshape the voice the scorer compares). The scorer
/// still reads whatever rate/format the phone actually wrote, resamples it
/// to 16 kHz and does its own gentle noise gate.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract class StageMic {
  Future<bool> hasPermission();

  /// Starts a take. [level] gets dBFS (≈ -60 … 0) about 20 times a second.
  Future<void> start(String name, void Function(double dbfs) level);

  /// Stops and returns the WAV bytes (null when nothing was written).
  Future<Uint8List?> stop();

  Future<void> cancel();

  /// Path of the last take on disk (for "Hear my attempt"), if any.
  String? get lastPath;

  void dispose();
}

class RecordStageMic implements StageMic {
  final AudioRecorder _rec = AudioRecorder();
  StreamSubscription<Amplitude>? _amp;
  String? _path;

  @override
  String? get lastPath => _path;

  @override
  Future<bool> hasPermission() => _rec.hasPermission();

  @override
  Future<void> start(String name, void Function(double dbfs) level) async {
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/$name.wav';
    try {
      final f = File(_path!);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        // Android: the voice-recognition source is tuned for clean speech
        // capture without the call-style processing of the default source.
        androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.voiceRecognition),
      ),
      path: _path!,
    );
    await _amp?.cancel();
    _amp = _rec.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((a) => level(a.current));
  }

  @override
  Future<Uint8List?> stop() async {
    await _amp?.cancel();
    _amp = null;
    String? out;
    try {
      out = await _rec.stop();
    } catch (_) {}
    final p = out ?? _path;
    if (p == null) return null;
    try {
      final f = File(p);
      if (!await f.exists()) return null;
      final b = await f.readAsBytes();
      return b.length > 44 ? b : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancel() async {
    await _amp?.cancel();
    _amp = null;
    try {
      if (await _rec.isRecording()) await _rec.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _amp?.cancel();
    _rec.dispose();
  }
}
