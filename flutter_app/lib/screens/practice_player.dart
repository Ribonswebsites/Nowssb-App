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
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/practice_progress.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import 'sound_library.dart';
import 'store.dart';

String _fmtClock(num sec) {
  final s = sec.round().clamp(0, 24 * 3600);
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

String _wordClock(Word word) {
  var sec = 0.0;
  for (final part in word.parts) {
    sec += part.hold;
  }
  if (sec < 8) sec = 321;
  return _fmtClock(sec);
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

  final FlutterTts _tts = FlutterTts();
  var _index = 0;
  var _playing = false;
  var _completed = false;
  var _liked = false;
  var _loop = false;
  var _volume = 1.0;
  String? _error;

  Word get _word => widget.words[_index];
  _PlayerTheme get _theme => _playerThemes[_index % _playerThemes.length];

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_onProgress);
    unawaited(PracticeProgress.instance.start());
    unawaited(_loadLiked());
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

  Future<void> _move(int direction) async {
    final next = _index + direction;
    if (next < 0 || next >= widget.words.length) return;
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
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB8060C18),
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: _LevelList(),
      ),
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

  void _openSettings() {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB8060C18),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(28),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE6172334),
              border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
              boxShadow: [BoxShadow(color: _theme.accent.withOpacity(.35), blurRadius: 44)],
            ),
            child: Stack(children: [
              Center(
                child: Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x33FFFFFF),
                    border: Border.all(color: const Color(0x88FFFFFF)),
                  ),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.settings_rounded, color: Colors.white, size: 34),
                    SizedBox(height: 4),
                    Text('SETTINGS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ]),
                ),
              ),
              _RadialOption(
                alignment: Alignment.topCenter,
                label: 'VOICE',
                value: 'Device',
                accent: _theme.accent,
                onTap: () => ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('NowssB uses your selected device voice.')),
                ),
              ),
              _RadialOption(
                alignment: Alignment.centerRight,
                label: 'LOOP',
                value: _loop ? 'On' : 'Off',
                accent: _theme.accent,
                onTap: () => setState(() => _loop = !_loop),
              ),
              _RadialOption(
                alignment: Alignment.bottomCenter,
                label: 'REPLAY',
                value: 'Word',
                accent: _theme.accent,
                onTap: _prepareAndPlay,
              ),
              _RadialOption(
                alignment: Alignment.centerLeft,
                label: 'LIBRARY',
                value: 'Open',
                accent: _theme.accent,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).push(MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen()));
                },
              ),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
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
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(children: [
        // The application-wide selected Fashion Plus layer stays mounted on
        // this route. The liquid Player visual is the route's own supplied
        // skin, exactly as it is in the WebView Player, rather than a second
        // generic practice-card background.
        const Positioned.fill(child: AppBackdrop()),
        Positioned.fill(child: _PlayerThemeArtwork(theme: theme)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x48060A19), Color(0x74060A19), Color(0xC4060A19)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final stageWidth = math.min(constraints.maxWidth - 48, 360.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 28)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  _PlayerHeader(onBack: () => Navigator.of(context).pop(), onSettings: _openSettings),
                  const SizedBox(height: 14),
                  Text(
                    _word.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE8D5A3), fontSize: 46, fontWeight: FontWeight.w600, height: 1.02, letterSpacing: -1.1, fontFamily: 'Georgia', shadows: [Shadow(color: Color(0x73000000), blurRadius: 22)]),
                  ),
                  const SizedBox(height: 4),
                  const Text('NowssB', style: TextStyle(color: Color(0xFFE8D5A3), fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(width: stageWidth, child: _VisualStage(
                    word: _word,
                    theme: theme,
                    playing: _playing,
                    liked: _liked,
                    volume: _volume,
                    onLevel: _openLevel,
                    onInfo: _openInfo,
                    onReplay: _prepareAndPlay,
                    onNotes: _openNotes,
                    onLike: _toggleLike,
                    onVolumeChanged: (volume) async {
                      setState(() => _volume = volume);
                      await _tts.setVolume(volume);
                    },
                  )),
                  const SizedBox(height: 10),
                  SizedBox(width: math.min(stageWidth, 360), child: _TransportTube(
                    playing: _playing,
                    hasPrevious: _index > 0,
                    hasNext: _index < widget.words.length - 1,
                    durationLabel: _wordClock(_word),
                    onLibrary: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen())),
                    onPrevious: () => _move(-1),
                    onPlay: _togglePlay,
                    onNext: () => _move(1),
                    onReplay: _prepareAndPlay,
                  )),
                  const SizedBox(height: 10),
                  SizedBox(width: stageWidth, child: _NextUpCard(
                    next: _index < widget.words.length - 1 ? widget.words[_index + 1] : null,
                    art: _index < widget.words.length - 1
                        ? _playerThemes[(_index + 1) % _playerThemes.length].image
                        : null,
                    onPlay: () => _move(1),
                    onAdd: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen())),
                  )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: stageWidth,
                    child: _WordOverlay(
                      word: _word, accent: theme.accent, playing: _playing, liked: _liked,
                      onReplay: _prepareAndPlay, onNotes: _openNotes, onLike: _toggleLike,
                    ),
                  ),
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
      ]),
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
  const _PlayerHeader({required this.onBack, required this.onSettings});
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Stack(alignment: Alignment.center, children: [
      Align(alignment: Alignment.centerLeft, child: _BareIconButton(icon: Icons.keyboard_arrow_down_rounded, onTap: onBack)),
      const Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .3)),
        SizedBox(height: 6),
        ColoredBox(color: Color(0xFFE8D5A3), child: SizedBox(width: 28, height: 2)),
      ]),
      Align(alignment: Alignment.centerRight, child: _BareIconButton(icon: Icons.more_horiz_rounded, onTap: onSettings)),
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
        final current = PracticeProgress.instance.level;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD1060A16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x38FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: 12,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: ColoredBox(color: Color(0x47FFFFFF), child: SizedBox(height: 1, width: double.infinity)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Text(
                      'Level $n',
                      style: TextStyle(
                        color: on ? const Color(0xFFE8D5A3) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: word == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(children: [
                const Text('No more sessions queued', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x2EFFFFFF))),
                    child: const Text('Add a session', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ]),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Text('UP NEXT', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),
              Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 12),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: art != null && art!.isNotEmpty
                        ? (art!.startsWith('http')
                            ? Image.network(art!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)))
                            : Image.asset(art!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111))))
                        : const ColoredBox(color: Color(0xFF111111)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onPlay,
                    behavior: HitTestBehavior.opaque,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(word.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(_wordClock(word), style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11, letterSpacing: .2)),
                    ]),
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.more_horiz_rounded, color: Color(0xBFFFFFFF), size: 22),
                  ),
                ),
              ]),
            ),
            ]),
    );
  }
}

class _VisualStage extends StatelessWidget {
  const _VisualStage({
    required this.word, required this.theme, required this.playing, required this.liked,
    required this.volume, required this.onLevel, required this.onInfo,
    required this.onReplay, required this.onNotes, required this.onLike,
    required this.onVolumeChanged,
  });

  final Word word;
  final _PlayerTheme theme;
  final bool playing;
  final bool liked;
  final double volume;
  final VoidCallback onLevel;
  final VoidCallback onInfo;
  final VoidCallback onReplay;
  final VoidCallback onNotes;
  final VoidCallback onLike;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1 / 0.92,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Stack(fit: StackFit.expand, children: [
          NwsbVideo(asset: theme.video, poster: theme.image, priority: ClipPriority.feature, autoplay: true),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x09060A16), Color(0x00060A16), Color(0xC8060A16)]))),
          Positioned(
            top: 12, left: 12,
            child: Container(
              width: 34, height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8E8F5)]),
                border: Border.all(color: const Color(0xB3FFFFFF), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 14)],
              ),
              child: const Text('H', style: TextStyle(color: Color(0xFF0A0A12), fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
          Positioned(
            top: 14, right: 14,
            child: Text(_wordClock(word), style: const TextStyle(color: Color(0xEBFFFFFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .4, shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)])),
          ),
          Positioned(right: 10, bottom: 52, child: _VolumeRail(value: volume, onChanged: onVolumeChanged)),
          Positioned(
            left: 14, right: 14, bottom: 12,
            child: Row(children: [
              const Expanded(child: Text('Healing through words', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)]))),
              GestureDetector(
                onTap: onLevel,
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: const Color(0x29E8D5A3),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x73E8D5A3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFE8D5A3), size: 12),
                    const SizedBox(width: 6),
                    Text('Level ${PracticeProgress.instance.level}  ›', style: const TextStyle(color: Color(0xFFE8D5A3), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}

class _WordOverlay extends StatelessWidget {
  const _WordOverlay({
    required this.word, required this.accent, required this.playing,
    required this.liked, required this.onReplay, required this.onNotes, required this.onLike,
  });
  final Word word;
  final Color accent;
  final bool playing;
  final bool liked;
  final VoidCallback onReplay;
  final VoidCallback onNotes;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
      if (word.parts.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: word.parts.map((part) => _PronunciationChip(part: part, accent: accent, compact: true)).toList()),
      ],
      if (word.organ.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(word.organ.toUpperCase(), style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3.6)),
      ],
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x8C060A16),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0x38FFFFFF)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _ActBtn(icon: Icons.replay_rounded, onTap: onReplay),
          Container(width: 1, height: 16, color: const Color(0x59FFFFFF)),
          _ActBtn(icon: Icons.description_outlined, onTap: onNotes),
          Container(width: 1, height: 16, color: const Color(0x59FFFFFF)),
          _ActBtn(icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? accent : Colors.white, onTap: onLike),
        ]),
      ),
    ]);
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
  const _TransportTube({required this.playing, required this.hasPrevious, required this.hasNext, required this.durationLabel, required this.onLibrary, required this.onPrevious, required this.onPlay, required this.onNext, required this.onReplay});
  final bool playing;
  final bool hasPrevious;
  final bool hasNext;
  final String durationLabel;
  final VoidCallback onLibrary;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  static const _tube = 'https://media.nowssb.com/migrated-images/19432211f0f348fc_file_0000000016bc71fab1ae5a054ac772af_gwttc6.png';
  static const _play = 'https://media.nowssb.com/migrated-images/74d38b3c7b69b30b_e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png';
  static const _pause = 'https://media.nowssb.com/migrated-images/f073aa60452e1cb9_e0723190-7389-11f1-8c74-0593c060acc9_e0lcl6.png';
  static const _prev = 'https://media.nowssb.com/migrated-images/2f091c1083cd0b65_ad77f630-7389-11f1-8c74-0593c060acc9_pe0zco.png';
  static const _next = 'https://media.nowssb.com/migrated-images/71a2d8954b5e6209_c5576970-7389-11f1-8c74-0593c060acc9_c4epec.png';

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 36, child: Text('0:00', style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11, fontWeight: FontWeight.w600))),
    Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 86),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
        decoration: const BoxDecoration(
          image: DecorationImage(image: NetworkImage(_tube), fit: BoxFit.fill),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _ImageControl(asset: 'assets/player/lgp-prev.png', network: _prev, label: 'Previous', onTap: hasPrevious ? onPrevious : null, size: 48),
          GestureDetector(
            onTap: onPlay,
            child: SizedBox(
              width: 66,
              height: 66,
              child: Image.asset(
                playing ? 'assets/player/lgp-pause.png' : 'assets/player/lgp-play.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.network(playing ? _pause : _play, fit: BoxFit.contain),
              ),
            ),
          ),
          _ImageControl(asset: 'assets/player/lgp-next.png', network: _next, label: 'Next', onTap: hasNext ? onNext : null, size: 48),
        ]),
      ),
    ),
    SizedBox(width: 36, child: Text(durationLabel, textAlign: TextAlign.right, style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11, fontWeight: FontWeight.w600))),
  ]);
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
  const _RadialOption({required this.alignment, required this.label, required this.value, required this.accent, required this.onTap});
  final Alignment alignment;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: InkResponse(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x2BFFFFFF),
            border: Border.all(color: accent.withOpacity(.8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    ),
  );
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
  // The former third visual is now the first/default look for a session.
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/d694cb3157c4e58f_grok_image_1782656710977_nj5r6x.jpg', video: 'assets/videos/31cbc323e2d03dbb_grok_video_2026-06-28-19-55-09_otgbxd.mp4', accent: Color(0xFF9BB8FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/3670d1e477f48c31_grok_image_1782656676834_rzp2cz.jpg', video: 'assets/videos/3628088cee108d9e_grok_video_2026-06-28-19-54-38_wrxkgr.mp4', accent: Color(0xFF7FE9DA)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/fd380f5670852d0c_grok_image_1782656704854_cfsah3.jpg', video: 'assets/videos/f36df7528f8d741b_grok_video_2026-06-28-19-55-02_of5fwh.mp4', accent: Color(0xFFBD7BFF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/e8bb832f2815c15a_grok_image_1782656684101_o9vc93.jpg', video: 'assets/videos/9207084d44a79e06_grok_video_2026-06-28-19-54-43_it2bur.mp4', accent: Color(0xFFA6DCFF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/48ad23ade254b2d7_grok_image_1782795582310_llvpix.jpg', video: 'assets/videos/874f8fcfb0e6ea6d_grok_video_2026-06-30-10-29-43_hzxyun.mp4', accent: Color(0xFFB9A6FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/20314fda05d34b49_grok_image_1782796537731_vzyhwn.jpg', video: 'assets/videos/c35616e766f6d146_grok_video_2026-06-30-10-45-45_dg2ohg.mp4', accent: Color(0xFFA6C8FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/f734c819e92db433_grok_image_1782796641824_izkh09.jpg', video: 'assets/videos/aca728b4c8b51a0e_grok_video_2026-06-30-10-47-20_rljghs.mp4', accent: Color(0xFFB9A6FF)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/e103480a2c87d55b_grok_image_1782796519587_thrrws.jpg', video: 'assets/videos/00212abd615fbd11_grok_video_2026-06-30-10-45-34_pg2y2j.mp4', accent: Color(0xFFE8D5A3)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/122962572090895c_grok_image_1782796924745_nmksmi.jpg', video: 'assets/videos/93c66feecbddedb0_grok_video_2026-06-30-10-52-07_gvffol.mp4', accent: Color(0xFFF0D9A8)),
  _PlayerTheme(image: 'https://media.nowssb.com/migrated-images/28b7b32c97232472_grok_image_1782796933792_qwzfgx.jpg', video: 'assets/videos/5972626e2ce6c9a6_grok_video_2026-06-30-10-52-20_zk87yh.mp4', accent: Color(0xFF8FE6FF)),
];

class PracticeProgressScreen extends StatelessWidget {
  const PracticeProgressScreen({super.key, required this.words});
  final List<Word> words;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: PracticeProgress.instance,
    builder: (context, _) {
      final progress = PracticeProgress.instance;
      final completed = progress.completedTodayFor(words);
      final goal = words.isEmpty ? 0 : (completed / words.length * 100).round().clamp(0, 100);
      return Scaffold(
        backgroundColor: NwsbColors.deep,
        appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white, title: const Text('Your progress')),
        body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('LIVE PRACTICE DATA', style: TextStyle(color: NwsbColors.goldLight, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Text(progress.totalSessions == 0 ? 'Your first completed playback will appear here.' : 'Your progress is built from completed sessions on this device.', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 17, height: 1.45)),
          const SizedBox(height: 26),
          _ProgressStat(value: '${progress.todaySessions}', label: 'Sessions today'),
          _ProgressStat(value: '${progress.totalSessions}', label: 'Total sessions'),
          _ProgressStat(value: '${progress.streak}', label: 'Day streak'),
          _ProgressStat(value: words.isEmpty ? '—' : '$goal%', label: words.isEmpty ? 'Today’s goal' : '$completed of ${words.length} words today'),
        ]))),
      );
    },
  );
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x24FFFFFF))),
    child: Row(children: [Text(value, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 26, fontWeight: FontWeight.w800)), const SizedBox(width: 16), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))]),
  );
}
