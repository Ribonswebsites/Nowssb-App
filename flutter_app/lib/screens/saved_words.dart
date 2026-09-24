/// Saved words — the quick library opened from the clock.
///
/// These are words the listener saved. Nothing here is a download.
library;

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

  void _open(int index) {
    if (_saved.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePlayerScreen(
          words: _saved,
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
                  _ready
                      ? '${_saved.length} WORDS · SAVED'
                      : 'SAVED WORDS',
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
                    : _saved.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Text(
                                'No saved words yet. Save a word from the player and it stays in this library.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xB3FFFFFF), height: 1.4),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: _saved.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final word = _saved[i];
                              final secs = 150 + (word.word.hashCode.abs() % 120);
                              final m = secs ~/ 60;
                              final s = (secs % 60).toString().padLeft(2, '0');
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _open(i),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: word.img.isEmpty
                                                ? const ColoredBox(color: Color(0xFF1A1A1A))
                                                : Image.asset(
                                                    word.img,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        const ColoredBox(color: Color(0xFF1A1A1A)),
                                                  ),
                                          ),
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
                                                word.origin.isEmpty ? 'NOWSSB' : word.origin.toUpperCase(),
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
                                        Text(
                                          '$m:$s',
                                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (_saved.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Material(
                    color: const Color(0x66101418),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _open(0),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: _saved.first.img.isEmpty
                                    ? const ColoredBox(color: Color(0xFF1A1A1A))
                                    : Image.asset(
                                        _saved.first.img,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(color: Color(0xFF1A1A1A)),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _saved.first.word.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Icon(Icons.skip_previous_rounded, color: Colors.white),
                            const SizedBox(width: 6),
                            const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                            const SizedBox(width: 6),
                            const Icon(Icons.skip_next_rounded, color: Colors.white),
                          ],
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
