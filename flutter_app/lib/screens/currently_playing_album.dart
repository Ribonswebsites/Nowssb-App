/// YouTube Music album page used by the Sound Library "Currently Playing" chip.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../data/models.dart';
import '../widgets/app_thinking_loader.dart';

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
        child: Text(
          'Nothing is playing yet. Start a session and it lands here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99FFFFFF)),
        ),
      );
    }
    final head = words.first;
    final cover = art(head.word);
    final year = DateTime.now().year.toString();

    return ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                    child: Transform.scale(
                      scale: 1.35,
                      child: Image.asset(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF2A1038)),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66140A22),
                          Color(0xCC000000),
                          Color(0xFF000000),
                        ],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0x33FFFFFF),
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'NOWSSB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Currently Playing · $year',
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
              ),
              const SizedBox(height: 18),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 228,
                    height: 228,
                    child: Image.asset(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  head.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _round(Icons.download_outlined, onTap: () {}),
                  const SizedBox(width: 14),
                  _round(Icons.bookmark_border, onTap: () => onOpen(head)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => onPlay(head),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppThinkingLoader(
                        size: 42,
                        state: OrbState.composing,
                        circlePad: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _round(Icons.chat_bubble_outline, onTap: () => onOpen(head)),
                  const SizedBox(width: 14),
                  _round(Icons.more_vert, onTap: () => onOpen(head)),
                ],
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
                            Text(
                              'Sample this',
                              style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
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
                                      child: Image.asset(
                                        art(words[i].word),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(
                                                color: Color(0xFF333333)),
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
                          child: Image.asset(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ColoredBox(color: Color(0xFF333333)),
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
                      GestureDetector(
                        onTap: () => onPlay(head),
                        child: const AppThinkingLoader(
                          size: 28,
                          state: OrbState.composing,
                          circlePad: 5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onPlay(head),
                        icon: const Icon(Icons.pause_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                  Text(
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
