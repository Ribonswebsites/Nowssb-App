/// Premium Practice tab opened from the NowssB player.
///
/// Glass over the player film. A white microphone in a circle sits on a
/// tilted 3D water plane. Hold to speak writes a take. Below the orb: the
/// word broken into parts, then the 29-second vertical-edit craft.
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
  processing,
  results,
  locked,
  complete,
}

const _sessionLength = 29;

class _Beat {
  const _Beat(this.at, this.until, this.state, this.part, this.note);
  final int at;
  final int until;
  final String state;
  final int? part;
  final String note;
}

const _beats = <_Beat>[
  _Beat(0, 2, 'Listening', null, 'Talking head with the first large caption'),
  _Beat(
    2,
    4,
    'Practicing',
    0,
    'Talking head plus the small inset — mouth shape',
  ),
  _Beat(
    4,
    7,
    'Practicing',
    1,
    'Product motion. The syllable replaces the last word.',
  ),
  _Beat(
    7,
    10,
    'Listening',
    null,
    'Dark UI. Slow motion inside, hard cut outside.',
  ),
  _Beat(
    10,
    14,
    'Recording',
    2,
    'Close-up with changing captions, timed to the voice',
  ),
  _Beat(
    14,
    18,
    'Thinking',
    null,
    'More UI examples. The three cuts in one frame.',
  ),
  _Beat(18, 22, 'Recording', null, 'Feature detail. You take the word.'),
  _Beat(
    22,
    26,
    'Solving',
    null,
    'Return to the full word with the repository of the mouth',
  ),
  _Beat(26, 29, 'Locked', null, 'Final screen. Closing word. Hold.'),
];

_Beat _beatAt(int t) {
  final n = ((t % _sessionLength) + _sessionLength) % _sessionLength;
  return _beats.firstWhere(
    (b) => n >= b.at && n < b.until,
    orElse: () => _beats.last,
  );
}

class _CraftStep {
  const _CraftStep(this.n, this.title, this.kicker, this.body);
  final String n;
  final String title;
  final String kicker;
  final String body;
}

const _craftSteps = <_CraftStep>[
  _CraftStep(
    '01',
    'Create the project',
    'Canvas',
    'Practice is a vertical edit, not a looping meditation video. Set the session as 9:16, 1080 × 1920, 30 fps. Import only the voice, the mouth inset, the dark UI stills.',
  ),
  _CraftStep(
    '02',
    'Record the talking head',
    'Voice',
    'Shoot vertical, subject centered, chest-up. Soft front light. Record the full word in one take, then cut it into the syllables you will emphasize.',
  ),
  _CraftStep(
    '03',
    'Build the timeline',
    '29 seconds',
    'Most shots live between 0.5 and 2 seconds. Nothing should sit long enough to become wallpaper. The 29-second practice is the cut, not the lecture.',
  ),
  _CraftStep(
    '04',
    'The text style',
    'Typography',
    'High-contrast serif. White. Large. Centered. Slightly tight tracking. No box behind it. Never set the whole sentence as one caption. Split it. Each word appears at the moment it is spoken.',
  ),
  _CraftStep(
    '05',
    'Animate each word',
    'Kinetic',
    'A separate layer per word, parked on the spoken moment. Entrance is 0.08–0.15s — fade or a tiny pop, scale 95 → 100, ease-out. Then the word is replaced, not faded like a subtitle.',
  ),
  _CraftStep(
    '06',
    'The inset',
    'Demo card',
    'A small horizontal rectangle over the talking head — 60–75% of the width, lower-middle, slightly rounded, a small shadow. It must keep moving while the head remains visible.',
  ),
  _CraftStep(
    '07',
    'Match-cut the inset',
    'Edit',
    'Do not use decorative transitions. Match shapes and positions. Most cuts are 1 frame. Occasionally a 2–4 frame dissolve. A slight zoom makes the cut feel chosen.',
  ),
  _CraftStep(
    '08',
    'Screen recordings',
    'Evidence',
    'Short clips of the dark interface, a loader, a button changing state, the word locking into progress. Crop to 9:16. Kill browser chrome. Raise contrast.',
  ),
  _CraftStep(
    '09',
    'Dark UI shots',
    'Punctuation',
    'Near-black fields. White or light-gray marks. A soft glow only on the live element. Circular loaders move slowly. The edit cuts quickly; the UI inside does not.',
  ),
  _CraftStep(
    '10',
    'Subtle camera',
    'Push-in',
    'Talking head: scale 100 → 103–106 over the shot, with a slight drift. It should only keep the frame from dying.',
  ),
  _CraftStep(
    '11',
    'Speed',
    'Ramps',
    'Normal is 100%. Emphasis 85–95%. Transition 110–125%. Timing of the cut does more work than the ramp.',
  ),
  _CraftStep(
    '12',
    'Grade',
    'Color',
    'Talking head: slightly brighter, contrast up a little, highlights down. Product UI: contrast up, blacks a little lower, a very small glow. No cinematic LUT soup.',
  ),
  _CraftStep(
    '13',
    'Sound',
    'Mix',
    'Voice is the spine. Soft music under it. A small whoosh on major cuts. Quiet clicks on interface. Almost inaudible taps when the kinetic word changes.',
  ),
  _CraftStep(
    '14',
    'Captions by hand',
    'Timing',
    'Split into words, rebuild each word in the large serif, and park it on the speaker’s timing. Change the word on the cut or the gesture.',
  ),
];

const _formula = <String>[
  'Talking head',
  'Large serif word',
  'Small moving inset',
  'Hard cut',
  'Dark UI example',
  'New word',
  'Screen recording',
  'Subtle zoom',
  'Another hard cut',
];

const _formulaLaws = <String>[
  'Change the large word in sync with speech.',
  'Keep the inset demo visible over the talking head.',
  'Use high-contrast serif typography.',
  'Cut quickly between real product examples.',
  'Use hard cuts instead of flashy transitions.',
  'Keep all movement subtle and intentional.',
  'Use dark UI screens as visual punctuation.',
];

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
                child: _MicDisc(size: 28, iconSize: 14),
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
      duration: const Duration(milliseconds: 520),
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
    if (mounted) setState(() => _status = _PracticeStatus.listening);
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
    if (!mounted) return;
    setState(() => _status = _PracticeStatus.results);
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
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .34,
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
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: const ColoredBox(color: Color(0x66050506)),
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: _entry,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 28 * (1 - _entry.value)),
                  child: Transform.scale(
                    scale: .97 + _entry.value * .03,
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
                  kinetic: _kinetic(),
                  note: _beatAt(_elapsed).note,
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
          ],
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
    required this.note,
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
  final String note;
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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xD20B0F14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.14)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
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
                          'PRACTICE LAB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    children: [
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 188,
                        child: GestureDetector(
                          onLongPressStart: (_) => onHoldStart(),
                          onLongPressEnd: (_) => onHoldEnd(),
                          onTapDown: (_) => onHoldStart(),
                          onTapUp: (_) => onHoldEnd(),
                          onTapCancel: onHoldEnd,
                          child: AnimatedBuilder(
                            animation: pulse,
                            builder: (context, _) => CustomPaint(
                              painter: _ThinkingOrbPainter(
                                progress: pulse.value,
                                accent: accent,
                                intensity: holding ? 1.55 : 1.0,
                              ),
                              child: Center(
                                child: _MicDisc(
                                  size: holding ? 78 : 72,
                                  iconSize: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                holding || status == 'Recording' ? 1 : .45,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        child: Text(
                          kinetic,
                          key: ValueKey(kinetic),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            height: .95,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              active: holding || activePart == i,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InsetCard(
                        glyph: () {
                          if (activePart != null &&
                              activePart! < parts.length) {
                            final p = parts[activePart!];
                            return p.roman.isNotEmpty ? p.roman : p.deva;
                          }
                          return word.word;
                        }(),
                        mouth: () {
                          if (activePart != null &&
                              activePart! < parts.length &&
                              parts[activePart!].say.isNotEmpty) {
                            return parts[activePart!].say;
                          }
                          return word.mouthPos.isNotEmpty
                              ? word.mouthPos
                              : note;
                        }(),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: elapsed / _sessionLength,
                          minHeight: 2,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '00:${elapsed.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            '00:29',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _PracticePhaseTabs(status: status),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onReplay,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(.2),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Replay session'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: onHoldStart,
                              onLongPress: onHoldStart,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF050506),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: _AnimatedHoldLabel(
                                holding: holding,
                                processing: status == 'Processing',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        takeLocked
                            ? 'Take saved on this device.'
                            : 'Nothing locked yet. Hold the word once.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
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
                      _WordBreakdown(
                        word: word,
                        parts: parts,
                        active: activePart,
                        matched: matched,
                      ),
                      _SessionCraft(elapsed: elapsed),
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
            color: Colors.white.withOpacity(.22),
            blurRadius: 28,
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

class _PracticePhaseTabs extends StatelessWidget {
  const _PracticePhaseTabs({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    const phases = ['Listening', 'Processing', 'Results'];
    final active = status == 'Processing' ? 1 : (status == 'Results' ? 2 : 0);
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < phases.length; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i == active ? Colors.white : const Color(0x16000000),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: Colors.white.withOpacity(i == active ? .9 : .16),
                ),
              ),
              child: Text(
                phases[i].toUpperCase(),
                style: TextStyle(
                  color: i == active ? const Color(0xFF050506) : Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
            if (i != phases.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _AnimatedHoldLabel extends StatelessWidget {
  const _AnimatedHoldLabel({required this.holding, required this.processing});
  final bool holding;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final label = processing
        ? 'Processing…'
        : (holding ? 'Listening…' : 'Hold to speak');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Text(label, key: ValueKey(label)),
    );
  }
}

class _ThinkingOrbPainter extends CustomPainter {
  const _ThinkingOrbPainter({
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
    final radius = math.min(size.width, size.height) * .31;
    final glow = Paint()
      ..color = accent.withOpacity(.12 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius * 1.08, glow);
    final lines = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;
    for (var i = -9; i <= 9; i++) {
      final x = center.dx + i * radius / 9;
      final width = math.sqrt(
        math.max(0, radius * radius - (x - center.dx) * (x - center.dx)),
      );
      final wave = math.sin(progress * math.pi * 2 + i * .42) * 3.5 * intensity;
      lines.color = accent.withOpacity(
        (.22 + .62 * (1 - i.abs() / 10)) * intensity.clamp(.7, 1.0),
      );
      canvas.drawArc(
        Rect.fromLTRB(
          x - width * .12 + wave,
          center.dy - width,
          x + width * .12 + wave,
          center.dy + width,
        ),
        -math.pi / 2,
        math.pi,
        false,
        lines,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingOrbPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}

class _InsetCard extends StatelessWidget {
  const _InsetCard({required this.glyph, required this.mouth});
  final String glyph;
  final String mouth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                const Text(
                  'INSET',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  glyph,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(.1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                mouth,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.35,
                ),
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
      padding: const EdgeInsets.only(top: 28),
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
          const SizedBox(height: 8),
          Text(
            word.word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontFamily: 'serif',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (word.origin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                word.origin,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          if (word.meaning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                word.meaning,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          for (var i = 0; i < parts.length; i++)
            _PartCard(index: i, part: parts[i], on: active == i),
          if (word.mouthPos.isNotEmpty || word.tip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF16161A) : const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(on ? .28 : .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                glyph,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontFamily: 'serif',
                ),
              ),
              if (on)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    'NOW',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      letterSpacing: 1.8,
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
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: on ? 1 : (part.hold / 2).clamp(0.2, .85),
            minHeight: 1,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          if (part.say.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              part.say,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionCraft extends StatefulWidget {
  const _SessionCraft({required this.elapsed});
  final int elapsed;

  @override
  State<_SessionCraft> createState() => _SessionCraftState();
}

class _SessionCraftState extends State<_SessionCraft> {
  String _open = '05';
  int? _kineticLock;
  String? _darkLock;

  @override
  Widget build(BuildContext context) {
    final kinetic = [
      'these',
      'animations',
      'feel',
      'native',
      'and',
      'polished',
    ];
    final dark = ['Solving…', 'Thinking…', 'Listening…', 'Paused'];
    final ki = _kineticLock ?? (widget.elapsed * 7 ~/ 5) % kinetic.length;
    final di = _darkLock ?? dark[widget.elapsed ~/ 3 % dark.length];

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSION CRAFT',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A 29-second vertical edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'serif',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Practice is not one complicated 3D animation. It is a fast-paced cut: talking head, product stills, a small inset, large white serif words, hard cuts, short zooms, and screen recordings timed to the voice.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  for (final b in _beats)
                    Expanded(
                      flex: b.until - b.at,
                      child: Container(
                        alignment: Alignment.center,
                        color:
                            widget.elapsed >= b.at && widget.elapsed < b.until
                            ? Colors.white12
                            : const Color(0xFF080808),
                        child: Text(
                          b.state,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '29s · 9:16 · 1080 × 1920 · 30 fps',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.12)),
              color: const Color(0xFF0B0B0D),
            ),
            child: Column(
              children: [
                for (final b in _beats)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: widget.elapsed >= b.at && widget.elapsed < b.until
                        ? const Color(0xFF16161A)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 58,
                          child: Text(
                            '${b.at}–${b.until}s',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b.note,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CAPCUT WORKFLOW',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fourteen cuts that make the word feel native',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 12),
          for (final step in _craftSteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: const Color(0xFF0B0B0D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(.12)),
                ),
                child: InkWell(
                  onTap: () =>
                      setState(() => _open = _open == step.n ? '' : step.n),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              step.n,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    step.kicker.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _open == step.n ? '–' : '+',
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                        if (_open == step.n) ...[
                          const SizedBox(height: 8),
                          Text(
                            step.body,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: Column(
              children: [
                const Text(
                  'DARK UI SHOTS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  di,
                  key: ValueKey(di),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in dark)
                      GestureDetector(
                        onTap: () => setState(() => _darkLock = s),
                        child: Text(
                          s.replaceAll('…', ''),
                          style: TextStyle(
                            color: di == s ? Colors.white : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: Column(
              children: [
                const Text(
                  'WORD REPLACEMENT',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  kinetic[ki],
                  key: ValueKey(kinetic[ki]),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < kinetic.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _kineticLock = i),
                        child: Text(
                          kinetic[i],
                          style: TextStyle(
                            color: ki == i ? Colors.white : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'THE FORMULA',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _formula.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _formula[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          for (final law in _formulaLaws)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                law,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Recreate the editing system, not just the appearance: narration-driven word changes, product-demo inserts, screen-recording montage, and minimal editorial motion.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
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
    final c = Offset(size.width / 2, size.height * .58);
    final maxR = math.min(size.width, size.height) * .46;
    const tilt = .3;

    final floor = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(.14 * intensity.clamp(0.4, 1.8)),
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
      ..color = Colors.white.withOpacity(.07);
    for (final f in [0.28, 0.5, 0.74]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: maxR * 2 * f,
          height: maxR * 2 * f * tilt,
        ),
        radar,
      );
    }

    for (var i = 0; i < 10; i++) {
      final t = (progress + i / 10) % 1.0;
      final radius = 28 + t * maxR * 1.15 * intensity;
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
      final wave =
          math.sin(a * 7 + progress * math.pi * 2) * 5.2 * fade +
          math.sin(a * 3 - progress * math.pi * 1.4 + age * 6) * 2.2 * fade;
      final z = math.cos(a * 4 + progress * math.pi * 1.6) * 4.2 * fade;
      final p = Offset(
        c.dx + math.cos(a) * (radius + wave),
        c.dy + math.sin(a) * (radius + wave) * tilt - z * .45,
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
