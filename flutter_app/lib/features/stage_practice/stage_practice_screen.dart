/// Listen → your turn → score, one client-recorded stage at a time.
///
/// The teacher's recording plays (voice only, or over soft music), the mic
/// records the learner, and the take is scored on the phone against that
/// stage's recording (lib/pronunciation/shabda): sounds, rhythm, pitch,
/// vowel length and completeness, with corrections that say where in the
/// word the difference is. Takes that cannot be judged (silence, too quiet,
/// too noisy, too short, too long) get a message instead of a score.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../../data/app_haptics.dart';
import '../../data/entitlements.dart';
import '../../data/models.dart';
import '../../data/word_requests.dart';
import '../../pronunciation/shabda/shabda_practice.dart';
import '../../widgets/content_lock.dart';
import '../../widgets/restyle_kit.dart';
import 'stage_mic.dart';
import 'stage_pack.dart';
import 'stage_progress.dart';

/// Opens stage practice for [w] when the app ships a stage pack for it
/// (after the usual word lock). Returns false when [w] has none.
Future<bool> openStagePractice(BuildContext context, Word w, {int? stage}) async {
  final pack = StagePack.forWord(w);
  if (pack == null) return false;
  if (!await ensureWordOpen(context, w)) return true;
  if (!context.mounted) return true;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => StagePracticeScreen(pack: pack, initialStage: stage),
  ));
  return true;
}

enum StagePhase { ready, playing, recording, scoring, result, micDenied, micError }

/// Scores [take] against [ref] in a background isolate.
Future<AttemptResult> scoreStageTake(Uint8List ref, Uint8List take, {required int stage, required double passMark}) {
  return compute(_scoreJob, (ref, take, stage, passMark));
}

AttemptResult _scoreJob((Uint8List, Uint8List, int, double) a) {
  final feats = referenceFeatures(a.$1);
  return assessTakeBytes(feats, a.$2, stage: a.$3, config: PracticeConfig(passMark: a.$4));
}

class StagePracticeScreen extends StatefulWidget {
  const StagePracticeScreen({
    super.key,
    required this.pack,
    this.initialStage,
    this.mic,
    @visibleForTesting this.debugPhase,
    @visibleForTesting this.debugResult,
    @visibleForTesting this.debugLevel,
  });

  final StagePack pack;
  final int? initialStage;

  /// The microphone (tests pass a fake).
  final StageMic? mic;

  final StagePhase? debugPhase;
  final AttemptResult? debugResult;
  final double? debugLevel;

  @override
  State<StagePracticeScreen> createState() => _StagePracticeScreenState();
}

class _StagePracticeScreenState extends State<StagePracticeScreen> {
  late final StageMic _mic = widget.mic ?? RecordStageMic();
  AudioPlayer? _player;
  final _progress = StageProgressStore.instance;

  late int _stage;
  bool _withMusic = false;
  StagePhase _phase = StagePhase.ready;
  AttemptResult? _result;
  bool _newlyPassed = false;
  String? _playingWhat; // 'ref' | 'take'

  // Recording.
  double _level = -60;
  final List<double> _levels = [];
  Timer? _cap;
  Timer? _tick;
  DateTime? _recStart;
  DateTime? _lastLoud;
  bool _heard = false;
  bool _hasTake = false;

  bool _requesting = false;
  bool _requested = false;

  StagePack get pack => widget.pack;
  PackStage get stage => pack.stages[_stage - 1];
  bool get _admin => Entitlements.instance.isAdmin;

  bool _unlocked(int n) => _admin || _progress.isUnlocked(pack.wordKey, n);

  @override
  void initState() {
    super.initState();
    _stage = (widget.initialStage ?? 1).clamp(1, pack.stages.length);
    _phase = widget.debugPhase ?? StagePhase.ready;
    _result = widget.debugResult;
    if (_phase == StagePhase.playing) _playingWhat = 'ref';
    if (widget.debugLevel != null) {
      _level = widget.debugLevel!;
      _heard = true;
      _recStart = DateTime.now().subtract(const Duration(milliseconds: 1400));
      for (var i = 0; i < 48; i++) {
        _levels.add(-50 + 38 * (0.5 + 0.5 * math.sin(i / 3.2)) * (i / 48));
      }
    }
    _progress.addListener(_onProgress);
    unawaited(_progress.ensureLoaded().then((_) {
      if (!mounted) return;
      if (widget.initialStage == null && widget.debugPhase == null) {
        setState(() => _stage = _progress.currentStage(pack.wordKey, pack.stages.length));
      }
    }));
    unawaited(_loadRequested());
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRequested() async {
    try {
      final s = WordRequestStore.instance;
      await s.ensureLoaded();
      final mine =
          s.items.any((r) => r.word.toLowerCase() == pack.word.toLowerCase() && r.notes.startsWith('More stages'));
      if (mounted && mine) setState(() => _requested = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    _cap?.cancel();
    _tick?.cancel();
    unawaited(_mic.cancel());
    _mic.dispose();
    _player?.dispose();
    super.dispose();
  }

  // ── Listening ─────────────────────────────────────────────────────
  Future<void> _stopAudio() async {
    try {
      await _player?.stop();
    } catch (_) {}
    if (mounted && _phase == StagePhase.playing) {
      setState(() => _phase = _result == null ? StagePhase.ready : StagePhase.result);
    }
    _playingWhat = null;
  }

  Future<void> _play({bool take = false}) async {
    if (_phase == StagePhase.recording || _phase == StagePhase.scoring) return;
    if (_phase == StagePhase.playing) {
      final same = _playingWhat == (take ? 'take' : 'ref');
      await _stopAudio();
      if (same) return;
    }
    final back = _result == null ? StagePhase.ready : StagePhase.result;
    final p = _player ??= AudioPlayer();
    setState(() {
      _phase = StagePhase.playing;
      _playingWhat = take ? 'take' : 'ref';
    });
    try {
      await p.stop();
      if (take) {
        final path = _mic.lastPath;
        if (path == null) throw StateError('no take');
        await p.setFilePath(path);
      } else {
        final src = _withMusic && stage.music.isNotEmpty ? stage.music : stage.audio;
        await p.setAsset(src);
      }
      await p.setVolume(1);
      final done = p.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
      unawaited(p.play());
      await done.timeout(const Duration(seconds: 40));
    } catch (e) {
      debugPrint('NowssB stage practice: playback — $e');
      if (mounted && _playingWhat != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(take
              ? 'Your attempt could not be played.'
              : 'The recording could not be played. Turn the volume up and try again.'),
        ));
      }
    }
    try {
      await p.stop();
    } catch (_) {}
    if (!mounted) return;
    if (_phase == StagePhase.playing) setState(() => _phase = back);
    _playingWhat = null;
  }

  // ── Your turn ────────────────────────────────────────────────────
  Future<void> _record() async {
    if (_phase == StagePhase.recording) {
      await _finish();
      return;
    }
    if (_phase == StagePhase.scoring) return;
    await _stopAudio();
    AppHaptics.selection();
    bool ok;
    try {
      ok = await _mic.hasPermission();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      setState(() => _phase = StagePhase.micDenied);
      return;
    }
    setState(() {
      _phase = StagePhase.recording;
      _result = null;
      _newlyPassed = false;
      _levels.clear();
      _level = -60;
      _heard = false;
      _lastLoud = null;
      _recStart = DateTime.now();
    });
    try {
      await _mic.start('nwsb-stage-${pack.wordKey}-$_stage', _onLevel);
    } catch (e) {
      debugPrint('NowssB stage practice: mic — $e');
      if (mounted) setState(() => _phase = StagePhase.micError);
      return;
    }
    // Hard stop: the recording's length plus room to breathe.
    final capMs = ((stage.seconds + 3.0).clamp(4.0, 10.0) * 1000).round();
    _cap?.cancel();
    _cap = Timer(Duration(milliseconds: capMs), () => unawaited(_finish()));
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _phase != StagePhase.recording) return;
      final now = DateTime.now();
      // Stop by itself once the word is said and the room is quiet again.
      if (_heard && _lastLoud != null && now.difference(_lastLoud!).inMilliseconds > 1100) {
        unawaited(_finish());
      } else {
        setState(() {});
      }
    });
  }

  void _onLevel(double db) {
    if (!mounted || _phase != StagePhase.recording) return;
    final v = db.isFinite ? db.clamp(-60.0, 0.0) : -60.0;
    final now = DateTime.now();
    final started = _recStart != null && now.difference(_recStart!).inMilliseconds > 250;
    if (v > -38 && started) {
      _heard = true;
      _lastLoud = now;
    } else if (v > -48 && _heard) {
      _lastLoud = now;
    }
    _level = v;
    _levels.add(v);
    if (_levels.length > 64) _levels.removeAt(0);
  }

  Future<void> _finish() async {
    if (_phase != StagePhase.recording) return;
    _cap?.cancel();
    _tick?.cancel();
    setState(() => _phase = StagePhase.scoring);
    final take = await _mic.stop();
    if (!mounted) return;
    if (take == null) {
      setState(() => _phase = StagePhase.micError);
      return;
    }
    _hasTake = _mic.lastPath != null;
    AttemptResult r;
    try {
      final ref = (await rootBundle.load(stage.reference)).buffer.asUint8List();
      r = await scoreStageTake(ref, take, stage: _stage, passMark: pack.passMark);
    } catch (e) {
      debugPrint('NowssB stage practice: score — $e');
      if (mounted) setState(() => _phase = StagePhase.micError);
      return;
    }
    var first = false;
    if (r.scored) {
      first = await _progress.addAttempt(pack.wordKey, _stage, score: r.overall, passed: r.passed);
    }
    if (!mounted) return;
    if (r.passed) AppHaptics.selection();
    setState(() {
      _result = r;
      _newlyPassed = first;
      _phase = StagePhase.result;
    });
  }

  void _pick(int n) {
    if (_phase == StagePhase.recording || _phase == StagePhase.scoring) return;
    if (!_unlocked(n)) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('Pass Stage ${n - 1} to open Stage $n.')));
      return;
    }
    unawaited(_stopAudio());
    setState(() {
      _stage = n;
      _result = null;
      _hasTake = false;
      _phase = StagePhase.ready;
    });
  }

  Future<void> _requestStages() async {
    if (_requesting || _requested) return;
    setState(() => _requesting = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await WordRequestStore.instance.submit(
        word: pack.word.isEmpty ? pack.wordKey : _title(pack.word),
        notes: 'More stages requested for ${_title(pack.word)} (${pack.stages.length} so far).',
        kind: 'stages',
      );
      if (!mounted) return;
      setState(() => _requested = true);
      messenger?.showSnackBar(
          const SnackBar(content: Text('Request sent. You will see new stages here when they are recorded.')));
    } catch (e) {
      messenger?.showSnackBar(
          SnackBar(content: Text(e is ArgumentError ? '${e.message}' : 'Could not send the request. Try again.')));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  static String _title(String w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase();

  // ── UI ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = _title(pack.word);
    return KitPage(
      eyebrow: 'Practice · $name',
      title: 'Stage $_stage of ${pack.stages.length}',
      children: [
        _stageStrip(),
        _listenPane(name),
        _turnPane(name),
        if (_phase == StagePhase.result && _result != null) ..._resultPanes(_result!),
        _progressPane(),
        _morePane(name),
      ],
    );
  }

  Widget _stageStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        for (final s in pack.stages) ...[
          if (s.number > 1) const SizedBox(width: 8),
          Expanded(child: _stageChip(s.number)),
        ],
      ]),
    );
  }

  Widget _stageChip(int n) {
    final rec = _progress.record(pack.wordKey, n);
    final open = _unlocked(n);
    final sel = n == _stage;
    final sub = !open
        ? 'Locked'
        : rec.passed
            ? 'Passed · ${rec.best}'
            : rec.attempts > 0
                ? 'Best ${rec.best}'
                : 'Not tried';
    return Semantics(
      button: true,
      selected: sel,
      label: 'Stage $n, $sub',
      child: GestureDetector(
        key: ValueKey('stage-chip-$n'),
        onTap: () => _pick(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: sel ? Colors.white : const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? Colors.white : const Color(0x33FFFFFF)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STAGE $n',
                    style: TextStyle(
                        color: sel ? const Color(0xFF0B0B10) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 3),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: sel ? const Color(0xA60B0B10) : kKitMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            Icon(
              !open
                  ? Icons.lock_rounded
                  : (rec.passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
              size: 18,
              color: sel ? const Color(0xFF0B0B10) : (rec.passed ? const Color(0xFF7BE0A8) : kKitMuted),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _listenPane(String name) {
    final playing = _phase == StagePhase.playing && _playingWhat == 'ref';
    return KitPane(
      eyebrow: 'Step 1 · Listen',
      title: 'Hear the teacher',
      mark: NwsbMarks.sound,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          KitRoundButton(
            key: const ValueKey('stage-listen'),
            icon: playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 58,
            label: playing ? 'Stop' : 'Play the recording',
            onTap: () => unawaited(_play()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 3),
              Text(
                playing
                    ? 'Playing ${stage.title} …'
                    : '${stage.title} · ${stage.seconds.toStringAsFixed(1)} s · the teacher’s own recording',
                style: const TextStyle(color: kKitMuted, fontSize: 12.5, height: 1.35),
              ),
            ]),
          ),
        ]),
        if (pack.hasMusic && stage.music.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(children: [
            GlassPill(label: 'Voice only', selected: !_withMusic, onTap: () => _setMusic(false)),
            const SizedBox(width: 8),
            GlassPill(label: 'With music', selected: _withMusic, onTap: () => _setMusic(true)),
          ]),
          if (_withMusic && pack.musicCredit.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(pack.musicCredit, style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 10.5, height: 1.35)),
          ],
        ],
        if (stage.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(stage.text, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.4)),
        ],
      ]),
    );
  }

  void _setMusic(bool v) {
    if (_withMusic == v) return;
    unawaited(_stopAudio());
    setState(() => _withMusic = v);
  }

  Widget _turnPane(String name) {
    final rec = _phase == StagePhase.recording;
    final busy = _phase == StagePhase.scoring;
    String line;
    switch (_phase) {
      case StagePhase.recording:
        final secs = _recStart == null ? 0.0 : DateTime.now().difference(_recStart!).inMilliseconds / 1000;
        line = _heard
            ? 'Listening… stops by itself when you finish (${secs.toStringAsFixed(1)} s)'
            : 'Listening — say $name now';
      case StagePhase.scoring:
        line = 'Comparing with the recording…';
      case StagePhase.micDenied:
        line =
            'NowssB can’t use the microphone. Allow it in your phone’s Settings → Apps → NowssB → Permissions → Microphone, then tap the mic again.';
      case StagePhase.micError:
        line =
            'The microphone did not record. Close other apps that use it (calls, voice notes) and tap the mic again.';
      default:
        line = _result == null ? 'Tap the mic and say $name the way you heard it.' : 'Tap the mic to try again.';
    }
    return KitPane(
      eyebrow: 'Step 2 · Your turn',
      title: rec ? 'Recording' : (busy ? 'Scoring' : 'Say it back'),
      mark: NwsbMarks.signature,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Semantics(
            button: true,
            label: rec ? 'Stop recording' : 'Record your attempt',
            child: GestureDetector(
              key: const ValueKey('stage-mic'),
              onTap: busy ? null : () => unawaited(_record()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rec ? const Color(0xFFFF5A5F) : Colors.white,
                  boxShadow: rec
                      ? [BoxShadow(color: const Color(0x66FF5A5F), blurRadius: 10 + (_level + 60) / 3, spreadRadius: 1)]
                      : null,
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(21),
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF111118)),
                      )
                    : Icon(rec ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 32, color: rec ? Colors.white : const Color(0xFF111118)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: rec || (_levels.isNotEmpty && busy)
                ? SizedBox(height: 44, child: CustomPaint(painter: _LevelPainter(List.of(_levels))))
                : Text(line, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.4)),
          ),
        ]),
        if (rec || busy) ...[
          const SizedBox(height: 10),
          Text(line, style: const TextStyle(color: kKitMuted, fontSize: 12.5, height: 1.35)),
        ],
        if (_phase == StagePhase.micDenied || _phase == StagePhase.micError) ...[
          const SizedBox(height: 12),
          KitActionPill('Try the microphone again',
              icon: Icons.mic_rounded, primary: false, onTap: () => unawaited(_record())),
        ],
      ]),
    );
  }

  List<Widget> _resultPanes(AttemptResult r) {
    final next = _stage < pack.stages.length ? _stage + 1 : null;
    final canNext = next != null && _unlocked(next);
    final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      if (r.passed && canNext) ...[
        KitActionPill('Go to Stage $next', icon: Icons.arrow_forward_rounded, onTap: () => _pick(next)),
        const SizedBox(height: 10),
      ],
      Row(children: [
        Expanded(
            child: KitActionPill('Hear teacher',
                icon: Icons.volume_up_rounded, primary: false, onTap: () => unawaited(_play()))),
        const SizedBox(width: 10),
        Expanded(
            child: KitActionPill('Try again',
                icon: Icons.mic_rounded, primary: !(r.passed && canNext), onTap: () => unawaited(_record()))),
      ]),
      if (_hasTake) ...[
        const SizedBox(height: 10),
        KitActionPill(
          _phase == StagePhase.playing && _playingWhat == 'take' ? 'Stop' : 'Hear my attempt',
          icon: Icons.hearing_rounded,
          primary: false,
          onTap: () => unawaited(_play(take: true)),
        ),
      ],
    ]);

    if (!r.scored) {
      return [
        KitPane(
          eyebrow: 'Not scored',
          title: r.headline,
          mark: NwsbMarks.thought,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              KitIconBadge(_statusIcon(r.status), size: 40),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(r.message, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 14, height: 1.45))),
            ]),
            actions,
          ]),
        ),
      ];
    }

    return [
      KitPane(
        eyebrow: r.passed ? (_newlyPassed ? 'Stage passed' : 'Passed') : 'Your score',
        title: r.headline,
        mark: NwsbMarks.trending,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(
                painter: _RingPainter(r.overall / 100, r.passed ? const Color(0xFF7BE0A8) : const Color(0xFFFFC86B)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${r.overall}',
                        key: const ValueKey('stage-score'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
                    const Text('of 100', style: TextStyle(color: kKitMuted, fontSize: 11)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.message, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 8),
                Text('Pass mark ${pack.passMark.round()} · best ${_progress.record(pack.wordKey, _stage).best}',
                    style: const TextStyle(color: kKitMuted, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          for (final s in r.subs) _subBar(s),
          actions,
        ]),
      ),
      if (r.fixes.isNotEmpty)
        KitPane(
          eyebrow: 'What to fix',
          title: r.passed ? 'To make it even closer' : 'Where it differs',
          mark: NwsbMarks.compass,
          child: Column(children: [
            for (var i = 0; i < r.fixes.length; i++) _tip('${i + 1}', r.fixes[i], const Color(0xFFFFC86B))
          ]),
        ),
      if (r.good.isNotEmpty)
        KitPane(
          eyebrow: 'What you got right',
          title: 'Keep this',
          mark: NwsbMarks.crown,
          child: Column(children: [for (final g in r.good) _tip('', g, const Color(0xFF7BE0A8))]),
        ),
    ];
  }

  IconData _statusIcon(AttemptStatus s) => switch (s) {
        AttemptStatus.silent => Icons.mic_off_rounded,
        AttemptStatus.tooQuiet => Icons.volume_down_rounded,
        AttemptStatus.tooNoisy => Icons.noise_aware_rounded,
        AttemptStatus.tooShort => Icons.timer_off_rounded,
        AttemptStatus.tooLong => Icons.timelapse_rounded,
        AttemptStatus.scored => Icons.check_rounded,
      };

  Widget _subBar(SubScore s) {
    final v = s.value.clamp(0, 100);
    final c = v >= 80 ? const Color(0xFF7BE0A8) : (v >= 55 ? const Color(0xFFFFC86B) : const Color(0xFFFF7A7A));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 104,
            child:
                Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(children: [
              Container(height: 8, color: const Color(0x22FFFFFF)),
              FractionallySizedBox(widthFactor: v / 100, child: Container(height: 8, color: c)),
            ]),
          ),
        ),
        SizedBox(
            width: 38,
            child: Text('$v',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _tip(String lead, String text, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.18),
              border: Border.all(color: c.withValues(alpha: 0.6))),
          child: lead.isEmpty
              ? Icon(Icons.check_rounded, size: 15, color: c)
              : Text(lead, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14, height: 1.42))),
      ]),
    );
  }

  Widget _progressPane() {
    final passed = _progress.passedCount(pack.wordKey);
    final total = pack.stages.length;
    return KitPane(
      eyebrow: 'Your progress',
      title: '$passed of $total stages passed',
      mark: NwsbMarks.stages,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : passed / total,
            minHeight: 8,
            backgroundColor: const Color(0x22FFFFFF),
            color: const Color(0xFF7BE0A8),
          ),
        ),
        const SizedBox(height: 12),
        for (final s in pack.stages) _progressRow(s.number),
        if (_admin)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Admin: every stage is open for testing.', style: TextStyle(color: kKitMuted, fontSize: 11.5)),
          ),
      ]),
    );
  }

  Widget _progressRow(int n) {
    final r = _progress.record(pack.wordKey, n);
    final open = _unlocked(n);
    final sub = !open
        ? 'Opens when Stage ${n - 1} is passed'
        : r.attempts == 0
            ? 'Not tried yet'
            : 'Best ${r.best} · ${r.attempts} ${r.attempts == 1 ? 'attempt' : 'attempts'}${r.passed ? ' · passed' : ''}';
    return InkWell(
      onTap: () => _pick(n),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          KitIconBadge(!open ? Icons.lock_rounded : (r.passed ? Icons.check_rounded : Icons.graphic_eq_rounded),
              size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stage $n', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(sub, style: const TextStyle(color: kKitMuted, fontSize: 12)),
            ]),
          ),
          if (n == _stage) const Text('NOW', style: kKitEyebrow),
        ]),
      ),
    );
  }

  Widget _morePane(String name) {
    return KitPane(
      eyebrow: 'More stages',
      title: 'Want to go further?',
      mark: NwsbMarks.thought,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          _requested
              ? 'Your request for more $name stages is with the teacher.'
              : '$name has ${pack.stages.length} recorded stages. Ask the teacher to record more.',
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        KitActionPill(
          _requested ? 'Requested' : 'Request more stages',
          key: const ValueKey('stage-request'),
          icon: _requested ? Icons.check_rounded : Icons.add_rounded,
          primary: false,
          busy: _requesting,
          onTap: _requested ? null : () => unawaited(_requestStages()),
        ),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0x22FFFFFF);
    canvas.drawCircle(c, r, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

class _LevelPainter extends CustomPainter {
  _LevelPainter(this.levels);
  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 48;
    final w = size.width / n;
    final p = Paint()..strokeCap = StrokeCap.round;
    final start = math.max(0, levels.length - n);
    for (var i = 0; i < n; i++) {
      final idx = start + i;
      final v = idx < levels.length ? levels[idx] : -60.0;
      final h = (((v + 60) / 60).clamp(0.04, 1.0)) * size.height;
      p
        ..strokeWidth = math.max(2, w * 0.55)
        ..color = v > -38 ? Colors.white : const Color(0x66FFFFFF);
      final x = i * w + w / 2;
      canvas.drawLine(Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), p);
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) => true;
}
