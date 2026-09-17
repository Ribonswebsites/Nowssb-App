/// Premium Practice tab opened from the NowssB player.
///
/// The reference track is played first, then the microphone session begins.
/// The microphone is intentionally represented only by the visual language of
/// the product: a white mic orb, liquid-glass shell and pulse field. There is
/// no "recording" label, red dot, waveform or recorder chrome.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../data/models.dart';

class PracticeLabSheet extends StatefulWidget {
  const PracticeLabSheet({
    super.key,
    required this.word,
    required this.onSpeak,
    required this.onClose,
    this.accent = const Color(0xFFB8C9FF),
  });

  final Word word;
  final Future<void> Function() onSpeak;
  final VoidCallback onClose;
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

  String _heard = '';
  bool _speechReady = false;
  bool _busy = true;
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    unawaited(_beginPractice());
  }

  @override
  void dispose() {
    unawaited(_finishCapture());
    _pulse.dispose();
    _entry.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _beginPractice() async {
    // The reference audio remains whatever the player supplies. Nothing in
    // this UI assumes the current TTS placeholder will be the shipped audio.
    try {
      await widget.onSpeak();
    } catch (_) {}

    if (!mounted) return;
    await _startCapture();
  }

  Future<void> _startCapture() async {
    try {
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final dir = await getTemporaryDirectory();
      final file =
          '${dir.path}/nwsb-practice-${DateTime.now().millisecondsSinceEpoch}.m4a';
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
        path: file,
      );

      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            unawaited(_finishCapture());
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
              _heard = heard;
              _matched = _similarEnough(heard, widget.word.word);
            });
          },
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            autoPunctuation: false,
            listenFor: Duration(seconds: 9),
            pauseFor: Duration(seconds: 2),
          ),
        );
      }
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishCapture() async {
    try {
      if (_speechReady && _speech.isListening) await _speech.stop();
    } catch (_) {}
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
  }

  bool _similarEnough(String heard, String target) {
    final a = heard.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    final b = target.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final heardWords = a.split(RegExp(r'\s+'));
    return heardWords.any((w) => w == b) || a.contains(b);
  }

  List<WordPart> get _parts => widget.word.parts;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: ColoredBox(color: Color(0x22080B10)),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _entry,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 36 * (1 - _entry.value)),
                  child: Opacity(opacity: _entry.value, child: child),
                ),
                child: _PracticeTab(
                  word: widget.word,
                  parts: _parts,
                  accent: widget.accent,
                  pulse: _pulse,
                  heard: _heard,
                  busy: _busy,
                  matched: _matched,
                  onClose: widget.onClose,
                  onReplay: () => unawaited(_beginPractice()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.word,
    required this.parts,
    required this.accent,
    required this.pulse,
    required this.heard,
    required this.busy,
    required this.matched,
    required this.onClose,
    required this.onReplay,
  });

  final Word word;
  final List<WordPart> parts;
  final Color accent;
  final Animation<double> pulse;
  final String heard;
  final bool busy;
  final bool matched;
  final VoidCallback onClose;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xE20B0F14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.58),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.28),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'PRACTICE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                    _SmallButton(icon: Icons.close_rounded, onTap: onClose),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  word.word,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 126,
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (context, _) => CustomPaint(
                      painter: _LiquidPulsePainter(
                        progress: pulse.value,
                        accent: accent,
                      ),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 104,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size.square(104),
                                painter: _OrbPainter(
                                  progress: pulse.value,
                                  accent: accent,
                                ),
                              ),
                              SizedBox(
                                width: 34,
                                height: 42,
                                child: SvgPicture.asset(
                                  'assets/icons/microphone.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      _SoundPill(
                        label: parts[i].roman.isNotEmpty
                            ? parts[i].roman
                            : parts[i].deva,
                        active:
                            heard.isNotEmpty &&
                            heard.toLowerCase().contains(
                              (parts[i].roman.isNotEmpty
                                      ? parts[i].roman
                                      : parts[i].deva)
                                  .toLowerCase(),
                            ),
                      ),
                  ],
                ),
                if (heard.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    matched ? '✓' : '•',
                    style: TextStyle(
                      color: matched ? Colors.white : Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onReplay,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      busy ? '' : 'tap to hear again',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoundPill extends StatelessWidget {
  const _SoundPill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFF090A0D),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(active ? .75 : .16)),
        boxShadow: active
            ? [BoxShadow(color: Colors.white.withOpacity(.12), blurRadius: 18)]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.06),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: Icon(icon, color: Colors.white70, size: 19),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .42;
    final sphere = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -.35),
          radius: 1.05,
          colors: [
            Colors.white.withOpacity(.98),
            accent.withOpacity(.64),
            const Color(0xFF15171B),
            Colors.black,
          ],
          stops: const [.02, .27, .62, 1],
        ).createShader(sphere),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    for (var x = -radius; x <= radius; x += 3.5) {
      final width = math.sqrt(math.max(0, radius * radius - x * x));
      final wave = math.sin(progress * math.pi * 2 + x / radius * math.pi * 2);
      final bend = wave * 3.4;
      final light = (.5 + .5 * math.cos(x / radius * math.pi)).clamp(0.0, 1.0);
      final opacity = (.12 + light * .78).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(center.dx + x + bend, center.dy - width),
        Offset(center.dx + x - bend, center.dy + width),
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = .9 + light * 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      Offset(center.dx - radius * .28, center.dy - radius * .34),
      radius * .12,
      Paint()..color = Colors.white.withOpacity(.32),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _LiquidPulsePainter extends CustomPainter {
  const _LiquidPulsePainter({required this.progress, required this.accent});
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * .46;

    for (var i = 0; i < 9; i++) {
      final t = (progress + i / 9) % 1.0;
      final radius = 48 + t * maxRadius;
      final fade = math.pow(1 - t, 1.45).toDouble();
      final path = Path();
      for (var a = 0.0; a <= math.pi * 2 + .08; a += .08) {
        final wave =
            math.sin(a * 3 + progress * math.pi * 2) * (1.2 + 3.5 * (1 - t));
        final rr = radius + wave;
        final p = Offset(
          c.dx + math.cos(a) * rr,
          c.dy + math.sin(a) * rr * .64,
        );
        if (a == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 + fade * 1.8
          ..color = Color.lerp(
            Colors.white,
            accent,
            .35,
          )!.withOpacity(.025 + fade * .18),
      );
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withOpacity(.16), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c, radius: 62));
    canvas.drawCircle(c, 62, glow);
  }

  @override
  bool shouldRepaint(covariant _LiquidPulsePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
