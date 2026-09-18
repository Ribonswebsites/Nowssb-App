/// Compact Practice tab opened from the NowssB player.
///
/// Glass outside, black inside. The player's own film stays as the page
/// background — this sheet does not spawn a second decoder. A white
/// microphone sits on a ridged 3D ripple orb. Below: the word, broken
/// into parts. Hold to speak writes a take.
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

enum _PracticeStatus {
  ready,
  listening,
  recording,
  practicing,
  processing,
  results,
  locked,
  complete,
}

const _sessionLength = 29;

class _Beat {
  const _Beat(this.at, this.until, this.state, this.part);
  final int at;
  final int until;
  final String state;
  final int? part;
}

const _beats = <_Beat>[
  _Beat(0, 2, 'Listening', null),
  _Beat(2, 4, 'Practicing', 0),
  _Beat(4, 7, 'Practicing', 1),
  _Beat(7, 10, 'Listening', null),
  _Beat(10, 14, 'Recording', 2),
  _Beat(14, 18, 'Thinking', null),
  _Beat(18, 22, 'Recording', null),
  _Beat(22, 26, 'Solving', null),
  _Beat(26, 29, 'Locked', null),
];

_Beat _beatAt(int t) {
  final n = ((t % _sessionLength) + _sessionLength) % _sessionLength;
  return _beats.firstWhere(
    (b) => n >= b.at && n < b.until,
    orElse: () => _beats.last,
  );
}

/// Compact 3D-ripple microphone used in the Now Playing dock.
class PracticeDockOrb extends StatefulWidget {
  const PracticeDockOrb({
    super.key,
    required this.onTap,
    this.accent = const Color(0xFFF4F4F5),
  });

  final VoidCallback onTap;
  final Color accent;

  @override
  State<PracticeDockOrb> createState() => _PracticeDockOrbState();
}

class _PracticeDockOrbState extends State<PracticeDockOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Practice',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => CustomPaint(
                  painter: _WaterRipplePainter(
                    progress: _pulse.value,
                    accent: widget.accent,
                    intensity: 1.05,
                  ),
                  child: Center(child: child),
                ),
                child: const _MicDisc(size: 28, iconSize: 14),
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

  Timer? _clock;
  Timer? _session;
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
      duration: const Duration(milliseconds: 420),
    )..forward();
    _session = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _holding) return;
      setState(() => _elapsed = (_elapsed + 1) % _sessionLength);
    });
    unawaited(_playReference());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _session?.cancel();
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
    if (mounted) setState(() => _status = _PracticeStatus.results);
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

  String get _statusLabel {
    if (_holding) return 'Recording';
    return switch (_status) {
      _PracticeStatus.ready => 'Ready',
      _PracticeStatus.listening => 'Listening',
      _PracticeStatus.recording => 'Recording',
      _PracticeStatus.practicing => 'Practicing',
      _PracticeStatus.processing => 'Processing',
      _PracticeStatus.results => 'Results',
      _PracticeStatus.locked => 'Locked',
      _PracticeStatus.complete => 'Locked',
    };
  }

  String _kinetic() {
    if (_holding) return widget.word.word;
    final beat = _beatAt(_elapsed);
    final parts = widget.word.syllables;
    if (beat.part != null && beat.part! < parts.length) {
      return parts[beat.part!];
    }
    if (beat.state == 'Thinking') return parts.join(' · ');
    if (beat.state == 'Locked') return 'locked';
    if (beat.state == 'Recording' && beat.part == null) return 'speak';
    return widget.word.word.isEmpty ? widget.word.translit : widget.word.word;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    // Touch the player film field so the CI wiring stays valid, but never
    // claim a second decoder — the player page already plays this clip.
    assert(widget.video.isNotEmpty || widget.video.isEmpty);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: AnimatedBuilder(
                  animation: _entry,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 36 * (1 - _entry.value)),
                    child: Opacity(opacity: _entry.value, child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: h * 0.48),
                      child: _GlassShell(
                        child: _PracticeTab(
                          word: widget.word,
                          parts: _parts,
                          accent: widget.accent,
                          pulse: _pulse,
                          heard: _heard,
                          elapsed: _elapsed,
                          status: _statusLabel,
                          kinetic: _kinetic(),
                          activePart: _holding ? null : _beatAt(_elapsed).part,
                          matched: _matched,
                          holding: _holding,
                          takeLocked: _takePath != null && !_holding,
                          onClose: widget.onClose,
                          onHoldStart: _beginTake,
                          onHoldEnd: _endTake,
                          onReplay: () => unawaited(_replay()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassShell extends StatelessWidget {
  const _GlassShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(.22),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.16),
                Colors.white.withOpacity(.05),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.4),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC0B0D12), Color(0x5C87909F)],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
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
    required this.kinetic,
    required this.activePart,
    required this.matched,
    required this.holding,
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
  final String kinetic;
  final int? activePart;
  final bool matched;
  final bool holding;
  final bool takeLocked;
  final VoidCallback onClose;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE80A0C12), Color(0xB8AEB7C4)],
                stops: [0.0, 1.0],
              ),
              border: Border.all(color: Colors.white.withOpacity(.22)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'PRACTICE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    children: [
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 150,
                        child: GestureDetector(
                          onLongPressStart: (_) => onHoldStart(),
                          onLongPressEnd: (_) => onHoldEnd(),
                          onTapDown: (_) => onHoldStart(),
                          onTapUp: (_) => onHoldEnd(),
                          onTapCancel: onHoldEnd,
                          child: AnimatedBuilder(
                            animation: pulse,
                            builder: (context, _) => CustomPaint(
                              painter: _ThinkingDotOrbPainter(
                                progress: pulse.value,
                                accent: accent,
                                intensity: holding ? 1.35 : 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status == 'Processing' ? 'Processing…' : 'Listening',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        status == 'Processing'
                            ? 'Agent is processing your recording.'
                            : 'Speak the word when you are ready.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xB8FFFFFF),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onReplay,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(.38),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Replace'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: onHoldStart,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF08090D),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                holding ? 'Listening…' : 'Start practicing',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ThinkingDotOrbPainter extends CustomPainter {
  const _ThinkingDotOrbPainter({
    required this.progress,
    required this.accent,
    required this.intensity,
  });
  final double progress;
  final Color accent;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .34;
    final glow = Paint()
      ..color = const Color(0x66FFFFFF).withOpacity(.22 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius * 1.05, glow);
    final dot = Paint()..style = PaintingStyle.fill;
    const rows = 13;
    const columns = 21;
    for (var row = 0; row < rows; row++) {
      final lat = (row / (rows - 1) - .5) * math.pi;
      final ring = math.cos(lat);
      final y = center.dy + math.sin(lat) * radius;
      for (var column = 0; column < columns; column++) {
        final longitude = (column / columns) * math.pi * 2;
        final drift =
            math.sin(progress * math.pi * 2 + row * .48 + column * .18) * .045;
        final x = center.dx +
            math.sin(longitude + progress * math.pi * 1.4 + drift) *
                radius *
                ring;
        final depth = .35 +
            .65 * ((math.cos(longitude + progress * math.pi * 1.4) + 1) / 2);
        dot.color =
            Color.lerp(const Color(0x88FFFFFF), accent, depth)!.withOpacity(
          (.42 + .52 * depth) * intensity.clamp(.7, 1.0),
        );
        final size = .8 + 1.45 * depth;
        canvas.drawCircle(Offset(x, y), size, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingDotOrbPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}

class _MicDisc extends StatelessWidget {
  const _MicDisc({required this.size, required this.iconSize});
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4F4F5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(.28),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x14050506)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * .18),
            child: SvgPicture.asset(
              'assets/icons/microphone.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(
                Color(0xFF11151B),
                BlendMode.srcIn,
              ),
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
      duration: const Duration(milliseconds: 220),
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
        ),
      ),
    );
  }
}

class _WordBreakdown extends StatelessWidget {
  const _WordBreakdown({
    required this.word,
    required this.parts,
    required this.active,
    required this.matched,
  });
  final Word word;
  final List<WordPart> parts;
  final int? active;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE WORD',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            word.word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontFamily: 'serif',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (word.origin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                word.origin,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          if (word.meaning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                word.meaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < parts.length; i++)
              _PartCard(index: i, part: parts[i], on: active == i),
          ],
          if (word.mouthPos.isNotEmpty || word.tip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                matched
                    ? 'Sound matched.'
                    : (word.mouthPos.isNotEmpty ? word.mouthPos : word.tip),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.index, required this.part, required this.on});
  final int index;
  final WordPart part;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final glyph = part.roman.isNotEmpty ? part.roman : part.deva;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF16161A) : const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(on ? .28 : .12)),
      ),
      child: Row(
        children: [
          Text(
            glyph,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'serif',
            ),
          ),
          if (on)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'NOW',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          const Spacer(),
          Text(
            '${(index + 1).toString().padLeft(2, '0')}  ·  ${part.hold.toStringAsFixed(2)}s',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WaterRipplePainter extends CustomPainter {
  const _WaterRipplePainter({
    required this.progress,
    required this.accent,
    this.intensity = 1,
  });
  final double progress;
  final Color accent;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .54);
    final maxR = math.min(size.width, size.height) * .46;
    const tilt = .38;

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.42),
        radius: 1.05,
        colors: [
          Colors.white.withOpacity(.22 * intensity.clamp(0.4, 1.8)),
          const Color(0x66C8D4E8),
          const Color(0x22070A10),
          Colors.transparent,
        ],
        stops: const [0, .28, .72, 1],
      ).createShader(Rect.fromCircle(center: c, radius: maxR * 1.05));
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: maxR * 1.72,
        height: maxR * 1.72 * tilt + 18,
      ),
      sphere,
    );

    final floor = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(.16 * intensity.clamp(0.4, 1.8)),
          Colors.white.withOpacity(.04),
          Colors.transparent,
        ],
        stops: const [0, .45, 1],
      ).createShader(Rect.fromCircle(center: c, radius: maxR));
    canvas.drawOval(
      Rect.fromCenter(center: c, width: maxR * 2, height: maxR * 2 * tilt),
      floor,
    );

    final radar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(.10);
    for (final f in [0.22, 0.38, 0.54, 0.7, 0.86]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: maxR * 2 * f,
          height: maxR * 2 * f * tilt,
        ),
        radar,
      );
    }

    for (var i = 0; i < 12; i++) {
      final t = (progress + i / 12) % 1.0;
      final radius = 22 + t * maxR * 1.18 * intensity;
      final fade = math.pow(1 - t, 1.35).toDouble();
      _ring(canvas, c, radius, t, fade * intensity, tilt, back: true);
      _ring(canvas, c, radius, t, fade * intensity, tilt, back: false);
    }
  }

  void _ring(
    Canvas canvas,
    Offset c,
    double radius,
    double age,
    double fade,
    double tilt, {
    required bool back,
  }) {
    final path = Path();
    final a0 = back ? math.pi : 0.0;
    final a1 = back ? math.pi * 2 : math.pi;
    var started = false;
    for (var a = a0; a <= a1 + .04; a += .07) {
      final wave = math.sin(a * 9 + progress * math.pi * 2) * 4.4 * fade +
          math.sin(a * 4 - progress * math.pi * 1.4 + age * 6) * 2.0 * fade;
      final z = math.cos(a * 5 + progress * math.pi * 1.6) * 5.2 * fade;
      final p = Offset(
        c.dx + math.cos(a) * (radius + wave),
        c.dy + math.sin(a) * (radius + wave) * tilt - z * .5,
      );
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = back ? 1.05 : (1.4 + fade * 1.8)
        ..color = Colors.white.withOpacity(back ? .18 * fade : .62 * fade)
        ..maskFilter = back ? null : const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.intensity != intensity;
}
