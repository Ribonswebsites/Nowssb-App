/// Compact black Practice tab opened from the NowssB player.
///
/// No glass wrapper. The player's film stays as the page background — this
/// sheet never claims a second decoder. A metallic ridged orb (blender-style)
/// spins in fast on open. Status is Waiting / Listening / Analyzing.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../data/models.dart';

enum _PracticeStatus {
  ready,
  listening,
  recording,
  practicing,
  processing,
  results,
  complete,
}

const _sessionLength = 29;

/// Compact microphone used in the Now Playing dock.
class PracticeDockOrb extends StatelessWidget {
  const PracticeDockOrb({
    super.key,
    required this.onTap,
    this.accent = const Color(0xFFF4F4F5),
  });

  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Practice',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 38,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/microphone.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const Text(
              'PRACTICE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeLabSheet extends StatefulWidget {
  const PracticeLabSheet({
    super.key,
    required this.word,
    required this.onSpeak,
    required this.onClose,
    required this.video,
    this.accent = const Color(0xFFB8C9FF),
  });

  final Word word;
  final Future<void> Function() onSpeak;
  final VoidCallback onClose;

  /// Kept so the CI patcher can keep wiring the player film. The sheet
  /// itself never plays it — the player page already owns that decoder.
  final String video;
  final Color accent;

  @override
  State<PracticeLabSheet> createState() => _PracticeLabSheetState();
}

class _PracticeLabSheetState extends State<PracticeLabSheet>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulse;
  late final AnimationController _entry;
  late final AnimationController _spin;

  Timer? _clock;
  String? _takePath;
  bool _speechReady = false;
  bool _holding = false;
  bool _matched = false;
  int _elapsed = 0;
  _PracticeStatus _status = _PracticeStatus.ready;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    unawaited(_playReference());
  }

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_finishCapture());
    _pulse.dispose();
    _entry.dispose();
    _spin.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    try {
      await widget.onSpeak();
    } catch (_) {}
    if (mounted) setState(() => _status = _PracticeStatus.ready);
  }

  Future<void> _beginTake() async {
    if (_holding || _status == _PracticeStatus.recording) return;
    _clock?.cancel();
    setState(() {
      _holding = true;
      _elapsed = 0;
      _matched = false;
      _status = _PracticeStatus.listening;
    });

    try {
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        if (mounted) setState(() => _holding = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      _takePath = '${dir.path}/nwsb-practice-${widget.word.key}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: _takePath!,
      );
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted || !_holding) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _status = _PracticeStatus.practicing);
          }
        },
        onError: (_) {},
      );
      if (_speechReady) {
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            final heard = result.recognizedWords.trim();
            if (heard.isEmpty) return;
            setState(() {
              _matched = _similarEnough(heard, widget.word.word);
              _status = _PracticeStatus.practicing;
            });
          },
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            autoPunctuation: false,
            listenFor: const Duration(seconds: _sessionLength),
            pauseFor: const Duration(seconds: 4),
          ),
        );
      }
      if (!mounted) return;
      setState(() => _status = _PracticeStatus.recording);
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_holding) return;
        if (_elapsed >= _sessionLength - 1) {
          unawaited(_endTake());
        } else {
          setState(() => _elapsed++);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _holding = false);
    }
  }

  Future<void> _endTake() async {
    if (!_holding && _status != _PracticeStatus.recording) return;
    _clock?.cancel();
    await _finishCapture();
    if (!mounted) return;
    setState(() {
      _holding = false;
      _status = _PracticeStatus.processing;
    });
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (mounted) {
      setState(
        () => _status = _matched
            ? _PracticeStatus.complete
            : _PracticeStatus.results,
      );
    }
  }

  Future<void> _finishCapture() async {
    try {
      if (_speechReady && _speech.isListening) await _speech.stop();
    } catch (_) {}
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
  }

  Future<void> _replay() async {
    _clock?.cancel();
    await _finishCapture();
    if (!mounted) return;
    setState(() {
      _takePath = null;
      _matched = false;
      _elapsed = 0;
      _holding = false;
      _status = _PracticeStatus.ready;
    });
    _spin
      ..reset()
      ..forward();
    await _playReference();
  }

  bool _similarEnough(String heard, String target) {
    final a = heard.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    final b = target.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final heardWords = a.split(RegExp(r'\s+'));
    return heardWords.any((w) => w == b) || a.contains(b);
  }

  String get _statusLabel {
    if (_holding || _status == _PracticeStatus.recording) return 'Listening';
    if (_status == _PracticeStatus.processing ||
        _status == _PracticeStatus.practicing) {
      return 'Analyzing';
    }
    return 'Waiting';
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.video.isNotEmpty || widget.video.isEmpty);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.translucent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: Listenable.merge([_entry, _spin, _pulse]),
              builder: (context, _) {
                final open = Curves.easeOutCubic.transform(_entry.value);
                final spin = _spin.isCompleted
                    ? _pulse.value
                    : Curves.easeOutCubic.transform(_spin.value);
                final punch = _spin.isCompleted
                    ? 1.0
                    : Curves.easeOutBack.transform(_spin.value.clamp(0.0, 1.0));
                return Transform.translate(
                  offset: Offset(0, 48 * (1 - open)),
                  child: Opacity(
                    opacity: open,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: _BlackTab(
                        status: _statusLabel,
                        holding: _holding,
                        orbProgress: spin,
                        orbScale: 0.22 + punch * 0.78,
                        intensity: _holding ? 1.35 : 1.0,
                        onStart: _beginTake,
                        onReplace: () => unawaited(_replay()),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BlackTab extends StatelessWidget {
  const _BlackTab({
    required this.status,
    required this.holding,
    required this.orbProgress,
    required this.orbScale,
    required this.intensity,
    required this.onStart,
    required this.onReplace,
  });

  final String status;
  final bool holding;
  final double orbProgress;
  final double orbScale;
  final double intensity;
  final VoidCallback onStart;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 148,
            child: Transform.scale(
              scale: orbScale,
              child: CustomPaint(
                painter: _BlenderOrbPainter(
                  progress: orbProgress,
                  intensity: intensity,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onReplace,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.2),
                      backgroundColor: Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Replace',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF08090D),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      holding ? 'Listening' : 'Start',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Metallic ridged sphere — blender-style meridians with lighting.
class _BlenderOrbPainter extends CustomPainter {
  const _BlenderOrbPainter({required this.progress, required this.intensity});

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final rot = progress * math.pi * 2;

    final fill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.46),
        radius: 1.05,
        colors: [
          Color.lerp(
            const Color(0xFF9AA3AD),
            const Color(0xFFE8EDF2),
            0.35 * intensity,
          )!,
          const Color(0xFF2A2E34),
          const Color(0xFF07080A),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.08));
    canvas.drawCircle(center, radius, fill);

    const meridians = 26;
    for (var i = 0; i < meridians; i++) {
      final lon0 = (i / meridians) * math.pi * 2 + rot;
      final path = Path();
      var started = false;
      for (var step = 0; step <= 40; step++) {
        final lat = step / 40 * math.pi - math.pi / 2;
        final x = math.sin(lon0) * math.cos(lat);
        final y = math.sin(lat);
        final z = math.cos(lon0) * math.cos(lat);
        if (z < -0.08) {
          started = false;
          continue;
        }
        final px = center.dx + x * radius;
        final py = center.dy + y * radius;
        if (!started) {
          path.moveTo(px, py);
          started = true;
        } else {
          path.lineTo(px, py);
        }
      }
      final face = (0.22 + 0.78 * math.cos(lon0).abs()).clamp(0.0, 1.0);
      final light = (0.28 + 0.72 * math.cos(lon0 - 0.7)).clamp(0.12, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.05 + face * 0.85
          ..color = Color.lerp(
            const Color(0xFF6E7680),
            const Color(0xFFF4F7FA),
            light,
          )!.withOpacity((0.42 + face * 0.5) * intensity.clamp(0.7, 1.2)),
      );
    }

    for (final lat in const [-0.7, 0.0, 0.7]) {
      final path = Path();
      var started = false;
      for (var step = 0; step <= 48; step++) {
        final lon = step / 48 * math.pi * 2 + rot;
        final x = math.sin(lon) * math.cos(lat);
        final y = math.sin(lat);
        final z = math.cos(lon) * math.cos(lat);
        if (z < 0.05) {
          started = false;
          continue;
        }
        final px = center.dx + x * radius;
        final py = center.dy + y * radius;
        if (!started) {
          path.moveTo(px, py);
          started = true;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = Colors.white.withOpacity(0.16 * intensity),
      );
    }

    canvas.drawCircle(
      center + Offset(-radius * .32, -radius * .38),
      radius * .16,
      Paint()
        ..color = Colors.white.withOpacity(0.18 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant _BlenderOrbPainter old) =>
      old.progress != progress || old.intensity != intensity;
}
