/// Compact Practice tab opened from the NowssB player.
///
/// Looks like the Now Playing practice card: PRACTICE header, close, status,
/// glowing-orb film, and two pills. A separate black tab above it shows the
/// word and syllable breakdown. The player behind the tab is blurred; the
/// cards stay dark so the video orb can blend.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'dart:io';
import 'dart:typed_data';

import '../data/models.dart';
import '../pronunciation/reference.dart';
import '../pronunciation/scorer.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../widgets/app_thinking_loader.dart';
import '../widgets/glass_wrap.dart';
import '../admin/template/editable.dart';

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

const _practiceOrbClip = 'assets/video/practice-orb.mp4';
const _storeMark = 'assets/store/nowssb-bag-headphones.webp';

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
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 38,
              child: Center(
                child: EditableSvg.asset(
                  'assets/icons/microphone.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  slot: 'practice_overlay.PracticeDockOrb',
                ),
              ),
            ),
            const EditableLabel(
              'practice_overlay.PracticeDockOrb',
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
  late final AnimationController _entry;
  late final AnimationController _spin;
  late final CurvedAnimation _open;
  late final CurvedAnimation _punch;
  late final Animation<Offset> _slide;
  late final Animation<double> _cardScale;

  Timer? _clock;
  String? _takePath;
  bool _holding = false;
  // Client reference takes (WAV bytes). null = still loading.
  List<Uint8List>? _refs;
  PronunciationResult? _result;
  int _elapsed = 0;
  _PracticeStatus _status = _PracticeStatus.ready;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _open = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _punch = CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_open);
    _cardScale = Tween<double>(begin: 0.96, end: 1).animate(_punch);
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed) unawaited(_playReference());
    });
    _entry.forward();
    _spin.forward();
    unawaited(_loadRefs());
  }

  Future<void> _loadRefs() async {
    final refs = await loadReferences(widget.word);
    if (mounted) setState(() => _refs = refs);
  }

  bool get _noReference => _refs != null && _refs!.isEmpty;

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_finishCapture());
    _open.dispose();
    _punch.dispose();
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
    if (_noReference) {
      setState(() => _result =
          const PronunciationResult(outcome: PronunciationOutcome.noReference));
      return;
    }
    _clock?.cancel();
    setState(() {
      _holding = true;
      _elapsed = 0;
      _result = null;
      _status = _PracticeStatus.listening;
    });

    try {
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        if (mounted) {
          setState(() {
            _holding = false;
            _status = _PracticeStatus.ready;
          });
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
              content: Text('Allow the microphone in phone settings to practise.')));
        }
        return;
      }
      // Replay (or the 30 s end) can land while the mic prompt, the recorder
      // or speech is still starting. Recording must not start for a take
      // that already ended — it used to run on with the screen stuck on
      // "Listening", the clock frozen and the mic open.
      if (!_holding || !mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      if (!_holding || !mounted) return;
      // WAV 16 kHz mono: compared sound-for-sound with the client's take.
      _takePath = '${dir.path}/nwsb-practice-${widget.word.key}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: _takePath!,
      );
      if (!_holding || !mounted) {
        await _finishCapture();
        return;
      }
      if (!mounted) return;
      if (!_holding) {
        await _finishCapture();
        return;
      }
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
      if (mounted) {
        setState(() {
          _holding = false;
          _status = _PracticeStatus.ready;
        });
      }
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
    PronunciationResult result;
    try {
      final take = await File(_takePath!).readAsBytes();
      final refs = _refs ?? await loadReferences(widget.word);
      result = await scoreInBackground(refs, take, widget.word.syllables);
    } catch (_) {
      result = const PronunciationResult(outcome: PronunciationOutcome.tooQuiet);
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _status = result.outcome == PronunciationOutcome.scored && result.score >= 75
          ? _PracticeStatus.complete
          : _PracticeStatus.results;
    });
  }

  Future<void> _finishCapture() async {
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
      _result = null;
      _elapsed = 0;
      _holding = false;
      _status = _PracticeStatus.ready;
    });
    _spin
      ..reset()
      ..forward();
    await _playReference();
  }

  String get _statusLabel {
    if (_holding || _status == _PracticeStatus.recording) return 'Listening';
    final r = _result;
    if (r != null && r.outcome == PronunciationOutcome.scored) {
      return 'Score ${r.score}';
    }
    if (_noReference) return 'Reference not added yet';
    if (_status == _PracticeStatus.processing ||
        _status == _PracticeStatus.practicing) {
      return 'Analyzing';
    }
    return 'Waiting';
  }

  /// Feedback line under the orb; null keeps the template copy.
  String? get _message {
    final r = _result;
    if (r != null) {
      final weak = r.weakest;
      if (r.outcome == PronunciationOutcome.scored && weak != null) {
        return '${r.verdict}. Work on "${weak.text}".';
      }
      return r.verdict;
    }
    if (_noReference) {
      return 'The recording for ${widget.word.word} has not been added yet. Practice scoring opens as soon as it is.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.video.isNotEmpty || widget.video.isEmpty);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _open,
              child: GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: const ColoredBox(color: Color(0x59000000)),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _open,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WordBreakTab(word: widget.word, result: _result),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {},
                          child: _BlackTab(
                            status: _statusLabel,
                            message: _message,
                            holding: _holding,
                            onStart: _beginTake,
                            onReplay: () => unawaited(_replay()),
                            onClose: widget.onClose,
                          ),
                        ),
                      ],
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

class _WordBreakTab extends StatelessWidget {
  const _WordBreakTab({required this.word, this.result});

  final Word word;
  final PronunciationResult? result;

  /// After a scored take each syllable box shows how close it was.
  Color _boxColor(int i) {
    final r = result;
    if (r == null || r.outcome != PronunciationOutcome.scored || i >= r.syllables.length) {
      return const Color(0xFFF5F5F5);
    }
    final s = r.syllables[i].score;
    if (s >= 75) return const Color(0xFFB9F6CA);
    if (s >= 50) return const Color(0xFFFFE58F);
    return const Color(0xFFFFB3B3);
  }

  @override
  Widget build(BuildContext context) {
    final raw = word.word.trim();
    final title = raw.isEmpty
        ? ''
        : '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
    final syllables = word.syllables
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final syllableRow = syllables.isEmpty
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < syllables.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xCCF4F4F5),
                      shape: BoxShape.circle,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _boxColor(i),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    syllables[i],
                    style: const TextStyle(
                      color: Color(0xFF0A0A0B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ],
          );

    // Glass wrapper around a black pill: [bigger composing] [Ananda + syllables].
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(6),
      radius: 32,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 18, 14),
        decoration: BoxDecoration(
          color: const Color(0xF00C0C0E),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppThinkingLoader(
              size: 48,
              state: OrbState.composing,
              circlePad: 8,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel(
                    'practice_overlay.WordBreakTab',
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF5F5F7),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                  if (syllables.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    syllableRow,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlackTab extends StatelessWidget {
  const _BlackTab({
    required this.status,
    this.message,
    required this.holding,
    required this.onStart,
    required this.onReplay,
    required this.onClose,
  });

  final String status;
  final String? message;
  final bool holding;
  final VoidCallback onStart;
  final VoidCallback onReplay;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF00C0C0E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EditableLabel(
                    'practice_overlay.BlackTab',
                    'PRACTICE',
                    style: TextStyle(
                      color: Color(0xFFB8B8BC),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 22,
                        height: 22,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x55FFFFFF)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: EditableImage.asset(
                            _storeMark,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            slot: 'practice_overlay.BlackTab',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.close, color: Color(0xCCFFFFFF), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD4D4D8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 4.6,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 132, child: Center(child: _OrbFilm())),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: message != null
                ? Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xCCF4F4F5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        letterSpacing: 0.1))
                : const EditableLabel(
              'practice_overlay.BlackTab',
              'Wait for you to say it — then tap Start',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xCCF4F4F5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onReplay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.2),
                      backgroundColor: Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: const EditableLabel(
                      'practice_overlay.BlackTab',
                      'Replay',
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
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing sphere loop. Circular clip, no chrome, black plate matches the tab.
class _OrbFilm extends StatelessWidget {
  const _OrbFilm();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 112,
        height: 112,
        child: ClipOval(
          child: ColoredBox(
            color: Colors.black,
            child: Transform.scale(
              scale: 1.16,
              child: const NwsbVideo(
                asset: _practiceOrbClip,
                fit: BoxFit.cover,
                priority: ClipPriority.feature,
                loop: true,
                autoplay: true,
                showPoster: true,
                slot: 'practice_overlay.OrbFilm',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
