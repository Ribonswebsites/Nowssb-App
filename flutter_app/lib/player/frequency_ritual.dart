/// Play opening. The lines are always spoken.
///
/// Drop ElevenLabs files on these paths and they replace the device voice.
/// Until a file is in the app, the same line is spoken with text-to-speech.
///
///   assets/voice/cues/count-3.mp3
///   assets/voice/cues/count-2.mp3
///   assets/voice/cues/count-1.mp3
///   assets/voice/cues/begin.mp3
///   assets/voice/cues/breathe-in.mp3
///   assets/voice/cues/breathe-out.mp3
///   assets/voice/cues/hear-a-sound.mp3
///   assets/voice/cues/repeat-after.mp3
///   assets/voice/cues/hear-again.mp3
///   assets/voice/cues/let-it-finish.mp3
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';

const kFrequencyNames = <String>[
  'Still',
  'Breath',
  'Pulse',
  'Tone',
  'Field',
  'Current',
  'Harmonic',
  'Resonance',
  'Origin',
  'Infinite',
];

String frequencyName(int level) {
  final i = (level - 1).clamp(0, kFrequencyNames.length - 1);
  return kFrequencyNames[i];
}

/// Frequency N speaks that word's stage N. No stages, every frequency
/// speaks the same word.
String frequencyLine(Word word, int level) {
  if (word.stages.isEmpty) return word.word;
  final stage = word.stages[(level - 1) % word.stages.length];
  final text = stage.text.trim();
  if (text.isNotEmpty) return text;
  final title = stage.title.trim();
  if (title.isNotEmpty) return title;
  return word.word;
}

class RitualFrame {
  const RitualFrame({this.count, required this.caption});
  final int? count;
  final String caption;
}

class CueLine {
  const CueLine(this.line, this.asset);
  final String line;
  final String asset;
}

class PlayerRitual {
  PlayerRitual._();

  static const before = <CueLine>[
    CueLine('Breathe in.', 'assets/voice/cues/breathe-in.mp3'),
    CueLine('Breathe out.', 'assets/voice/cues/breathe-out.mp3'),
    CueLine('You hear a sound.', 'assets/voice/cues/hear-a-sound.mp3'),
    CueLine('Repeat after it.', 'assets/voice/cues/repeat-after.mp3'),
  ];

  static final AudioPlayer _player = AudioPlayer();
  static int _token = 0;

  static Future<void> stop() async {
    _token++;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// True when the file played or playback was stopped. False means say it
  /// with text-to-speech.
  static Future<bool> playAsset(String asset, {required double volume}) async {
    try {
      await rootBundle.load(asset);
    } catch (_) {
      return false;
    }
    final token = ++_token;
    try {
      await _player.stop();
      await _player.setAsset(asset);
      if (token != _token) return true;
      await _player.setVolume(volume.clamp(0.0, 1.0));
      final done = _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed || token != _token,
      );
      unawaited(_player.play());
      await done.timeout(const Duration(seconds: 25), onTimeout: () => _player.playerState);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> run({
    required bool Function() alive,
    required String line,
    required void Function(RitualFrame frame) onFrame,
    required Future<void> Function(String line, String asset) say,
    required Future<void> Function(String line) sayWord,
  }) async {
    const counts = <(int, String)>[
      (3, 'assets/voice/cues/count-3.mp3'),
      (2, 'assets/voice/cues/count-2.mp3'),
      (1, 'assets/voice/cues/count-1.mp3'),
    ];
    for (final step in counts) {
      if (!alive()) return;
      onFrame(RitualFrame(count: step.$1, caption: step.$1 == 3 ? 'Three.' : step.$1 == 2 ? 'Two.' : 'One.'));
      await _hold(say(step.$1 == 3 ? 'Three.' : step.$1 == 2 ? 'Two.' : 'One.', step.$2));
      if (!alive()) return;
    }
    if (!alive()) return;
    for (final cue in before) {
      if (!alive()) return;
      onFrame(RitualFrame(caption: cue.line));
      await _hold(say(cue.line, cue.asset));
    }
    if (!alive()) return;
    onFrame(RitualFrame(caption: line));
    await sayWord(line);
  }

  static Future<void> _hold(Future<void> speak) async {
    final started = DateTime.now();
    try {
      await speak;
    } catch (_) {}
    final left = 720 - DateTime.now().difference(started).inMilliseconds;
    if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
  }
}
