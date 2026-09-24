/// Saved words — the quick library opened from the clock.
///
/// These are words the listener saved. Nothing here is a download.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/player_aura.dart';
import 'player_settings.dart';
import 'practice_player.dart';

class SavedWordsScreen extends StatefulWidget {
  const SavedWordsScreen({super.key});

  @override
  State<SavedWordsScreen> createState() => _SavedWordsScreenState();
}

class _SavedWordsScreenState extends State<SavedWordsScreen> {
  static const _likedWordsKey = 'nwsb_liked_words';
  List<Word> _saved = const [];
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final names = (prefs.getStringList(_likedWordsKey) ?? const <String>[]).toSet();
    final library = ContentStore.instance.library;
    final saved = <Word>[
      for (final word in library)
        if (names.contains(word.word)) word,
    ];
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _ready = true;
    });
  }

  List<Word> _rows() {
    final have = _saved.map((w) => w.word).toSet();
    final extra = <Word>[
      for (final word in ContentStore.instance.library)
        if (!have.contains(word.word)) word,
    ];
    return [..._saved, ...extra.take(5)];
  }

  static const _arts = <String>[
    'assets/banners/promo/pose-01.png',
    'assets/banners/promo/pose-02.png',
    'assets/banners/promo/pose-03.png',
    'assets/banners/promo/pose-04.png',
    'assets/banners/promo/pose-05.png',
    'assets/banners/promo/pose-06.png',
    'assets/banners/promo/pose-07.png',
  ];

  static const _backs = <Color>[
    Color(0xFFE07A32),
    Color(0xFF7C4DFF),
    Color(0xFF2EC4B6),
    Color(0xFFE85D9A),
    Color(0xFFD4A017),
    Color(0xFF3D8BDB),
    Color(0xFF2D6A4F),
  ];

  Widget _thumb(Word word, int i) {
    final asset = word.img.startsWith('assets/') ? word.img : _arts[i % _arts.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: ColoredBox(
          color: _backs[i % _backs.length],
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1A)),
            ),
          ),
        ),
      ),
    );
  }

  void _open(List<Word> words) {
    if (words.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePlayerScreen(
          words: words,
          title: 'Saved words',
          showIntro: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPlayerAuraBg,
      body: PlayerAuraBackdrop(
        film: kPlayerPageFilm,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
                child: Row(
                  children: [
                    PlayerAuraBackButton(
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.schedule_rounded, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlayerSettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Text(
                  'LIBRARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 6,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Text(
                  _ready ? '${_rows().length} WORDS · SAVED' : 'SAVED WORDS',
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              Expanded(
                child: !_ready
                    ? const SizedBox.shrink()
                    : Builder(
                        builder: (context) {
                          final rows = _rows();
                          if (rows.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(28),
                                child: Text(
                                  'No saved words yet. Save a word from the player and it stays in this library.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xB3FFFFFF), height: 1.4),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final word = rows[i];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _open(rows),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Row(
                                      children: [
                                        _thumb(word, i),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 1,
                                          height: 36,
                                          color: const Color(0x33FFFFFF),
                                        ),
                                        const SizedBox(width: 12),
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                word.origin.isEmpty
                                                    ? 'NATURAL ORIGIN'
                                                    : word.origin.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0x88FFFFFF),
                                                  fontSize: 11,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (_ready && _rows().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xB312161C),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: InkWell(
                          onTap: () => _open(_rows()),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                            child: Row(
                              children: [
                                _thumb(_rows().first, 0),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: const Color(0x33FFFFFF),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _rows().first.word.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      Text(
                                        _rows().first.origin.isEmpty
                                            ? 'NATURAL ORIGIN'
                                            : _rows().first.origin.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0x88FFFFFF),
                                          fontSize: 10,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 26),
                                const SizedBox(width: 4),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.6),
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
