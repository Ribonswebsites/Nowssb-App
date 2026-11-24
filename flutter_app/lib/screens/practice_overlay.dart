/// Compact Practice tab opened from the NowssB player.
///
/// Looks like the Now Playing practice card: PRACTICE header, close, status,
/// glowing-orb film, and two pills. A separate black tab above it shows the
/// word and syllable breakdown. The player behind the tab is blurred; the
/// cards stay dark so the video orb can blend.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'dart:io';
import 'dart:typed_data';

import '../data/models.dart';
import '../data/word_devanagari.dart';
import '../data/entitlements.dart';
import '../features/stage_practice/stage_mic.dart';
import '../features/stage_practice/stage_vad.dart';
import '../data/word_voice.dart';
import '../features/stage_practice/stage_pack.dart';
import '../features/stage_practice/stage_progress.dart';
import '../features/stage_practice/stage_scoring.dart';
import '../features/stage_practice/stage_take_panel.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../pronunciation/reference.dart';
import '../pronunciation/scorer.dart';
import '../pronunciation/shabda/shabda_practice.dart' show AttemptResult, AttemptStatus;
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
    this.pack,
    this.stage,
    this.onStage,
  });

  final Word word;

  /// A teacher-recorded word: the take is scored against [stage]'s
  /// recording (sub-scores, where in the word, tips), and progress shows.
  final StagePack? pack;
  final PackStage? stage;

  /// Plays stage N in the Player (after passing, "Stage N ›").
  final ValueChanged<int>? onStage;

  /// Tests: stands in for the microphone.
  @visibleForTesting
  static StageMic Function()? debugMic;
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
  StageMic? _mic;
  StageTake? _take;

  // Stage takes start by themselves after a quick 3-2-1 and stop by
  // themselves once the word has been said (StageVad).
  int? _count;
  Timer? _countTimer;
  StageVad? _vad;
  double _level = -60;
  bool _ending = false;

  bool get _staged => widget.pack != null && widget.stage != null;

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
      if (status != AnimationStatus.completed) return;
      if (_staged) {
        _startCountdown();
      } else {
        unawaited(_playReference());
      }
    });
    // The Player's recording must not play into the microphone.
    if (_staged) unawaited(WordVoice.instance.stop());
    _entry.forward();
    _spin.forward();
    if (!_staged) unawaited(_loadRefs());
  }

  Future<void> _loadRefs() async {
    final refs = await loadReferences(widget.word);
    if (mounted) setState(() => _refs = refs);
  }

  bool get _noReference => !_staged && _refs != null && _refs!.isEmpty;

  @override
  void dispose() {
    _clock?.cancel();
    _countTimer?.cancel();
    unawaited(_finishCapture());
    if (_mic != null) {
      unawaited(_mic!.cancel());
      _mic!.dispose();
    }
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

  // ── Teacher stage: 3-2-1, record, stop by itself, score ──
  bool get _busy => _count != null || _holding || _status == _PracticeStatus.recording;

  /// The main button: Cancel while counting down or listening, else a new take.
  Future<void> _stageTap() async {
    if (_busy) {
      await _cancelTake();
    } else if (_status != _PracticeStatus.processing) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (!mounted || _busy || _status == _PracticeStatus.processing) return;
    _countTimer?.cancel();
    setState(() {
      _take = null;
      _count = 3;
      _status = _PracticeStatus.ready;
    });
    _countTimer = Timer.periodic(const Duration(milliseconds: 450), (t) {
      if (!mounted) return t.cancel();
      if ((_count ?? 0) <= 1) {
        t.cancel();
        setState(() => _count = null);
        unawaited(_beginStageTake());
      } else {
        setState(() => _count = _count! - 1);
      }
    });
  }

  Future<void> _cancelTake() async {
    _countTimer?.cancel();
    _clock?.cancel();
    final wasRecording = _holding || _status == _PracticeStatus.recording;
    if (!mounted) return;
    setState(() {
      _count = null;
      _holding = false;
      _status = _PracticeStatus.ready;
    });
    if (wasRecording) await _mic?.cancel();
  }

  Future<void> _beginStageTake() async {
    final stage = widget.stage!;
    _clock?.cancel();
    _ending = false;
    final vad = _vad = StageVad.forStage(stage.seconds);
    setState(() {
      _holding = true;
      _elapsed = 0;
      _take = null;
      _level = -60;
      _status = _PracticeStatus.listening;
    });
    try {
      final mic = _mic ??= PracticeLabSheet.debugMic?.call() ?? RecordStageMic();
      if (!await mic.hasPermission()) {
        if (!mounted) return;
        setState(() {
          _holding = false;
          _status = _PracticeStatus.ready;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Allow the microphone in phone settings to practise.')));
        return;
      }
      if (!_holding || !mounted) return;
      var heardLevel = false;
      // Time is counted in mic frames (the level stream runs every 50 ms),
      // so a busy UI thread cannot stretch or squeeze the take.
      var frames = 0;
      await mic.start('nwsb-stage-${widget.pack!.wordKey}-${stage.number}', (db) {
        if (!mounted || !_holding || _ending || !identical(_vad, vad)) return;
        heardLevel = true;
        frames++;
        final d = vad.add(db, Duration(milliseconds: 50 * frames));
        if ((db - _level).abs() > 1.5) setState(() => _level = db);
        if (d != VadDecision.keepGoing) unawaited(_endStageTake(silent: d == VadDecision.noSpeech));
      });
      if (!mounted) return;
      if (!_holding) {
        await mic.cancel();
        return;
      }
      setState(() => _status = _PracticeStatus.recording);
      // Back-stop when the level stream is late or absent: the take still
      // ends at the stage's max length.
      var ticks = 0;
      _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted || !_holding || _ending) return;
        final t = Duration(milliseconds: 250 * ++ticks);
        if (t >= vad.maxLength || (!heardLevel && t >= vad.noSpeechTimeout + const Duration(seconds: 2))) {
          unawaited(_endStageTake(silent: heardLevel && !vad.heardSpeech));
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

  Future<void> _endStageTake({bool silent = false}) async {
    if (_ending) return;
    if (!_holding && _status != _PracticeStatus.recording) return;
    _ending = true;
    _clock?.cancel();
    final pack = widget.pack!, stage = widget.stage!;
    setState(() {
      _holding = false;
      _status = _PracticeStatus.processing;
    });
    final unheard = AttemptResult(
        status: AttemptStatus.silent,
        headline: 'We didn’t hear you',
        message: 'Say the word clearly after the 3-2-1. Tap Try again when you’re ready.');
    StageTake take;
    try {
      if (silent) {
        await _mic?.cancel();
        throw StateError('no speech');
      }
      final bytes = await _mic?.stop();
      if (bytes == null) throw StateError('no take');
      final ref = (await rootBundle.load(stage.reference)).buffer.asUint8List();
      take = await scoreStageTakeWithContour(ref, bytes, stage: stage.number, passMark: pack.passMark);
      if (!take.result.scored) take = StageTake(unheard, take.refTimes, take.refEnergyDb);
    } catch (_) {
      take = StageTake(unheard, const [], const []);
    }
    if (take.result.scored) {
      await StageProgressStore.instance.addAttempt(pack.wordKey, stage.number, score: take.result.overall, passed: take.result.passed);
    }
    if (!mounted) return;
    setState(() {
      _take = take;
      _ending = false;
      _status = take.result.passed ? _PracticeStatus.complete : _PracticeStatus.results;
    });
  }

  /// The next recorded stage, offered after a good take.
  PackStage? get _nextStage {
    final pack = widget.pack, stage = widget.stage;
    if (pack == null || stage == null) return null;
    if (_take?.result.passed != true) return null;
    return pack.stages.where((s) => s.number == stage.number + 1).firstOrNull;
  }

  Future<void> _beginTake() async {
    if (_staged) return _stageTap();
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
    _countTimer?.cancel();
    _count = null;
    await _finishCapture();
    await _mic?.cancel();
    if (!mounted) return;
    setState(() {
      _takePath = null;
      _result = null;
      _take = null;
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
    if (_staged && _count != null) return 'Get ready';
    if (_holding || _status == _PracticeStatus.recording) return 'Listening';
    if (_staged) {
      final t = _take;
      if (_status == _PracticeStatus.processing) return 'Scoring';
      if (t != null && t.result.scored) return 'Score ${t.result.overall}';
      return '${widget.word.word} · Stage ${widget.stage!.number}';
    }
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
    if (_staged) {
      if (_count != null) return 'Recording starts in a moment.';
      if (_holding || _status == _PracticeStatus.recording) return 'Say it now. It stops by itself when you finish.';
      if (_status == _PracticeStatus.processing) return 'Comparing your take with the teacher’s recording…';
      if (_take != null) return 'Tap Try again to say it once more, or Replay to hear the teacher.';
      final st = widget.stage!;
      return 'Tap Start, wait for 3-2-1, then say Stage ${st.number}${st.deva.isNotEmpty ? ' (${st.deva})' : ''}.';
    }
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
                      child: SingleChildScrollView(
                      key: const ValueKey('practice-sheet-scroll'),
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Staged words: ONE pop-up only, no word card above it.
                        if (!_staged) ...[
                          _WordBreakTab(word: widget.word, result: _result, stages: null),
                          const SizedBox(height: 10),
                        ],
                        GestureDetector(
                          onTap: () {},
                          child: _BlackTab(
                            status: _statusLabel,
                            message: _message,
                            holding: _holding,
                            startLabel: _staged
                                ? (_busy ? 'Cancel' : (_take != null ? 'Try again' : 'Start'))
                                : null,
                            centre: !_staged
                                ? null
                                : _count != null
                                    ? _Countdown(n: _count!, tick: const Duration(milliseconds: 450))
                                    : (_holding || _status == _PracticeStatus.recording)
                                        ? _ListeningRing(level: _level)
                                        : null,
                            result: _take == null
                                ? null
                                : StageResultPanel(take: _take!, stage: widget.stage!.number),
                            next: _nextStage == null || widget.onStage == null
                                ? null
                                : (_nextStage!.number, () => widget.onStage!(_nextStage!.number)),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _WordBreakTab extends StatelessWidget {
  const _WordBreakTab({required this.word, this.result, this.stages});

  final Word word;
  final PronunciationResult? result;

  /// Stage progress (teacher-recorded words), under the title.
  final Widget? stages;

  @override
  Widget build(BuildContext context) {
    final raw = word.word.trim();
    final title = raw
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
    // English title on top; the Devanagari (content data only, never
    // transliterated) on the line under it. No English syllable pills.
    final deva = wordDevanagari(word);

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
                  if (deva != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      deva,
                      key: const ValueKey('practice-card-deva'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE6E6EA),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (stages != null) ...[
                    const SizedBox(height: 10),
                    stages!,
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
    this.startLabel,
    this.result,
    this.next,
    this.centre,
  });

  /// Replaces the orb: the 3-2-1 countdown, or the live level while listening.
  final Widget? centre;

  final String? startLabel;
  final Widget? result;
  final (int, VoidCallback)? next;
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
          if (result == null) ...[
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
          SizedBox(height: 132, child: Center(child: centre ?? const _OrbFilm())),
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
          ],
          if (result != null) ...[
            const SizedBox(height: 4),
            result!,
          ],
          if (next != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('practice-next-stage'),
                onPressed: next!.$2,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0x26FFFFFF),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x40FFFFFF)),
                  shape: const StadiumBorder(),
                ),
                child: Text('Next: Stage ${next!.$1}  ›', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
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
                      key: const ValueKey('practice-start'),
                      startLabel ?? (holding ? 'Listening' : 'Start'),
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


/// Listening: a white ring that swells with the voice.
/// Live voice: a soft glass blob whose edge ripples with the real mic level,
/// two echo rings that swell as you speak, and a white mic at the centre.
class _ListeningRing extends StatefulWidget {
  const _ListeningRing({required this.level});
  final double level;

  @override
  State<_ListeningRing> createState() => _ListeningRingState();
}

class _ListeningRingState extends State<_ListeningRing> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  double _amp = 0; // smoothed 0..1
  final List<double> _trail = List<double>.filled(48, 0, growable: true);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      final target = ((widget.level + 55) / 40).clamp(0.0, 1.0);
      // Rise fast, fall slowly: feels alive without jitter.
      _amp += (target - _amp) * (target > _amp ? .35 : .08);
      _trail
        ..removeAt(0)
        ..add(_amp);
      setState(() => _t = d.inMicroseconds / 1e6);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('practice-listening'),
      width: 170,
      height: 170,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: CustomPaint(painter: _VoiceBlob(_t, _amp, List.of(_trail)))),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color.fromRGBO(255, 255, 255, .25 + .35 * _amp), blurRadius: 18 + 24 * _amp)],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.black, size: 26),
        ),
      ]),
    );
  }
}

class _VoiceBlob extends CustomPainter {
  _VoiceBlob(this.t, this.amp, this.trail);
  final double t;
  final double amp;
  final List<double> trail;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.shortestSide * .22;
    // Echo rings.
    for (var k = 0; k < 2; k++) {
      final g = ((t * .6 + k * .5) % 1);
      final r = base + 10 + g * (size.shortestSide * .26) * (.4 + amp);
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Color.fromRGBO(255, 255, 255, (1 - g) * (.10 + .30 * amp)));
    }
    // Fluid edge driven by the recent mic levels, layered twice.
    for (var layer = 0; layer < 2; layer++) {
      final path = Path();
      const n = 96;
      for (var i = 0; i <= n; i++) {
        final a = i / n * math.pi * 2;
        final h = trail[(i * trail.length ~/ n) % trail.length];
        final wob = math.sin(a * 3 + t * 2.2 + layer) * .5 + math.sin(a * 5 - t * 3.1) * .3 + math.sin(a * 7 + t * 1.3) * .2;
        final r = base + 6 + (8 + 26 * h) * (.6 + .4 * wob) * (layer == 0 ? 1 : .7);
        final p = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, layer == 0 ? .07 + .10 * amp : .10 + .12 * amp));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer == 0 ? 1.2 : 1.6
            ..color = Color.fromRGBO(255, 255, 255, layer == 0 ? .35 + .3 * amp : .55 + .4 * amp));
    }
  }

  @override
  bool shouldRepaint(_VoiceBlob o) => true;
}

/// 3-2-1: each number pops in, and a thin ring runs down around it.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.n, required this.tick});
  final int n;
  final Duration tick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('practice-countdown'),
      width: 150,
      height: 150,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('cd-ring-$n'),
        tween: Tween(begin: 1, end: 0),
        duration: tick,
        builder: (_, v, child) => CustomPaint(painter: _CountRing(v), child: child),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
            ),
            child: Text('$n',
                key: ValueKey('cd-$n'),
                style: const TextStyle(color: Colors.white, fontSize: 76, fontWeight: FontWeight.w200, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _CountRing extends CustomPainter {
  _CountRing(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(6);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x1AFFFFFF));
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CountRing o) => o.v != v;
}
