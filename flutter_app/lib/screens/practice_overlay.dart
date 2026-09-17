/// Premium Practice tab opened from the NowssB player.
///
/// The lab is deliberately self-contained: the reference is played first, then
/// the learner holds the mic to make a take. A take is written to the app's
/// documents directory so it survives the session and can be replayed locally.
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
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

enum _PracticeStatus {
  ready,
  listening,
  recording,
  practicing,
  locked,
  complete,
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
  final String video;
  final Color accent;

  @override
  State<PracticeLabSheet> createState() => _PracticeLabSheetState();
}

class _PracticeLabSheetState extends State<PracticeLabSheet>
    with TickerProviderStateMixin {
  static const _sessionLength = 29;
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulse;
  late final AnimationController _entry;

  Timer? _clock;
  String _heard = '';
  String? _takePath;
  bool _speechReady = false;
  bool _holding = false;
  bool _matched = false;
  int _elapsed = 0;
  _PracticeStatus _status = _PracticeStatus.listening;

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
    unawaited(_playReference());
  }

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_finishCapture());
    _pulse.dispose();
    _entry.dispose();
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
      _heard = '';
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
              _heard = heard;
              _matched = _similarEnough(heard, widget.word.word);
              _status = _PracticeStatus.practicing;
            });
          },
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            autoPunctuation: false,
            listenFor: Duration(seconds: _sessionLength),
            pauseFor: Duration(seconds: 4),
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
      _status = _elapsed >= _sessionLength - 1
          ? _PracticeStatus.complete
          : _PracticeStatus.locked;
    });
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
      _heard = '';
      _matched = false;
      _elapsed = 0;
      _holding = false;
      _status = _PracticeStatus.listening;
    });
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

  List<WordPart> get _parts => widget.word.parts;
  String get _statusLabel => switch (_status) {
    _PracticeStatus.ready => 'Ready',
    _PracticeStatus.listening => 'Listening',
    _PracticeStatus.recording => 'Recording',
    _PracticeStatus.practicing => 'Practicing',
    _PracticeStatus.locked => 'Take locked',
    _PracticeStatus.complete => '29s complete',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .28,
              child: NwsbVideo(
                asset: widget.video,
                priority: ClipPriority.feature,
                autoplay: true,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: const ColoredBox(color: Color(0x22080B10)),
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
                  child: Transform.scale(
                    scale: .96 + _entry.value * .04,
                    child: Opacity(opacity: _entry.value, child: child),
                  ),
                ),
                child: _PracticeTab(
                  word: widget.word,
                  parts: _parts,
                  accent: widget.accent,
                  pulse: _pulse,
                  heard: _heard,
                  elapsed: _elapsed,
                  status: _statusLabel,
                  matched: _matched,
                  takeLocked: _takePath != null && !_holding,
                  onClose: widget.onClose,
                  onHoldStart: _beginTake,
                  onHoldEnd: _endTake,
                  onReplay: () => unawaited(_replay()),
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
    required this.elapsed,
    required this.status,
    required this.matched,
    required this.takeLocked,
    required this.onClose,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onReplay,
  });

  final Word word;
  final List<WordPart> parts;
  final Color accent;
  final Animation<double> pulse;
  final String heard;
  final int elapsed;
  final String status;
  final bool matched;
  final bool takeLocked;
  final VoidCallback onClose;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final target = word.word.isEmpty ? word.translit : word.word;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xE20B0F14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.58),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white60,
                      ),
                      const Expanded(
                        child: Text(
                          'PRACTICE LAB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                      _SmallButton(icon: Icons.close_rounded, onTap: onClose),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$status  •  ${elapsed.toString().padLeft(2, '0')} / 29s',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      target,
                      key: ValueKey(target),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        height: .98,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (word.translit.isNotEmpty && word.translit != target)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        word.translit,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _Timeline(elapsed: elapsed, accent: accent),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPressStart: (_) => onHoldStart(),
                    onLongPressEnd: (_) => onHoldEnd(),
                    onTapDown: (_) => onHoldStart(),
                    onTapUp: (_) => onHoldEnd(),
                    onTapCancel: onHoldEnd,
                    child: SizedBox(
                      height: 170,
                      child: AnimatedBuilder(
                        animation: pulse,
                        builder: (context, _) => CustomPaint(
                          painter: _LiquidPulsePainter(
                            progress: pulse.value,
                            accent: accent,
                          ),
                          child: Center(
                            child: SizedBox.square(
                              dimension: 124,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size.square(124),
                                    painter: _OrbPainter(
                                      progress: pulse.value,
                                      accent: accent,
                                    ),
                                  ),
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(.96),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(.55),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SvgPicture.asset(
                                        'assets/icons/microphone.svg',
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF11151B),
                                          BlendMode.srcIn,
                                        ),
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
                  ),
                  Text(
                    takeLocked ? 'Take saved on this device' : 'Hold to speak',
                    style: TextStyle(
                      color: takeLocked ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                  ),
                  if (heard.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      heard,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        _SoundPill(
                          label: parts[i].roman.isNotEmpty
                              ? parts[i].roman
                              : parts[i].deva,
                          active: heard.toLowerCase().contains(
                            (parts[i].roman.isNotEmpty
                                    ? parts[i].roman
                                    : parts[i].deva)
                                .toLowerCase(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MouthCard(word: word, matched: matched),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: onReplay,
                        icon: const Icon(Icons.replay_rounded, size: 17),
                        label: const Text('Replay reference'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        label: const Text('Now Playing'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.elapsed, required this.accent});
  final int elapsed;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: elapsed / 29,
      minHeight: 3,
      backgroundColor: Colors.white12,
      valueColor: AlwaysStoppedAnimation<Color>(accent),
      borderRadius: BorderRadius.circular(99),
    );
  }
}

class _MouthCard extends StatelessWidget {
  const _MouthCard({required this.word, required this.matched});
  final Word word;
  final bool matched;
  @override
  Widget build(BuildContext context) {
    final hint = word.mouthPos.isNotEmpty
        ? word.mouthPos
        : (word.tip.isNotEmpty
              ? word.tip
              : 'Relax the jaw and let the sound resonate.');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.face_retouching_natural_outlined,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matched ? 'Sound matched' : 'Mouth shape',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFF090A0D),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(active ? .75 : .16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
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
  Widget build(BuildContext context) => GestureDetector(
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

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.progress, required this.accent});
  final double progress;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * .42;
    final sphere = Rect.fromCircle(center: c, radius: r);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-.12);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawOval(
      sphere,
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
    canvas.clipPath(Path()..addOval(sphere));
    for (var x = -r; x <= r; x += 3.5) {
      final width = math.sqrt(math.max(0, r * r - x * x));
      final wave = math.sin(progress * math.pi * 2 + x / r * math.pi * 2);
      final bend = wave * 4.5;
      final light = (.5 + .5 * math.cos(x / r * math.pi)).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(c.dx + x + bend, c.dy - width),
        Offset(c.dx + x - bend, c.dy + width),
        Paint()
          ..color = Colors.white.withOpacity(.12 + light * .75)
          ..strokeWidth = .9 + light * 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _LiquidPulsePainter extends CustomPainter {
  const _LiquidPulsePainter({required this.progress, required this.accent});
  final double progress;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * .46;
    for (var i = 0; i < 11; i++) {
      final t = (progress + i / 11) % 1.0;
      final radius = 48 + t * maxR;
      final fade = math.pow(1 - t, 1.45).toDouble();
      final path = Path();
      for (var a = 0.0; a <= math.pi * 2 + .08; a += .08) {
        final wave =
            math.sin(a * 3 + progress * math.pi * 2) * (1.4 + 4 * (1 - t));
        final p = Offset(
          c.dx + math.cos(a) * (radius + wave),
          c.dy + math.sin(a) * (radius + wave) * .62,
        );
        if (a == 0)
          path.moveTo(p.dx, p.dy);
        else
          path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 + fade * 1.9
          ..color = Color.lerp(
            Colors.white,
            accent,
            .35,
          )!.withOpacity(.025 + fade * .2),
      );
    }
    canvas.drawCircle(
      c,
      64,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withOpacity(.18), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: 64)),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPulsePainter old) =>
      old.progress != progress || old.accent != accent;
}
