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
import 'dart:math' as math;

import 'package:flutter/material.dart';
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

  static const again = CueLine('Do you want to hear it again?', 'assets/voice/cues/hear-again.mp3');
  static const finish = CueLine('Let the sound finish.', 'assets/voice/cues/let-it-finish.mp3');

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
      onFrame(RitualFrame(count: step.$1, caption: 'Settle'));
      await _hold(say(step.$1 == 3 ? 'Three.' : step.$1 == 2 ? 'Two.' : 'One.', step.$2));
      if (!alive()) return;
    }
    if (!alive()) return;
    onFrame(const RitualFrame(caption: 'Begin'));
    await _hold(say('Begin.', 'assets/voice/cues/begin.mp3'));
    for (final cue in before) {
      if (!alive()) return;
      onFrame(RitualFrame(caption: cue.line));
      await _hold(say(cue.line, cue.asset));
    }
    if (!alive()) return;
    onFrame(RitualFrame(caption: line));
    await sayWord(line);
    if (!alive()) return;
    onFrame(RitualFrame(caption: again.line));
    await _hold(say(again.line, again.asset));
    if (!alive()) return;
    onFrame(RitualFrame(caption: line));
    await sayWord(line);
    if (!alive()) return;
    onFrame(RitualFrame(caption: finish.line));
    await _hold(say(finish.line, finish.asset));
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

class RitualStage extends StatefulWidget {
  const RitualStage({super.key, required this.frame});
  final RitualFrame frame;

  @override
  State<RitualStage> createState() => _RitualStageState();
}

class _RitualStageState extends State<RitualStage> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.frame.count;
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, _) {
              return CustomPaint(
                painter: _RingPainter(_spin.value),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count != null)
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 92,
                            height: 0.9,
                            fontWeight: FontWeight.w200,
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Text(
                          widget.frame.caption,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE8D5A3),
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = const Color(0x88FFFFFF);
    for (var i = 0; i < 5; i++) {
      final radius = 46.0 + i * 16;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * (i.isEven ? 1 : -1) * math.pi * 2 * (0.35 + i * 0.12));
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius), -0.4, 2.2, false, arc);
      canvas.restore();
    }
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        transform: GradientRotation(t * math.pi * 2),
        colors: const [Color(0x00E8D5A3), Color(0xFFE8D5A3), Color(0x00FFFFFF)],
      ).createShader(Rect.fromCircle(center: c, radius: 128));
    canvas.drawCircle(c, 128, sweep);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.t != t;
}
