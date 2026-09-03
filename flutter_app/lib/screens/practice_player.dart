/// The native counterpart to www/nowssb-player.js.
///
/// It uses the same ordered image/video theme pairs, the local liquid-splash
/// assets, word-action clip, and the same five-item control treatment as the
/// WebView Player. Speech remains native text-to-speech and completed words
/// are recorded locally, so the visual port does not replace a real session
/// with a mock screen.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/practice_progress.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import 'sound_library.dart';
import 'aura_sound_library.dart';
import 'store.dart';
import 'player_settings.dart';
import 'select_level.dart';
import 'player_dial.dart';

String _fmtClock(num sec) {
  final s = sec.round().clamp(0, 24 * 3600);
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

double _wordSecs(Word word) {
  var sec = 0.0;
  for (final part in word.parts) {
    sec += part.hold;
  }
  if (sec < 8) sec = 12;
  return sec;
}

String _wordClock(Word word) => _fmtClock(_wordSecs(word));

String _prettyTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return t;
  return '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
}

class PracticePlayerScreen extends StatefulWidget {
  const PracticePlayerScreen({super.key, required this.words, required this.title});

  final List<Word> words;
  final String title;

  @override
  State<PracticePlayerScreen> createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  static const _likedWordsKey = 'nwsb_liked_words';
  static const _shuffleKey = 'nwsb_player_shuffle';

  final FlutterTts _tts = FlutterTts();
  var _index = 0;
  var _playing = false;
  var _completed = false;
  var _liked = false;
  var _loop = false;
  var _repTarget = 7;
  var _shuffle = false;
  var _volume = 1.0;
  DateTime? _startedAt;
  String? _error;

  Word get _word => widget.words[_index];
  _PlayerTheme get _theme => _playerThemes[_index % _playerThemes.length];

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_onProgress);
    unawaited(PracticeProgress.instance.start());
    unawaited(_loadLiked());
    unawaited(_loadShuffle());
    unawaited(_prepareAndPlay());
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_onProgress);
    unawaited(_tts.stop());
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  Future<void> _loadShuffle() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _shuffle = prefs.getBool(_shuffleKey) ?? false);
  }

  Future<void> _toggleShuffle() async {
    final next = !_shuffle;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shuffleKey, next);
    if (mounted) setState(() => _shuffle = next);
  }

  Future<void> _loadLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList(_likedWordsKey) ?? const <String>[];
    if (mounted) setState(() => _liked = liked.contains(_word.word));
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList(_likedWordsKey) ?? const <String>[]).toSet();
    if (liked.contains(_word.word)) {
      liked.remove(_word.word);
    } else {
      liked.add(_word.word);
    }
    await prefs.setStringList(_likedWordsKey, liked.toList()..sort());
    if (mounted) setState(() => _liked = liked.contains(_word.word));
  }

  Future<void> _prepareAndPlay() async {
    if (_playing || widget.words.isEmpty) return;
    setState(() {
      _playing = true;
      _completed = false;
      _error = null;
      _startedAt = DateTime.now();
    });
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.0);
      await _tts.setVolume(_volume);
      await _tts.stop();
      final started = DateTime.now();
      await _tts.speak(_word.word);
      final elapsed = DateTime.now().difference(started).inSeconds;
      await PracticeProgress.instance.recordCompletedWord(_word, durationSec: elapsed > 0 ? elapsed : 1);
      if (mounted) setState(() => _completed = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Your device could not start voice playback. Check that text-to-speech is enabled.');
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _tts.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _prepareAndPlay();
  }

  Future<void> _skipPrev() async {
    final elapsed = _startedAt == null
        ? 0.0
        : DateTime.now().difference(_startedAt!).inMilliseconds / 1000;
    if (elapsed > 1.5) {
      await _tts.stop();
      if (mounted) setState(() { _playing = false; _completed = false; });
      await _prepareAndPlay();
      return;
    }
    await _move(-1);
  }

  Future<void> _playRandom() async {
    if (widget.words.length < 2) {
      await _prepareAndPlay();
      return;
    }
    var next = _index;
    var guard = 0;
    while (next == _index && guard++ < 24) {
      next = math.Random().nextInt(widget.words.length);
    }
    await _tts.stop();
    setState(() {
      _index = next;
      _liked = false;
      _completed = false;
      _error = null;
    });
    await _loadLiked();
    await _prepareAndPlay();
  }

  Future<void> _copyWord() async {
    final syllables = _word.syllables.join(' · ');
    final organ = _word.organ.trim().isEmpty ? '' : ' — ${_word.organ.toUpperCase()}';
    await Clipboard.setData(ClipboardData(
      text: '${_word.word}$organ\n$syllables\n${_word.meaning}',
    ));
  }

  Future<void> _move(int direction) async {
    if (widget.words.isEmpty) return;
    int next;
    if (_shuffle && direction > 0 && widget.words.length > 1) {
      next = _index;
      var guard = 0;
      while (next == _index && guard++ < 24) {
        next = math.Random().nextInt(widget.words.length);
      }
    } else {
      next = (_index + direction) % widget.words.length;
      if (next < 0) next += widget.words.length;
    }
    await _tts.stop();
    setState(() {
      _index = next;
      _liked = false;
      _completed = false;
      _error = null;
    });
    await _loadLiked();
    await _prepareAndPlay();
  }

  void _openLevel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(.62),
      builder: (_) => const FractionallySizedBox(heightFactor: .96, child: SelectLevelScreen()),
    );
  }

  void _openInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PlayerInfoSheet(word: _word, accent: _theme.accent),
    );
  }

  void _openNotes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xF10A101B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('PRONUNCIATION NOTES', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7)),
            const SizedBox(height: 14),
            Text(_word.word, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            if (_word.tip.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_word.tip, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.45)),
            ],
            if (_word.parts.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _word.parts
                    .map((part) => _PronunciationChip(part: part, accent: _theme.accent))
                    .toList(),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _openAuraClock() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerDial(
      word: _word.word,
      playing: _playing,
      onPlay: _togglePlay,
      onClose: () => Navigator.of(context).pop(),
      onSettings: _openSettings,
    )));
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(.62),
      builder: (_) => const FractionallySizedBox(heightFactor: .96, child: PlayerSettingsScreen()),
    );
  }

  void _openSettingsLegacy() {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB8060C18),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: SizedBox(
          width: 360,
          height: 560,
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xE6060C18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x44C8E8F5)),
                  boxShadow: [BoxShadow(color: _theme.accent.withOpacity(.26), blurRadius: 42)],
                ),
                child: CustomPaint(painter: _AuraSettingsPainter(accent: _theme.accent)),
              ),
            ),
            Positioned(
              top: 18,
              left: 22,
              right: 22,
              child: Row(children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                ),
                const Expanded(child: Text('NowssB Player', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2))),
                const SizedBox(width: 36),
              ]),
            ),
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x331D3448),
                  border: Border.all(color: _theme.accent.withOpacity(.75), width: 1.2),
                  boxShadow: [BoxShadow(color: _theme.accent.withOpacity(.18), blurRadius: 26)],
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.settings_rounded, color: Colors.white, size: 30),
                  SizedBox(height: 5),
                  Text('SETTINGS', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
                ]),
              ),
            ),
            _RadialOption(alignment: const Alignment(0, -.62), label: 'VOICE', value: 'Device', icon: Icons.record_voice_over_rounded, accent: _theme.accent, onTap: () => ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('NowssB uses your selected device voice.')))),
            _RadialOption(alignment: const Alignment(.72, -.2), label: 'LOOP', value: _loop ? 'On' : 'Off', icon: Icons.all_inclusive_rounded, accent: _theme.accent, onTap: () => setState(() => _loop = !_loop)),
            _RadialOption(alignment: const Alignment(.45, .62), label: 'REPS', value: '${_repTarget}×', icon: Icons.repeat_rounded, accent: _theme.accent, onTap: () => setState(() => _repTarget = _repTarget == 3 ? 7 : _repTarget == 7 ? 11 : _repTarget == 11 ? 21 : 3)),
            _RadialOption(alignment: const Alignment(-.45, .62), label: 'LIBRARY', value: 'Open', icon: Icons.library_music_rounded, accent: _theme.accent, onTap: () { Navigator.of(dialogContext).pop(); showModalBottomSheet<void>(context: this.context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const FractionallySizedBox(heightFactor: .96, child: AuraSoundLibraryScreen())); }),
            _RadialOption(alignment: const Alignment(-.72, -.2), label: 'REPLAY', value: 'Word', icon: Icons.replay_rounded, accent: _theme.accent, onTap: _prepareAndPlay),
            const Positioned(left: 24, right: 24, bottom: 20, child: Text('Choose a player control', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.4))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: NwsbColors.deep,
        appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white),
        body: const Center(child: Text('Choose words for your routine before starting a session.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
      );
    }

    final theme = _theme;
    final nextIndex = widget.words.isEmpty ? 0 : (_index + 1) % widget.words.length;
    final nextWord = widget.words.isEmpty ? null : widget.words[nextIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final stageWidth = math.min(constraints.maxWidth - 24, 340.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _PlayerHeader(onBack: () => Navigator.of(context).pop(), onSettings: _openSettings, onMore: _openAuraClock),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: stageWidth,
                    child: _VisualStage(
                      word: _word,
                      theme: theme,
                      playing: _playing,
                      accent: theme.accent,
                      onReplay: _prepareAndPlay,
                      onCopy: _copyWord,
                      onSettings: _openSettings,
                      onInfo: _openInfo,
                      onLevel: _openLevel,
                      onSyllable: (part) async {
                        await _tts.stop();
                        await _tts.speak(part.roman.isNotEmpty ? part.roman : part.deva);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Stack(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(children: [
                      Text(
                        _prettyTitle(_word.word),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF4F4F5),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'NowssB  ·  Words Without Dictionary',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8B8B90), fontSize: 14),
                      ),
                    ]),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _liked ? const Color(0xFFF5F5F7) : const Color(0xFF8B8B90),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _ProgressBar(playing: _playing, durationSec: _wordSecs(_word)),
                const SizedBox(height: 8),
                _TransportRow(
                  playing: _playing,
                  shuffle: _shuffle,
                  loop: _loop,
                  onShuffle: _toggleShuffle,
                  onPrevious: _skipPrev,
                  onPlay: _togglePlay,
                  onNext: () => _move(1),
                  onRepeat: () => setState(() => _loop = !_loop),
                ),
                const SizedBox(height: 16),
                SizedBox(width: stageWidth, child: _NextUpCard(
                  next: nextWord,
                  art: nextWord == null ? null : _playerThemes[(nextIndex) % _playerThemes.length].image,
                  onPlay: () => _move(1),
                  onAdd: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuraSoundLibraryScreen())),
                )),
                if (_completed || _error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error ?? 'Completed and added to your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _error == null ? Colors.white70 : const Color(0xFFFFB4B4), fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(width: stageWidth, child: _WordActionStrip(
                  accent: theme.accent,
                  video: theme.video,
                  onSentence: _openInfo,
                  onPractice: _prepareAndPlay,
                  onStore: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoreScreen())),
                )),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _PlayerThemeArtwork extends StatelessWidget {
  const _PlayerThemeArtwork({required this.theme});
  final _PlayerTheme theme;

  @override
  Widget build(BuildContext context) {
    if (theme.image.startsWith('http')) {
      return Image.network(theme.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: NwsbColors.deep));
    }
    return Image.asset(theme.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: NwsbColors.deep));
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.onBack, required this.onSettings, required this.onMore});
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Stack(alignment: Alignment.center, children: [
      Align(alignment: Alignment.centerLeft, child: _BareIconButton(icon: Icons.keyboard_arrow_down_rounded, onTap: onBack)),
      const Column(mainAxisSize: MainAxisSize.min, children: [
        Text('NOW PLAYING', style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 3.8)),
        SizedBox(height: 6),
        SizedBox(width: 28, height: 1, child: ColoredBox(color: Color(0x8CF4F4F5))),
      ]),
      Align(alignment: Alignment.centerRight, child: _BareIconButton(icon: Icons.more_horiz_rounded, onTap: onMore)),
    ]),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final progress = PracticeProgress.instance;
    return AspectRatio(
      aspectRatio: 1371 / 317,
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Colors.black),
        IgnorePointer(child: Image.asset('assets/frames/word-acts-tab.webp', fit: BoxFit.fill)),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(children: [
            _StatCell(icon: Icons.local_fire_department_outlined, value: '${progress.streak}', label: 'Days Streak'),
            _statDivider(),
            _StatCell(icon: Icons.graphic_eq_rounded, value: '${progress.totalSessions}', label: 'Sessions'),
            _statDivider(),
            _StatCell(icon: Icons.schedule_rounded, value: progress.timeLabel, label: 'Time Meditated'),
          ]),
        ),
      ]),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 28, color: const Color(0x24FFFFFF));
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: const Color(0xFFE8D5A3), size: 16),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label.toUpperCase(), style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
    ]),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onLevel, this.compact = false});
  final VoidCallback onLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = PracticeProgress.instance;
    final avatar = compact ? 56.0 : 72.0;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: avatar,
        height: avatar,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8E8F5)]),
          border: Border.all(color: const Color(0xB3E8D5A3), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x6BE8D5A3), blurRadius: 22),
            BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        alignment: Alignment.center,
        child: Text('H', style: TextStyle(color: const Color(0xFF0A0A12), fontSize: compact ? 18 : 22, fontWeight: FontWeight.w800)),
      ),
      SizedBox(width: compact ? 10 : 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Healer', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: compact ? 18 : 22, fontWeight: FontWeight.w700, height: 1.15, shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 10)])),
          const SizedBox(height: 2),
          Text('Healing through words', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xB8FFFFFF), fontSize: compact ? 11 : 12, fontWeight: FontWeight.w500, shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 8)])),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onLevel,
            child: Container(
              height: 26,
              padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
              decoration: BoxDecoration(
                color: const Color(0x29E8D5A3),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x73E8D5A3)),
                boxShadow: const [BoxShadow(color: Color(0x47E8D5A3), blurRadius: 12)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Color(0xFFE8D5A3), size: 12),
                const SizedBox(width: 6),
                Text('Level ${progress.level}  ›', style: const TextStyle(color: Color(0xFFE8D5A3), fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PracticeProgress.instance,
      builder: (context, _) {
        final current = PracticeProgress.instance.level.clamp(1, 10);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 10,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: ColoredBox(color: Color(0x1FFFFFFF), child: SizedBox(height: 1, width: double.infinity)),
              ),
              itemBuilder: (context, index) {
                final n = index + 1;
                final on = n == current;
                return GestureDetector(
                  onTap: () async {
                    await PracticeProgress.instance.setLevel(n);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Icon(
                        Icons.star_rounded,
                        color: on ? const Color(0xFFE8D5A3) : const Color(0xFFF4F4F5),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Level $n',
                        style: TextStyle(
                          color: on ? const Color(0xFFE8D5A3) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.next, required this.art, required this.onPlay, required this.onAdd});
  final Word? next;
  final String? art;
  final VoidCallback onPlay;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final word = next;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -250) {
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: const Color(0xFF14171E),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => const SafeArea(child: AuraSoundLibraryScreen()),
          );
        }
      },
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xD1161618),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 0, offset: Offset(0, 1))],
      ),
      child: word == null
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Text('End of queue', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 2), decoration: BoxDecoration(color: const Color(0x7AFFFFFF), borderRadius: BorderRadius.circular(99)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(children: [
                  const Expanded(child: Text('UP NEXT', style: TextStyle(color: Color(0xFF8D8D92), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.8))),
                  GestureDetector(
                    onTap: onAdd,
                    child: const SizedBox(width: 36, height: 36, child: Icon(Icons.queue_music_rounded, color: Color(0xFFCFCFD2), size: 20)),
                  ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ColoredBox(color: Color(0x1AFFFFFF), child: SizedBox(width: double.infinity, height: 1)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: GestureDetector(
                  onTap: onPlay,
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: art != null && art!.isNotEmpty
                            ? (art!.startsWith('http')
                                ? Image.network(art!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)))
                                : Image.asset(art!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111))))
                            : const ColoredBox(color: Color(0xFF111111)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(word.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.15)),
                        const SizedBox(height: 3),
                        Text('NowssB  ·  ${_wordClock(word)}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                      ]),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F7),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 6))],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF0A0A0C), size: 22),
                    ),
                  ]),
                ),
              ),
            ]),
      ),
    );
  }
}

class _VisualStage extends StatelessWidget {
  const _VisualStage({
    required this.word, required this.theme, required this.playing,
    required this.accent, required this.onReplay, required this.onCopy,
    required this.onSettings, required this.onInfo, required this.onLevel, required this.onSyllable,
  });

  final Word word;
  final _PlayerTheme theme;
  final bool playing;
  final Color accent;
  final VoidCallback onReplay;
  final VoidCallback onCopy;
  final VoidCallback onSettings;
  final VoidCallback onInfo;
  final VoidCallback onLevel;
  final ValueChanged<WordPart> onSyllable;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0x38FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x8C000000), blurRadius: 28, offset: Offset(0, 18)),
          BoxShadow(color: Color(0x24FFFFFF), blurRadius: 0, spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.black),
          NwsbVideo(
            asset: theme.video,
            poster: theme.image,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.24),
            priority: ClipPriority.feature,
            autoplay: true,
            loop: true,
            showPoster: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x00000000), Color(0xD9000000)],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: AnimatedBuilder(
              animation: PracticeProgress.instance,
              builder: (context, _) => _LevelPill(
                level: PracticeProgress.instance.level.clamp(1, 10),
                onTap: onLevel,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _StageGlassChip(onSettings: onSettings, onInfo: onInfo),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  word.word.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xE6F4F4F5), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 6),
                ),
                const SizedBox(height: 8),
                _WordOverlay(
                  word: word, accent: accent, playing: playing, liked: false,
                  onReplay: onReplay, onNotes: onCopy, onLike: () {},
                  onSyllable: onSyllable,
                  embedded: true,
                ),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level, required this.onTap});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8C46464E), Color(0xB80C0C0E)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x29FFFFFF), blurRadius: 0, spreadRadius: 1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Color(0xFFE8D5A3), size: 14),
          const SizedBox(width: 6),
          Text(
            'Level $level',
            style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    ),
  );
}

class _StageGlassChip extends StatelessWidget {
  const _StageGlassChip({required this.onSettings, required this.onInfo});
  final VoidCallback onSettings;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x8C46464E), Color(0xB80C0C0E)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
        BoxShadow(color: Color(0x29FFFFFF), blurRadius: 0, spreadRadius: 1),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _StageGlassBtn(icon: Icons.settings_rounded, label: 'Settings', onTap: onSettings),
        _StageGlassBtn(icon: Icons.help_outline_rounded, label: 'Word info', onTap: onInfo),
      ]),
    ),
  );
}

class _StageGlassBtn extends StatelessWidget {
  const _StageGlassBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, color: const Color(0xFFF4F4F5), size: 16),
      ),
    ),
  );
}

class _ArtWavePainter extends CustomPainter {
  const _ArtWavePainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 320;
    final sy = size.height / 36;
    final path = Path()
      ..moveTo(0 * sx, 22 * sy)
      ..cubicTo(18 * sx, 22 * sy, 22 * sx, 16 * sy, 32 * sx, 16 * sy)
      ..cubicTo(48 * sx, 16 * sy, 52 * sx, 28 * sy, 68 * sx, 20 * sy)
      ..cubicTo(84 * sx, 12 * sy, 92 * sx, 8 * sy, 108 * sx, 14 * sy)
      ..cubicTo(128 * sx, 22 * sy, 132 * sx, 30 * sy, 152 * sx, 18 * sy)
      ..cubicTo(168 * sx, 8 * sy, 176 * sx, 4 * sy, 192 * sx, 12 * sy)
      ..cubicTo(208 * sx, 20 * sy, 214 * sx, 26 * sy, 232 * sx, 18 * sy)
      ..cubicTo(248 * sx, 10 * sy, 260 * sx, 16 * sy, 276 * sx, 20 * sy)
      ..cubicTo(292 * sx, 24 * sy, 304 * sx, 22 * sy, 320 * sx, 22 * sy);
    final paint = Paint()
      ..color = const Color(0xD1FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArtWavePainter oldDelegate) => oldDelegate.active != active;
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.playing, required this.durationSec});
  final bool playing;
  final double durationSec;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: (widget.durationSec * 1000).round().clamp(400, 120000)));
    if (widget.playing) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _c.duration = Duration(milliseconds: (widget.durationSec * 1000).round().clamp(400, 120000));
    if (widget.playing && !oldWidget.playing) {
      _c.forward(from: 0);
    } else if (!widget.playing && oldWidget.playing) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final t = _c.value.clamp(0.0, 1.0);
      return Column(children: [
        SizedBox(
          height: 14,
          child: LayoutBuilder(builder: (context, constraints) {
            final x = t * constraints.maxWidth;
            return Stack(alignment: Alignment.centerLeft, children: [
              Container(height: 3, decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(99))),
              Container(width: x, height: 3, decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(99))),
              Positioned(
                left: (x - 5.5).clamp(0.0, math.max(0.0, constraints.maxWidth - 11)),
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0xFF050505), blurRadius: 0, spreadRadius: 3)],
                  ),
                ),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmtClock(widget.durationSec * t), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
          Text(_fmtClock(widget.durationSec), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
        ]),
      ]);
    },
  );
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({
    required this.playing, required this.shuffle, required this.loop,
    required this.onShuffle, required this.onPrevious, required this.onPlay, required this.onNext, required this.onRepeat,
  });
  final bool playing;
  final bool shuffle;
  final bool loop;
  final VoidCallback onShuffle;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) => _GlassTube(
    playing: playing,
    shuffle: shuffle,
    loop: loop,
    onShuffle: onShuffle,
    onPrevious: onPrevious,
    onPlay: onPlay,
    onNext: onNext,
    onRepeat: onRepeat,
  );
}

class _GlassTube extends StatelessWidget {
  const _GlassTube({
    required this.playing, required this.shuffle, required this.loop,
    required this.onShuffle, required this.onPrevious, required this.onPlay, required this.onNext, required this.onRepeat,
  });
  final bool playing;
  final bool shuffle;
  final bool loop;
  final VoidCallback onShuffle;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onRepeat;

  static const _tube = 'https://media.nowssb.com/migrated-images/19432211f0f348fc_file_0000000016bc71fab1ae5a054ac772af_gwttc6.png';
  static const _play = 'https://media.nowssb.com/migrated-images/74d38b3c7b69b30b_e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png';
  static const _pause = 'https://media.nowssb.com/migrated-images/f073aa60452e1cb9_e0723190-7389-11f1-8c74-0593c060acc9_e0lcl6.png';
  static const _prev = 'https://media.nowssb.com/migrated-images/2f091c1083cd0b65_ad77f630-7389-11f1-8c74-0593c060acc9_pe0zco.png';
  static const _next = 'https://media.nowssb.com/migrated-images/71a2d8954b5e6209_c5576970-7389-11f1-8c74-0593c060acc9_c4epec.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          image: DecorationImage(image: NetworkImage(_tube), fit: BoxFit.fill),
          boxShadow: [
            BoxShadow(color: Color(0x8C000000), blurRadius: 40, offset: Offset(0, 18)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _TubeIcon(icon: Icons.shuffle_rounded, on: shuffle, onTap: onShuffle, label: 'Shuffle'),
            _ImageControl(asset: 'assets/player/lgp-prev.png', network: _prev, label: 'Previous', onTap: onPrevious, size: 48),
            Semantics(
              button: true,
              label: playing ? 'Pause' : 'Play',
              child: GestureDetector(
                onTap: onPlay,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    playing ? _pause : _play,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      playing ? 'assets/player/lgp-pause.png' : 'assets/player/lgp-play.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _ImageControl(asset: 'assets/player/lgp-next.png', network: _next, label: 'Next', onTap: onNext, size: 48),
            _TubeIcon(icon: Icons.repeat_rounded, on: loop, onTap: onRepeat, label: 'Repeat'),
          ]),
        ),
      ),
    );
  }
}

class _TubeIcon extends StatelessWidget {
  const _TubeIcon({required this.icon, required this.onTap, required this.label, this.on = false});
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          color: on ? const Color(0xFFFFFFFF) : const Color(0xFFF4F4F5),
          size: 22,
          shadows: on
              ? const [Shadow(color: Color(0x8CDCE6FF), blurRadius: 12)]
              : const [Shadow(color: Color(0x8C000000), blurRadius: 8)],
        ),
      ),
    ),
  );
}

class _GlassOrb extends StatelessWidget {
  const _GlassOrb({
    required this.icon, required this.onTap, required this.label,
    this.on = false, this.filled = false, this.play = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final bool on;
  final bool filled;
  final bool play;

  @override
  Widget build(BuildContext context) {
    final size = play ? 58.0 : 44.0;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment(-0.4, -0.6),
              end: Alignment(0.4, 0.8),
              colors: [Color(0xB346464E), Color(0xE60A0A0C)],
            ),
            boxShadow: [
              const BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 6)),
              BoxShadow(color: on ? const Color(0x47DCE6FF) : const Color(0x1FFFFFFF), blurRadius: on ? 16 : 0, spreadRadius: 1),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFF4F4F5), size: play ? 26 : 18),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({required this.icon, required this.on, required this.onTap});
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    iconSize: 22,
    color: on ? const Color(0xFFF5F5F7) : const Color(0xFFCFCFD2),
    icon: Icon(icon),
  );
}

class _WordOverlay extends StatelessWidget {
  const _WordOverlay({
    required this.word, required this.accent, required this.playing,
    required this.liked, required this.onReplay, required this.onNotes, required this.onLike,
    this.onSyllable,
    this.embedded = false,
  });
  final Word word;
  final Color accent;
  final bool playing;
  final bool liked;
  final VoidCallback onReplay;
  final VoidCallback onNotes;
  final VoidCallback onLike;
  final ValueChanged<WordPart>? onSyllable;
  final bool embedded;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: embedded ? null : BoxDecoration(
      color: const Color(0xD1161618),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0x14FFFFFF)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (word.parts.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < word.parts.length; i++) ...[
              if (i > 0) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xCCF4F4F5), shape: BoxShape.circle)),
              _SyllablePill(part: word.parts[i], onTap: onSyllable == null ? null : () => onSyllable!(word.parts[i])),
            ],
          ],
        )
      else if (word.syllables.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < word.syllables.length; i++) ...[
              if (i > 0) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xCCF4F4F5), shape: BoxShape.circle)),
              _SyllablePill(label: word.syllables[i]),
            ],
          ],
        ),
      if (word.organ.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 28, height: 1, child: ColoredBox(color: Color(0x2EFFFFFF))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(word.organ.toUpperCase(), style: const TextStyle(color: Color(0xFF8B8B90), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 4.2)),
          ),
          const SizedBox(width: 28, height: 1, child: ColoredBox(color: Color(0x2EFFFFFF))),
        ]),
      ],
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xE6222226),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _ActBtn(icon: Icons.replay_rounded, onTap: onReplay),
          Container(width: 1, height: 16, color: const Color(0x2EFFFFFF)),
          _ActBtn(icon: Icons.copy_rounded, onTap: onNotes),
        ]),
      ),
    ]),
  );
}

class _SyllablePill extends StatelessWidget {
  const _SyllablePill({this.part, this.label, this.onTap});
  final WordPart? part;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = (part == null)
        ? (label ?? '')
        : (part!.roman.isNotEmpty ? part!.roman : part!.deva);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF0A0A0B), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 40, height: 40,
      child: Icon(icon, color: color ?? Colors.white, size: 20),
    ),
  );
}

class _PronunciationChip extends StatelessWidget {
  const _PronunciationChip({required this.part, required this.accent, this.compact = false});
  final WordPart part;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 13, vertical: compact ? 8 : 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 6))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (part.deva.isNotEmpty) Text(part.deva, style: TextStyle(color: const Color(0xFF0A0A12), fontSize: compact ? 12 : 16, height: 1.2)),
      Text(part.roman.isEmpty ? part.deva : part.roman, style: TextStyle(color: const Color(0xFF0A0A12), fontSize: compact ? 10 : 13, fontWeight: FontWeight.w800, letterSpacing: .4)),
      if (!compact) Text('${part.hold.toStringAsFixed(part.hold.truncateToDouble() == part.hold ? 0 : 1)}s', style: const TextStyle(color: Color(0x8C0A0A12), fontSize: 9, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _TransportTube extends StatelessWidget {
  const _TransportTube({required this.playing, required this.hasPrevious, required this.hasNext, required this.durationLabel, required this.onLibrary, required this.onPrevious, required this.onPlay, required this.onNext, required this.onReplay, required this.onRewind});
  final bool playing;
  final bool hasPrevious;
  final bool hasNext;
  final String durationLabel;
  final VoidCallback onLibrary;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onRewind;

  static const _tube = 'https://media.nowssb.com/migrated-images/19432211f0f348fc_file_0000000016bc71fab1ae5a054ac772af_gwttc6.png';
  static const _play = 'https://media.nowssb.com/migrated-images/74d38b3c7b69b30b_e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png';
  static const _pause = 'https://media.nowssb.com/migrated-images/f073aa60452e1cb9_e0723190-7389-11f1-8c74-0593c060acc9_e0lcl6.png';
  static const _prev = 'https://media.nowssb.com/migrated-images/2f091c1083cd0b65_ad77f630-7389-11f1-8c74-0593c060acc9_pe0zco.png';
  static const _next = 'https://media.nowssb.com/migrated-images/71a2d8954b5e6209_c5576970-7389-11f1-8c74-0593c060acc9_c4epec.png';

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 88, maxWidth: 268),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      image: DecorationImage(image: NetworkImage(_tube), fit: BoxFit.fill),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      GestureDetector(onTap: onRewind, child: const SizedBox(width: 32, height: 32, child: Icon(Icons.fast_rewind_rounded, color: Color(0xFFF5F5F7), size: 22))),
      _ImageControl(asset: 'assets/player/lgp-prev.png', network: _prev, label: 'Previous', onTap: hasPrevious ? onPrevious : null, size: 44),
      GestureDetector(
        onTap: onPlay,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Image.asset(
            playing ? 'assets/player/lgp-pause.png' : 'assets/player/lgp-play.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.network(playing ? _pause : _play, fit: BoxFit.contain),
          ),
        ),
      ),
      _ImageControl(asset: 'assets/player/lgp-next.png', network: _next, label: 'Next', onTap: hasNext ? onNext : null, size: 44),
      GestureDetector(onTap: onReplay, child: const SizedBox(width: 32, height: 32, child: Icon(Icons.replay_rounded, color: Color(0xFFF5F5F7), size: 22))),
    ]),
  );
}

class _WordActionStrip extends StatelessWidget {
  const _WordActionStrip({required this.accent, required this.video, required this.onSentence, required this.onPractice, required this.onStore});
  final Color accent;
  final String video;
  final VoidCallback onSentence;
  final VoidCallback onPractice;
  final VoidCallback onStore;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1371 / 317,
    child: Stack(fit: StackFit.expand, children: [
      NwsbVideo(asset: video, priority: ClipPriority.decoration, autoplay: true),
      IgnorePointer(child: Image.asset('assets/frames/word-acts-tab.webp', fit: BoxFit.fill)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _WordAction(icon: Icons.chat_bubble_outline_rounded, label: 'Sentence', onTap: onSentence),
        _WordAction(icon: Icons.mic_none_rounded, label: 'Practice', onTap: onPractice, accent: accent),
        _WordAction(icon: Icons.shopping_bag_outlined, label: 'Store', onTap: onStore),
      ]),
    ]),
  );
}

class _WordAction extends StatelessWidget {
  const _WordAction({required this.icon, required this.label, required this.onTap, this.accent});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 78, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 25, shadows: [Shadow(color: (accent ?? Colors.black).withOpacity(.85), blurRadius: 12)]),
        const SizedBox(height: 3),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      ])),
    ),
  );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.size = 42});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x2EFFFFFF),
    shape: const CircleBorder(side: BorderSide(color: Color(0x66FFFFFF))),
    child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * .48))),
  );
}

class _BareIconButton extends StatelessWidget {
  const _BareIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 26)),
  );
}

class _Equalizer extends StatelessWidget {
  const _Equalizer({required this.active, required this.accent});
  final bool active;
  final Color accent;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: List.generate(4, (i) => AnimatedContainer(duration: Duration(milliseconds: active ? 300 + i * 90 : 180), curve: Curves.easeInOut, width: 2.5, height: active ? 8.0 + (i.isEven ? 8 : 3) : 7.0 + i * 2, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: accent.withOpacity(.7), blurRadius: 5)]))));
}

class _VolumeRail extends StatelessWidget {
  const _VolumeRail({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Container(width: 36, height: 128, decoration: BoxDecoration(color: const Color(0x2BFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x55FFFFFF))), child: Column(children: [
    const SizedBox(height: 4),
    Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(value: value, onChanged: onChanged, activeColor: Colors.white, inactiveColor: const Color(0x55FFFFFF))),),
    Icon(value == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 17),
    const SizedBox(height: 8),
  ]));
}

class _ImageControl extends StatelessWidget {
  const _ImageControl({required this.asset, required this.label, required this.onTap, required this.size, this.network});
  final String asset;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final String? network;
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: label, child: Opacity(opacity: onTap == null ? .35 : 1, child: InkResponse(onTap: onTap, radius: size * .62, child: SizedBox(width: size, height: size, child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => network != null
    ? Image.network(network!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(label == 'Play' ? Icons.play_arrow_rounded : Icons.circle_outlined, color: Colors.white, size: size * .68))
    : Icon(label == 'Play' ? Icons.play_arrow_rounded : Icons.circle_outlined, color: Colors.white, size: size * .68))))));
}

class _RadialOption extends StatelessWidget {
  const _RadialOption({required this.alignment, required this.label, required this.value, required this.icon, required this.accent, required this.onTap});
  final Alignment alignment;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: InkResponse(
      onTap: onTap,
      customBorder: const CircleBorder(),
      radius: 48,
      child: SizedBox(
        width: 86,
        height: 86,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x241D3448),
            border: Border.all(color: accent.withOpacity(.62)),
            boxShadow: [BoxShadow(color: accent.withOpacity(.10), blurRadius: 16)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ),
  );
}

class _AuraSettingsPainter extends CustomPainter {
  const _AuraSettingsPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .34;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      paint.color = accent.withOpacity(.12 - i * .02);
      canvas.drawCircle(center, radius + i * 27, paint);
    }
    paint.color = accent.withOpacity(.32);
    paint.strokeWidth = 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius + 82), -.8, 1.35, false, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius + 82), 2.4, 1.05, false, paint);
  }
  @override
  bool shouldRepaint(covariant _AuraSettingsPainter oldDelegate) => oldDelegate.accent != accent;
}
class _PlayerInfoSheet extends StatelessWidget {
  const _PlayerInfoSheet({required this.word, required this.accent});
  final Word word;
  final Color accent;
  @override
  Widget build(BuildContext context) => SafeArea(top: false, child: Container(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
    decoration: const BoxDecoration(color: Color(0xF00B1321), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: ListView(children: [
      Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99)))),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: Text(word.word, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))), Icon(Icons.spa_rounded, color: accent)]),
      if (word.phonetic.isNotEmpty) Text(word.phonetic, style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 20),
      _InfoFact(label: 'WHAT’S HAPPENING', value: word.benefit.isEmpty ? 'Listen, then repeat at your own pace.' : word.benefit, accent: accent),
      if (word.meaning.isNotEmpty) _InfoFact(label: 'MEANING', value: word.meaning, accent: accent),
      if (word.organ.isNotEmpty) _InfoFact(label: 'TARGET ORGAN', value: word.organ, accent: accent),
      if (word.resonance.isNotEmpty) _InfoFact(label: 'RESONANCE POINT', value: word.resonance, accent: accent),
      if (word.mouthPos.isNotEmpty) _InfoFact(label: 'MOUTH POSITION', value: word.mouthPos, accent: accent),
    ]),
  ));
}

class _InfoFact extends StatelessWidget {
  const _InfoFact({required this.label, required this.value, required this.accent});
  final String label;
  final String value;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x24FFFFFF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35))]));
}

class _PlayerTheme {
  const _PlayerTheme({required this.image, required this.video, required this.accent});
  final String image;
  final String video;
  final Color accent;
}

const _playerThemes = <_PlayerTheme>[
  // Same ordered clips as nowssb-player.js — streamed from the live site so
  // the native player is not stuck on a missing bundled assets/videos path.
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/d694cb3157c4e58f_grok_image_1782656710977_nj5r6x.jpg', video: 'https://nowssb.com/assets/videos/79d7c93a6734ed8d_grok_video_2026-06-28-19-55-09_otgbxd.mp4', accent: Color(0xFF9BB8FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/3670d1e477f48c31_grok_image_1782656676834_rzp2cz.jpg', video: 'https://nowssb.com/assets/videos/a1b0a1b513ec57f6_grok_video_2026-06-28-19-54-38_wrxkgr.mp4', accent: Color(0xFF7FE9DA)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/fd380f5670852d0c_grok_image_1782656704854_cfsah3.jpg', video: 'https://nowssb.com/assets/videos/dc68caaf51e87003_grok_video_2026-06-28-19-55-02_of5fwh.mp4', accent: Color(0xFFBD7BFF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/e8bb832f2815c15a_grok_image_1782656684101_o9vc93.jpg', video: 'https://nowssb.com/assets/videos/d8ac259577c403f3_grok_video_2026-06-28-19-54-43_it2bur.mp4', accent: Color(0xFFA6DCFF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/48ad23ade254b2d7_grok_image_1782795582310_llvpix.jpg', video: 'https://nowssb.com/assets/videos/3b63edc1485a45e2_grok_video_2026-06-30-10-29-43_hzxyun.mp4', accent: Color(0xFFB9A6FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/20314fda05d34b49_grok_image_1782796537731_vzyhwn.jpg', video: 'https://nowssb.com/assets/videos/a779a65872bf917c_grok_video_2026-06-30-10-45-45_dg2ohg.mp4', accent: Color(0xFFA6C8FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/f734c819e92db433_grok_image_1782796641824_izkh09.jpg', video: 'https://nowssb.com/assets/videos/da4159578099ee48_grok_video_2026-06-30-10-47-20_rljghs.mp4', accent: Color(0xFFB9A6FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/e103480a2c87d55b_grok_image_1782796519587_thrrws.jpg', video: 'https://nowssb.com/assets/videos/e55e1f1f879d8074_grok_video_2026-06-30-10-45-34_pg2y2j.mp4', accent: Color(0xFFE8D5A3)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/122962572090895c_grok_image_1782796924745_nmksmi.jpg', video: 'https://nowssb.com/assets/videos/7a0e0cf6903f3b16_grok_video_2026-06-30-10-52-07_gvffol.mp4', accent: Color(0xFFF0D9A8)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/28b7b32c97232472_grok_image_1782796933792_qwzfgx.jpg', video: 'https://nowssb.com/assets/videos/39905d27bd778cff_grok_video_2026-06-30-10-52-20_zk87yh.mp4', accent: Color(0xFF8FE6FF)),
];

class PracticeProgressScreen extends StatefulWidget {
  const PracticeProgressScreen({super.key, required this.words});
  final List<Word> words;

  @override
  State<PracticeProgressScreen> createState() => _PracticeProgressScreenState();
}

class _PracticeProgressScreenState extends State<PracticeProgressScreen> {
  bool _intro = true;

  Widget _introPage(PracticeProgress p) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/profile_source/img-progress.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF101218)),
          ),
        ),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.18), Colors.black.withOpacity(.92)], stops: const [0.18, .9])))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 19)),
              const Spacer(),
              const Text('HEALING JOURNEY', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
            ]),
            const Spacer(),
            const Text('MY PROGRESS', style: TextStyle(color: NwsbColors.goldLight, fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('Your\npractice.\nYour proof.', style: TextStyle(color: Colors.white, fontSize: 42, height: .98, fontWeight: FontWeight.w700, letterSpacing: -1.6)),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 18),
            const Text("Every session you complete is recorded here. Your streak, the words you've activated, the organs you've reached — all real, all yours.", style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            Row(children: [
              Text('${p.streak}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const Text(' day streak', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('·', style: TextStyle(color: Colors.white54))),
              Text('${p.totalSessions}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const Text(' sessions', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('·', style: TextStyle(color: Colors.white54))),
              Text('${p.uniqueWords}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const Text(' words', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => setState(() => _intro = false),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0x66C8E8F5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('VIEW MY PROGRESS', style: TextStyle(color: Color(0xD9C8E8F5), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w700)), SizedBox(width: 10), Icon(Icons.arrow_forward, color: Color(0xD9C8E8F5), size: 17)]),
            )),
          ]),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: PracticeProgress.instance,
        builder: (context, _) {
          final p = PracticeProgress.instance;
          final uniqueWords = p.uniqueWords;
          if (_intro) return _introPage(p);
          return Scaffold(
            backgroundColor: NwsbColors.deep,
            appBar: AppBar(
              backgroundColor: NwsbColors.deep,
              foregroundColor: Colors.white,
              title: const Text('My Progress'),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              children: [
                _WebsiteProgressGreeting(streak: p.streak, sessions: p.totalSessions, words: uniqueWords),
                const _WebsiteSectionLabel('Your Numbers'),
                _WebsiteStats(streak: p.streak, sessions: p.totalSessions, words: uniqueWords),
                const _WebsiteSectionLabel('This Week'),
                _WebsiteWeek(streak: p.streak),
                if (p.lastPracticed != null) _LastPracticed(value: p.lastPracticed!),
                const _WebsiteSectionLabel('Recent Sessions'),
                _RecentSessions(sessions: p.sessionsSnapshot, words: widget.words),
                const _WebsiteSectionLabel('Your Feedback'),
                const _NativeFeedback(),
                const _WebsiteSectionLabel('Milestones'),
                _Milestones(streak: p.streak, sessions: p.totalSessions, words: uniqueWords),
                const _WebsiteSectionLabel('Healing Body Map'),
                const _NativeBodyMap(),
                const _WebsiteSectionLabel('Weekly Insight'),
                const _NativeInsight(),
              ],
            ),
          );
        },
      );
}

class _WebsiteProgressGreeting extends StatelessWidget {
  const _WebsiteProgressGreeting({required this.streak, required this.sessions, required this.words});
  final int streak, sessions, words;
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    String msg, sub;
    if (streak == 0 && sessions == 0) { msg = 'Your journey starts today.'; sub = 'Every master word practitioner began with zero sessions. Practice one word — your data begins building now.'; }
    else if (streak == 0) { msg = '$sessions session${sessions == 1 ? '' : 's'} in your history.'; sub = "You've practiced $words unique word${words == 1 ? '' : 's'}. Practice today to restart your streak."; }
    else if (streak >= 21) { msg = '$streak-day streak. Deep resonance.'; sub = '$words words activated. $sessions sessions complete. You are building something real.'; }
    else if (streak >= 7) { msg = '$streak days in a row. Momentum building.'; sub = '$words unique word${words == 1 ? '' : 's'} practiced. $sessions sessions logged.'; }
    else { msg = '${streak > 0 ? '$streak-day' : 'Starting your'} streak.'; sub = '$sessions session${sessions == 1 ? '' : 's'} completed · $words word${words == 1 ? '' : 's'} practiced.'; }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x24FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greet, Practitioner', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.55)),
      ]),
    );
  }
}

class _WebsiteSectionLabel extends StatelessWidget {
  const _WebsiteSectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(2, 8, 2, 12), child: Text(text.toUpperCase(), style: const TextStyle(color: NwsbColors.goldLight, letterSpacing: 2.2, fontSize: 10, fontWeight: FontWeight.w700)));
}

class _WebsiteStats extends StatelessWidget {
  const _WebsiteStats({required this.streak, required this.sessions, required this.words});
  final int streak, sessions, words;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _StatPanel('$streak', 'Day Streak', streak == 0 ? 'Start today' : streak == 1 ? 'Started' : 'consecutive')),
    const SizedBox(width: 10), Expanded(child: _StatPanel('$sessions', 'Sessions', sessions == 0 ? 'None yet' : 'total logged')),
    const SizedBox(width: 10), Expanded(child: _StatPanel('$words', 'Words', words == 0 ? 'None yet' : 'practiced')),
  ]);
}
class _StatPanel extends StatelessWidget {
  const _StatPanel(this.value, this.label, this.sub);
  final String value, label, sub;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 15, 10, 14), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), border: Border.all(color: const Color(0x24FFFFFF)), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 26, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9))]));
}

class _WebsiteWeek extends StatelessWidget {
  const _WebsiteWeek({required this.streak});
  final int streak;
  @override
  Widget build(BuildContext context) { const names=['Mon','Tue','Wed','Thu','Fri','Sat','Sun']; const letters=['M','T','W','T','F','S','S']; final done=streak.clamp(0,7); return Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x24FFFFFF))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for(var i=0;i<7;i++) Column(children: [Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:i>=7-done?NwsbColors.goldLight:const Color(0x14FFFFFF),shape:BoxShape.circle),child:Text(letters[i],style:TextStyle(color:i>=7-done?NwsbColors.deep:Colors.white54,fontWeight:FontWeight.w700))),const SizedBox(height:6),Text(names[i],style:const TextStyle(color:Colors.white54,fontSize:9))])])); }
}
class _LastPracticed extends StatelessWidget { const _LastPracticed({required this.value}); final String value; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:10,bottom:12),child:Row(children:[Container(width:5,height:5,decoration:const BoxDecoration(color:NwsbColors.goldLight,shape:BoxShape.circle)),const SizedBox(width:7),Text('Last practiced $value',style:const TextStyle(color:Colors.white54,fontSize:10))])); }

class _RecentSessions extends StatelessWidget { const _RecentSessions({required this.sessions, required this.words}); final List<Map<String,dynamic>> sessions; final List<Word> words; @override Widget build(BuildContext context){ if(sessions.isEmpty)return _EmptyPanel(title:'No sessions recorded yet',text:'Complete your first word practice session and your real progress will appear here — every rep, every word, every day.'); final rows=sessions.take(8).toList(); return Column(children:[for(final s in rows) Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0x0DFFFFFF),border:Border.all(color:const Color(0x24FFFFFF)),borderRadius:BorderRadius.circular(16)),child:Row(children:[Container(width:38,height:38,alignment:Alignment.center,decoration:const BoxDecoration(color:Color(0x1AE8D5A3),shape:BoxShape.circle),child:Text('${s['word']??'—'}'.characters.first,style:const TextStyle(color:NwsbColors.goldLight,fontSize:17,fontWeight:FontWeight.w700))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${s['word']??'—'}',style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600)),Text('${s['date']??''}',style:const TextStyle(color:Colors.white54,fontSize:10))])),Text('✓',style:const TextStyle(color:NwsbColors.goldLight,fontSize:18))]))]); } }
class _EmptyPanel extends StatelessWidget { const _EmptyPanel({required this.title,required this.text}); final String title,text; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0x0DFFFFFF),border:Border.all(color:const Color(0x24FFFFFF)),borderRadius:BorderRadius.circular(18)),child:Column(children:[const Text('◌',style:TextStyle(color:Colors.white38,fontSize:30)),const SizedBox(height:8),Text(title,style:const TextStyle(color:Colors.white70,fontSize:14,fontWeight:FontWeight.w600)),const SizedBox(height:6),Text(text,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white54,fontSize:11,height:1.5))])); }

class _NativeFeedback extends StatelessWidget { const _NativeFeedback(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0x0DFFFFFF),border:Border.all(color:const Color(0x24FFFFFF)),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text("What's working for you?",style:TextStyle(color:Colors.white70,fontSize:13)),const SizedBox(height:10),Wrap(spacing:7,runSpacing:7,children:['Morning routine','Evening session','Repeat mode','Listening mode','Word meaning','Phonetic guide'].map((x)=>_FeedbackChip(x)).toList()),const SizedBox(height:14),const Text("What's not working or feels off?",style:TextStyle(color:Colors.white70,fontSize:13)),const SizedBox(height:10),Wrap(spacing:7,runSpacing:7,children:['Too many words','Audio missing','Pronunciation unclear','App too slow'].map((x)=>_FeedbackChip(x)).toList())])); }
class _FeedbackChip extends StatelessWidget { const _FeedbackChip(this.text); final String text; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:8),decoration:BoxDecoration(color:const Color(0x0FFFFFFF),border:Border.all(color:const Color(0x33FFFFFF)),borderRadius:BorderRadius.circular(20)),child:Text(text,style:const TextStyle(color:Colors.white60,fontSize:10))); }

class _Milestones extends StatelessWidget {
  const _Milestones({required this.streak, required this.sessions, required this.words});
  final int streak, sessions, words;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('◎', 'First Session', 'Complete 1 session', sessions >= 1),
      ('◈', '3-Day Streak', 'Practice 3 days in a row', streak >= 3),
      ('◉', 'Weekly Rhythm', '7 consecutive days', streak >= 7),
      ('◆', '21-Day Resonance', '21 days unbroken', streak >= 21),
      ('◇', '5 Words Activated', 'Practice 5 unique words', words >= 5),
      ('⬡', '10 Words Activated', 'Practice 10 unique words', words >= 10),
      ('▲', 'Deep Practitioner', '21 sessions completed', sessions >= 21),
      ('★', 'Century Mark', '100 sessions logged', sessions >= 100),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        final unlocked = item.$4;
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: unlocked ? const Color(0x0DE8D5A3) : const Color(0x0DFFFFFF),
            border: Border.all(color: unlocked ? const Color(0x55E8D5A3) : const Color(0x24FFFFFF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$1, style: TextStyle(color: unlocked ? NwsbColors.goldLight : Colors.white38, fontSize: 18)),
            const Spacer(),
            Text(item.$2, style: TextStyle(color: unlocked ? NwsbColors.goldLight : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(item.$3, style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ]),
        );
      },
    );
  }
}
class _NativeBodyMap extends StatelessWidget { const _NativeBodyMap(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0x0DFFFFFF),border:Border.all(color:const Color(0x24FFFFFF)),borderRadius:BorderRadius.circular(18)),child:Column(children:[SizedBox(height:290,child:SvgPicture.asset('assets/icons/bodymap.svg', fit: BoxFit.contain, placeholderBuilder: (_) => const Icon(Icons.accessibility_new, color: NwsbColors.goldLight, size: 150))),const Text('Your practiced words activate resonance pathways through the body.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:12,height:1.5))])); }
class _NativeInsight extends StatelessWidget { const _NativeInsight(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xD9060C18),Color(0xB80F1C37)]),border:Border.all(color:const Color(0x24C8E8F5)),borderRadius:BorderRadius.circular(18)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text('•',style:TextStyle(color:NwsbColors.mist,fontSize:18)),SizedBox(width:8),Text('SHABDAPATHY · AI ANALYSIS',style:TextStyle(color:NwsbColors.mist,letterSpacing:2.5,fontSize:9,fontWeight:FontWeight.w700))]),SizedBox(height:14),Text('Complete your first practice session and a personal insight will appear here — built from your actual data, not a template.',style:TextStyle(color:Color(0xB8FFFFFF),fontSize:14,height:1.7))]));
}
