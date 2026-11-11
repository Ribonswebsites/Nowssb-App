/// YouTube Music album page used by the Sound Library "Currently Playing" chip.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/word_voice.dart';
import '../data/playback_session.dart';
import '../widgets/hero_glass.dart';
import '../widgets/sound_glass.dart' show SessionPlayer, SlTransport;
import '../widgets/glass_wrap.dart';
import '../widgets/nwsb_icon.dart';
import '../admin/template/editable.dart';

class CurrentlyPlayingAlbum extends StatelessWidget {
  const CurrentlyPlayingAlbum({
    super.key,
    required this.words,
    required this.art,
    required this.counts,
    required this.onPlay,
    required this.onOpen,
  });

  final List<Word> words;
  final String Function(String) art;
  final Map<String, int> counts;
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word> onOpen;

  static String _dur(Word w) {
    final sec = (w.word.hashCode.abs() % 90) + 45;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _plays(int n) {
    if (n <= 0) return '0 plays';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M plays';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K plays';
    return '$n plays';
  }

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EditableLabel('currently_playing_album.CurrentlyPlayingAlbum',
          'Nothing is playing yet. Start a session and it lands here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99FFFFFF)),
        ),
      );
    }
    final head = words.first;
    final cover = art(head.word);
    final year = DateTime.now().year.toString();

    return Column(
      children: [
        const SizedBox(height: 10),
        CurrentlyPlayingHero(
          words: words,
          art: art,
          onPlay: onPlay,
          onOpen: onOpen,
          onDownload: () => _saveOffline(context),
        ),
        const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EditableLabel('currently_playing_album.CurrentlyPlayingAlbum',
                              'Sample this',
                              style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            EditableLabel('currently_playing_album.CurrentlyPlayingAlbum',
                              'Tap to preview this album and find your favorites',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        height: 48,
                        child: Stack(
                          children: [
                            for (var i = 0; i < words.take(3).length; i++)
                              Positioned(
                                left: i * 14.0,
                                child: Transform.rotate(
                                  angle: (i - 1) * 0.12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      width: 36,
                                      height: 48,
                                      child: EditableImage.asset(
                                        art(words[i].word),
                                        fit: BoxFit.cover,
                                        word: words[i].word,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(
                                                color: Color(0xFF333333)),
                                                slot: 'currently_playing_album.CurrentlyPlayingAlbum',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < words.length; i++)
                _track(
                  index: i + 1,
                  word: words[i],
                  sub:
                      '${words[i].origin.isNotEmpty ? words[i].origin : 'NowssB'} · ${_dur(words[i])} · ${_plays(counts[words[i].word] ?? ((words[i].word.hashCode.abs() % 9000) + 120))}',
                  onPlay: () => onPlay(words[i]),
                  onMore: () => onOpen(words[i]),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: EditableImage.asset(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ColoredBox(color: Color(0xFF333333)),
                                slot: 'currently_playing_album.CurrentlyPlayingAlbum',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              head.word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              head.origin.isNotEmpty ? head.origin : 'NowssB',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniToggle(head: head, onPlay: onPlay),
                    ],
                  ),
                ),
              ),
            ],
    );
  }

  /// Keeps every recording in this list on the phone (WordVoice's cache),
  /// so the session plays without a connection.
  Future<void> _saveOffline(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final withVoice = words.where(WordVoice.hasVoice).toList();
    if (withVoice.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: EditableLabel('currently_playing_album.CurrentlyPlayingAlbum', 'These words use the built-in voice, which already works offline.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text('Saving ${withVoice.length} recordings for offline…'),
      behavior: SnackBarBehavior.floating,
    ));
    for (final w in withVoice) {
      await WordVoice.prefetch(w);
    }
    messenger.showSnackBar(const SnackBar(
      content: EditableLabel('currently_playing_album.CurrentlyPlayingAlbum', 'Saved. This session now plays offline.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _round(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _track({
    required int index,
    required Word word,
    required String sub,
    required VoidCallback onPlay,
    required VoidCallback onMore,
  }) {
    return InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  EditableLabel('currently_playing_album.CurrentlyPlayingAlbum',
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, color: Color(0x99FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

const String _kSlot = 'currently_playing_album.CurrentlyPlayingAlbum';

/// The whole Currently Playing block in ONE glass wrapper: NOWSSB mark and
/// label on top, the artwork on the LEFT, and on the RIGHT the eyebrow,
/// title, subtitle, progress and the previous / play-pause / next controls,
/// with the download / save / chat / more actions along the bottom.
///
/// Wired to the real [PlaybackSession] through [SlTransport]. With a live
/// session the buttons drive it; with none, play starts the session on the
/// shown word ([onPlay]) and previous / next step through [words].
///
/// There is deliberately no thinking orb here. The play button is a plain
/// white disc with a play or pause glyph.
class CurrentlyPlayingHero extends StatefulWidget {
  const CurrentlyPlayingHero({
    super.key,
    required this.words,
    required this.art,
    required this.onPlay,
    required this.onOpen,
    required this.onDownload,
    this.player,
  });

  final List<Word> words;
  final String Function(String) art;
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word> onOpen;
  final VoidCallback onDownload;
  final SlTransport? player;

  @override
  State<CurrentlyPlayingHero> createState() => _CurrentlyPlayingHeroState();
}

class _CurrentlyPlayingHeroState extends State<CurrentlyPlayingHero>
    with SingleTickerProviderStateMixin {
  late final SlTransport _p = widget.player ?? SessionPlayer();
  late final AnimationController _bar =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));
  int _i = 0;

  bool get _live => _p.active && _p.word != null;
  bool get _playing => _live && _p.playing;

  Word get _word {
    if (_live) return _p.word!;
    return widget.words[_i % widget.words.length];
  }

  @override
  void initState() {
    super.initState();
    _p.addListener(_onSession);
    _sync();
  }

  @override
  void dispose() {
    _p.removeListener(_onSession);
    _bar.dispose();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    _sync();
    setState(() {});
  }

  void _sync() {
    if (_playing) {
      if (!_bar.isAnimating) _bar.repeat();
    } else {
      _bar.stop();
      if (!_live) _bar.value = 0;
    }
  }

  void _toggle() {
    if (_live) {
      unawaited(_p.toggle());
    } else {
      widget.onPlay(_word);
    }
  }

  void _step(int by) {
    if (_live) {
      unawaited(by > 0 ? _p.next() : _p.previous());
      return;
    }
    final n = widget.words.length;
    setState(() {
      _i = (_i + by) % n;
      if (_i < 0) _i += n;
      _bar.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    final year = DateTime.now().year;
    final sub = [
      if (w.origin.isNotEmpty) w.origin else if (w.organ.isNotEmpty) w.organ,
      if (w.meaning.isNotEmpty) w.meaning,
    ].join(' · ');
    final eyebrow = _live
        ? (_playing ? 'NOW PLAYING' : 'PAUSED')
        : 'READY TO PLAY';
    return GlassWrap(
      key: const ValueKey('cp-hero'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                    color: Color(0x33000000), shape: BoxShape.circle),
                child: const Center(
                  child: NwsbIcon(NwsbMarks.play, size: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const EditableLabel(
                _kSlot,
                'NOWSSB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'Currently Playing · $year',
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  key: const ValueKey('cp-hero-art'),
                  width: 136,
                  height: 136,
                  child: EditableImage.asset(
                    widget.art(w.word),
                    fit: BoxFit.cover,
                    word: w.word,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF1A1A1A)),
                    slot: _kSlot,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrow,
                      key: const ValueKey('cp-hero-eyebrow'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 10.5,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w.word,
                      key: const ValueKey('cp-hero-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xCCFFFFFF), fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _bar,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          height: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: Color(0x33FFFFFF)),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _bar.value.clamp(0.0, 1.0),
                                child: const ColoredBox(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _glassButton(const ValueKey('cp-hero-prev'),
                            Icons.skip_previous_rounded, 'Previous', () => _step(-1)),
                        Semantics(
                          button: true,
                          label: _playing ? 'Pause' : 'Play',
                          excludeSemantics: true,
                          child: GestureDetector(
                            key: const ValueKey('cp-hero-toggle'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggle,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                _playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF111118),
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                        _glassButton(const ValueKey('cp-hero-next'),
                            Icons.skip_next_rounded, 'Next', () => _step(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _glassButton(const ValueKey('cp-hero-download'),
                  Icons.download_outlined, 'Save offline', widget.onDownload),
              _glassButton(const ValueKey('cp-hero-save'),
                  Icons.bookmark_border, 'Save', () => widget.onOpen(w)),
              _glassButton(const ValueKey('cp-hero-chat'),
                  Icons.chat_bubble_outline, 'Chat', () => widget.onOpen(w)),
              _glassButton(const ValueKey('cp-hero-more'), Icons.more_vert,
                  'More', () => widget.onOpen(w)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassButton(Key key, IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HeroGlassRecipe.fill,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Play / pause on the mini row at the bottom — the real session, no orb.
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.head, required this.onPlay});
  final Word head;
  final ValueChanged<Word> onPlay;

  @override
  Widget build(BuildContext context) {
    final s = PlaybackSession.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final playing = s.active && s.playing;
        return IconButton(
          key: const ValueKey('cp-mini-toggle'),
          tooltip: playing ? 'Pause' : 'Play',
          onPressed: () {
            if (s.active) {
              unawaited(s.togglePlay());
            } else {
              onPlay(head);
            }
          },
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
